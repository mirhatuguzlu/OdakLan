import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaklan_core/odaklan_core.dart';

import '../../app/services.dart';
import '../focus/wallet.dart';
import '../progress/progress_controller.dart';

/// Local city. Becomes a cache of the server city in step 5.
class CityController extends Notifier<City> {
  static const _key = 'city.levels';

  @override
  City build() {
    final prefs = ref.watch(prefsProvider);
    final progress = ref.watch(progressProvider);
    final raw = prefs.getString(_key);
    final City stored;
    if (raw == null) {
      stored = City.starter;
    } else {
      try {
        stored = City.tryFromJson(jsonDecode(raw));
      } on FormatException {
        return const City();
      }
    }
    // shortcut: decay settles when the city is (re)built — app start and
    // after every session. A day rollover while the app stays open settles
    // on the next of those; fine until the server owns decay (step 6).
    final u = stored.settle(
      tendedDays: tendedDays(progress.log, progress.frozen),
      today: ref.read(clockProvider)(),
    );
    if (raw == null || u.city.settledDay != stored.settledDay) _save(u.city);
    if (u.events.isNotEmpty) {
      // Providers may not modify other providers while building.
      Future.microtask(
        () => ref.read(cityNewsProvider.notifier).show(u.events),
      );
    }
    return u.city;
  }

  void _save(City city) =>
      ref.read(prefsProvider).setString(_key, jsonEncode(city.toJson()));

  UpgradeCheck upgrade(Building b) {
    final wallet = ref.read(walletProvider);
    final check = state.check(b, energy: wallet.energy, xp: wallet.xp);
    if (check != UpgradeCheck.ok) return check;
    if (!ref.read(walletProvider.notifier).spend(state.nextCost(b)!)) {
      return UpgradeCheck.notEnoughEnergy;
    }
    state = state.upgraded(b);
    _save(state);
    HapticFeedback.mediumImpact();
    return check;
  }

  /// Repairs for kept blocks; cracks the city when the session wasn't
  /// finished. Returns what happened, for the result card.
  List<CityEvent> afterSession(FocusSession ended) {
    final u = state.afterSession(
      blocks: ended.focusedAt(ended.endedAt!).inMinutes ~/ energyBlockMinutes,
      completed: ended.phase == FocusPhase.completed,
    );
    state = u.city;
    _save(state);
    ref.read(cityNewsProvider.notifier).show(u.events);
    return u.events;
  }
}

final cityProvider = NotifierProvider<CityController, City>(CityController.new);

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

/// Turkish one-liner for an event.
String describeCityEvent(CityEvent e) {
  final name = buildingById(e.buildingId).name;
  return switch (e) {
    Damaged(:final amount) => '$name −$amount sağlık',
    Repaired(:final amount) => '$name +$amount onarıldı',
    Collapsed(level: 0) => '$name yıkıldı — harabe yarı fiyatına kurulur',
    Collapsed(:final level) => '$name çöktü: Sv $level’e düştü',
  };
}
