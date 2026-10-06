import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A standard, clean, RedBus-style passenger seat icon.
///
/// Represents an individual passenger seat with:
/// - A clear headrest / backrest shape at the top
/// - A seat cushion and base shape in the center
/// - Left and right armrests flanking the seat
///
/// Designed with clean lines and balanced visual weight to match
/// standard Material Design icons across all screen resolutions.
class AppSeatIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final String? semanticsLabel;

  const AppSeatIcon({
    super.key,
    this.size = 20.0,
    this.color,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;

    return Semantics(
      label: semanticsLabel ?? 'Seat',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: _SeatIconPainter(color: iconColor),
        ),
      ),
    );
  }
}

class _SeatIconPainter extends CustomPainter {
  final Color color;

  _SeatIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw on a canonical 24x24 coordinate space, scaled to target size
    final scale = math.min(size.width, size.height) / 24.0;
    final dx = (size.width - 24.0 * scale) / 2.0;
    final dy = (size.height - 24.0 * scale) / 2.0;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale, scale);

    // 1. Headrest / Upper Backrest (horizontal pill at the top)
    final headrestRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(5.5, 2.5, 13.0, 4.2),
      const Radius.circular(2.1),
    );
    canvas.drawRRect(headrestRect, paint);

    // 2. Left Armrest (vertical pill on the left)
    final leftArmrestRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(2.2, 7.2, 2.2, 12.2),
      const Radius.circular(1.1),
    );
    canvas.drawRRect(leftArmrestRect, paint);

    // 3. Right Armrest (vertical pill on the right)
    final rightArmrestRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(19.6, 7.2, 2.2, 12.2),
      const Radius.circular(1.1),
    );
    canvas.drawRRect(rightArmrestRect, paint);

    // 4. Main Seat Cushion & Base (comfortable seat cushion in the center)
    final cushionRect = RRect.fromRectAndCorners(
      const Rect.fromLTWH(5.6, 8.2, 12.8, 12.8),
      topLeft: const Radius.circular(2.5),
      topRight: const Radius.circular(2.5),
      bottomLeft: const Radius.circular(3.8),
      bottomRight: const Radius.circular(3.8),
    );
    canvas.drawRRect(cushionRect, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SeatIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
