import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../focus/wallet_chips.dart';
import 'progress_controller.dart';

/// Current streak in days; amber once today is done, muted while at risk.
class StreakChip extends ConsumerWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final today = ref.read(clockProvider)();
    final days = p.streak(today);
    final doneToday = p.on(today).any((e) => e.completed);
    return Semantics(
      label: '$days günlük seri',
      excludeSemantics: true,
      child: StatChip(
        icon: Icons.local_fire_department,
        text: '$days',
        color: doneToday ? AppColors.accent : AppColors.textMuted,
      ),
    );
  }
}
