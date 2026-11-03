/// Focus-session rules and state machine. Pure Dart, clock injected, so the
/// app, the website and (later) the server agree on the same numbers.
library;

/// Every full block of focused time earns 1 Enerji.
const energyBlockMinutes = 10;

/// Leaving the app for longer than this breaks the session.
const leaveGrace = Duration(seconds: 10);

/// Session lengths offered in the app, in minutes.
const sessionPresetsMinutes = [10, 25, 45, 60];

class FocusReward {
  const FocusReward({required this.energy, required this.xp});

  final int energy;
  final int xp;

  static const zero = FocusReward(energy: 0, xp: 0);

  @override
  bool operator ==(Object other) =>
      other is FocusReward && other.energy == energy && other.xp == xp;

  @override
  int get hashCode => Object.hash(energy, xp);

  @override
  String toString() => 'FocusReward(energy: $energy, xp: $xp)';
}

/// Full 10-minute blocks are always kept; finishing adds +1 Enerji and
/// doubles the XP.
FocusReward rewardFor(Duration focused, {required bool completed}) {
  final minutes = focused.isNegative ? 0 : focused.inMinutes;
  return FocusReward(
    energy: minutes ~/ energyBlockMinutes + (completed ? 1 : 0),
    xp: minutes * (completed ? 2 : 1),
  );
}

enum FocusPhase { running, completed, broken, gaveUp }

/// One focus session. Immutable; every transition returns a new value.
///
/// Background handling: the app reports when it went to the background,
/// and on return, when (if ever) the screen was locked and unlocked
/// meanwhile. Locking the phone is fine — that is the point. Only time spent
/// *unlocked and outside the app* counts as leaving.
class FocusSession {
  const FocusSession({
    required this.startedAt,
    required this.planned,
    this.phase = FocusPhase.running,
    this.backgroundedAt,
    this.endedAt,
  });

  factory FocusSession.start(DateTime now, Duration planned) {
    if (planned < const Duration(minutes: 1)) {
      throw ArgumentError.value(
        planned,
        'planned',
        'must be at least 1 minute',
      );
    }
    return FocusSession(startedAt: now, planned: planned);
  }

  final DateTime startedAt;
  final Duration planned;
  final FocusPhase phase;

  /// Set while the app is in the background.
  final DateTime? backgroundedAt;

  /// When focus stopped counting (finish, break or give-up).
  final DateTime? endedAt;

  DateTime get plannedEnd => startedAt.add(planned);
  bool get isRunning => phase == FocusPhase.running;

  /// Focused time so far (capped at [planned]).
  Duration focusedAt(DateTime now) {
    final end = endedAt ?? now;
    final d = end.difference(startedAt);
    if (d.isNegative) return Duration.zero;
    return d > planned ? planned : d;
  }

  Duration remainingAt(DateTime now) => planned - focusedAt(now);

  FocusReward get reward => switch (phase) {
    FocusPhase.running => FocusReward.zero,
    FocusPhase.completed => rewardFor(planned, completed: true),
    FocusPhase.broken ||
    FocusPhase.gaveUp => rewardFor(focusedAt(endedAt!), completed: false),
  };

  FocusSession _end(FocusPhase phase, DateTime at) => FocusSession(
    startedAt: startedAt,
    planned: planned,
    phase: phase,
    endedAt: at,
  );

  /// Call on every tick while in the foreground.
  FocusSession tick(DateTime now) {
    if (!isRunning || backgroundedAt != null) return this;
    return now.isBefore(plannedEnd)
        ? this
        : _end(FocusPhase.completed, plannedEnd);
  }

  FocusSession backgrounded(DateTime now) {
    if (!isRunning || backgroundedAt != null) return this;
    return FocusSession(
      startedAt: startedAt,
      planned: planned,
      backgroundedAt: now,
    );
  }

  /// Back in the foreground. [lockedAt]/[unlockedAt] are the latest screen
  /// lock/unlock times the platform saw while we were away (null if none).
  FocusSession resumed(
    DateTime now, {
    DateTime? lockedAt,
    DateTime? unlockedAt,
  }) {
    final left = backgroundedAt;
    if (!isRunning || left == null) return this;

    // A lock within the grace window means "the user put the phone down".
    // Away time then starts only once they unlocked it.
    final lockedSoonAfterLeaving =
        lockedAt != null &&
        !lockedAt.isBefore(left) &&
        lockedAt.difference(left) <= leaveGrace;
    final DateTime? awaySince;
    if (!lockedSoonAfterLeaving) {
      awaySince = left;
    } else if (unlockedAt != null && unlockedAt.isAfter(lockedAt)) {
      awaySince = unlockedAt;
    } else {
      awaySince = null; // Still counted as locked until now.
    }

    if (awaySince != null && now.difference(awaySince) > leaveGrace) {
      final brokeAt = awaySince.add(leaveGrace);
      // Session had already finished before the grace ran out.
      return brokeAt.isBefore(plannedEnd)
          ? _end(FocusPhase.broken, awaySince)
          : _end(FocusPhase.completed, plannedEnd);
    }
    final back = FocusSession(startedAt: startedAt, planned: planned);
    return back.tick(now);
  }

  FocusSession giveUp(DateTime now) =>
      isRunning ? _end(FocusPhase.gaveUp, now) : this;

  Map<String, Object?> toJson() => {
    'startedAt': startedAt.toUtc().toIso8601String(),
    'plannedSeconds': planned.inSeconds,
    'phase': phase.name,
    'backgroundedAt': backgroundedAt?.toUtc().toIso8601String(),
    'endedAt': endedAt?.toUtc().toIso8601String(),
  };

  /// Returns null for anything malformed (persisted data is untrusted).
  static FocusSession? tryFromJson(Object? json) {
    if (json is! Map) return null;
    try {
      DateTime? date(Object? v) =>
          v == null ? null : DateTime.parse(v as String);
      final seconds = json['plannedSeconds'] as int;
      if (seconds < 60 || seconds > 24 * 3600) return null;
      return FocusSession(
        startedAt: date(json['startedAt'])!,
        planned: Duration(seconds: seconds),
        phase: FocusPhase.values.byName(json['phase'] as String),
        backgroundedAt: date(json['backgroundedAt']),
        endedAt: date(json['endedAt']),
      );
    } catch (_) {
      return null;
    }
  }
}
