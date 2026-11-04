import 'package:odaklan_core/odaklan_core.dart';
import 'package:test/test.dart';

void main() {
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
