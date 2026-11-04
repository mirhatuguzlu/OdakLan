import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaklan_core/odaklan_core.dart';

import '../../app/theme.dart';
import '../focus/wallet.dart';
import '../focus/wallet_chips.dart';
import '../progress/progress_controller.dart';
import '../../app/services.dart';
import 'city_controller.dart';
import 'city_view.dart';

class CityScreen extends ConsumerWidget {
  const CityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(cityProvider);
    final wallet = ref.watch(walletProvider);
    final level = levelForXp(wallet.xp);
    final news = ref.watch(cityNewsProvider);
    final tendedToday = ref
        .watch(progressProvider)
        .on(ref.watch(clockProvider)())
        .fold(0, (m, e) => m + e.minutes);

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
          const SizedBox(height: 12),
          _Upkeep(city: city, minutes: tendedToday),
          if (news.isNotEmpty) _News(news: news),
          const SizedBox(height: 8),
          CityView(city: city, playerLevel: level),
          const SizedBox(height: 8),
          for (final b in buildings)
            _BuildingTile(
              building: b,
              level: city.levelOf(b.id),
              condition: city.conditionOf(b.id),
              ruin: city.isRuin(b),
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
    required this.condition,
    required this.ruin,
    required this.cost,
    required this.check,
  });

  final Building building;
  final int level;
  final int condition;
  final bool ruin;
  final int? cost;
  final UpgradeCheck check;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = building;
    final subtitle = switch (check) {
      UpgradeCheck.locked => 'Seviye ${b.unlockLevel}’de açılır',
      _ when level == 0 && ruin => 'Harabe · yeniden kurmak yarı fiyat',
      _ => b.effect,
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
                if (level > 0) _ConditionBar(condition: condition),
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

/// Şehir Gücü and today's upkeep: what stops the city from decaying.
class _Upkeep extends StatelessWidget {
  const _Upkeep({required this.city, required this.minutes});

  final City city;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final done = minutes >= tendedDayMinutes;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: done ? AppColors.border : AppColors.accent),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done
                      ? 'Bugünkü bakım tamam'
                      : 'Bugünkü bakım: $minutes / $tendedDayMinutes dk',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  done
                      ? 'Şehrin bu gece yıpranmayacak.'
                      : 'Tamamlamazsan gece her bina −${city.decayPerDay} sağlık kaybeder.',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                '${city.power}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Şehir Gücü',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// What happened to the city since the last look; dismissible.
class _News extends ConsumerWidget {
  const _News({required this.news});

  final List<CityEvent> news;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bad = news.any((e) => e is! Repaired);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bad ? AppColors.danger : AppColors.success),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in news.take(6))
                  Text(
                    describeCityEvent(e),
                    style: const TextStyle(fontSize: 13),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ref.read(cityNewsProvider.notifier).clear(),
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Kapat',
          ),
        ],
      ),
    );
  }
}

class _ConditionBar extends StatelessWidget {
  const _ConditionBar({required this.condition});

  final int condition;

  @override
  Widget build(BuildContext context) {
    final working = condition >= workingCondition;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: condition / maxCondition,
                minHeight: 4,
                backgroundColor: AppColors.raised,
                color: working ? AppColors.success : AppColors.danger,
                semanticsLabel: 'Sağlık',
                semanticsValue: '%$condition',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            working ? '%$condition' : 'Hasarlı · güç kapalı',
            style: TextStyle(
              fontSize: 12,
              color: working ? AppColors.textMuted : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
