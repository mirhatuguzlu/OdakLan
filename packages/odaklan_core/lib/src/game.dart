/// The whole game as one state machine: `applyAction(state, action, now)`.
///
/// The server (Supabase Edge Function running this code compiled to JS) is
/// the only place that applies actions for real, with ITS clock; the app
/// renders the state it gets back. All times are the player's wall clock
/// (see [wallClock]), so calendar days match the player's day.
library;

import 'dart:convert';

import 'city.dart';
import 'focus.dart';
import 'progress.dart';

/// History kept on the server (and sent to the app) per player.
const maxLogEntries = 2000;

/// Actions accepted per wall-clock minute (anti-spam).
const maxActionsPerMinute = 30;

/// A "completed" report this early before the planned end is accepted
/// (network latency, clock skew between phone and server).
const finishTolerance = Duration(seconds: 30);

/// A session nobody finished (lost phone, reinstall) is closed as broken,
/// with nothing earned, this long after its planned end.
const abandonAfter = Duration(hours: 24);

/// Timezone changes allowed this often, so days can't be farmed.
const tzChangeEvery = Duration(hours: 24);

/// [utcMs] as the wall clock of a player at UTC+[offsetMinutes], built from
/// fields so it is right whatever timezone this code runs in.
DateTime wallClock(int utcMs, int offsetMinutes) {
  final u = DateTime.fromMillisecondsSinceEpoch(
    utcMs + offsetMinutes * 60000,
    isUtc: true,
  );
  return DateTime(
    u.year,
    u.month,
    u.day,
    u.hour,
    u.minute,
    u.second,
    u.millisecond,
  );
}

// ----------------------------------------------------------------- State

class GameState {
  const GameState({
    this.energy = 0,
    this.xp = 0,
    this.city = City.starter,
    this.active,
    this.log = const [],
    this.frozen = const {},
    this.freezes = 0,
    this.claimedDay,
    this.claimed = const {},
    this.questsSettledDay,
    this.tzOffsetMinutes,
    this.tzChangedAt,
    this.rateMinute,
    this.rateCount = 0,
  });

  static const initial = GameState();

  final int energy;
  final int xp;
  final City city;

  /// The running session, if any (server timestamps).
  final FocusSession? active;

  /// Finished sessions, oldest first.
  final List<LogEntry> log;
  final Set<DateTime> frozen;
  final int freezes;

  /// Quest ids claimed on [claimedDay].
  final DateTime? claimedDay;
  final Set<String> claimed;

  /// Last day whose unclaimed quests were auto-collected.
  final DateTime? questsSettledDay;

  final int? tzOffsetMinutes;
  final DateTime? tzChangedAt;

  /// Rate limit window (wall-clock minute) and actions in it.
  final DateTime? rateMinute;
  final int rateCount;

  Iterable<LogEntry> on(DateTime day) => log.where((e) => e.day == dayOf(day));

  bool isClaimed(Quest q, DateTime day) =>
      claimedDay == dayOf(day) && claimed.contains(q.id);

  int streak(DateTime today) => streakLength(streakDays(log), frozen, today);

  FocusStats get stats => FocusStats.of(log);

  /// Enerji of finished quests on [day] that weren't claimed.
  int unclaimedOn(DateTime day) => questsFor(day)
      .where((q) => !isClaimed(q, day) && q.progress(on(day)) >= q.target)
      .fold(0, (sum, q) => sum + q.reward);

  GameState copyWith({
    int? energy,
    int? xp,
    City? city,
    FocusSession? Function()? active,
    List<LogEntry>? log,
    Set<DateTime>? frozen,
    int? freezes,
    DateTime? claimedDay,
    Set<String>? claimed,
    DateTime? questsSettledDay,
    int? tzOffsetMinutes,
    DateTime? tzChangedAt,
    DateTime? rateMinute,
    int? rateCount,
  }) => GameState(
    energy: energy ?? this.energy,
    xp: xp ?? this.xp,
    city: city ?? this.city,
    active: active == null ? this.active : active(),
    log: log ?? this.log,
    frozen: frozen ?? this.frozen,
    freezes: freezes ?? this.freezes,
    claimedDay: claimedDay ?? this.claimedDay,
    claimed: claimed ?? this.claimed,
    questsSettledDay: questsSettledDay ?? this.questsSettledDay,
    tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
    tzChangedAt: tzChangedAt ?? this.tzChangedAt,
    rateMinute: rateMinute ?? this.rateMinute,
    rateCount: rateCount ?? this.rateCount,
  );

