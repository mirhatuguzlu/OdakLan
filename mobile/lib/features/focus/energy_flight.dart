import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import 'wallet.dart';

/// Global rect of a laid-out widget, or null.
Rect? rectOf(GlobalKey key) {
  final box = key.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// A glowing bolt rises from [from] to the balance icon at [to]; [amount]
/// stays off the balance until it hits.
void flyEnergy(
  BuildContext context, {
  required Rect? from,
  required GlobalKey to,
  required int amount,
}) {
  final target = rectOf(to);
  if (from == null || target == null) return; // Balance just updates.
  final container = ProviderScope.containerOf(context, listen: false);
  final inFlight = container.read(energyInFlightProvider.notifier)..add(amount);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Flight(
      from: from.center,
      to: target.center,
      onHit: () {
        inFlight.add(-amount);
        if (entry.mounted) entry.remove();
      },
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
}

class _Flight extends StatefulWidget {
  const _Flight({required this.from, required this.to, required this.onHit});

  final Offset from;
  final Offset to;
  final VoidCallback onHit;

  @override
  State<_Flight> createState() => _FlightState();
}

class _FlightState extends State<_Flight> with SingleTickerProviderStateMixin {
  static const _glowShare = 0.3; // First 30%: glow in place, then fly.
  static const _size = 22.0;

  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..forward().whenComplete(_hit);

  bool _done = false;

  void _hit() {
    if (_done) return;
    _done = true;
    widget.onHit();
  }

  @override
  void dispose() {
    _hit(); // Never leave Enerji held back.
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final glow = Curves.easeOut.transform(math.min(t / _glowShare, 1));
          final fly = Curves.easeInCubic.transform(
            math.max(0, (t - _glowShare) / (1 - _glowShare)),
          );
          // Quadratic arc bulging up and outward.
          final a = widget.from, b = widget.to;
          final control = Offset(
            a.dx + (b.dx - a.dx) * 0.2,
            math.min(a.dy, b.dy) - 40,
          );
          final u = 1 - fly;
          final p = a * (u * u) + control * (2 * u * fly) + b * (fly * fly);
          final scale = 1 + 0.7 * glow - 0.5 * fly;
          return Stack(
            children: [
              Positioned(
                left: p.dx - _size / 2,
                top: p.dy - _size / 2,
                child: Transform.scale(
                  scale: scale,
                  child: Icon(
                    Icons.bolt,
                    size: _size,
                    color: Color.lerp(
                      AppColors.accent,
                      Colors.white,
                      0.35 * glow,
                    ),
                    shadows: [
                      Shadow(
                        color: AppColors.accent,
                        blurRadius: 4 + 14 * glow,
                      ),
                      Shadow(color: AppColors.accent, blurRadius: 24 * glow),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
