/// City and player-level rules. Pure Dart, shared by the app, the website
/// and (later) the server.
library;

/// Total XP needed to reach [level] (level 1 = 0 XP, 2 = 50, 3 = 150, ...).
int xpForLevel(int level) => level <= 1 ? 0 : 25 * level * (level - 1);

int levelForXp(int xp) {
  var level = 1;
  while (xp >= xpForLevel(level + 1)) {
    level++;
  }
  return level;
}

class Building {
  const Building({
    required this.id,
    required this.name,
    required this.description,
    required this.baseCost,
    required this.unlockLevel,
    this.maxLevel = 5,
  });

  final String id;
  final String name;
  final String description;

  /// Upgrading to level n costs baseCost * n Enerji.
  final int baseCost;

  /// Player level needed before the first build.
  final int unlockLevel;
  final int maxLevel;

  int costToReach(int level) => baseCost * level;
}

const buildings = <Building>[
  Building(
    id: 'home',
    name: 'Ev',
    description: 'Şehrinin ilk ışığı.',
    baseCost: 2,
    unlockLevel: 1,
  ),
  Building(
    id: 'library',
    name: 'Kütüphane',
    description: 'Sessiz saatlerin anıtı.',
    baseCost: 3,
    unlockLevel: 2,
  ),
  Building(
    id: 'park',
    name: 'Park',
    description: 'Ekransız bir nefes.',
    baseCost: 3,
    unlockLevel: 3,
  ),
  Building(
    id: 'workshop',
    name: 'Atölye',
    description: 'Odaklanan eller burada üretir.',
    baseCost: 5,
    unlockLevel: 4,
  ),
  Building(
    id: 'tower',
    name: 'Odak Kulesi',
    description: 'Şehrin her yerinden görünür.',
    baseCost: 8,
    unlockLevel: 6,
  ),
];

enum UpgradeCheck { ok, maxed, locked, notEnoughEnergy }

/// Building levels by id (0 = empty plot). Immutable.
class City {
  const City([this.levels = const {}]);

  final Map<String, int> levels;

  int levelOf(String id) => levels[id] ?? 0;

  /// Enerji for the next level, or null when maxed.
  int? nextCost(Building b) {
    final next = levelOf(b.id) + 1;
    return next > b.maxLevel ? null : b.costToReach(next);
  }

  UpgradeCheck check(Building b, {required int energy, required int xp}) {
    final cost = nextCost(b);
    if (cost == null) return UpgradeCheck.maxed;
    if (levelForXp(xp) < b.unlockLevel) return UpgradeCheck.locked;
    if (energy < cost) return UpgradeCheck.notEnoughEnergy;
    return UpgradeCheck.ok;
  }

  City upgraded(Building b) => City({...levels, b.id: levelOf(b.id) + 1});

  /// All Enerji ever spent on this city.
  int get totalSpent => [
    for (final b in buildings)
      for (var l = 1; l <= levelOf(b.id); l++) b.costToReach(l),
  ].fold(0, (a, c) => a + c);

  Map<String, Object?> toJson() => {
    for (final e in levels.entries)
      if (e.value > 0) e.key: e.value,
  };

  /// Unknown ids and out-of-range levels are dropped (persisted data is
  /// untrusted).
  static City tryFromJson(Object? json) {
    if (json is! Map) return const City();
    return City({
      for (final b in buildings)
        if (json[b.id] case final int l when l > 0 && l <= b.maxLevel) b.id: l,
    });
  }
}
