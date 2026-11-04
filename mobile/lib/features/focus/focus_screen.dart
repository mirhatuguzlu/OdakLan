import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaklan_core/odaklan_core.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../progress/streak_chip.dart';
import '../city/city_controller.dart';
import 'focus_controller.dart';
import 'focus_ring.dart';
import 'wallet.dart';
import 'wallet_chips.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = ref.watch(focusProvider);
    final active = focus.active;
    final ended = focus.lastEnded;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [Text('Odak'), SizedBox(width: 10), StreakChip()],
        ),
        centerTitle: false,
        actions: const [WalletChips(), SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: active != null
                ? _Running(key: const ValueKey('running'), session: active)
                : ended != null
                ? _Result(key: ValueKey(ended.startedAt), session: ended)
                : const _Idle(key: ValueKey('idle')),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ Idle

class _Idle extends ConsumerStatefulWidget {
  const _Idle({super.key});

  @override
  ConsumerState<_Idle> createState() => _IdleState();
}

class _IdleState extends ConsumerState<_Idle> {
  int _minutes = 25;
  int _stake = 0;
  String? _tag;

  void _start() {
    final ok = ref
        .read(focusProvider.notifier)
        .start(
          Duration(minutes: _minutes),
          stake: _stake,
          tag: _tag,
        );
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sözleşme için yeterli Enerjin yok.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final planned = Duration(minutes: _minutes);
    final city = ref.watch(cityProvider);
    final best = city.boosted(
      rewardFor(planned, completed: true),
      completed: true,
    );
    final energy = ref.watch(walletProvider).energy;
    final won = stakePayout(_stake, completed: true);
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          'Ne kadar odaklanacaksın?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (final m in sessionPresetsMinutes)
              ButtonSegment(value: m, label: Text('$m dk')),
          ],
          selected: {_minutes},
          onSelectionChanged: (s) => setState(() => _minutes = s.first),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final t in focusTags)
              ChoiceChip(
                label: Text(t.label),
                selected: _tag == t.id,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                onSelected: (on) => setState(() => _tag = on ? t.id : null),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Tooltip(
              message:
                  'Enerji yatır: bitirirsen %50 fazlasıyla geri al, kaçarsan kaybet.',
              child: Row(
                children: [
                  Icon(Icons.bolt, size: 16, color: AppColors.accent),
                  Text(
                    'Sözleşme',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  for (final s in stakeOptions)
                    ButtonSegment(
                      value: s,
                      enabled: s <= energy,
                      label: Text(s == 0 ? 'Yok' : '$s'),
                    ),
                ],
                selected: {_stake <= energy ? _stake : 0},
                onSelectionChanged: (s) => setState(() => _stake = s.first),
              ),
            ),
          ],
        ),
        Expanded(
          child: Center(
            child: FocusRing(
              progress: 0,
              planned: planned,
              child: _BigTime(planned),
            ),
          ),
        ),
        Text(
          _stake == 0
              ? 'Bitirirsen +${best.energy} Enerji · +${best.xp} XP'
              : 'Bitirirsen +${best.energy + won} Enerji (sözleşme $won) · +${best.xp} XP',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _start,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Odaklanmaya başla'),
          ),
        ),
        const SizedBox(height: 16),
        const _Rule(
          Icons.lock_outline,
          'Telefonu kilitleyebilirsin, seans devam eder.',
        ),
        _Rule(
          Icons.logout,
          'Başka uygulamaya geçersen ${leaveGrace.inSeconds} sn sonra seans bozulur'
          '${city.levels.isEmpty ? '' : ', en değerli binan −${city.breakDamage} hasar alır'}.',
        ),
        const _Rule(
          Icons.bolt,
          'Her $energyBlockMinutes dakika 1 Enerji; bozulsa da tamamlanan bloklar senin.',
        ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }
}