  static String _day(DateTime d) => d.toIso8601String().substring(0, 10);

  Map<String, Object?> toJson() => {
    'v': 1,
    'energy': energy,
    'xp': xp,
    'city': city.toJson(),
    'active': active?.toJson(),
    'log': [for (final e in log) e.toJson()],
    'frozen': [for (final d in frozen) _day(d)],
    'freezes': freezes,
    'claimedDay': claimedDay == null ? null : _day(claimedDay!),
    'claimed': claimed.toList(),
    'questsSettledDay': questsSettledDay == null
        ? null
        : _day(questsSettledDay!),
    'tzOffsetMinutes': tzOffsetMinutes,
    'tzChangedAt': tzChangedAt?.toIso8601String(),
    'rateMinute': rateMinute?.toIso8601String(),
    'rateCount': rateCount,
  };

  /// Null for anything that isn't a valid state.
  static GameState? tryFromJson(Object? json) {
    if (json is! Map || json['v'] != 1) return null;
    try {
      DateTime? date(Object? v) => v is String ? DateTime.parse(v) : null;
      DateTime? day(Object? v) => v is String ? dayOf(DateTime.parse(v)) : null;
      int count(Object? v) => v is int && v >= 0 ? v : 0;
      final active = json['active'] == null
          ? null
          : FocusSession.tryFromJson(json['active']);
      return GameState(
        energy: count(json['energy']),
        xp: count(json['xp']),
        city: City.tryFromJson(json['city']),
        active: active != null && active.isRunning ? active : null,
        log: [
          for (final j in (json['log'] as List? ?? const []))
            ?LogEntry.tryFromJson(j),
        ],
        frozen: {
          for (final d in (json['frozen'] as List? ?? const [])) ?day(d),
        },
        freezes: count(json['freezes']).clamp(0, maxFreezes),
        claimedDay: day(json['claimedDay']),
        claimed: {
          for (final id in (json['claimed'] as List? ?? const []))
            if (questPool.any((q) => q.id == id)) id as String,
        },
        questsSettledDay: day(json['questsSettledDay']),
        tzOffsetMinutes: json['tzOffsetMinutes'] as int?,
        tzChangedAt: date(json['tzChangedAt']),
        rateMinute: date(json['rateMinute']),
        rateCount: count(json['rateCount']),
      );
    } catch (_) {
      return null;
    }
  }
}

// --------------------------------------------------------------- Actions

sealed class GameAction {
  const GameAction();

  /// Strict parsing: the server gets this from the network.
  static GameAction? tryFromJson(Object? json) {
    if (json is! Map) return null;
    return switch (json['type']) {
      'sync' => const Sync(),
      'start' => switch ((json['minutes'], json['stake'] ?? 0, json['tag'])) {
        (final int m, final int s, final Object? tag)
            when sessionPresetsMinutes.contains(m) &&
                stakeOptions.contains(s) &&
                (tag == null || isFocusTag(tag as String?)) =>
          StartSession(m, stake: s, tag: tag as String?),
        _ => null,
      },
      'finish' => switch ((json['outcome'], json['endedAt'])) {
        (final String o, final String at)
            when const {'completed', 'broken', 'gaveUp'}.contains(o) &&
                DateTime.tryParse(at) != null =>
          FinishSession(FocusPhase.values.byName(o), DateTime.parse(at)),
        _ => null,
      },
      'upgrade' => switch (json['building']) {
        final String id when buildings.any((b) => b.id == id) => Upgrade(id),
        _ => null,
      },
      'buyFreeze' => const BuyFreeze(),
      'claimQuest' => switch (json['quest']) {
        final String id when questPool.any((q) => q.id == id) => ClaimQuest(id),
        _ => null,
      },
      _ => null,
    };
  }

  Map<String, Object?> toJson();
}

