import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaklan_core/odaklan_core.dart';

import '../../app/services.dart';

typedef Wallet = ({int energy, int xp});

/// Local Enerji/XP balance. Becomes a cache of the server balance in step 5.
class WalletNotifier extends Notifier<Wallet> {
  static const _energyKey = 'wallet.energy';
  static const _xpKey = 'wallet.xp';

  @override
  Wallet build() {
    final prefs = ref.watch(prefsProvider);
    // Clamp: stored values are untrusted.
    return (
      energy: (prefs.getInt(_energyKey) ?? 0).clamp(0, 1 << 30),
      xp: (prefs.getInt(_xpKey) ?? 0).clamp(0, 1 << 30),
    );
  }

  void add(FocusReward reward) =>
      _save((energy: state.energy + reward.energy, xp: state.xp + reward.xp));

  /// Returns false (and spends nothing) when the balance is too low.
  bool spend(int energy) {
    if (energy < 0 || energy > state.energy) return false;
    _save((energy: state.energy - energy, xp: state.xp));
    return true;
  }

  void _save(Wallet next) {
    state = next;
    final prefs = ref.read(prefsProvider);
    prefs.setInt(_energyKey, state.energy);
    prefs.setInt(_xpKey, state.xp);
  }
}

final walletProvider = NotifierProvider<WalletNotifier, Wallet>(
  WalletNotifier.new,
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
