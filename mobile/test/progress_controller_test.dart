import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odaklan/app/services.dart';
import 'package:odaklan/features/focus/focus_controller.dart';
import 'package:odaklan/features/focus/wallet.dart';
import 'package:odaklan/features/progress/progress_controller.dart';
import 'package:odaklan_core/odaklan_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late SharedPreferences prefs;

  ProviderContainer make() {
    final c = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'wallet.energy': 20,
      'wallet.xp': 0,
    });
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 11, 4, 9);
  });

  test('won contract pays back 1.5x; lost contract keeps the stake', () async {
    final c = make();
    final focus = c.read(focusProvider.notifier);
    focus.start(const Duration(minutes: 10), stake: 10, tag: 'code');
    expect(c.read(walletProvider).energy, 10, reason: 'stake taken up front');
    now = now.add(const Duration(minutes: 10));
    focus.onHidden(); // tick path: completes on resume
    await focus.onShown();
    // 10 left + 2 focus Enerji + 15 contract.
    expect(c.read(walletProvider).energy, 27);

    focus.dismissResult();
    focus.start(const Duration(minutes: 25), stake: 5);
    now = now.add(const Duration(minutes: 3));
    focus.giveUp();
    expect(c.read(walletProvider).energy, 22);

    final log = c.read(progressProvider).log;
    expect(log.map((e) => (e.phase, e.tag, e.stake)), [
      (FocusPhase.completed, 'code', 10),
      (FocusPhase.gaveUp, null, 5),
    ]);
  });

  test('cannot bet more than the balance', () {
    prefs.setInt('wallet.energy', 1);
    final c = make();
    expect(
      c
          .read(focusProvider.notifier)
          .start(const Duration(minutes: 10), stake: 2),
      isFalse,
    );
    expect(c.read(focusProvider).active, isNull);
    expect(c.read(walletProvider).energy, 1);
  });

  test('quest claims once, only when done, and persists', () async {
    final c = make();
    final q = questsFor(now).first;
    expect(c.read(progressProvider.notifier).claim(q), isFalse);
    // Record a day that satisfies every quest kind.
    final p = c.read(progressProvider.notifier);
    for (final (min, tag, stake) in [
      (45, 'code', 5),
      (45, 'read', 0),
      (10, 'work', 0),
    ]) {
      p.record(
        FocusSession(
          startedAt: now,
          planned: Duration(minutes: min),
          phase: FocusPhase.completed,
          endedAt: now.add(Duration(minutes: min)),
          tag: tag,
          stake: stake,
        ),
      );
    }
    final before = c.read(walletProvider).energy;
    expect(p.claim(q), isTrue);
    expect(p.claim(q), isFalse);
    expect(c.read(walletProvider).energy, before + q.reward);

    final c2 = make();
    expect(c2.read(progressProvider).isClaimed(q, now), isTrue);
    expect(c2.read(progressProvider).log.length, 3);
    now = now.add(const Duration(days: 1));
    final c3 = make();
    expect(
      c3.read(progressProvider).isClaimed(q, now),
      isFalse,
      reason: 'new day',
    );
  });

  test('next day auto-collects unclaimed quests once', () async {
    final c = make();
    final p = c.read(progressProvider.notifier);
    for (final (min, tag, stake) in [
      (45, 'code', 5),
      (45, 'read', 0),
      (10, 'work', 0),
    ]) {
      p.record(
        FocusSession(
          startedAt: now,
          planned: Duration(minutes: min),
          phase: FocusPhase.completed,
          endedAt: now.add(Duration(minutes: min)),
          tag: tag,
          stake: stake,
        ),
      );
    }
    final quests = questsFor(now);
    expect(p.claim(quests.first), isTrue);
    final before = c.read(walletProvider).energy;
    final leftover = quests.skip(1).fold(0, (s, q) => s + q.reward);

    now = now.add(const Duration(days: 1));
    Future<int> energyOnOpen() async {
      final next = make();
      next.read(progressProvider);
      await Future<void>.delayed(Duration.zero); // settle runs after build
      return next.read(walletProvider).energy;
    }

    expect(
      await energyOnOpen(),
      before + leftover,
      reason: 'claimed one skipped',
    );
    expect(await energyOnOpen(), before + leftover, reason: 'paid only once');
  });

  test('a freeze bought today saves the streak after a missed day', () {
    final c = make();
    final p = c.read(progressProvider.notifier);
    p.record(
      FocusSession(
        startedAt: now,
        planned: const Duration(minutes: 10),
        phase: FocusPhase.completed,
        endedAt: now,
      ),
    );
    expect(c.read(progressProvider).streak(now), 1);
    expect(p.buyFreeze(), isTrue);
    expect(c.read(walletProvider).energy, 20 - freezeCost);

    now = now.add(const Duration(days: 2)); // Missed one day.
    final c2 = make();
    final s = c2.read(progressProvider);
    expect(s.freezes, 0);
    expect(s.streak(now), 1);
  });

  test('corrupt stored progress is ignored', () {
    prefs.setString('progress.log', '[{"bad":1}, 3, "x"]');
    prefs.setString('progress.claimed', '{nope');
    prefs.setInt('progress.freezes', 99);
    final s = make().read(progressProvider);
    expect(s.log, isEmpty);
    expect(s.freezes, maxFreezes);
  });
}
