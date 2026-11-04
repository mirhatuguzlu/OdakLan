import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaklan_core/odaklan_core.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../focus/energy_flight.dart';
import '../focus/wallet_chips.dart';
import 'progress_controller.dart';

/// Where claimed quest Enerji flies to.
final _walletEnergyKey = GlobalKey(debugLabel: 'profileEnergy');

/// Profil tab: streak, daily quests and the focus map (stats).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final today = ref.read(clockProvider)();
    final stats = p.stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: false,
        actions: [
          WalletChips(energyKey: _walletEnergyKey),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _StreakCard(p: p, today: today),
          const _Heading('Bugünün görevleri'),
          for (final q in questsFor(today))
            _QuestTile(q: q, p: p, today: today),
          const _Heading('Toplam'),
          Row(
            children: [
              _Tile(_duration(stats.totalMinutes), 'odak'),
              const SizedBox(width: 8),
              _Tile('${stats.completed}', 'tamamlanan seans'),
              const SizedBox(width: 8),
              _Tile(
                '%${(stats.completionRate * 100).round()}',
                'tamamlama oranı',
              ),
            ],
          ),
          const _Heading('Son 7 gün'),
          _WeekBars(minutes: stats.lastDays(today, 7), today: today),
          const _Heading('Odak haritası · 12 hafta'),
          _Heatmap(stats: stats, today: today),
          const _Heading('Niyetlerine göre'),
          _TagBars(stats: stats),
        ].animate(interval: 30.ms).fadeIn(duration: 250.ms),
      ),
    );
  }
}

String _duration(int minutes) => minutes < 60
    ? '$minutes dk'
    : '${minutes ~/ 60} sa ${minutes % 60 == 0 ? '' : '${minutes % 60} dk'}'
          .trim();

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

// ---------------------------------------------------------------- Streak

class _StreakCard extends ConsumerWidget {
  const _StreakCard({required this.p, required this.today});

  final ProgressState p;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = p.streak(today);
    final doneToday = p.on(today).any((e) => e.completed);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: 40,
                color: doneToday ? AppColors.accent : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$days günlük seri',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      doneToday
                          ? 'Bugün tamam. Yarın da gel.'
                          : 'Seriyi korumak için bugün bir seans bitir.',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              for (var i = 0; i < maxFreezes; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.shield,
                    size: 20,
                    color: i < p.freezes ? AppColors.accent : AppColors.border,
                  ),
                ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Seri Kalkanı: kaçırdığın günü kurtarır.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
              TextButton.icon(
                onPressed: p.freezes >= maxFreezes
                    ? null
                    : () {
                        if (!ref.read(progressProvider.notifier).buyFreeze()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Yeterli Enerjin yok.'),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.bolt, size: 16),
                label: const Text('$freezeCost'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Quests

class _QuestTile extends ConsumerStatefulWidget {
  const _QuestTile({required this.q, required this.p, required this.today});

  final Quest q;
  final ProgressState p;
  final DateTime today;

  @override
  ConsumerState<_QuestTile> createState() => _QuestTileState();
}

class _QuestTileState extends ConsumerState<_QuestTile> {
  final _boltKey = GlobalKey();

  void _claim() {
    // Measure first: claiming swaps the button for a check mark.
    final from = rectOf(_boltKey);
    if (ref.read(progressProvider.notifier).claim(widget.q)) {
      flyEnergy(
        context,
        from: from,
        to: _walletEnergyKey,
        amount: widget.q.reward,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (q, p, today) = (widget.q, widget.p, widget.today);
    final progress = q.progress(p.on(today));
    final done = progress >= q.target;
    final claimed = p.isClaimed(q, today);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _Card(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: claimed ? AppColors.textMuted : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress / q.target,
                      minHeight: 6,
                      backgroundColor: AppColors.raised,
                      color: done ? AppColors.success : AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$progress / ${q.target}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (claimed)
              const Icon(Icons.check_circle, color: AppColors.success)
            else
              FilledButton.tonalIcon(
                onPressed: done ? _claim : null,
                icon: Icon(Icons.bolt, key: _boltKey, size: 16),
                label: Text('+${q.reward}'),
              ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- Stats

class _Tile extends StatelessWidget {
  const _Tile(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

const _weekdays = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.minutes, required this.today});

  final List<int> minutes;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final top = math.max(minutes.reduce(math.max), 1);
    return _Card(
      child: SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < minutes.length; i++)
              Expanded(
                child: Semantics(
                  label: '${minutes[i]} dakika',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (minutes[i] > 0)
                        Text(
                          '${minutes[i]}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        width: 18,
                        height: math.max(3, 90 * minutes[i] / top),
                        decoration: BoxDecoration(
                          color: i == minutes.length - 1
                              ? AppColors.accent
                              : AppColors.accent.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _weekdays[addDays(
                              today,
                              i - minutes.length + 1,
                            ).weekday -
                            1],
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.stats, required this.today});

  final FocusStats stats;
  final DateTime today;

  static const _weeks = 12;

  Color _color(int m) => m == 0
      ? AppColors.raised
      : AppColors.accent.withValues(
          alpha: m < 25
              ? 0.3
              : m < 60
              ? 0.55
              : m < 120
              ? 0.8
              : 1,
        );

  @override
  Widget build(BuildContext context) {
    // Columns are Mon..Sun weeks; the last column holds today.
    final t = dayOf(today);
    final lastMonday = addDays(t, 1 - t.weekday);
    final first = addDays(lastMonday, -7 * (_weeks - 1));
    return _Card(
      child: LayoutBuilder(
        builder: (context, c) {
          final cell = math.min(22.0, (c.maxWidth - 3.0 * _weeks) / _weeks);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var w = 0; w < _weeks; w++)
                Column(
                  children: [
                    for (var d = 0; d < 7; d++)
                      Builder(
                        builder: (_) {
                          final day = addDays(first, w * 7 + d);
                          final m = stats.minutesByDay[day] ?? 0;
                          return Container(
                            width: cell,
                            height: cell,
                            margin: const EdgeInsets.only(bottom: 3),
                            decoration: BoxDecoration(
                              color: day.isAfter(t)
                                  ? Colors.transparent
                                  : _color(m),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        },
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TagBars extends StatelessWidget {
  const _TagBars({required this.stats});

  final FocusStats stats;

  @override
  Widget build(BuildContext context) {
    final rows = stats.minutesByTag.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (rows.isEmpty) {
      return const _Card(
        child: Text(
          'Seans başlatırken bir niyet seç; burada dağılımını göreceksin.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }
    final top = rows.first.value;
    return _Card(
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(width: 72, child: Text(tagLabel(r.key))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: r.value / top,
                        minHeight: 8,
                        backgroundColor: AppColors.raised,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      _duration(r.value),
                      textAlign: TextAlign.end,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
