import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaklan_core/odaklan_core.dart';

import '../../app/theme.dart';
import '../focus/wallet.dart';
import '../focus/wallet_chips.dart';
import 'city_controller.dart';
import 'city_view.dart';

class CityScreen extends ConsumerWidget {
  const CityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(cityProvider);
    final wallet = ref.watch(walletProvider);
    final level = levelForXp(wallet.xp);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Şehir'),
        centerTitle: false,
        actions: const [WalletChips(), SizedBox(width: 12)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _LevelBar(xp: wallet.xp, level: level),
          const SizedBox(height: 8),
          CityView(city: city, playerLevel: level),
          const SizedBox(height: 8),
          for (final b in buildings)
            _BuildingTile(
              building: b,
              level: city.levelOf(b.id),
              cost: city.nextCost(b),
              check: city.check(b, energy: wallet.energy, xp: wallet.xp),
            ),
        ],
      ),
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.xp, required this.level});

  final int xp;
  final int level;

  @override
  Widget build(BuildContext context) {
    final from = xpForLevel(level);
    final to = xpForLevel(level + 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Seviye $level',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Text(
              '${xp - from} / ${to - from} XP',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (xp - from) / (to - from),
            minHeight: 6,
            backgroundColor: AppColors.raised,
          ),
        ),
      ],
    );
  }
}

class _BuildingTile extends ConsumerWidget {
  const _BuildingTile({
    required this.building,
    required this.level,
    required this.cost,
    required this.check,
  });

  final Building building;
  final int level;
  final int? cost;
  final UpgradeCheck check;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = building;
    final subtitle = switch (check) {
      UpgradeCheck.locked => 'Seviye ${b.unlockLevel}’de açılır',
      _ => b.description,
    };
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level == 0 ? b.name : '${b.name} · Sv $level/${b.maxLevel}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: check == UpgradeCheck.locked
                        ? AppColors.textMuted
                        : AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          switch (check) {
            UpgradeCheck.maxed => const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.check_circle, color: AppColors.success),
            ),
            UpgradeCheck.locked => const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.lock_outline,
                color: AppColors.textMuted,
                semanticLabel: 'Kilitli',
              ),
            ),
            _ => FilledButton.tonalIcon(
              onPressed: check == UpgradeCheck.ok
                  ? () => ref.read(cityProvider.notifier).upgrade(b)
                  : null,
              icon: const Icon(Icons.bolt, size: 18),
              label: Text(
                '${level == 0 ? 'Kur' : 'Yükselt'} · $cost',
                semanticsLabel:
                    '${level == 0 ? 'Kur' : 'Yükselt'}, $cost Enerji',
              ),
            ),
          },
        ],
      ),
    );
  }
}
