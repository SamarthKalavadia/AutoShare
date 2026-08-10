// lib/shared/widgets/app_fab.dart
import 'package:flutter/material.dart';
import '../../core/theme/color_palette.dart';

class AppFAB extends StatelessWidget {
  const AppFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: AppColors.primaryYellow,
      foregroundColor: Colors.white,
      onPressed: () {
        // Navigate to create ride page (placeholder)
        // Assuming route exists
        // context.go(AppRoutes.createRide); // Uncomment when route added
      },
      child: const Icon(Icons.directions_car_filled),
    );
  }
}
