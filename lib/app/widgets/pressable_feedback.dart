import 'package:flutter/material.dart';

class PressableFeedback extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const PressableFeedback({
    super.key,
    this.onTap,
    required this.child,
  });

  @override
  State<PressableFeedback> createState() => _PressableFeedbackState();
}

class _PressableFeedbackState extends State<PressableFeedback> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 80),
        opacity: _pressed ? 0.8 : 1.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 80),
          scale: _pressed ? 0.97 : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}