class _Rule extends StatelessWidget {
  const _Rule(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigTime extends StatelessWidget {
  const _BigTime(this.d);

  final Duration d;

  @override
  Widget build(BuildContext context) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return Text(
      '$m:$s',
      style: const TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

// --------------------------------------------------------------- Running

class _Running extends ConsumerStatefulWidget {
  const _Running({super.key, required this.session});

  final FocusSession session;

  @override
  ConsumerState<_Running> createState() => _RunningState();
}

class _RunningState extends ConsumerState<_Running>
    with SingleTickerProviderStateMixin {
  // Repaints every frame so the ring moves smoothly, not once a second.
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => setState(() {}))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _confirmGiveUp() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vazgeçmek istiyor musun?'),
        content: const Text(
          'Tamamlanan bloklar senin kalır ama bitirme bonusunu kaybedersin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Devam et'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Vazgeç',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok ?? false) ref.read(focusProvider.notifier).giveUp();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final now = ref.read(clockProvider)();
    final focused = s.focusedAt(now);
    final progress = focused.inMilliseconds / s.planned.inMilliseconds;
    final earned = rewardFor(focused, completed: false).energy;

    return Column(
      children: [
        const SizedBox(height: 8),
        Text('Odaktasın', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          [
            if (s.tag != null) tagLabel(s.tag),
            if (s.stake > 0) 'Sözleşme: ${s.stake} Enerji masada',
            if (s.tag == null && s.stake == 0)
              'Telefonu bırak. Kilitlemek serbest.',
          ].join(' · '),
          style: const TextStyle(color: AppColors.textMuted),
        ),
        Expanded(
          child: Center(
            child: Semantics(
              label: 'Kalan süre',
              child: FocusRing(
                progress: progress,
                planned: s.planned,
                child: _BigTime(s.remainingAt(now)),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, color: AppColors.accent),
            Text(
              ' Bu seansta +$earned Enerji',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: _confirmGiveUp, child: const Text('Vazgeç')),
      ],
    );
  }
}

// ---------------------------------------------------------------- Result

class _Result extends ConsumerWidget {
  const _Result({super.key, required this.session});

  final FocusSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(focusProvider).credited ?? session.reward;
    final news = ref.watch(cityNewsProvider);
    final contract = session.stakeReturn;
    final focusedMin = session.focusedAt(session.endedAt!).inMinutes;
    final (icon, color, title, body) = switch (session.phase) {
      FocusPhase.completed => (
        Icons.check_circle,
        AppColors.success,
        'Seans tamamlandı',
        '$focusedMin dakika kesintisiz odaklandın.',
      ),
      FocusPhase.broken => (
        Icons.cancel,
        AppColors.danger,
        'Seans bozuldu',
        'Uygulamadan ayrıldın. $focusedMin dakikalık odak sayıldı.',
      ),
      _ => (
        Icons.flag,
        AppColors.textMuted,
        'Seansı bitirdin',
        '$focusedMin dakika odaklandın.',
      ),
    };

    return Column(
      children: [
        const Spacer(),
        Icon(
          icon,
          size: 88,
          color: color,
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 20),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatChip(
              icon: Icons.bolt,
              text: '+${r.energy} Enerji',
              color: AppColors.accent,
            ),
            const SizedBox(width: 10),
            StatChip(
              icon: Icons.star_rounded,
              text: '+${r.xp} XP',
              color: AppColors.textMuted,
            ),
          ],
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
        if (session.stake > 0) ...[
          const SizedBox(height: 14),
          Text(
            contract > 0
                ? 'Sözleşmeyi kazandın: +$contract Enerji'
                : 'Sözleşmeyi kaybettin: -${session.stake} Enerji',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: contract > 0 ? AppColors.success : AppColors.danger,
            ),
          ).animate().fadeIn(delay: 350.ms),
        ],
        for (final (i, e) in news.indexed)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              describeCityEvent(e),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: e is Repaired ? AppColors.success : AppColors.danger,
              ),
            ).animate().fadeIn(delay: (450 + 120 * i).ms),
          ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              ref.read(cityNewsProvider.notifier).clear();
              ref.read(focusProvider.notifier).dismissResult();
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: const Text('Tamam'),
          ),
        ),
      ],
    );
  }
}
