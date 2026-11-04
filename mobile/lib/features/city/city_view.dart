import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:odaklan_core/odaklan_core.dart';

import '../../app/theme.dart';

/// Grid cell (column, row) of each building on the 3x3 isometric map.
const _plots = {
  'tower': (0, 0),
  'library': (1, 0),
  'workshop': (0, 1),
  'home': (1, 1),
  'park': (2, 1),
};

/// Isometric city; buildings grow smoothly when a level changes.
class CityView extends StatefulWidget {
  const CityView({super.key, required this.city, required this.playerLevel});

  final City city;
  final int playerLevel;

  @override
  State<CityView> createState() => _CityViewState();
}

class _CityViewState extends State<CityView>
    with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: 1,
  );
  late Map<String, double> _from = _levels(widget.city);

  static Map<String, double> _levels(City c) => {
    for (final b in buildings) b.id: c.levelOf(b.id).toDouble(),
  };

  Map<String, double> get _current {
    final t = Curves.easeOutBack.transform(_anim.value);
    final to = _levels(widget.city);
    return {for (final id in to.keys) id: lerpDouble(_from[id], to[id], t)!};
  }

  @override
  void didUpdateWidget(CityView old) {
    super.didUpdateWidget(old);
    if (old.city != widget.city) {
      _from = {
        for (final b in buildings)
          b.id: lerpDouble(
            _from[b.id],
            old.city.levelOf(b.id).toDouble(),
            Curves.easeOutBack.transform(_anim.value),
          )!,
      };
      _anim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final built = buildings.where((b) => widget.city.levelOf(b.id) > 0);
    return Semantics(
      label: built.isEmpty
          ? 'Şehir henüz boş'
          : 'Şehir: ${built.map((b) => '${b.name} seviye ${widget.city.levelOf(b.id)}, sağlık %${widget.city.conditionOf(b.id)}').join(', ')}',
      child: AspectRatio(
        aspectRatio: 1.1,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) => CustomPaint(
            painter: _CityPainter(_current, widget.playerLevel, widget.city),
          ),
        ),
      ),
    );
  }
}

class _CityPainter extends CustomPainter {
  _CityPainter(this.levels, this.playerLevel, this.city);

  final Map<String, double> levels;
  final int playerLevel;

  /// For condition (cracks, dim windows) and ruins.
  final City city;

