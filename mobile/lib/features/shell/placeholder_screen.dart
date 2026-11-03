import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme.dart';

/// Temporary tab body until the step that implements it (see plan).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.hint,
    required this.icon,
  });

  final String title;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: AppColors.neonCyan)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(duration: 1800.ms, color: AppColors.neonPink)
                .scaleXY(begin: 0.95, end: 1.05, duration: 1800.ms),
            const SizedBox(height: 16),
            Text(hint, style: const TextStyle(color: AppColors.textMuted)),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
      ),
    );
  }
}
