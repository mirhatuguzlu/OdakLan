import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import 'wallet.dart';

/// Enerji + XP balance for app bars. [energyKey] marks the Enerji icon as a
/// target for [flyEnergy].
class WalletChips extends ConsumerStatefulWidget {
  const WalletChips({super.key, this.energyKey});

  final GlobalKey? energyKey;

  @override
  ConsumerState<WalletChips> createState() => _WalletChipsState();
}

class _WalletChipsState extends ConsumerState<WalletChips> {
  int? _shown;
  int _bumps = 0;

  @override
  Widget build(BuildContext context) {
    final w = ref.watch(walletProvider);
    final energy = math.max<int>(
      0,
      w.energy - ref.watch(energyInFlightProvider),
    );
    if (_shown != null && energy > _shown!) _bumps++;
    _shown = energy;
    return Row(
      children: [
        StatChip(
              icon: Icons.bolt,
              iconKey: widget.energyKey,
              text: '$energy',
              color: AppColors.accent,
            )
            .animate(key: ValueKey(_bumps), autoPlay: _bumps > 0)
            .scaleXY(
              begin: 1.35,
              end: 1,
              duration: 450.ms,
              curve: Curves.elasticOut,
            )
            .shimmer(duration: 450.ms, color: AppColors.accent),
        const SizedBox(width: 8),
        StatChip(
          icon: Icons.star_rounded,
          text: '${w.xp} XP',
          color: AppColors.textMuted,
        ),
      ],
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    this.iconKey,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Key? iconKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, key: iconKey, size: 16, color: color),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
