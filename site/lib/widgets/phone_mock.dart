import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme.dart';

/// Phone frame previewing the focus timer (the app's step-2 screen).
class PhoneMock extends StatefulWidget {
  const PhoneMock({super.key});

  @override
  State<PhoneMock> createState() => _PhoneMockState();
}

class _PhoneMockState extends State<PhoneMock>
    with SingleTickerProviderStateMixin {
  // One loop = a compressed 25-minute session.
  late final _c = AnimationController(vsync: this, duration: 8.seconds);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 0.62;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Odak zamanlayıcısı önizlemesi',
      child: Container(
        width: 280,
        height: 560,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF05050A),
          borderRadius: BorderRadius.circular(44),
          border: Border.all(color: SiteColors.border, width: 2),
          boxShadow: [
            BoxShadow(
              color: SiteColors.neonCyan.withValues(alpha: 0.25),
              blurRadius: 60,
              spreadRadius: -10,
            ),
            BoxShadow(
              color: SiteColors.neonPink.withValues(alpha: 0.18),
              blurRadius: 80,
              offset: const Offset(20, 40),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: ColoredBox(
            color: SiteColors.background,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final p = _c.value;
                final minutesLeft = (25 * (1 - p)).ceil();
                final energy = (25 * p) ~/ 10;
                return Column(
                  children: [
                    const SizedBox(height: 28),
                    const Text(
                      'ODAK SEANSI',
                      style: TextStyle(
                        letterSpacing: 4,
                        fontSize: 12,
                        color: SiteColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    SizedBox.square(
                      dimension: 200,
                      child: CustomPaint(
                        painter: _RingPainter(p),
                        child: Center(
                          child: Text(
                            '$minutesLeft dk',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: SiteColors.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _chip(Icons.bolt, '+$energy Enerji', SiteColors.neonCyan),
                    const SizedBox(height: 10),
                    _chip(Icons.shield, 'Klan kalesi güvende', SiteColors.success),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2 - 10;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..color = SiteColors.border,
    );
    final arc = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * math.pi * progress;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [SiteColors.neonCyan, SiteColors.neonViolet, SiteColors.neonPink],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(arc);
    // Neon glow under the arc.
    canvas.drawArc(
      arc,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..color = SiteColors.neonCyan.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawArc(arc, -math.pi / 2, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
