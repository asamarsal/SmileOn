import 'package:flutter/cupertino.dart';
import 'package:smileon/core/theme/app_theme.dart';

/// Komponen Switch seragam (Design System)
/// Menggunakan CupertinoSwitch agar terlihat lebih premium dan membulat
/// dengan warna kustom AppTheme.
class SmileSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SmileSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryRose,
      trackColor: AppTheme.muted.withOpacity(0.3),
    );
  }
}
