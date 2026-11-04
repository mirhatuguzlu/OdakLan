/// Progress rules: intentions, focus contract (stake), session log, stats,
/// streaks with freezes and daily quests. Pure Dart, clock injected.
library;

import 'focus.dart';

// ------------------------------------------------------------ Intentions

class FocusTag {
  const FocusTag(this.id, this.label);

  final String id;
  final String label;
}

/// What the user is focusing on; picked before a session.
const focusTags = <FocusTag>[
  FocusTag('study', 'Ders'),
  FocusTag('code', 'Kod'),
  FocusTag('read', 'Okuma'),
  FocusTag('work', 'İş'),
  FocusTag('create', 'Üretim'),
  FocusTag('other', 'Diğer'),
];

bool isFocusTag(String? id) => focusTags.any((t) => t.id == id);

String tagLabel(String? id) =>
    focusTags.where((t) => t.id == id).firstOrNull?.label ?? 'Etiketsiz';

// ------------------------------------------------------- Focus contract

/// Enerji the user may bet on finishing a session (0 = no contract).
const stakeOptions = [0, 2, 5, 10];

/// Finish → stake back plus 50%. Break or give up → stake is lost.
int stakePayout(int stake, {required bool completed}) =>
    completed && stake > 0 ? stake + stake ~/ 2 : 0;

// ---------------------------------------------------------- Session log

DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Calendar-day arithmetic (safe across DST, unlike adding 24h).
DateTime addDays(DateTime day, int n) =>
    DateTime(day.year, day.month, day.day + n);

/// One finished session, as kept in the local history.
class LogEntry {
  const LogEntry({
    required this.endedAt,
    required this.minutes,
    required this.plannedMinutes,
    required this.phase,
    this.tag,
    this.stake = 0,
  });

  factory LogEntry.fromSession(FocusSession s) => LogEntry(
    endedAt: s.endedAt!,
    minutes: s.focusedAt(s.endedAt!).inMinutes,
    plannedMinutes: s.planned.inMinutes,
    phase: s.phase,
    tag: s.tag,
    stake: s.stake,
  );

  final DateTime endedAt;
  final int minutes;
  final int plannedMinutes;
  final FocusPhase phase;
  final String? tag;
  final int stake;

  bool get completed => phase == FocusPhase.completed;
  DateTime get day => dayOf(endedAt);

  /// Local time on purpose: "today" is the user's calendar day.
  Map<String, Object?> toJson() => {
    'endedAt': endedAt.toIso8601String(),
    'minutes': minutes,
    'planned': plannedMinutes,
    'phase': phase.name,
    'tag': tag,
    'stake': stake,
  };

