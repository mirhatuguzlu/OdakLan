import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odaklan/app/services.dart';
import 'package:odaklan/features/focus/focus_controller.dart';
import 'package:odaklan/features/focus/wallet.dart';
import 'package:odaklan_core/odaklan_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeLock extends ScreenLockEvents {
  LockEvents next = (lockedAt: null, unlockedAt: null);

  @override
  Future<LockEvents> take() async => next;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late FakeLock lock;
  late SharedPreferences prefs;

  Future<ProviderContainer> makeContainer() async {
    final c = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => now),
        screenLockProvider.overrideWithValue(lock),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 11, 4, 10);
    lock = FakeLock();
  });

  test('locking the phone keeps the session running', () async {
    final c = await makeContainer();
    final focus = c.read(focusProvider.notifier);
    focus.start(const Duration(minutes: 25));

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

  test('leaving the app breaks it and credits full blocks once', () async {
    final c = await makeContainer();
    final focus = c.read(focusProvider.notifier);
    focus.start(const Duration(minutes: 25));

    now = now.add(const Duration(minutes: 12));
    focus.onHidden();
    now = now.add(const Duration(minutes: 1));
    await focus.onShown();
    await focus.onShown(); // Repeated callbacks must not double-credit.

    final s = c.read(focusProvider);
    expect(s.active, isNull);
    expect(s.lastEnded?.phase, FocusPhase.broken);
    expect(c.read(walletProvider), (energy: 1, xp: 12));
    expect(prefs.getString('focus.active'), isNull);
  });

  test('session survives an app restart and completes', () async {
    final c1 = await makeContainer();
    c1.read(focusProvider.notifier).start(const Duration(minutes: 10));
    c1.dispose();

    now = now.add(const Duration(minutes: 11));
    final c2 = await makeContainer();
    final s = c2.read(focusProvider);
    expect(s.lastEnded?.phase, FocusPhase.completed);
    await Future<void>.delayed(Duration.zero); // Deferred wallet credit.
    expect(c2.read(walletProvider), (energy: 2, xp: 20));
  });

  test('corrupt persisted session is ignored', () async {
    await prefs.setString('focus.active', '{not json');
    final c = await makeContainer();
    expect(c.read(focusProvider), (active: null, lastEnded: null));
  });
}
