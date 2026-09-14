// lib/shared/widgets/app_fab.dart
import 'package:flutter/material.dart';
import '../../core/theme/color_palette.dart';

class AppFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;

  const AppFAB({
    super.key,
    this.onPressed,
    this.icon = Icons.directions_car_filled,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FloatingActionButton(
      backgroundColor: isDark ? const Color(0xFF10B981) : AppColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}
