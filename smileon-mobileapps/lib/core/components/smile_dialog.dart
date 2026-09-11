import 'package:flutter/material.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/core/components/smile_button.dart';

class SmileDialog extends StatelessWidget {
  final String title;
  final String description;
  final String primaryButtonText;
  final VoidCallback onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final IconData? icon;

  const SmileDialog({
    super.key,
    required this.title,
    required this.description,
    required this.primaryButtonText,
    required this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.icon,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String description,
    required String primaryButtonText,
    required VoidCallback onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    IconData? icon,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext context) {
        return SmileDialog(
          title: title,
          description: description,
          primaryButtonText: primaryButtonText,
          onPrimaryPressed: onPrimaryPressed,
          secondaryButtonText: secondaryButtonText,
          onSecondaryPressed: onSecondaryPressed,
          icon: icon,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRose.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.primaryRose, size: 36),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.muted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                if (secondaryButtonText != null) ...[
                  Expanded(
                    child: SmileButton(
                      text: secondaryButtonText!,
                      onPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(),
                      variant: SmileButtonVariant.outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: SmileButton(
                    text: primaryButtonText,
                    onPressed: onPrimaryPressed,
                    variant: SmileButtonVariant.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
