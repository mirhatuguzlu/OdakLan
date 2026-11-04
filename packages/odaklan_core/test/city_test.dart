import 'package:odaklan_core/odaklan_core.dart';
import 'package:test/test.dart';

void main() {
  group("decay and loss", decayAndLoss);
  final home = buildings.firstWhere((b) => b.id == 'home');
  final tower = buildings.firstWhere((b) => b.id == 'tower');

  test('level thresholds', () {
    expect(levelForXp(0), 1);
    expect(levelForXp(49), 1);
    expect(levelForXp(50), 2);
    expect(levelForXp(149), 2);
    expect(levelForXp(150), 3);
    for (var l = 1; l < 20; l++) {
      expect(levelForXp(xpForLevel(l)), l);
    }
  });

  test('upgrade checks in order: maxed, locked, energy', () {
    const city = City();
    expect(city.check(home, energy: 1, xp: 0), UpgradeCheck.notEnoughEnergy);
    expect(city.check(home, energy: 2, xp: 0), UpgradeCheck.ok);
    expect(city.check(tower, energy: 999, xp: 0), UpgradeCheck.locked);
    final maxed = City({'home': home.maxLevel});
    expect(maxed.check(home, energy: 999, xp: 0), UpgradeCheck.maxed);
    expect(maxed.nextCost(home), isNull);
  });

  test('upgrade raises level and cost; totalSpent sums costs', () {
    final city = const City().upgraded(home).upgraded(home);
    expect(city.levelOf('home'), 2);
    expect(city.nextCost(home), 6);
    expect(city.totalSpent, 2 + 4);
  });

  test('json round trip drops junk', () {
    final city = City({'home': 3});
    expect(City.tryFromJson(city.toJson()).levels, {'home': 3});
    expect(
      City.tryFromJson({'home': 99, 'tower': 'x', 'evil': 1, 'park': 2}).levels,
      {'park': 2},
    );
    expect(City.tryFromJson('nope').levels, isEmpty);
  });
}

void decayAndLoss() {
  final home = buildingById('home');
  final park = buildingById('park');
  final d = DateTime(2026, 11, 10);

  test('first settle starts counting from today (no retro loss)', () {
    final u = City.starter.settle(tendedDays: {}, today: d);
    expect(u.events, isEmpty);
    expect(u.city.settledDay, DateTime(2026, 11, 9));
  });

  test('untended days decay, tended/frozen days do not, idempotent', () {
    final c = City({'home': 1}, const {}, const {}, DateTime(2026, 11, 6));
    // Days 7, 8, 9 to settle; 8 was tended.
    final u = c.settle(tendedDays: {DateTime(2026, 11, 8)}, today: d);
    expect(u.city.conditionOf('home'), 100 - 2 * 22); // home lvl1 → 22/day
    expect(u.city.settle(tendedDays: {}, today: d).events, isEmpty);
  });

  test('a level collapses at 0 and leaves a half-price ruin', () {
    var c = const City().upgraded(home).upgraded(home);
    c = City(c.levels, const {'home': 10}, c.peak, DateTime(2026, 11, 8));
    final u = c.settle(tendedDays: {}, today: d);
    expect(u.events.whereType<Collapsed>().single.level, 1);
    expect(u.city.levelOf('home'), 1);
    expect(u.city.conditionOf('home'), conditionAfterCollapse);
    expect(u.city.isRuin(home), isTrue);
    expect(u.city.nextCost(home), 2); // full price 4
    expect(u.city.upgraded(home).nextCost(home), 6); // back to full
  });

  test('a long absence is bounded and ends in ruins, not negatives', () {
    final c = City(
      {'home': 1, 'park': 2},
      const {},
      const {'home': 1, 'park': 2},
      DateTime(2020),
    );
    final u = c.settle(tendedDays: {}, today: d);
    expect(u.city.levels, isEmpty);
    expect(u.city.peakOf('park'), 2);
    expect(u.city.power, 0);
  });

  test('breaking cracks the most valuable building, blocks repair weakest', () {
    final c = City({'home': 2, 'park': 1}, const {'home': 50});
    final broken = c.afterSession(blocks: 0, completed: false);
    expect(broken.city.conditionOf('home'), 20); // 30 damage, home worth 4
    final fixed = broken.city.afterSession(blocks: 2, completed: true);
    // park active (lvl1, full) → 13 per block, both go to home.
    expect(fixed.city.conditionOf('home'), 46);
    expect(fixed.events.single, isA<Repaired>());
  });

  test('damaged buildings lose their effect; bonuses apply when working', () {
    const r = FocusReward(energy: 5, xp: 10);
    final ok = City({'library': 2, 'workshop': 1});
    expect(
      ok.boosted(r, completed: true),
      const FocusReward(energy: 6, xp: 12),
    );
    expect(ok.boosted(r, completed: false).energy, 5);
    final hurt = City(const {'library': 2}, const {'library': 39});
    expect(hurt.boosted(r, completed: true).xp, 10);
    expect(park.effect, isNotEmpty);
  });

  test('power drops with condition; json keeps everything valid', () {
    final c = City({'home': 2}, const {'home': 50}, const {
      'home': 3,
    }, DateTime(2026, 11, 9));
    expect(c.power, 2 * 2 * 50 * 10 ~/ 100);
    final back = City.tryFromJson(c.toJson());
    expect(back.conditionOf('home'), 50);
    expect(back.peakOf('home'), 3);
    expect(back.settledDay, DateTime(2026, 11, 9));
    // Old flat format still loads; bad condition/peak dropped.
    final old = City.tryFromJson({'home': 2});
    expect(old.levels, {'home': 2});
    expect(old.peakOf('home'), 2);
    final bad = City.tryFromJson({
      'levels': {'home': 2},
      'condition': {'home': 999},
      'peak': {'home': 1},
    });
    expect(bad.conditionOf('home'), 100);
    expect(bad.peakOf('home'), 2);
  });

  test('tendedDays needs 20 min or a freeze', () {
    LogEntry e(int day, int min) => LogEntry(
      endedAt: DateTime(2026, 11, day, 12),
      minutes: min,
      plannedMinutes: 60,
      phase: FocusPhase.completed,
    );
    final t = tendedDays(
      [e(1, 10), e(1, 10), e(2, 15)],
      {DateTime(2026, 11, 3)},
    );
    expect(t, {DateTime(2026, 11, 1), DateTime(2026, 11, 3)});
  });
}
