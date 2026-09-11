import 'package:flutter/material.dart';

/// Komponen dasar interaktif (Touchable)
/// Memberikan efek scale down atau opacity secara otomatis saat diklik.
class SmileTouchable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enableScale;
  final bool enableOpacity;

  const SmileTouchable({
    super.key,
    required this.child,
    this.onTap,
    this.enableScale = true,
    this.enableOpacity = false,
  });

  @override
  State<SmileTouchable> createState() => _SmileTouchableState();
}

class _SmileTouchableState extends State<SmileTouchable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Widget animatedChild = widget.child;

    if (widget.enableScale) {
      animatedChild = ScaleTransition(
        scale: _scaleAnimation,
        child: animatedChild,
      );
    }

    if (widget.enableOpacity) {
      animatedChild = FadeTransition(
        opacity: _opacityAnimation,
        child: animatedChild,
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: animatedChild,
    );
  }
}
