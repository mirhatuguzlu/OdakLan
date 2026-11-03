import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odaklan_core/odaklan_core.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import 'focus_controller.dart';
import 'focus_ring.dart';
import 'wallet.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = ref.watch(focusProvider);
    final active = focus.active;
    final ended = focus.lastEnded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Odak'),
        centerTitle: false,
        actions: const [_WalletChips(), SizedBox(width: 12)],
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

class _WalletChips extends ConsumerWidget {
  const _WalletChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = ref.watch(walletProvider);
    return Row(
      children: [
        _Chip(icon: Icons.bolt, text: '${w.energy}', color: AppColors.accent),
        const SizedBox(width: 8),
        _Chip(
          icon: Icons.star_rounded,
          text: '${w.xp} XP',
          color: AppColors.textMuted,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, required this.color});

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
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
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

  @override
  Widget build(BuildContext context) {
    final planned = Duration(minutes: _minutes);
    final best = rewardFor(planned, completed: true);
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
          'Bitirirsen +${best.energy} Enerji · +${best.xp} XP',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => ref.read(focusProvider.notifier).start(planned),
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
          'Başka uygulamaya geçersen ${leaveGrace.inSeconds} sn sonra seans bozulur.',
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
        const Text(
          'Telefonu bırak. Kilitlemek serbest.',
          style: TextStyle(color: AppColors.textMuted),
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
    final r = session.reward;
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
            _Chip(
              icon: Icons.bolt,
              text: '+${r.energy} Enerji',
              color: AppColors.accent,
            ),
            const SizedBox(width: 10),
            _Chip(
              icon: Icons.star_rounded,
              text: '+${r.xp} XP',
              color: AppColors.textMuted,
            ),
          ],
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => ref.read(focusProvider.notifier).dismissResult(),
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
