import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odaklan/features/focus/focus_controller.dart';
import 'package:odaklan/features/game/game.dart';
import 'package:odaklan_core/odaklan_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late FakeLock lock;
  late SharedPreferences prefs;
  late LocalGameBackend server;

  Future<ProviderContainer> makeContainer() async {
    final c = ProviderContainer(
      overrides: signedIn(
        prefs: prefs,
        clock: () => now,
        server: server,
        lock: lock,
      ),
    );
    addTearDown(c.dispose);
    await c.read(gameProvider.future);
    return c;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 11, 8, 10);
    lock = FakeLock();
    server = LocalGameBackend(() => now);
  });

  test('start happens on the server, with its clock', () async {
    final c = await makeContainer();
    expect(
      await c.read(focusProvider.notifier).start(const Duration(minutes: 25)),
      isNull,
    );
    expect(server.game.active?.startedAt, now);
    expect(c.read(focusProvider).active?.startedAt, now);
  });

  test('a stake you cannot pay is refused by the server', () async {
    final c = await makeContainer();
    final refused = await c
        .read(focusProvider.notifier)
        .start(const Duration(minutes: 25), stake: 5);
    expect(refused, GameError.notEnoughEnergy);
    expect(c.read(focusProvider).active, isNull);
  });

  test('locking the phone keeps the session running', () async {
    final c = await makeContainer();
    final focus = c.read(focusProvider.notifier);
    await focus.start(const Duration(minutes: 25));

    focus.onHidden();
    lock.next = (
      lockedAt: now.add(const Duration(seconds: 1)),
      unlockedAt: null,
    );
    now = now.add(const Duration(minutes: 15));
    await focus.onShown();

    expect(c.read(focusProvider).active?.isRunning, isTrue);
    expect(c.read(walletProvider).energy, 0);
  });

  test(
    'leaving the app breaks it; the server credits full blocks once',
    () async {
      final c = await makeContainer();
      final focus = c.read(focusProvider.notifier);
      await focus.start(const Duration(minutes: 25));

      now = now.add(const Duration(minutes: 12));
      focus.onHidden();
      now = now.add(const Duration(minutes: 1));
      await focus.onShown();
      await focus.onShown(); // Repeated callbacks must not double-credit.
      await settle();

      final s = c.read(focusProvider);
      expect(s.active, isNull);
      expect(s.lastEnded?.phase, FocusPhase.broken);
      expect(s.credited, const FocusReward(energy: 1, xp: 12));
      expect(c.read(walletProvider), (energy: 1, xp: 12));
      expect(server.game.log.single.minutes, 12);
      expect(prefs.getString('focus.active'), isNull);
    },
  );

  test('a finish made offline is kept and sent later', () async {
    final c = await makeContainer();
    final focus = c.read(focusProvider.notifier);
    await focus.start(const Duration(minutes: 10));

    server.offline = true;
    now = now.add(const Duration(minutes: 10));
    await Future<void>.delayed(const Duration(milliseconds: 1100)); // tick
    expect(c.read(focusProvider).lastEnded?.phase, FocusPhase.completed);
    expect(c.read(focusProvider).credited, isNull);
    expect(prefs.getString('focus.pending'), isNotNull);

    server.offline = false;
    await focus.onShown();
    await settle();
    expect(prefs.getString('focus.pending'), isNull);
    expect(c.read(walletProvider), (energy: 2, xp: 20));
  });

  group('system killed the app while the phone was locked', () {
    Future<ProviderContainer> killedWhileLocked() async {
      final first = await makeContainer();
      final focus = first.read(focusProvider.notifier);
      await focus.start(const Duration(minutes: 25));
      focus.onHidden();
      // Lock times are on disk natively, so they survive the process.
      lock.next = (
        lockedAt: now.add(const Duration(seconds: 1)),
        unlockedAt: null,
      );
      await settle();
      first.dispose(); // process death; the session stays in prefs
      now = now.add(const Duration(minutes: 12));
      return makeContainer();
    }

    test('reopening right after unlock keeps the session', () async {
      final locked = lock.next;
      final c = await killedWhileLocked();
      lock.next = (
        lockedAt: lock.next.lockedAt ?? locked.lockedAt,
        unlockedAt: now.subtract(const Duration(seconds: 3)),
      );
      c.read(focusProvider);
      await settle();
      await settle();
      expect(c.read(focusProvider).active?.isRunning, isTrue);
      expect(c.read(focusProvider).active?.backgroundedAt, isNull);
    });

    test('unlocked and stayed in other apps: broken', () async {
      final c = await killedWhileLocked();
      lock.next = (
        lockedAt: lock.next.lockedAt,
        unlockedAt: now.subtract(const Duration(minutes: 2)),
      );
      c.read(focusProvider);
      await settle();
      await settle();
      expect(c.read(focusProvider).active, isNull);
      expect(c.read(focusProvider).lastEnded?.phase, FocusPhase.broken);
    });
  });

  test('session survives an app restart and completes', () async {
    final c1 = await makeContainer();
    await c1.read(focusProvider.notifier).start(const Duration(minutes: 10));
    c1.dispose();

    now = now.add(const Duration(minutes: 11));
    final c2 = await makeContainer();
    c2.read(focusProvider); // ran out while closed: reported on open
    await settle();
    await settle();
    expect(c2.read(focusProvider).lastEnded?.phase, FocusPhase.completed);
    expect(c2.read(walletProvider), (energy: 2, xp: 20));
  });

  test('a session started on another device is adopted', () async {
    final c = await makeContainer();
    c.read(focusProvider);
    await c.read(gameProvider.notifier).act(const StartSession(45));
    await settle();
    expect(c.read(focusProvider).active?.planned, const Duration(minutes: 45));
  });

  test('corrupt persisted session is ignored', () async {
    await prefs.setString('focus.active', '{not json');
    final c = await makeContainer();
    expect(c.read(focusProvider), (
      active: null,
      lastEnded: null,
      credited: null,
    ));
  });
}
