import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme.dart';

/// Endless synthwave grid + drifting glow orbs, painted every frame.
/// Respects the OS "reduce motion" setting.
class NeonBackground extends StatefulWidget {
  const NeonBackground({super.key});

  @override
  State<NeonBackground> createState() => _NeonBackgroundState();
}

class _NeonBackgroundState extends State<NeonBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _time = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _time.value = elapsed.inMicroseconds / 1e6;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion && _ticker.isActive) _ticker.stop();
    if (!reduceMotion && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _GridPainter(_time),
        size: Size.infinite,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.time) : super(repaint: time);

  final ValueNotifier<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = SiteColors.background,
    );

    // Glow orbs.
    void orb(Color color, double phase, double radius) {
      final c = Offset(
        size.width * (0.5 + 0.35 * math.sin(t * 0.15 + phase)),
        size.height * (0.3 + 0.2 * math.cos(t * 0.12 + phase * 1.7)),
      );
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: radius)),
      );
    }

    final r = size.shortestSide * 0.6;
    orb(SiteColors.neonCyan, 0, r);
    orb(SiteColors.neonPink, 2.1, r * 0.9);
    orb(SiteColors.neonViolet, 4.2, r * 0.8);

    // Perspective floor grid in the lower 45% of the screen.
    final horizon = size.height * 0.55;
    final floorH = size.height - horizon;
    final line = Paint()
      ..strokeWidth = 1
      ..color = SiteColors.neonCyan.withValues(alpha: 0.22);

    final scroll = (t * 0.25) % 1.0;
    for (var i = 0; i < 18; i++) {
      final z = (i + scroll) / 18; // 0 = horizon, 1 = viewer
      final y = horizon + floorH * z * z;
      line.color = SiteColors.neonCyan.withValues(alpha: 0.05 + 0.25 * z);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final cx = size.width / 2;
    line.color = SiteColors.neonPink.withValues(alpha: 0.18);
    for (var i = -12; i <= 12; i++) {
      final xBottom = cx + i * size.width / 10;
      canvas.drawLine(Offset(cx + i * 8, horizon), Offset(xBottom, size.height), line);
    }

    // Fade the horizon into the background.
    canvas.drawRect(
      Rect.fromLTWH(0, horizon - 40, size.width, 120),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SiteColors.background,
            SiteColors.background.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, horizon - 40, size.width, 120)),
    );
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
