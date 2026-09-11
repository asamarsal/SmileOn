import 'package:flutter/material.dart';

/// Komponen Card seragam (Design System)
/// Digunakan untuk kontainer dengan sudut melengkung dan bayangan yang konsisten.
class SmileCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double borderRadius;
  final int elevationLevel; // 0 sampai 4, sesuai design.md
  final Border? border;
  final VoidCallback? onTap;

  const SmileCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color = Colors.white,
    this.borderRadius = 16.0,
    this.elevationLevel = 1,
    this.border,
    this.onTap,
  });

  List<BoxShadow>? _getBoxShadow() {
    switch (elevationLevel) {
      case 0:
        return null;
      case 1:
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ];
      case 2:
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ];
      case 3:
        return [
          BoxShadow(
            color: const Color(0xFFFF3A70).withOpacity(0.15), // primaryRose
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ];
      case 4:
        return [
          BoxShadow(
            color: const Color(0xFFFF3A70).withOpacity(0.30), // primaryRose
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ];
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: _getBoxShadow(),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
