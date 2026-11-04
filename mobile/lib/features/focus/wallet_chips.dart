import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import 'wallet.dart';

/// Enerji + XP balance for app bars.
class WalletChips extends ConsumerWidget {
  const WalletChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = ref.watch(walletProvider);
    return Row(
      children: [
        StatChip(
          icon: Icons.bolt,
          text: '${w.energy}',
          color: AppColors.accent,
        ),
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
  });

  final IconData icon;
  final String text;
  final Color color;

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
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