  @override
  void paint(Canvas canvas, Size size) {
    final tw = size.width / 3.3;
    final th = tw / 2;
    final origin = Offset(size.width / 2, size.height - 3 * th - 8);

    Offset top(double c, double r) =>
        origin + Offset((c - r) * tw / 2, (c + r) * th / 2);

    // Ground tiles.
    final tileFill = Paint()..color = AppColors.surface;
    final tileLine = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        final d = _diamond(top(c.toDouble(), r.toDouble()), tw, th);
        canvas
          ..drawPath(d, tileFill)
          ..drawPath(d, tileLine);
      }
    }

    // Back to front so nearer buildings overlap farther ones.
    final order = [...buildings]
      ..sort((a, b) {
        final (ac, ar) = _plots[a.id]!;
        final (bc, br) = _plots[b.id]!;
        return (ac + ar).compareTo(bc + br);
      });
    for (final b in order) {
      final (c, r) = _plots[b.id]!;
      final level = levels[b.id] ?? 0;
      // Inset footprint: 15% margin inside the tile.
      final base = top(c + 0.15, r + 0.15);
      final w = tw * 0.7, h = th * 0.7;
      final health = city.conditionOf(b.id) / maxCondition;
      if (level <= 0.01) {
        _emptyPlot(canvas, base, w, h, locked: playerLevel < b.unlockLevel);
        if (city.peakOf(b.id) > 0) _rubble(canvas, base, w, h);
      } else if (b.id == 'park') {
        _park(canvas, base, w, h, level, health);
      } else {
        final tall = b.id == 'tower' ? 1.4 : 1.0;
        _box(
          canvas,
          base,
          w,
          h,
          th * (0.35 + 0.3 * level) * tall,
          level,
          health,
        );
      }
    }
  }

  static Path _diamond(Offset t, double w, double h) => Path()
    ..moveTo(t.dx, t.dy)
    ..lineTo(t.dx + w / 2, t.dy + h / 2)
    ..lineTo(t.dx, t.dy + h)
    ..lineTo(t.dx - w / 2, t.dy + h / 2)
    ..close();

  void _emptyPlot(
    Canvas canvas,
    Offset t,
    double w,
    double h, {
    required bool locked,
  }) {
    canvas.drawPath(
      _diamond(t, w, h),
      Paint()
        ..color = locked
            ? AppColors.border.withValues(alpha: 0.5)
            : AppColors.accent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _box(
    Canvas canvas,
    Offset t,
    double w,
    double h,
    double height,
    double level,
    double health,
  ) {
    final up = Offset(0, -height);
    final left = t + Offset(-w / 2, h / 2);
    final right = t + Offset(w / 2, h / 2);
    final bottom = t + Offset(0, h);

    Path quad(Offset a, Offset b, Offset c, Offset d) => Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(d.dx, d.dy)
      ..close();

    canvas
      ..drawPath(
        quad(left, bottom, bottom + up, left + up),
        Paint()..color = AppColors.raised,
      )
      ..drawPath(
        quad(bottom, right, right + up, bottom + up),
        Paint()..color = const Color(0xFF24272E),
      )
      ..drawPath(_diamond(t + up, w, h), Paint()..color = AppColors.border);

    // Lit windows: one row per full level (lights = Enerji).
    // Lights fade as the building decays.
    final lit = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.15 + 0.7 * health);
    final floors = level.floor().clamp(0, 9);
    for (var f = 0; f < floors; f++) {
      final v0 = (f + 0.35) / (floors + 0.5);
      final v1 = (f + 0.75) / (floors + 0.5);
      for (final (a, b) in [(left, bottom), (bottom, right)]) {
        Offset at(double u, double v) => Offset.lerp(a, b, u)! + up * v;
        canvas.drawPath(
          quad(at(0.3, v0), at(0.7, v0), at(0.7, v1), at(0.3, v1)),
          lit,
        );
      }
    }
    if (health * maxCondition < workingCondition) {
      _crack(
        canvas,
        Offset.lerp(left, left + up, 0.9)!,
        Offset.lerp(bottom, left, 0.4)!,
      );
      _crack(
        canvas,
        Offset.lerp(bottom + up, right + up, 0.5)!,
        Offset.lerp(bottom, right, 0.6)!,
      );
    }
  }

  /// Zig-zag crack on a damaged building's front faces.
  void _crack(Canvas canvas, Offset from, Offset to) {
    final path = Path()..moveTo(from.dx, from.dy);
    for (var i = 1; i <= 4; i++) {
      final p = Offset.lerp(from, to, i / 4)!;
      path.lineTo(p.dx + (i.isOdd ? 4 : -4), p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.danger
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  /// Broken stones on a collapsed plot (cheap to rebuild).
  void _rubble(Canvas canvas, Offset t, double w, double h) {
    final stone = Paint()..color = AppColors.border;
    for (final (dx, dy, r) in [
      (-0.18, 0.5, 5.0),
      (0.1, 0.42, 4.0),
      (0.05, 0.62, 6.0),
    ]) {
      canvas.drawCircle(t + Offset(dx * w, dy * h), r, stone);
    }
  }

  void _park(
    Canvas canvas,
    Offset t,
    double w,
    double h,
    double level,
    double health,
  ) {
    canvas.drawPath(
      _diamond(t, w, h),
      Paint()..color = AppColors.success.withValues(alpha: 0.18),
    );
    final tree = Paint()
      ..color = Color.lerp(
        const Color(0xFF6B5B3E), // withered
        AppColors.success,
        health,
      )!.withValues(alpha: 0.8);
    final trees = level.ceil().clamp(1, 5);
    for (var i = 0; i < trees; i++) {
      // Spread trees on a small ring inside the plot.
      final a = i / trees * 2 * math.pi;
      final p =
          t + Offset(math.cos(a) * w * 0.22, h / 2 + math.sin(a) * h * 0.22);
      final s = (level - i).clamp(0.0, 1.0);
      canvas.drawCircle(p - Offset(0, 8 * s), 6 * s, tree);
    }
  }

  @override
  bool shouldRepaint(_CityPainter old) =>
      old.playerLevel != playerLevel ||
      !identical(old.city, city) ||
      !_sameLevels(old.levels, levels);

  static bool _sameLevels(Map<String, double> a, Map<String, double> b) =>
      a.length == b.length && a.keys.every((k) => a[k] == b[k]);
}
