import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:odaklan_core/odaklan_core.dart';

import 'theme.dart';
import 'widgets/phone_mock.dart';
import 'widgets/reveal.dart';

const _maxWidth = 1160.0;

/// Centers section content and caps its width.
class SectionFrame extends StatelessWidget {
  const SectionFrame({super.key, required this.child, this.vertical = 96});

  final Widget child;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: vertical),
          child: child,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.eyebrow, this.title, this.subtitle);

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return Reveal(
      child: Column(
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: SiteColors.neonCyan,
              letterSpacing: 4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: wide ? 44 : 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SiteColors.textMuted,
                fontSize: 17,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Hero

class HeroSection extends StatelessWidget {
  const HeroSection({super.key, required this.onLearnMore});

  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final copy = Column(
      crossAxisAlignment:
          wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        _VersionPill(),
        const SizedBox(height: 24),
        GradientText(
          'Kaydırma.\nOdaklan.\nŞehrini kur.',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            fontSize: wide ? 72 : 48,
            fontWeight: FontWeight.w900,
            height: 1.0,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'OdakLan, telefona dokunmadan geçirdiğin her dakikayı oyuna çeviren '
          'bir odak RPG\'si. Arkadaşlarınla Odak Klanı kur; biri TikTok\'a '
          'dalarsa ortak kale hasar alır.',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: const TextStyle(
            fontSize: 19,
            height: 1.55,
            color: SiteColors.textMuted,
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: wide ? WrapAlignment.start : WrapAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: onLearnMore,
              icon: const Icon(Icons.arrow_downward),
              label: const Text('Nasıl çalışır?'),
              style: FilledButton.styleFrom(
                backgroundColor: SiteColors.neonCyan,
                foregroundColor: SiteColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const _StoreSoon(icon: Icons.android, label: 'Google Play — yakında'),
            const _StoreSoon(icon: Icons.apple, label: 'App Store — yakında'),
          ],
        ),
      ],
    );

    final animatedCopy = copy
        .animate()
        .fadeIn(duration: 700.ms)
        .slideX(begin: wide ? -0.05 : 0, curve: Curves.easeOutCubic);
    final phone = const PhoneMock()
        .animate()
        .fadeIn(delay: 250.ms, duration: 800.ms)
        .slideY(begin: 0.15, curve: Curves.easeOutBack)
        .then()
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -12, duration: 3.seconds, curve: Curves.easeInOut);

    return SectionFrame(
      vertical: wide ? 120 : 64,
      child: wide
          ? Row(
              children: [
                Expanded(child: animatedCopy),
                const SizedBox(width: 48),
                phone,
              ],
            )
          : Column(children: [animatedCopy, const SizedBox(height: 56), phone]),
    );
  }
}

