import 'package:odaklan_core/odaklan_core.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 11, 4, 10);
  DateTime at(int minutes, [int seconds = 0]) =>
      t0.add(Duration(minutes: minutes, seconds: seconds));
  FocusSession start([int minutes = 25]) =>
      FocusSession.start(t0, Duration(minutes: minutes));

  group('rewardFor', () {
    test('keeps full blocks only, bonus on completion', () {
      expect(
        rewardFor(const Duration(minutes: 9, seconds: 59), completed: false),
        const FocusReward(energy: 0, xp: 9),
      );
      expect(
        rewardFor(const Duration(minutes: 25), completed: false),
        const FocusReward(energy: 2, xp: 25),
      );
      expect(
        rewardFor(const Duration(minutes: 25), completed: true),
        const FocusReward(energy: 3, xp: 50),
      );
      expect(
        rewardFor(const Duration(minutes: -5), completed: false),
        FocusReward.zero,
      );
    });
  });

  group('FocusSession', () {
    test('rejects sub-minute sessions', () {
      expect(
        () => FocusSession.start(t0, const Duration(seconds: 30)),
        throwsArgumentError,
      );
    });

    test('completes at planned end with full reward', () {
      final s = start().tick(at(24, 59));
      expect(s.isRunning, isTrue);
      final done = s.tick(at(26));
      expect(done.phase, FocusPhase.completed);
      expect(done.focusedAt(at(99)), const Duration(minutes: 25));
      expect(done.reward, const FocusReward(energy: 3, xp: 50));
    });

    test('short trip out of the app (within grace) is fine', () {
      final s = start().backgrounded(at(5)).resumed(at(5, 8));
      expect(s.isRunning, isTrue);
    });

    test('leaving the app past grace breaks it; full blocks kept', () {
      final s = start().backgrounded(at(12)).resumed(at(15));
      expect(s.phase, FocusPhase.broken);
      expect(s.focusedAt(at(99)), const Duration(minutes: 12));
      expect(s.reward, const FocusReward(energy: 1, xp: 12));
    });

    test('locking the phone does not break, even for long', () {
      final s = start()
          .backgrounded(at(3))
          .resumed(at(20), lockedAt: at(3, 1), unlockedAt: at(19, 59));
      expect(s.isRunning, isTrue);
    });

    test('unlocking then using other apps breaks it', () {
      final s = start()
          .backgrounded(at(3))
          .resumed(at(20), lockedAt: at(3, 1), unlockedAt: at(15));
      expect(s.phase, FocusPhase.broken);
      expect(s.focusedAt(at(99)), const Duration(minutes: 15));
    });

    test('lock long after leaving does not excuse leaving', () {
      final s = start()
          .backgrounded(at(3))
          .resumed(at(20), lockedAt: at(8), unlockedAt: at(19, 59));
      expect(s.phase, FocusPhase.broken);
      expect(s.focusedAt(at(99)), const Duration(minutes: 3));
    });

    test('session that ends while phone is locked completes', () {
      final s = start()
          .backgrounded(at(10))
          .resumed(at(40), lockedAt: at(10, 1));
      expect(s.phase, FocusPhase.completed);
    });

    test('leaving right before the end still completes', () {
      final s = start().backgrounded(at(24, 55)).resumed(at(30));
      expect(s.phase, FocusPhase.completed);
    });

    test('give up keeps full blocks, no bonus', () {
      final s = start().giveUp(at(21));
      expect(s.phase, FocusPhase.gaveUp);
      expect(s.reward, const FocusReward(energy: 2, xp: 21));
      expect(s.giveUp(at(22)), same(s));
    });

    test('json round trip; garbage is rejected', () {
      final s = start().backgrounded(at(4));
      final back = FocusSession.tryFromJson(s.toJson())!;
      expect(back.startedAt, s.startedAt);
      expect(back.planned, s.planned);
      expect(back.backgroundedAt, s.backgroundedAt);
      expect(back.phase, FocusPhase.running);
      expect(FocusSession.tryFromJson({'plannedSeconds': 'x'}), isNull);
      expect(
        FocusSession.tryFromJson({...s.toJson(), 'plannedSeconds': 5}),
        isNull,
      );
      expect(FocusSession.tryFromJson('nope'), isNull);
    });
  });
}
