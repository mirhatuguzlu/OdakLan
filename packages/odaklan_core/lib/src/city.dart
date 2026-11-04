/// City and player-level rules. Pure Dart, shared by the app, the website
/// and (later) the server.
///
/// Design (see docs/game-design.md): losses weigh ~2x gains (loss-aversion
/// meta-analysis, λ≈1.96), so the city is something you can *lose*:
/// - Buildings have a condition (0–100) that decays on days without focus
///   and cracks when you break a session; at 0 a level collapses.
/// - Focus repairs, so the fix for a loss is always "focus more", never pay.
/// - Each building has a different effect, so building order is a strategy.
/// - Collapsed levels leave ruins that rebuild at half price, so a loss
///   invites a comeback instead of churn.
library;

import 'focus.dart';
import 'progress.dart';

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
    required this.effect,
    required this.baseCost,
    required this.unlockLevel,
    this.maxLevel = 5,
  });

  final String id;
  final String name;
  final String description;

  /// What one level of this building does, for the UI and the site.
  final String effect;

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
    effect: 'Her seviye günlük çürümeyi 3 azaltır.',
    baseCost: 2,
    unlockLevel: 1,
  ),
  Building(
    id: 'library',
    name: 'Kütüphane',
    description: 'Sessiz saatlerin anıtı.',
    effect: 'Her seviye seans XP’sine %10 ekler.',
    baseCost: 3,
    unlockLevel: 2,
  ),
  Building(
    id: 'park',
    name: 'Park',
    description: 'Ekransız bir nefes.',
    effect: 'Her seviye 10 dakikalık blok başına onarımı 3 artırır.',
    baseCost: 3,
    unlockLevel: 3,
  ),
  Building(
    id: 'workshop',
    name: 'Atölye',
    description: 'Odaklanan eller burada üretir.',
    effect: 'Tamamlanan seanslarda her seviye Enerji’ye %20 ekler.',
    baseCost: 5,
    unlockLevel: 4,
  ),
  Building(
    id: 'tower',
    name: 'Odak Kulesi',
    description: 'Şehrin her yerinden görünür.',
    effect:
        'Her seviye yarıda bırakma hasarını 4 azaltır, Şehir Gücü’ne %10 ekler.',
    baseCost: 8,
    unlockLevel: 6,
  ),
];

Building buildingById(String id) => buildings.firstWhere((b) => b.id == id);

enum UpgradeCheck { ok, maxed, locked, notEnoughEnergy }

// ---------------------------------------------------------------- Rules

const maxCondition = 100;

/// Below this a building is "hasarlı" and its effect switches off.
const workingCondition = 40;

/// Condition a building keeps after one of its levels collapses.
const conditionAfterCollapse = 60;

/// A day counts as tended when this many minutes were focused (or the day
/// was covered by a Seri Kalkanı).
const tendedDayMinutes = 20;

/// Lazy decay never walks further back than this (by then all is ruins).
const maxDecayDays = 60;

/// One change to the city the player should be told about.
sealed class CityEvent {
  const CityEvent(this.buildingId);
  final String buildingId;
}

class Damaged extends CityEvent {
  const Damaged(super.buildingId, this.amount);
  final int amount;
}

class Repaired extends CityEvent {
  const Repaired(super.buildingId, this.amount);
  final int amount;
}

/// A level was lost; [level] is the level the building fell to (0 = ruins).
class Collapsed extends CityEvent {
  const Collapsed(super.buildingId, this.level);
  final int level;
}

typedef CityUpdate = ({City city, List<CityEvent> events});

/// Building levels, condition, ruins and decay bookkeeping. Immutable.
class City {
  const City([
    this.levels = const {},
    this.condition = const {},
    this.peak = const {},
    this.settledDay,
  ]);

  /// New players start owning a house: something to protect from day one
  /// (endowed progress, Kivetz et al. 2006).
  static const starter = City({'home': 1});

  final Map<String, int> levels;

  /// Missing = full condition.
  final Map<String, int> condition;

  /// Highest level each building ever reached; levels up to it are ruins
  /// that rebuild at half price.
  final Map<String, int> peak;

  /// Last calendar day whose decay has been applied.
  final DateTime? settledDay;

