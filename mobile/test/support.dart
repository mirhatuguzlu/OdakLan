import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:odaklan/app/services.dart';
import 'package:odaklan/features/account/account.dart';
import 'package:odaklan/features/game/game.dart';
import 'package:odaklan_core/odaklan_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The `game` Edge Function in-process: same rules, a controllable clock.
class LocalGameBackend implements GameBackend {
  LocalGameBackend(this.clock);

  final DateTime Function() clock;
  Object? state;
  var offline = false;

  @override
  Future<Map<String, Object?>> send(
    Map<String, Object?> action,
    int tzOffsetMinutes,
  ) async {
    if (offline) throw const GameOffline();
    final now = clock();
    final out =
        jsonDecode(
              handleGameRequest(
                jsonEncode({
                  'state': state,
                  'action': action,
                  'nowUtcMs': now.toUtc().millisecondsSinceEpoch,
                  'tzOffsetMinutes': now.timeZoneOffset.inMinutes,
                }),
              ),
            )
            as Map<String, Object?>;
    if (out['state'] != null) state = out['state'];
    return out;
  }

  GameState get game => GameState.tryFromJson(state)!;
}

class FakeLock extends ScreenLockEvents {
  LockEvents next = (lockedAt: null, unlockedAt: null);

  @override
  Future<LockEvents> take() async {
    final events = next;
    next = (lockedAt: null, unlockedAt: null);
    return events;
  }
}

const testAccount = (id: 'u1', email: 'a@b.co', nickname: 'Odakçı0042');

/// Overrides for a signed-in player talking to [server].
List<Override> signedIn({
  required SharedPreferences prefs,
  required DateTime Function() clock,
  required LocalGameBackend server,
  ScreenLockEvents? lock,
}) => [
  prefsProvider.overrideWithValue(prefs),
  clockProvider.overrideWithValue(clock),
  accountProvider.overrideWithValue(const AsyncData(testAccount)),
  gameBackendProvider.overrideWithValue(server),
  if (lock != null) screenLockProvider.overrideWithValue(lock),
];
