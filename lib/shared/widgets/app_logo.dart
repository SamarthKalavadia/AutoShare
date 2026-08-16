import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final TextStyle? textStyle;
  final Color? iconColor;

  const AppLogo({
    super.key,
    this.size = 32.0,
    this.showText = true,
    this.textStyle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = iconColor ?? theme.colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: Image.asset(
            'assets/appicon.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.directions_car_rounded,
                size: size,
                color: primaryColor,
              );
            },
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.3),
          Text(
            'AutoShare',
            style: textStyle ??
                GoogleFonts.inter(
                  fontSize: size * 0.65,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  letterSpacing: -0.3,
                ),
          ),
        ],
      ],
    );
  }
}