  int levelOf(String id) => levels[id] ?? 0;
  int conditionOf(String id) =>
      levelOf(id) == 0 ? 0 : condition[id] ?? maxCondition;
  int peakOf(String id) => peak[id] ?? 0;

  /// Level whose effect is active right now (0 while damaged).
  int activeLevel(String id) =>
      conditionOf(id) >= workingCondition ? levelOf(id) : 0;

  bool isRuin(Building b) => levelOf(b.id) < peakOf(b.id);

  /// Enerji for the next level, or null when maxed. Ruins cost half.
  int? nextCost(Building b) {
    final next = levelOf(b.id) + 1;
    if (next > b.maxLevel) return null;
    final full = b.costToReach(next);
    return next <= peakOf(b.id) ? (full + 1) ~/ 2 : full;
  }

  UpgradeCheck check(Building b, {required int energy, required int xp}) {
    final cost = nextCost(b);
    if (cost == null) return UpgradeCheck.maxed;
    if (levelForXp(xp) < b.unlockLevel) return UpgradeCheck.locked;
    if (energy < cost) return UpgradeCheck.notEnoughEnergy;
    return UpgradeCheck.ok;
  }

  City _copy({
    Map<String, int>? levels,
    Map<String, int>? condition,
    Map<String, int>? peak,
    DateTime? settledDay,
  }) => City(
    levels ?? this.levels,
    condition ?? this.condition,
    peak ?? this.peak,
    settledDay ?? this.settledDay,
  );

  /// A new level arrives freshly built (full condition).
  City upgraded(Building b) {
    final next = levelOf(b.id) + 1;
    return _copy(
      levels: {...levels, b.id: next},
      condition: {...condition}..remove(b.id),
      peak: {...peak, b.id: next > peakOf(b.id) ? next : peakOf(b.id)},
    );
  }

  /// All Enerji ever spent on this city at full prices.
  int get totalSpent => [
    for (final b in buildings)
      for (var l = 1; l <= levelOf(b.id); l++) b.costToReach(l),
  ].fold(0, (a, c) => a + c);

  // ----------------------------------------------------------- Effects

  int get decayPerDay => 25 - 3 * activeLevel('home');
  int get repairPerBlock => 10 + 3 * activeLevel('park');
  int get breakDamage => 30 - 4 * activeLevel('tower');

  /// Reward plus city bonuses (Kütüphane XP, Atölye Enerji on completion).
  FocusReward boosted(FocusReward r, {required bool completed}) => FocusReward(
    energy:
        r.energy + (completed ? r.energy * activeLevel('workshop') ~/ 5 : 0),
    xp: r.xp + r.xp * activeLevel('library') ~/ 10,
  );

  /// Şehir Gücü: what the city is worth today. The number friends and
  /// clans compare; it drops as buildings decay.
  int get power {
    var p = 0;
    for (final b in buildings) {
      p += levelOf(b.id) * b.baseCost * conditionOf(b.id);
    }
    return p * (10 + activeLevel('tower')) ~/ 100;
  }

  // ------------------------------------------------------------ Change

  /// Lowers [id]'s condition; a level collapses at 0.
  CityUpdate _damage(String id, int amount, List<CityEvent> events) {
    if (levelOf(id) == 0 || amount <= 0) return (city: this, events: events);
    final left = conditionOf(id) - amount;
    events.add(Damaged(id, amount));
    if (left > 0) {
      return (city: _copy(condition: {...condition, id: left}), events: events);
    }
    final fell = levelOf(id) - 1;
    events.add(Collapsed(id, fell));
    return (
      city: _copy(
        levels: {...levels, id: fell}..removeWhere((_, l) => l == 0),
        condition: {...condition, id: conditionAfterCollapse}
          ..removeWhere((k, _) => fell == 0 && k == id),
      ),
      events: events,
    );
  }

