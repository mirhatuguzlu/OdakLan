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

  /// Returns and clears the latest lock/unlock times.
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