/// Settle the day and return the state.
class Sync extends GameAction {
  const Sync();
  @override
  Map<String, Object?> toJson() => {'type': 'sync'};
}

class StartSession extends GameAction {
  const StartSession(this.minutes, {this.stake = 0, this.tag});
  final int minutes;
  final int stake;
  final String? tag;
  @override
  Map<String, Object?> toJson() => {
    'type': 'start',
    'minutes': minutes,
    'stake': stake,
    'tag': tag,
  };
}

/// The app's report of how the running session ended. [endedAt] only
/// matters for broken / gave-up sessions and is clamped by the server.
class FinishSession extends GameAction {
  const FinishSession(this.outcome, this.endedAt);
  final FocusPhase outcome;
  final DateTime endedAt;
  @override
  Map<String, Object?> toJson() => {
    'type': 'finish',
    'outcome': outcome.name,
    'endedAt': endedAt.toIso8601String(),
  };
}

class Upgrade extends GameAction {
  const Upgrade(this.buildingId);
  final String buildingId;
  @override
  Map<String, Object?> toJson() => {'type': 'upgrade', 'building': buildingId};
}

class BuyFreeze extends GameAction {
  const BuyFreeze();
  @override
  Map<String, Object?> toJson() => {'type': 'buyFreeze'};
}

class ClaimQuest extends GameAction {
  const ClaimQuest(this.questId);
  final String questId;
  @override
  Map<String, Object?> toJson() => {'type': 'claimQuest', 'quest': questId};
}

// ---------------------------------------------------------------- Result

/// Why an action was refused. The state is still settled and returned.
enum GameError {
  badRequest,
  rateLimited,
  alreadyRunning,
  notRunning,
  notEnoughEnergy,
  tooEarly,
  maxed,
  locked,
  freezesFull,
  questNotToday,
  questNotDone,
  questClaimed,
}

class GameResult {
  const GameResult(
    this.state, {
    this.error,
    this.ended,
    this.credited,
    this.cityEvents = const [],
    this.autoCollected = 0,
  });

  final GameState state;
  final GameError? error;

  /// The session a [FinishSession] closed, and what it paid (city bonus
  /// included, contract return not).
  final FocusSession? ended;
  final FocusReward? credited;

  final List<CityEvent> cityEvents;

  /// Enerji of past days' unclaimed quests paid while settling.
  final int autoCollected;

  bool get ok => error == null;

  Map<String, Object?> toJson() => {
    'state': state.toJson(),
    'error': error?.name,
    'ended': ended?.toJson(),
    'credited': credited == null
        ? null
        : {'energy': credited!.energy, 'xp': credited!.xp},
    'cityEvents': [for (final e in cityEvents) cityEventToJson(e)],
    'autoCollected': autoCollected,
  };

  static GameResult? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final state = GameState.tryFromJson(json['state']);
    if (state == null) return null;
    final credited = json['credited'];
    return GameResult(
      state,
      error: GameError.values.asNameMap()[json['error']],
      ended: json['ended'] == null
          ? null
          : FocusSession.tryFromJson(json['ended']),
      credited: credited is Map
          ? FocusReward(
              energy: credited['energy'] as int,
              xp: credited['xp'] as int,
            )
          : null,
      cityEvents: [
        for (final e in (json['cityEvents'] as List? ?? const []))
          ?cityEventFromJson(e),
      ],
      autoCollected: (json['autoCollected'] as int?) ?? 0,
    );
  }
}

Map<String, Object?> cityEventToJson(CityEvent e) => switch (e) {
  Damaged(:final amount) => {
    'type': 'damaged',
    'building': e.buildingId,
    'amount': amount,
  },
  Repaired(:final amount) => {
    'type': 'repaired',
    'building': e.buildingId,
    'amount': amount,
  },
  Collapsed(:final level) => {
    'type': 'collapsed',
    'building': e.buildingId,
    'level': level,
  },
};