  /// Applies decay for every untended day after [settledDay] up to
  /// yesterday. Idempotent per day; a city never settled before starts
  /// counting from today (no retroactive loss for new or updated installs).
  CityUpdate settle({
    required Set<DateTime> tendedDays,
    required DateTime today,
  }) {
    final t = dayOf(today);
    final from = settledDay;
    final yesterday = addDays(t, -1);
    if (from == null) return (city: _copy(settledDay: yesterday), events: []);
    var start = addDays(from, 1);
    if (start.isBefore(addDays(t, -maxDecayDays))) {
      start = addDays(t, -maxDecayDays);
    }
    var city = this;
    final events = <CityEvent>[];
    for (var d = start; d.isBefore(t); d = addDays(d, 1)) {
      if (tendedDays.contains(d)) continue;
      for (final b in buildings) {
        city = city._damage(b.id, city.decayPerDay, events).city;
      }
    }
    final settled =
        city.settledDay != null && city.settledDay!.isAfter(yesterday)
        ? city
        : city._copy(settledDay: yesterday);
    return (city: settled, events: events);
  }

  /// After a session: each kept 10-minute block repairs the weakest
  /// building; breaking or giving up cracks the most valuable one.
  CityUpdate afterSession({required int blocks, required bool completed}) {
    var city = this;
    final events = <CityEvent>[];
    if (!completed) {
      final target = buildings
          .where((b) => levelOf(b.id) > 0)
          .fold<Building?>(
            null,
            (best, b) =>
                best == null ||
                    b.costToReach(levelOf(b.id)) >
                        best.costToReach(levelOf(best.id))
                ? b
                : best,
          );
      if (target != null) {
        city = city._damage(target.id, city.breakDamage, events).city;
      }
    }
    final healed = <String, int>{};
    for (var i = 0; i < blocks; i++) {
      final weak = buildings
          .where((b) => city.levelOf(b.id) > 0)
          .where((b) => city.conditionOf(b.id) < maxCondition)
          .fold<Building?>(
            null,
            (w, b) =>
                w == null || city.conditionOf(b.id) < city.conditionOf(w.id)
                ? b
                : w,
          );
      if (weak == null) break;
      final before = city.conditionOf(weak.id);
      final after = (before + city.repairPerBlock).clamp(0, maxCondition);
      healed.update(
        weak.id,
        (v) => v + after - before,
        ifAbsent: () => after - before,
      );
      city = city._copy(condition: {...city.condition, weak.id: after});
    }
    for (final e in healed.entries) {
      events.add(Repaired(e.key, e.value));
    }
    return (city: city, events: events);
  }

  // -------------------------------------------------------------- JSON

  Map<String, Object?> toJson() => {
    'levels': {
      for (final e in levels.entries)
        if (e.value > 0) e.key: e.value,
    },
    'condition': condition,
    'peak': peak,
    if (settledDay case final d?)
      'settled': d.toIso8601String().substring(0, 10),
  };

  /// Unknown ids and out-of-range values are dropped (persisted data is
  /// untrusted). Accepts the old flat `{id: level}` format.
  static City tryFromJson(Object? json) {
    if (json is! Map) return const City();
    final levelsRaw = json['levels'] is Map ? json['levels'] as Map : json;
    final condRaw = json['condition'] is Map ? json['condition'] as Map : {};
    final peakRaw = json['peak'] is Map ? json['peak'] as Map : {};
    final levels = {
      for (final b in buildings)
        if (levelsRaw[b.id] case final int l when l > 0 && l <= b.maxLevel)
          b.id: l,
    };
    final settled = json['settled'] is String
        ? DateTime.tryParse(json['settled'] as String)
        : null;
    return City(
      levels,
      {
        for (final id in levels.keys)
          if (condRaw[id] case final int c when c > 0 && c <= maxCondition)
            id: c,
      },
      {
        for (final b in buildings)
          if (peakRaw[b.id] case final int p
              when p >= (levels[b.id] ?? 0) && p <= b.maxLevel && p > 0)
            b.id: p
          else if (levels[b.id] case final int l)
            b.id: l,
      },
      settled == null ? null : dayOf(settled),
    );
  }
}

/// Days that count as tended: [tendedDayMinutes]+ focused, or frozen.
Set<DateTime> tendedDays(Iterable<LogEntry> log, Set<DateTime> frozen) {
  final minutes = <DateTime, int>{};
  for (final e in log) {
    minutes.update(e.day, (m) => m + e.minutes, ifAbsent: () => e.minutes);
  }
  return {
    ...frozen,
    for (final e in minutes.entries)
      if (e.value >= tendedDayMinutes) e.key,
  };
}