  static LogEntry? tryFromJson(Object? json) {
    if (json is! Map) return null;
    try {
      final minutes = json['minutes'] as int;
      final planned = json['planned'] as int;
      final stake = (json['stake'] as int?) ?? 0;
      final tag = json['tag'] as String?;
      final phase = FocusPhase.values.byName(json['phase'] as String);
      if (minutes < 0 || minutes > planned || planned > 24 * 60) return null;
      if (!stakeOptions.contains(stake) || phase == FocusPhase.running) {
        return null;
      }
      return LogEntry(
        endedAt: DateTime.parse(json['endedAt'] as String),
        minutes: minutes,
        plannedMinutes: planned,
        phase: phase,
        tag: isFocusTag(tag) ? tag : null,
        stake: stake,
      );
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------- Stats

class FocusStats {
  const FocusStats({
    required this.totalMinutes,
    required this.sessions,
    required this.completed,
    required this.minutesByDay,
    required this.minutesByTag,
  });

  factory FocusStats.of(Iterable<LogEntry> log) {
    var total = 0, sessions = 0, completed = 0;
    final byDay = <DateTime, int>{};
    final byTag = <String?, int>{};
    for (final e in log) {
      total += e.minutes;
      sessions++;
      if (e.completed) completed++;
      byDay.update(e.day, (m) => m + e.minutes, ifAbsent: () => e.minutes);
      byTag.update(e.tag, (m) => m + e.minutes, ifAbsent: () => e.minutes);
    }
    return FocusStats(
      totalMinutes: total,
      sessions: sessions,
      completed: completed,
      minutesByDay: byDay,
      minutesByTag: byTag,
    );
  }

  final int totalMinutes;
  final int sessions;
  final int completed;
  final Map<DateTime, int> minutesByDay;
  final Map<String?, int> minutesByTag;

  /// 0..1; 0 when there are no sessions yet.
  double get completionRate => sessions == 0 ? 0 : completed / sessions;

  /// Focused minutes for the [days] calendar days ending at [today], oldest first.
  List<int> lastDays(DateTime today, int days) => [
    for (var i = days - 1; i >= 0; i--)
      minutesByDay[addDays(dayOf(today), -i)] ?? 0,
  ];
}

// --------------------------------------------------------------- Streak

/// A day counts for the streak when at least one session was completed.
Set<DateTime> streakDays(Iterable<LogEntry> log) => {
  for (final e in log)
    if (e.completed) e.day,
};

/// Enerji price of one Seri Kalkanı (streak freeze) and how many you can hold.
const freezeCost = 5;
const maxFreezes = 2;

/// Consecutive done days up to today (or yesterday, if today is not done
/// yet). Frozen days bridge a gap but do not add to the count.
int streakLength(Set<DateTime> done, Set<DateTime> frozen, DateTime today) {
  var day = dayOf(today);
  if (!done.contains(day)) day = addDays(day, -1);
  var length = 0;
  // Bounded walk: a streak can't be older than the history we keep.
  for (var i = 0; i < 3660; i++, day = addDays(day, -1)) {
    if (done.contains(day)) {
      length++;
    } else if (!frozen.contains(day)) {
      break;
    }
  }
  return length;
}

/// Spends freezes on missed days between the last streak day and today, but
/// only if there are enough to cover the whole gap (otherwise the streak is
/// lost and the freezes are kept). Idempotent.
({Set<DateTime> frozen, int freezes}) settleFreezes({
  required Set<DateTime> done,
  required Set<DateTime> frozen,
  required int freezes,
  required DateTime today,
}) {
  final t = dayOf(today);
  final kept = {...frozen};
  DateTime? last;
  for (final d in {...done, ...frozen}) {
    if (d.isBefore(t) && (last == null || d.isAfter(last))) last = d;
  }
  if (last == null || freezes <= 0) return (frozen: kept, freezes: freezes);
  final gap = [
    for (var d = addDays(last, 1); d.isBefore(t); d = addDays(d, 1)) d,
  ];
  if (gap.isEmpty || gap.length > freezes) {
    return (frozen: kept, freezes: freezes);
  }
  return (frozen: kept..addAll(gap), freezes: freezes - gap.length);
}

// --------------------------------------------------------- Daily quests

enum QuestKind { sessions, minutes, longSession, contractWon, earlyBird, tags }

class Quest {
  const Quest(this.id, this.kind, this.target, this.reward, this.title);

  final String id;
  final QuestKind kind;
  final int target;

  /// Enerji paid when claimed.
  final int reward;
  final String title;

  /// Progress from today's log entries (capped at [target]).
  int progress(Iterable<LogEntry> today) {
    final done = today.where((e) => e.completed);
    final value = switch (kind) {
      QuestKind.sessions => done.length,
      QuestKind.minutes => today.fold(0, (m, e) => m + e.minutes),
      QuestKind.longSession => done.where((e) => e.plannedMinutes >= 45).length,
      QuestKind.contractWon => done.where((e) => e.stake > 0).length,
      QuestKind.earlyBird => done.where((e) => e.endedAt.hour < 10).length,
      QuestKind.tags => {
        for (final e in today)
          if (e.minutes >= energyBlockMinutes && e.tag != null) e.tag,
      }.length,
    };
    return value > target ? target : value;
  }
}

const questPool = <Quest>[
  Quest('sessions2', QuestKind.sessions, 2, 3, '2 seans tamamla'),
  Quest('sessions3', QuestKind.sessions, 3, 5, '3 seans tamamla'),
  Quest('minutes40', QuestKind.minutes, 40, 3, 'Toplam 40 dakika odaklan'),
  Quest('minutes90', QuestKind.minutes, 90, 6, 'Toplam 90 dakika odaklan'),
  Quest('long', QuestKind.longSession, 1, 5, '45+ dakikalık bir seansı bitir'),
  Quest('contract', QuestKind.contractWon, 1, 4, 'Sözleşmeli bir seansı kazan'),
  Quest('early', QuestKind.earlyBird, 1, 4, "Saat 10'dan önce bir seans bitir"),
  Quest('tags2', QuestKind.tags, 2, 4, '2 farklı niyetle odaklan'),
];

const questsPerDay = 3;

/// The same 3 quests for everyone on a given calendar day (fixed hash, so
/// app, site and a future server pick identically on every platform).
List<Quest> questsFor(DateTime day) {
  final d = dayOf(day);
  var seed = (d.year * 10000 + d.month * 100 + d.day) & 0x7fffffff;
  final pool = [...questPool];
  final picked = <Quest>[];
  while (picked.length < questsPerDay) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    picked.add(pool.removeAt(seed % pool.length));
  }
  return picked;
}
