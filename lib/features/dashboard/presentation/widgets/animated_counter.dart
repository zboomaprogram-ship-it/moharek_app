import 'package:flutter/material.dart';

class AnimatedCounter extends StatefulWidget {
  final double endValue;
  final TextStyle style;
  final String suffix;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.endValue,
    required this.style,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: widget.endValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    _oldValue = widget.endValue;
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endValue != widget.endValue) {
      _animation = Tween<double>(begin: _oldValue, end: widget.endValue).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.forward(from: 0);
      _oldValue = widget.endValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Decide if we should show decimals. If it's an exact integer, don't show decimals.
        String text;
        if (widget.endValue == widget.endValue.toInt().toDouble()) {
          text = _animation.value.toInt().toString();
        } else {
          text = _animation.value.toStringAsFixed(1);
        }
        return Text('$text${widget.suffix}', style: widget.style);
      },
    );
  }
}
