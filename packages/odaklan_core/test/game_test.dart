import 'dart:convert';

import 'package:odaklan_core/odaklan_core.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime(2026, 11, 8, 9);
  DateTime at(int minutes) => t0.add(Duration(minutes: minutes));

  GameState rich() => GameState.initial.copyWith(energy: 50, xp: 500);

  GameState started(GameState s, {int minutes = 25, int stake = 0}) {
    final r = applyAction(s, StartSession(minutes, stake: stake), t0);
    expect(r.ok, isTrue, reason: '${r.error}');
    return r.state;
  }

  group('sessions', () {
    test('start uses the server clock; only one at a time', () {
      final s = started(GameState.initial);
      expect(s.active!.startedAt, t0);
      expect(
        applyAction(s, const StartSession(10), at(1)).error,
        GameError.alreadyRunning,
      );
    });

    test('"completed" before the planned end is refused', () {
      final s = started(GameState.initial);
      final r = applyAction(
        s,
        FinishSession(FocusPhase.completed, at(25)),
        at(20),
      );
      expect(r.error, GameError.tooEarly);
      expect(r.state.active, isNotNull);
    });

    test('completed pays the full reward once', () {
      final s = started(GameState.initial);
      final r = applyAction(
        s,
        FinishSession(FocusPhase.completed, at(25)),
        at(25),
      );
      expect(r.ok, isTrue);
      expect(
        r.credited,
        rewardFor(const Duration(minutes: 25), completed: true),
      );
      expect(r.state.energy, r.credited!.energy);
      expect(r.state.active, isNull);
      expect(r.state.log.single.completed, isTrue);
      expect(
        applyAction(
          r.state,
          FinishSession(FocusPhase.completed, at(25)),
          at(26),
        ).error,
        GameError.notRunning,
      );
    });

    test('a break claimed in the future is clamped to the server now', () {
      final s = started(GameState.initial);
      final r = applyAction(
        s,
        FinishSession(FocusPhase.broken, at(24)),
        at(12), // server now: only 12 min passed
      );
      expect(r.state.log.single.minutes, 12);
      expect(r.state.energy, 1);
    });

    test('contract: stake taken at start, returned +50% on finish', () {
      var s = started(rich(), stake: 10);
      expect(s.energy, 40);
      s = applyAction(
        s,
        FinishSession(FocusPhase.completed, at(25)),
        at(25),
      ).state;
      final paid = s.log.single;
      expect(paid.completed, isTrue);
      expect(s.energy, 40 + 15 + 3);
    });

    test('stake above the balance is refused', () {
      expect(
        applyAction(
          GameState.initial,
          const StartSession(25, stake: 5),
          t0,
        ).error,
        GameError.notEnoughEnergy,
      );
    });

    test('abandoned session closes as broken with nothing earned', () {
      final s = started(GameState.initial);
      final later = at(25).add(abandonAfter).add(const Duration(minutes: 1));
      final r = applyAction(s, const Sync(), later);
      expect(r.state.active, isNull);
      expect(r.state.log.single.phase, FocusPhase.broken);
      expect(r.state.log.single.minutes, 0);
    });
  });

  group('spending', () {
    test('upgrade spends Enerji; locked and broke are refused', () {
      final r = applyAction(rich(), const Upgrade('home'), t0);
      expect(r.ok, isTrue);
      expect(r.state.city.levelOf('home'), 2);
      expect(r.state.energy, 50 - City.starter.nextCost(buildingById('home'))!);
      expect(
        applyAction(GameState.initial, const Upgrade('home'), t0).error,
        GameError.notEnoughEnergy,
      );
      expect(
        applyAction(rich(), const Upgrade('tower'), t0).error,
        GameError.locked,
      );
    });

    test('freezes cost Enerji and are capped', () {
      var s = rich();
      for (var i = 0; i < maxFreezes; i++) {
        s = applyAction(s, const BuyFreeze(), t0).state;
      }
      expect(s.freezes, maxFreezes);
      expect(s.energy, 50 - maxFreezes * freezeCost);
      expect(
        applyAction(s, const BuyFreeze(), t0).error,
        GameError.freezesFull,
      );
    });
  });

  group('quests', () {
    GameState withSessions(int n) {
      var s = GameState.initial;
      for (var i = 0; i < n; i++) {
        final start = t0.add(Duration(minutes: 30 * i));
        s = applyAction(s, const StartSession(25), start).state;
        s = applyAction(
          s,
          FinishSession(FocusPhase.completed, start),
          start.add(const Duration(minutes: 25)),
        ).state;
      }
      return s;
    }

    test("claims only today's finished quests, once", () {
      final s = withSessions(3);
      final now = at(120);
      final today = questsFor(now);
      final done = today.where((q) => q.progress(s.on(now)) >= q.target);
      final open = today.where((q) => q.progress(s.on(now)) < q.target);
      for (final q in open) {
        expect(
          applyAction(s, ClaimQuest(q.id), now).error,
          GameError.questNotDone,
        );
      }
      var state = s;
      for (final q in done) {
        final r = applyAction(state, ClaimQuest(q.id), now);
        expect(r.state.energy, state.energy + q.reward);
        expect(
          applyAction(r.state, ClaimQuest(q.id), now).error,
          GameError.questClaimed,
        );
        state = r.state;
      }
      final notToday = questPool.firstWhere(
        (p) => !today.any((t) => t.id == p.id),
      );
      expect(
        applyAction(s, ClaimQuest(notToday.id), now).error,
        GameError.questNotToday,
      );
    });

    test("yesterday's unclaimed quests are collected once, next day", () {
      final s = withSessions(3);
      final owed = s.unclaimedOn(t0);
      final next = DateTime(2026, 11, 9, 8);
      final r = applyAction(s, const Sync(), next);
      expect(r.autoCollected, owed);
      expect(r.state.energy, s.energy + owed);
      expect(applyAction(r.state, const Sync(), next).autoCollected, 0);
    });
  });

  test('more than $maxActionsPerMinute actions a minute are refused', () {
    var s = GameState.initial;
    for (var i = 0; i < maxActionsPerMinute; i++) {
      s = applyAction(s, const Sync(), t0).state;
    }
    expect(applyAction(s, const Sync(), t0).error, GameError.rateLimited);
    expect(applyAction(s, const Sync(), at(1)).ok, isTrue);
  });

  group('server entry point', () {
    Map<String, Object?> call(Map<String, Object?> req) =>
        jsonDecode(handleGameRequest(jsonEncode(req))) as Map<String, Object?>;

    final utc = DateTime.utc(2026, 11, 8, 6).millisecondsSinceEpoch;

    test('fresh player at UTC+3: wall clock and starter city', () {
      final out = call({
        'state': null,
        'action': {'type': 'start', 'minutes': 25},
        'nowUtcMs': utc,
        'tzOffsetMinutes': 180,
      });
      expect(out['error'], isNull);
      expect(out['now'], startsWith('2026-11-08T09:00'));
      final s = GameState.tryFromJson(out['state'])!;
      expect(s.active!.startedAt, DateTime(2026, 11, 8, 9));
      expect(s.city.levelOf('home'), 1);
      expect(GameResult.tryFromJson(out)!.state.toJson(), s.toJson());
    });

    test('junk is refused', () {
      expect(handleGameRequest('nope'), contains('badRequest'));
      expect(
        call({
          'action': {'type': 'start', 'minutes': 7},
          'nowUtcMs': utc,
        }),
        {'error': 'badRequest'},
      );
      expect(
        call({
          'action': {'type': 'hack'},
          'nowUtcMs': utc,
        }),
        {'error': 'badRequest'},
      );
    });

    test('timezone can change only once a day', () {
      var out = call({
        'action': {'type': 'sync'},
        'nowUtcMs': utc,
        'tzOffsetMinutes': 180,
      });
      out = call({
        'state': out['state'],
        'action': {'type': 'sync'},
        'nowUtcMs': utc + 60000,
        'tzOffsetMinutes': 600,
      });
      expect((out['state'] as Map)['tzOffsetMinutes'], 600);
      out = call({
        'state': out['state'],
        'action': {'type': 'sync'},
        'nowUtcMs': utc + 120000,
        'tzOffsetMinutes': -300,
      });
      expect((out['state'] as Map)['tzOffsetMinutes'], 600);
    });
  });
}
