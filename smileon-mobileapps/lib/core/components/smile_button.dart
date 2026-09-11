import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/core/components/smile_touchable.dart';

enum SmileButtonVariant { primary, outlined, text }

/// Komponen Tombol seragam (Design System)
class SmileButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final SmileButtonVariant variant;
  final IconData? icon;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final bool isIconRight;

  const SmileButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = SmileButtonVariant.primary,
    this.icon,
    this.isFullWidth = false,
    this.padding,
    this.color,
    this.isIconRight = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && !isIconRight) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (icon != null && isIconRight) ...[
          const SizedBox(width: 8),
          Icon(icon, size: 20),
        ],
      ],
    );

    Widget button;

    final defaultPadding = padding ?? const EdgeInsets.symmetric(horizontal: 32, vertical: 16);

    switch (variant) {
      case SmileButtonVariant.primary:
        button = ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? AppTheme.primaryRose,
            foregroundColor: Colors.white,
            padding: defaultPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0, // No shadow by default based on Material 3
          ),
          child: buttonChild,
        );
        break;
      case SmileButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color ?? AppTheme.text,
            side: BorderSide(color: color ?? Colors.grey),
            padding: defaultPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: buttonChild,
        );
        break;
      case SmileButtonVariant.text:
        button = TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: color ?? AppTheme.primaryRose,
            padding: defaultPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: buttonChild,
        );
        break;
    }

    if (isFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    // Menggunakan SmileTouchable agar semua tombol punya efek scale down saat ditekan
    return SmileTouchable(
      onTap: onPressed, // Event ditangani oleh button jika disable/enable, tapi touchable kasih animasi
      enableScale: onPressed != null,
      child: IgnorePointer( // IgnorePointer agar event tap diteruskan ke SmileTouchable
        ignoring: true,
        child: button,
      ),
    );
  }
}
