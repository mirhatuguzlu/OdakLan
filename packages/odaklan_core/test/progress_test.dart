import 'package:odaklan_core/odaklan_core.dart';
import 'package:test/test.dart';

LogEntry entry(
  DateTime at, {
  int minutes = 25,
  int planned = 25,
  bool done = true,
  String? tag,
  int stake = 0,
}) => LogEntry(
  endedAt: at,
  minutes: minutes,
  plannedMinutes: planned,
  phase: done ? FocusPhase.completed : FocusPhase.broken,
  tag: tag,
  stake: stake,
);

void main() {
  final today = DateTime(2026, 11, 4, 15);
  DateTime d(int offset) => addDays(dayOf(today), offset);

  group('contract', () {
    test('finish pays stake + 50%, breaking loses it', () {
      expect(stakePayout(10, completed: true), 15);
      expect(stakePayout(5, completed: true), 7);
      expect(stakePayout(5, completed: false), 0);
      expect(stakePayout(0, completed: true), 0);
    });

    test('session carries stake/tag through background and JSON', () {
      final s = FocusSession.start(
        today,
        const Duration(minutes: 25),
        stake: 5,
        tag: 'code',
      );
      final back = s
          .backgrounded(today.add(const Duration(minutes: 1)))
          .resumed(today.add(const Duration(minutes: 1, seconds: 3)));
      expect((back.stake, back.tag), (5, 'code'));
      final done = back.tick(today.add(const Duration(minutes: 30)));
      expect(done.stakeReturn, 7);
      final json = FocusSession.tryFromJson(done.toJson())!;
      expect((json.stake, json.tag), (5, 'code'));
      expect(FocusSession.tryFromJson({...s.toJson(), 'stake': 999}), isNull);
      expect(
        () => FocusSession.start(today, s.planned, stake: 3),
        throwsArgumentError,
      );
    });

    test('unknown tag is dropped', () {
      final s = FocusSession.start(
        today,
        const Duration(minutes: 10),
        tag: 'x',
      );
      expect(s.tag, isNull);
    });
  });

  group('log + stats', () {
    test('json round trip rejects junk', () {
      final e = entry(today, tag: 'read', stake: 2);
      final back = LogEntry.tryFromJson(e.toJson())!;
      expect(
        (back.endedAt, back.minutes, back.tag, back.stake),
        (today, 25, 'read', 2),
      );
      expect(LogEntry.tryFromJson({...e.toJson(), 'minutes': 99}), isNull);
      expect(LogEntry.tryFromJson('nope'), isNull);
    });

    test('totals, rate, last days, by tag', () {
      final s = FocusStats.of([
        entry(today, tag: 'code'),
        entry(today, minutes: 5, done: false, tag: 'code'),
        entry(d(-2), minutes: 10, planned: 10),
      ]);
      expect(s.totalMinutes, 40);
      expect(s.completionRate, closeTo(2 / 3, 1e-9));
      expect(s.lastDays(today, 3), [10, 0, 30]);
      expect(s.minutesByTag, {'code': 30, null: 10});
    });
  });

  group('streak', () {
    test('counts back from today or yesterday; frozen days bridge', () {
      expect(streakLength({d(0), d(-1), d(-2)}, {}, today), 3);
      expect(streakLength({d(-1), d(-2)}, {}, today), 2);
      expect(streakLength({d(-2)}, {}, today), 0);
      expect(streakLength({d(0), d(-2)}, {d(-1)}, today), 2);
    });

    test('freezes cover a gap only if they cover all of it', () {
      final r = settleFreezes(
        done: {d(-3)},
        frozen: {},
        freezes: 2,
        today: today,
      );
      expect(r.frozen, {d(-2), d(-1)});
      expect(r.freezes, 0);
      expect(streakLength({d(-3)}, r.frozen, today), 1);

      final lost = settleFreezes(
        done: {d(-4)},
        frozen: {},
        freezes: 2,
        today: today,
      );
      expect(lost.frozen, isEmpty);
      expect(lost.freezes, 2);

      final again = settleFreezes(
        done: {d(-3)},
        frozen: r.frozen,
        freezes: 1,
        today: today,
      );
      expect(again.freezes, 1, reason: 'idempotent');
    });

    test('works across a DST change', () {
      final march = DateTime(2026, 3, 30, 12);
      expect(
        streakLength(
          {DateTime(2026, 3, 30), DateTime(2026, 3, 29), DateTime(2026, 3, 28)},
          {},
          march,
        ),
        3,
      );
    });
  });

  group('quests', () {
    test('3 distinct, deterministic per day', () {
      final a = questsFor(today);
      expect(a.length, questsPerDay);
      expect(a.map((q) => q.id).toSet().length, questsPerDay);
      expect(
        questsFor(today.add(const Duration(hours: 5))).map((q) => q.id),
        a.map((q) => q.id),
      );
      final ids = {
        for (var i = 0; i < 30; i++) ...questsFor(d(i)).map((q) => q.id),
      };
      expect(ids.length, greaterThan(questsPerDay), reason: 'rotates');
    });

    test('progress per kind, capped at target', () {
      Quest q(String id) => questPool.firstWhere((q) => q.id == id);
      final log = [
        entry(DateTime(2026, 11, 4, 8), tag: 'code', stake: 5),
        entry(DateTime(2026, 11, 4, 12), minutes: 45, planned: 45, tag: 'read'),
        entry(DateTime(2026, 11, 4, 13), minutes: 20, done: false, tag: 'read'),
      ];
      expect(q('sessions3').progress(log), 2);
      expect(q('minutes40').progress(log), 40);
      expect(q('minutes90').progress(log), 90);
      expect(q('long').progress(log), 1);
      expect(q('contract').progress(log), 1);
      expect(q('early').progress(log), 1);
      expect(q('tags2').progress(log), 2);
    });
  });
}
