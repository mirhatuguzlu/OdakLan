import 'dart:ui';

import 'package:flutter/material.dart';

import 'sections.dart';
import 'theme.dart';
import 'widgets/neon_background.dart';
import 'widgets/reveal.dart';

void main() {
  runApp(const OdakLanSite());
}

class OdakLanSite extends StatelessWidget {
  const OdakLanSite({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OdakLan — Kaydırma, odaklan, şehrini kur',
      debugShowCheckedModeBanner: false,
      theme: buildSiteTheme(),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _features = GlobalKey();
  final _clan = GlobalKey();
  final _roadmap = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: NeonBackground()),
          SelectionArea(
            child: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _NavBarDelegate(
                    links: [
                      ('Özellikler', () => _scrollTo(_features)),
                      ('Klanlar', () => _scrollTo(_clan)),
                      ('Yol haritası', () => _scrollTo(_roadmap)),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: HeroSection(onLearnMore: () => _scrollTo(_features)),
                ),
                SliverToBoxAdapter(child: FeaturesSection(key: _features)),
                SliverToBoxAdapter(child: ClanSection(key: _clan)),
                SliverToBoxAdapter(child: RoadmapSection(key: _roadmap)),
                const SliverToBoxAdapter(child: SiteFooter()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted-glass navigation bar.
class _NavBarDelegate extends SliverPersistentHeaderDelegate {
  _NavBarDelegate({required this.links});

  final List<(String, VoidCallback)> links;

  @override
  double get minExtent => 68;
  @override
  double get maxExtent => 68;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final wide = isWide(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: SiteColors.background.withValues(alpha: 0.6),
            border: const Border(bottom: BorderSide(color: SiteColors.border)),
          ),
          child: SectionFrame(
            vertical: 0,
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: SiteColors.neonCyan),
                  const SizedBox(width: 6),
                  const GradientText(
                    'OdakLan',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  if (wide)
                    for (final (label, onTap) in links)
                      TextButton(
                        onPressed: onTap,
                        child: Text(
                          label,
                          style: const TextStyle(color: SiteColors.text),
                        ),
                      )
                  else
                    PopupMenuButton<VoidCallback>(
                      tooltip: 'Menü',
                      icon: const Icon(Icons.menu),
                      onSelected: (cb) => cb(),
                      itemBuilder: (_) => [
                        for (final (label, onTap) in links)
                          PopupMenuItem(value: onTap, child: Text(label)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_NavBarDelegate old) => old.links != links;
}
