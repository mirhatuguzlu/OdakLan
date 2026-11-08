import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaklan_core/odaklan_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/services.dart';
import '../account/account.dart';

/// The server could not be reached (or answered nonsense).
class GameOffline implements Exception {
  const GameOffline();
}

/// Talks to the `game` Edge Function, the only place the rules run for real.
abstract interface class GameBackend {
  /// The function's JSON reply (a GameResult plus `now`).
  /// Throws [GameOffline] when unreachable.
  Future<Map<String, Object?>> send(
    Map<String, Object?> action,
    int tzOffsetMinutes,
  );
}

class SupabaseGameBackend implements GameBackend {
  SupabaseGameBackend(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, Object?>> send(
    Map<String, Object?> action,
    int tzOffsetMinutes,
  ) async {
    try {
      final r = await _client.functions.invoke(
        'game',
        body: {'action': action, 'tzOffsetMinutes': tzOffsetMinutes},
      );
      if (r.data case final Map<String, Object?> data) return data;
    } on FunctionException catch (e) {
      // Account deleted or session revoked: back to the sign-in screen.
      if (e.status == 401) await _client.auth.signOut();
      debugPrint('game: ${e.status}');
    } catch (e) {
      debugPrint('game: $e');
    }
    throw const GameOffline();
  }
}

final gameBackendProvider = Provider<GameBackend>(
  (ref) => SupabaseGameBackend(Supabase.instance.client),
);

/// The signed-in player's game, as the server last returned it.
class GameController extends AsyncNotifier<GameState> {
  /// When the auto-collect notice for a day's leftovers goes off, next day.
  static const noticeHour = 9;

  @override
  Future<GameState> build() async {
    final account = ref.watch(accountProvider).value;
    if (account == null) return GameState.initial;
    final r = await _call(const Sync());
    _after(r);
    return r.state;
  }

  Future<GameResult> _call(GameAction action) async {
    final reply = await ref
        .read(gameBackendProvider)
        .send(action.toJson(), DateTime.now().timeZoneOffset.inMinutes);
    final result = GameResult.tryFromJson(reply);
    if (result == null) throw const GameOffline();
    if (reply['now'] case final String now?) {
      final server = DateTime.tryParse(now);
      if (server != null) {
        ref
            .read(clockSkewProvider.notifier)
            .set(server.difference(DateTime.now()));
      }
    }
    return result;
  }

  /// Sends [action]; the new state replaces the old even when refused.
  /// Throws [GameOffline].
  Future<GameResult> act(GameAction action) async {
    final r = await _call(action);
    state = AsyncData(r.state);
    _after(r);
    return r;
  }

  void _after(GameResult r) {
    if (r.cityEvents.isNotEmpty) {
      ref.read(cityNewsProvider.notifier).show(r.cityEvents);
    }
    final now = ref.read(clockProvider)();
    final today = dayOf(now);
    final notice = ref.read(rewardNoticeProvider);
    // Before the scheduled notice fires, say it now instead.
    if (r.autoCollected > 0 &&
        now.isBefore(today.add(const Duration(hours: noticeHour)))) {
      notice.showNow(today, r.autoCollected);
    }
    // shortcut: Android drops alarms on reboot, so that notice is lost (the
    // Enerji is still paid); re-schedule on BOOT_COMPLETED if users miss it.
    notice.schedule(
      addDays(today, 1).add(const Duration(hours: noticeHour)),
      r.state.unclaimedOn(today),
    );
  }
}

final gameProvider = AsyncNotifierProvider<GameController, GameState>(
  GameController.new,
);

/// The state screens render; screens only exist once it has loaded.
final gameStateProvider = Provider<GameState>(
  (ref) => ref.watch(gameProvider).value ?? GameState.initial,
);

typedef Wallet = ({int energy, int xp});

final walletProvider = Provider<Wallet>((ref) {
  final s = ref.watch(gameStateProvider);
  return (energy: s.energy, xp: s.xp);
});

final cityProvider = Provider<City>((ref) => ref.watch(gameStateProvider).city);

/// The latest city changes the player hasn't dismissed yet.
class CityNews extends Notifier<List<CityEvent>> {
  @override
  List<CityEvent> build() => const [];

  void show(List<CityEvent> events) => state = events;
  void clear() => state = const [];
}

final cityNewsProvider = NotifierProvider<CityNews, List<CityEvent>>(
  CityNews.new,
);

/// Enerji already paid but still flying to the balance chip; the chip adds
/// it on impact.
class EnergyInFlight extends Notifier<int> {
  @override
  int build() => 0;

  void add(int energy) => state += energy;
}

final energyInFlightProvider = NotifierProvider<EnergyInFlight, int>(
  EnergyInFlight.new,
);

/// Turkish message for a refused action.
String describeGameError(GameError e) => switch (e) {
  GameError.notEnoughEnergy => 'Yeterli Enerjin yok.',
  GameError.alreadyRunning => 'Zaten süren bir seansın var.',
  GameError.rateLimited => 'Çok hızlı gidiyorsun, biraz bekle.',
  GameError.locked => 'Bu bina için seviyen yetmiyor.',
  GameError.maxed => 'Bu bina zaten en üst seviyede.',
  GameError.freezesFull => 'En fazla $maxFreezes Seri Kalkanı tutabilirsin.',
  GameError.questClaimed => 'Bu ödülü zaten aldın.',
  GameError.questNotDone => 'Görev henüz tamamlanmadı.',
  _ => 'İşlem yapılamadı.',
};

const offlineMessage = 'Sunucuya ulaşılamadı. İnternet bağlantını kontrol et.';

/// Sends [action] from a screen: a refusal or network trouble becomes a
/// snackbar. Returns the result when accepted, else null.
Future<GameResult?> playAction(
  BuildContext context,
  WidgetRef ref,
  GameAction action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final r = await ref.read(gameProvider.notifier).act(action);
    if (r.ok) {
      HapticFeedback.mediumImpact();
      return r;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(describeGameError(r.error!))),
    );
  } on GameOffline {
    messenger.showSnackBar(const SnackBar(content: Text(offlineMessage)));
  }
  return null;
}
