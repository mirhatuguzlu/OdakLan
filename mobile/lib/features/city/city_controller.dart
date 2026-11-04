import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaklan_core/odaklan_core.dart';

import '../../app/services.dart';
import '../focus/wallet.dart';

/// Local city. Becomes a cache of the server city in step 5.
class CityController extends Notifier<City> {
  static const _key = 'city.levels';

  @override
  City build() {
    final raw = ref.watch(prefsProvider).getString(_key);
    if (raw == null) return const City();
    try {
      return City.tryFromJson(jsonDecode(raw));
    } on FormatException {
      return const City();
    }
  }

  UpgradeCheck upgrade(Building b) {
    final wallet = ref.read(walletProvider);
    final check = state.check(b, energy: wallet.energy, xp: wallet.xp);
    if (check != UpgradeCheck.ok) return check;
    if (!ref.read(walletProvider.notifier).spend(state.nextCost(b)!)) {
      return UpgradeCheck.notEnoughEnergy;
    }
    state = state.upgraded(b);
    ref.read(prefsProvider).setString(_key, jsonEncode(state.toJson()));
    HapticFeedback.mediumImpact();
    return check;
  }
}

final cityProvider = NotifierProvider<CityController, City>(CityController.new);
