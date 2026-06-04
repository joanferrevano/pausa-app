import 'package:flutter/material.dart';

class CountUpText extends StatelessWidget {
  final num target;
  final Duration duration;
  final TextStyle? style;
  final String Function(int)? formatter;

  const CountUpText({
    super.key,
    required this.target,
    this.duration = const Duration(milliseconds: 1200),
    this.style,
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target.toDouble()),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, _) {
        final display = formatter != null
            ? formatter!(value.round())
            : '${value.round()}';
        return Text(display, style: style);
      },
    );
  }
}
