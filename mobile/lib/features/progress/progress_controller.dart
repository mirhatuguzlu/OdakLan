import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaklan_core/odaklan_core.dart';

import '../../app/services.dart';
import '../focus/wallet.dart';

class ProgressState {
  const ProgressState({
    this.log = const [],
    this.frozen = const {},
    this.freezes = 0,
    this.claimedDay,
    this.claimed = const {},
  });

  /// Oldest first.
  final List<LogEntry> log;
  final Set<DateTime> frozen;
  final int freezes;

  /// Quest ids claimed on [claimedDay]; stale once the day changes.
  final DateTime? claimedDay;
  final Set<String> claimed;

  Iterable<LogEntry> on(DateTime day) => log.where((e) => e.day == dayOf(day));

  bool isClaimed(Quest q, DateTime today) =>
      claimedDay == dayOf(today) && claimed.contains(q.id);

  int streak(DateTime today) => streakLength(streakDays(log), frozen, today);

  FocusStats get stats => FocusStats.of(log);
}

/// Local history, streak and quests. Becomes a server cache in step 6.
class ProgressController extends Notifier<ProgressState> {
  static const _logKey = 'progress.log';
  static const _frozenKey = 'progress.frozen';
  static const _freezesKey = 'progress.freezes';
  static const _claimedKey = 'progress.claimed';

  // shortcut: whole history in one prefs string; move to sqlite/server when
  // users exceed a few thousand sessions.
  static const _maxLog = 2000;

  DateTime _today() => dayOf(ref.read(clockProvider)());

  @override
  ProgressState build() {
    final prefs = ref.watch(prefsProvider);
    final log = [
      for (final j in _list(prefs.getString(_logKey))) ?LogEntry.tryFromJson(j),
    ];
    final frozen = {
      for (final j in _list(prefs.getString(_frozenKey)))
        if (j is String) ?_day(j),
    };
    final claimedRaw = _decode(prefs.getString(_claimedKey));
    final claimedDay = claimedRaw is Map && claimedRaw['day'] is String
        ? _day(claimedRaw['day'] as String)
        : null;
    final claimed = {
      if (claimedRaw is Map && claimedRaw['ids'] is List)
        for (final id in claimedRaw['ids'] as List)
          if (questPool.any((q) => q.id == id)) id as String,
    };
    final settled = settleFreezes(
      done: streakDays(log),
      frozen: frozen,
      freezes: (prefs.getInt(_freezesKey) ?? 0).clamp(0, maxFreezes),
      today: _today(),
    );
    final s = ProgressState(
      log: log,
      frozen: settled.frozen,
      freezes: settled.freezes,
      claimedDay: claimedDay,
      claimed: claimed,
    );
    if (settled.frozen.length != frozen.length) _saveStreak(s);
    return s;
  }

  static Object? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  static List<Object?> _list(String? raw) => switch (_decode(raw)) {
    final List<Object?> l => l,
    _ => const [],
  };

  static DateTime? _day(String s) {
    final d = DateTime.tryParse(s);
    return d == null ? null : dayOf(d);
  }

  static String _dayStr(DateTime d) => d.toIso8601String().substring(0, 10);

  void record(FocusSession ended) {
    final log = [...state.log, LogEntry.fromSession(ended)];
    if (log.length > _maxLog) log.removeRange(0, log.length - _maxLog);
    state = ProgressState(
      log: log,
      frozen: state.frozen,
      freezes: state.freezes,
      claimedDay: state.claimedDay,
      claimed: state.claimed,
    );
    ref
        .read(prefsProvider)
        .setString(_logKey, jsonEncode([for (final e in log) e.toJson()]));
  }

  /// Returns false when not affordable or already holding the maximum.
  bool buyFreeze() {
    if (state.freezes >= maxFreezes) return false;
    if (!ref.read(walletProvider.notifier).spend(freezeCost)) return false;
    state = ProgressState(
      log: state.log,
      frozen: state.frozen,
      freezes: state.freezes + 1,
      claimedDay: state.claimedDay,
      claimed: state.claimed,
    );
    _saveStreak(state);
    HapticFeedback.mediumImpact();
    return true;
  }

  /// Pays a finished, unclaimed quest of today. Returns false otherwise.
  bool claim(Quest q) {
    final today = _today();
    if (!questsFor(today).any((t) => t.id == q.id)) return false;
    if (state.isClaimed(q, today)) return false;
    if (q.progress(state.on(today)) < q.target) return false;
    final claimed = {if (state.claimedDay == today) ...state.claimed, q.id};
    state = ProgressState(
      log: state.log,
      frozen: state.frozen,
      freezes: state.freezes,
      claimedDay: today,
      claimed: claimed,
    );
    ref
        .read(prefsProvider)
        .setString(
          _claimedKey,
          jsonEncode({'day': _dayStr(today), 'ids': claimed.toList()}),
        );
    ref.read(walletProvider.notifier).add(FocusReward(energy: q.reward, xp: 0));
    HapticFeedback.heavyImpact();
    return true;
  }

  void _saveStreak(ProgressState s) {
    final prefs = ref.read(prefsProvider);
    // Only recent frozen days matter for the streak; keep the list small.
    final keep = s.frozen.where((d) => d.isAfter(addDays(_today(), -400)));
    prefs.setString(_frozenKey, jsonEncode([for (final d in keep) _dayStr(d)]));
    prefs.setInt(_freezesKey, s.freezes);
  }
}

final progressProvider = NotifierProvider<ProgressController, ProgressState>(
  ProgressController.new,
);
