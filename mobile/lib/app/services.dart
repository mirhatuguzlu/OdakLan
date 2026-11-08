import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in main() with the loaded instance.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('prefsProvider must be overridden'),
);

/// Injectable clock so tests can control time.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

typedef LockEvents = ({DateTime? lockedAt, DateTime? unlockedAt});

/// Screen lock/unlock times recorded natively (MainActivity / AppDelegate).
class ScreenLockEvents {
  static const _channel = MethodChannel('odaklan/screen_lock');

  /// Returns and clears the first lock (and first unlock after it) since
  /// the last call.
  Future<LockEvents> take() async {
    try {
      final map = await _channel.invokeMapMethod<String, Object?>(
        'takeLockEvents',
      );
      DateTime? at(Object? ms) =>
          ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
      return (
        lockedAt: at(map?['lockedAt']),
        unlockedAt: at(map?['unlockedAt']),
      );
    } on MissingPluginException {
      // Tests / unsupported platforms: no lock info, treated as leaving the app.
      return (lockedAt: null, unlockedAt: null);
    }
  }
}

final screenLockProvider = Provider<ScreenLockEvents>(
  (ref) => ScreenLockEvents(),
);

/// Native "come back" notification: a live countdown while the user is away
/// that turns into "session broken" when the grace runs out (Android only).
class LeaveAlert {
  static const _channel = MethodChannel('odaklan/screen_lock');

  Future<void> _call(String method, [Object? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Tests / iOS: no notification.
    }
  }

  Future<void> requestPermission() => _call('requestNotificationPermission');

  Future<void> started(Duration grace) =>
      _call('leaveStarted', {'graceMs': grace.inMilliseconds});

  Future<void> ended() => _call('leaveEnded');
}

final leaveAlertProvider = Provider<LeaveAlert>((ref) => LeaveAlert());

/// Native "yesterday's rewards were auto-collected" notification (Android).
class RewardNotice {
  static const _channel = MethodChannel('odaklan/screen_lock');

  /// Alarm id per fire day, so one day's notice never replaces another's.
  static int _code(DateTime day) =>
      day.year * 10000 + day.month * 100 + day.day;

  Future<void> _call(String method, Map<String, Object?> args) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Tests / iOS: no notification.
    }
  }

  /// Shows the notice at [at]; [energy] 0 cancels that day's notice.
  Future<void> schedule(DateTime at, int energy) => _call(
    'scheduleRewardNotice',
    {'code': _code(at), 'atMs': at.millisecondsSinceEpoch, 'energy': energy},
  );

  /// Shows it now instead of at the alarm scheduled for [day].
  Future<void> showNow(DateTime day, int energy) =>
      _call('showRewardNotice', {'code': _code(day), 'energy': energy});
}

final rewardNoticeProvider = Provider<RewardNotice>((ref) => RewardNotice());

/// While a session runs: screen kept awake, and on Android a foreground
/// "Odaklanıyorsun" service so the system doesn't kill the app when locked.
class SessionKeeper {
  static const _channel = MethodChannel('odaklan/screen_lock');

  Future<void> _call(String method, [Object? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Tests / unsupported platforms.
    }
  }

  /// [subtitle] e.g. "Ders · 25 dk", [goal] what finishing pays.
  Future<void> started(
    DateTime startedAt,
    DateTime plannedEnd, {
    required String subtitle,
    required String goal,
  }) => _call('sessionStarted', {
    'startMs': startedAt.millisecondsSinceEpoch,
    'endMs': plannedEnd.millisecondsSinceEpoch,
    'subtitle': subtitle,
    'goal': goal,
  });

  Future<void> ended() => _call('sessionEnded');
}

final sessionKeeperProvider = Provider<SessionKeeper>((ref) => SessionKeeper());