CityEvent? cityEventFromJson(Object? json) {
  if (json is! Map || !buildings.any((b) => b.id == json['building'])) {
    return null;
  }
  final id = json['building'] as String;
  return switch ((json['type'], json['amount'], json['level'])) {
    ('damaged', final int a, _) => Damaged(id, a),
    ('repaired', final int a, _) => Repaired(id, a),
    ('collapsed', _, final int l) => Collapsed(id, l),
    _ => null,
  };
}

// ----------------------------------------------------------------- Rules

/// Everything that happens just because time passed: freezes cover gaps,
/// yesterday's finished quests pay out, the city decays, abandoned sessions
/// close. Idempotent for the same [now].
({GameState state, List<CityEvent> events, int autoCollected}) settle(
  GameState s,
  DateTime now,
) {
  final today = dayOf(now);
  final yesterday = addDays(today, -1);

  final f = settleFreezes(
    done: streakDays(s.log),
    frozen: s.frozen,
    freezes: s.freezes,
    today: today,
  );
  s = s.copyWith(frozen: f.frozen, freezes: f.freezes);

  var day = s.questsSettledDay == null
      ? yesterday
      : addDays(s.questsSettledDay!, 1);
  if (day.isBefore(addDays(today, -7))) day = addDays(today, -7);
  var paid = 0;
  for (; day.isBefore(today); day = addDays(day, 1)) {
    // Claims of days before the last claim day aren't kept: paying nothing
    // beats paying twice.
    if (s.claimedDay != null && day.isBefore(s.claimedDay!)) continue;
    paid += s.unclaimedOn(day);
  }
  if (s.questsSettledDay == null || s.questsSettledDay!.isBefore(yesterday)) {
    s = s.copyWith(questsSettledDay: yesterday);
  }
  s = s.copyWith(energy: s.energy + paid);

  final c = s.city.settle(tendedDays: tendedDays(s.log, s.frozen), today: now);
  s = s.copyWith(city: c.city);

  final a = s.active;
  if (a != null && now.isAfter(a.plannedEnd.add(abandonAfter))) {
    final ended = a.endAs(FocusPhase.broken, a.startedAt);
    s = _record(s.copyWith(active: () => null), ended);
  }
  return (state: s, events: c.events, autoCollected: paid);
}

GameState _record(GameState s, FocusSession ended) {
  final log = [...s.log, LogEntry.fromSession(ended)];
  if (log.length > maxLogEntries) {
    log.removeRange(0, log.length - maxLogEntries);
  }
  return s.copyWith(log: log);
}

