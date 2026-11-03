import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Fades + slides its child in the first time it scrolls into view.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  final _key = UniqueKey();
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return VisibilityDetector(
      key: _key,
      onVisibilityChanged: (info) {
        if (!_shown && info.visibleFraction > 0.15 && mounted) {
          setState(() => _shown = true);
        }
      },
      child: widget.child
          .animate(target: _shown ? 1 : 0, delay: widget.delay)
          .fadeIn(duration: 600.ms, curve: Curves.easeOutCubic)
          .slideY(begin: 0.12, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),
    );
  }
}

/// Text painted with the brand gradient.
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, required this.style, this.textAlign});

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF00F0FF), Color(0xFF8B5CFF), Color(0xFFFF2E88)],
      ).createShader(bounds),
      child: Text(text, style: style, textAlign: textAlign),
    );
  }
}