class _VersionPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final done = roadmap.where((s) => s.done).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: SiteColors.neonPink.withValues(alpha: 0.5)),
        color: SiteColors.neonPink.withValues(alpha: 0.08),
      ),
      child: Text(
        'v$appVersion · Geliştiriliyor · $done/${roadmap.length} adım',
        style: const TextStyle(
          color: SiteColors.neonPink,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _StoreSoon extends StatelessWidget {
  const _StoreSoon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Disabled on purpose: no store listing exists yet.
    return OutlinedButton.icon(
      onPressed: null,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
    );
  }
}

// ------------------------------------------------------------ Features

const _featureIcons = <String, IconData>{
  'focus_session': Icons.timer_outlined,
  'anti_doomscroll': Icons.block,
  'city': Icons.location_city,
  'clans': Icons.groups_2_outlined,
  'fair_rewards': Icons.verified_user_outlined,
  'quests': Icons.local_fire_department_outlined,
  'social_detect': Icons.radar,
  'privacy': Icons.lock_outline,
};

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final columns = w >= 1100 ? 4 : (w >= 700 ? 2 : 1);
    return SectionFrame(
      child: Column(
        children: [
          const _SectionTitle(
            'Özellikler',
            'Dikkat dağıtıcıları oyuna çevir',
            'Forest\'ın sadeliği, Habitica\'nın RPG ruhu ve arkadaş grubunun '
                'gücü tek uygulamada.',
          ),
          LayoutBuilder(
            builder: (context, c) {
              const gap = 20.0;
              final itemW = (c.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final (i, f) in features.indexed)
                    SizedBox(
                      width: itemW,
                      child: Reveal(
                        delay: (60 * (i % columns)).ms,
                        child: _FeatureCard(f),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard(this.feature);

  final Feature feature;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    final (label, color) = switch (f.status) {
      FeatureStatus.live => ('Yayında', SiteColors.success),
      FeatureStatus.inProgress => ('Geliştiriliyor', SiteColors.neonPink),
      FeatureStatus.planned => ('Yakında', SiteColors.textMuted),
    };
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: 220.ms,
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
        constraints: const BoxConstraints(minHeight: 220),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: SiteColors.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hover ? SiteColors.neonCyan : SiteColors.border,
          ),
          boxShadow: [
            if (_hover)
              BoxShadow(
                color: SiteColors.neonCyan.withValues(alpha: 0.25),
                blurRadius: 32,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _featureIcons[f.id] ?? Icons.auto_awesome,
                  color: SiteColors.neonCyan,
                  size: 32,
                ),
                const Spacer(),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              f.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              f.description,
              style: const TextStyle(color: SiteColors.textMuted, height: 1.5),
            ),
            if (f.platformNote case final note?) ...[
              const SizedBox(height: 12),
              Text(
                note,
                style: const TextStyle(
                  color: SiteColors.neonPink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Clan

class ClanSection extends StatelessWidget {
  const ClanSection({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    const points = [
      (Icons.group_add_outlined, 'Davet koduyla arkadaşlarını klana çağır.'),
      (Icons.trending_down, 'Biri seansı bozarsa ortak kale can kaybeder.'),
      (Icons.build_outlined, 'Odaklanan herkes kaleyi onarır, klan puanı kazanır.'),
      (Icons.leaderboard_outlined, 'Klanlar haftalık liderlik tablosunda yarışır.'),
    ];
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, (icon, text)) in points.indexed)
          Reveal(
            delay: (80 * i).ms,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Icon(icon, color: SiteColors.neonPink),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(text, style: const TextStyle(fontSize: 17)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
    return SectionFrame(
      child: Column(
        children: [
          const _SectionTitle(
            'Odak Klanları',
            'Arkadaş grubunu rezil etme',
            'Akran baskısını verimliliğe çeviren sosyal hesap verebilirlik.',
          ),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: list),
                const SizedBox(width: 48),
                const Expanded(child: Reveal(child: _FortressDemo())),
              ],
            )
          else ...[
            list,
            const SizedBox(height: 24),
            const Reveal(child: _FortressDemo()),
          ],
        ],
      ),
    );
  }
}

/// Looping demo: a member slips, the fortress takes damage, the clan repairs it.
class _FortressDemo extends StatefulWidget {
  const _FortressDemo();

  @override
  State<_FortressDemo> createState() => _FortressDemoState();
}

class _FortressDemoState extends State<_FortressDemo>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: 7.seconds);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 0.45;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // 0–0.3 healthy, 0.3–0.4 hit, 0.4–0.9 repair.
  double _hp(double t) {
    if (t < 0.3) return 1;
    if (t < 0.4) return 1 - 0.35 * Curves.easeOut.transform((t - 0.3) / 0.1);
    if (t < 0.9) return 0.65 + 0.35 * Curves.easeInOut.transform((t - 0.4) / 0.5);
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    const members = ['Ayşe', 'Mert', 'Deniz', 'Can'];
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final hp = _hp(t);
        final hit = t >= 0.3 && t < 0.55;
        final color = Color.lerp(SiteColors.danger, SiteColors.success, hp)!;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: SiteColors.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: hit ? SiteColors.danger : SiteColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.fort, color: color, size: 36),
                  const SizedBox(width: 12),
                  const Text(
                    'Neon Kale',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    '${(hp * 100).round()} HP',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: hp,
                  minHeight: 12,
                  color: color,
                  backgroundColor: SiteColors.border,
                ),
              ),
              const SizedBox(height: 20),
              for (final m in members)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: SiteColors.neonViolet.withValues(alpha: 0.3),
                        child: Text(m[0], style: const TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      Text(m),
                      const Spacer(),
                      if (m == 'Mert' && hit)
                        const Text(
                          'TikTok\'a girdi! −35 HP',
                          style: TextStyle(
                            color: SiteColors.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        const Text(
                          'odaklanıyor',
                          style: TextStyle(color: SiteColors.success),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------- Roadmap

class RoadmapSection extends StatelessWidget {
  const RoadmapSection({super.key});

  @override
  Widget build(BuildContext context) {
    final current = roadmap.firstWhere((s) => !s.done, orElse: () => roadmap.last);
    return SectionFrame(
      child: Column(
        children: [
          const _SectionTitle(
            'Yol haritası',
            'Açık geliştiriliyor',
            'Bu sayfa uygulamayla aynı kaynaktan beslenir; her adımda güncellenir.',
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                for (final (i, s) in roadmap.indexed)
                  Reveal(
                    delay: (40 * i).ms,
                    child: _RoadmapTile(
                      step: s,
                      isCurrent: identical(s, current) && !s.done,
                      isLast: i == roadmap.length - 1,
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

class _RoadmapTile extends StatelessWidget {
  const _RoadmapTile({
    required this.step,
    required this.isCurrent,
    required this.isLast,
  });

  final RoadmapStep step;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = step.done
        ? SiteColors.success
        : (isCurrent ? SiteColors.neonCyan : SiteColors.border);
    Widget dot = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: step.done ? color : SiteColors.background,
        border: Border.all(color: color, width: 2),
      ),
      child: step.done
          ? const Icon(Icons.check, size: 16, color: SiteColors.background)
          : null,
    );
    if (isCurrent && !MediaQuery.disableAnimationsOf(context)) {
      dot = dot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .boxShadow(
            end: BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 16),
            duration: 1.seconds,
          );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              dot,
              if (!isLast)
                Expanded(child: Container(width: 2, color: SiteColors.border)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28, top: 2),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Adım ${step.number}  ',
                      style: TextStyle(color: color, fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: step.title),
                    if (isCurrent)
                      const TextSpan(
                        text: '  · şu an',
                        style: TextStyle(color: SiteColors.neonCyan),
                      ),
                  ],
                ),
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- Footer

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: SiteColors.border)),
        color: SiteColors.background,
      ),
      child: SectionFrame(
        vertical: 40,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          spacing: 24,
          children: [
            Text(
              '© ${DateTime.now().year} OdakLan',
              style: const TextStyle(color: SiteColors.textMuted),
            ),
            const Text(
              'Reklam yok · Veri satışı yok · KVKK uyumlu tasarım',
              style: TextStyle(color: SiteColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
