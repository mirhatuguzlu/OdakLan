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

  void add(FocusReward reward) {
    state = (energy: state.energy + reward.energy, xp: state.xp + reward.xp);
    final prefs = ref.read(prefsProvider);
    prefs.setInt(_energyKey, state.energy);
    prefs.setInt(_xpKey, state.xp);
  }
}

final walletProvider = NotifierProvider<WalletNotifier, Wallet>(
  WalletNotifier.new,
);
