import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:odaklan_core/odaklan_core.dart';

import '../../app/theme.dart';

/// Progress ring with a marker for every Enerji block; passed markers light up.
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.progress,
    required this.planned,
    required this.child,
  });

  final double progress;
  final Duration planned;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _RingPainter(progress.clamp(0, 1), planned),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.planned);

  final double progress;
  final Duration planned;

  static const _stroke = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - _stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = AppColors.border,
    );
    if (progress > 0) {
      canvas.drawArc(
        rect,
        start,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeCap = StrokeCap.round
          ..color = AppColors.accent,
      );
    }

    // Block markers just outside the track.
    final blocks = planned.inMinutes ~/ energyBlockMinutes;
    for (var i = 1; i <= blocks; i++) {
      final f = i * energyBlockMinutes / planned.inMinutes;
      if (f >= 1) continue; // The end is the completion bonus, not a marker.
      final a = start + 2 * math.pi * f;
      final p =
          center + Offset(math.cos(a), math.sin(a)) * (radius + _stroke + 4);
      canvas.drawCircle(
        p,
        4,
        Paint()..color = progress >= f ? AppColors.accent : AppColors.border,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.planned != planned;
}