/// Applies [action] at the player's wall-clock [now].
GameResult applyAction(GameState state, GameAction action, DateTime now) {
  final minute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
  if (state.rateMinute == minute && state.rateCount >= maxActionsPerMinute) {
    return GameResult(state, error: GameError.rateLimited);
  }
  state = state.copyWith(
    rateMinute: minute,
    rateCount: state.rateMinute == minute ? state.rateCount + 1 : 1,
  );

  final settled = settle(state, now);
  var s = settled.state;
  GameResult done(
    GameState s, {
    GameError? error,
    FocusSession? ended,
    FocusReward? credited,
    List<CityEvent> more = const [],
  }) => GameResult(
    s,
    error: error,
    ended: ended,
    credited: credited,
    cityEvents: [...settled.events, ...more],
    autoCollected: settled.autoCollected,
  );
  GameResult refuse(GameError e) => done(s, error: e);

  switch (action) {
    case Sync():
      return done(s);

    case StartSession(:final minutes, :final stake, :final tag):
      if (s.active != null) return refuse(GameError.alreadyRunning);
      if (stake > s.energy) return refuse(GameError.notEnoughEnergy);
      final session = FocusSession.start(
        now,
        Duration(minutes: minutes),
        stake: stake,
        tag: tag,
      );
      return done(s.copyWith(energy: s.energy - stake, active: () => session));

    case FinishSession(:final outcome, :final endedAt):
      final a = s.active;
      if (a == null) return refuse(GameError.notRunning);
      final FocusSession ended;
      if (outcome == FocusPhase.completed) {
        if (now.isBefore(a.plannedEnd.subtract(finishTolerance))) {
          return refuse(GameError.tooEarly);
        }
        ended = a.endAs(FocusPhase.completed, a.plannedEnd);
      } else {
        // Never later than the server's now or the plan; never before start.
        var at = endedAt;
        if (at.isAfter(now)) at = now;
        if (at.isAfter(a.plannedEnd)) at = a.plannedEnd;
        if (at.isBefore(a.startedAt)) at = a.startedAt;
        ended = a.endAs(outcome, at);
      }
      final completed = ended.phase == FocusPhase.completed;
      // Paid with the city as it was during the session, then the city
      // takes the repair or damage.
      final paid = s.city.boosted(ended.reward, completed: completed);
      final c = s.city.afterSession(
        blocks: ended.focusedAt(ended.endedAt!).inMinutes ~/ energyBlockMinutes,
        completed: completed,
      );
      s = _record(
        s.copyWith(
          energy: s.energy + paid.energy + ended.stakeReturn,
          xp: s.xp + paid.xp,
          city: c.city,
          active: () => null,
        ),
        ended,
      );
      return done(s, ended: ended, credited: paid, more: c.events);

    case Upgrade(:final buildingId):
      final b = buildingById(buildingId);
      switch (s.city.check(b, energy: s.energy, xp: s.xp)) {
        case UpgradeCheck.maxed:
          return refuse(GameError.maxed);
        case UpgradeCheck.locked:
          return refuse(GameError.locked);
        case UpgradeCheck.notEnoughEnergy:
          return refuse(GameError.notEnoughEnergy);
        case UpgradeCheck.ok:
          return done(
            s.copyWith(
              energy: s.energy - s.city.nextCost(b)!,
              city: s.city.upgraded(b),
            ),
          );
      }

    case BuyFreeze():
      if (s.freezes >= maxFreezes) return refuse(GameError.freezesFull);
      if (s.energy < freezeCost) return refuse(GameError.notEnoughEnergy);
      return done(
        s.copyWith(energy: s.energy - freezeCost, freezes: s.freezes + 1),
      );

    case ClaimQuest(:final questId):
      final today = dayOf(now);
      final q = questsFor(today).where((q) => q.id == questId).firstOrNull;
      if (q == null) return refuse(GameError.questNotToday);
      if (s.isClaimed(q, today)) return refuse(GameError.questClaimed);
      if (q.progress(s.on(today)) < q.target) {
        return refuse(GameError.questNotDone);
      }
      return done(
        s.copyWith(
          energy: s.energy + q.reward,
          claimedDay: today,
          claimed: {if (s.claimedDay == today) ...s.claimed, q.id},
        ),
      );
  }
}

/// The server's whole job, as one JSON-in/JSON-out call:
/// `{state, action, nowUtcMs, tzOffsetMinutes}` → [GameResult] JSON plus
/// `now` (the wall clock used). Invalid input → `{"error":"badRequest"}`.
String handleGameRequest(String requestJson) {
  final Object? req;
  try {
    req = jsonDecode(requestJson);
  } on FormatException {
    return jsonEncode({'error': GameError.badRequest.name});
  }
  if (req is! Map) return jsonEncode({'error': GameError.badRequest.name});
  final action = GameAction.tryFromJson(req['action']);
  final nowUtcMs = req['nowUtcMs'];
  final asked = req['tzOffsetMinutes'];
  if (action == null || nowUtcMs is! int) {
    return jsonEncode({'error': GameError.badRequest.name});
  }
  var state = GameState.tryFromJson(req['state']) ?? GameState.initial;

  // The player's timezone, changeable once a day (else days could be farmed).
  final valid = asked is int && asked >= -720 && asked <= 840;
  var offset = state.tzOffsetMinutes ?? (valid ? asked : 0);
  final probe = wallClock(nowUtcMs, offset);
  if (valid &&
      asked != offset &&
      (state.tzChangedAt == null ||
          !probe.isBefore(state.tzChangedAt!.add(tzChangeEvery)))) {
    offset = asked;
    state = state.copyWith(tzChangedAt: wallClock(nowUtcMs, offset));
  }
  state = state.copyWith(tzOffsetMinutes: offset);

  final now = wallClock(nowUtcMs, offset);
  final result = applyAction(state, action, now);
  return jsonEncode({...result.toJson(), 'now': now.toIso8601String()});
}
