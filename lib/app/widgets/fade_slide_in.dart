import 'package:flutter/material.dart';

class FadeSlideIn extends StatefulWidget {
  final Duration delay;
  final Duration duration;
  final Widget child;

  const FadeSlideIn({
    super.key,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    required this.child,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _translateY = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: AnimatedBuilder(
        animation: _translateY,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _translateY.value),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
