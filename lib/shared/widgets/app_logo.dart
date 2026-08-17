import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final TextStyle? textStyle;
  final Color? iconColor;
  final Color? textColor;

  const AppLogo({
    super.key,
    this.size = 32.0,
    this.showText = true,
    this.textStyle,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = iconColor ?? const Color(0xFFF6C000);
    final brandTextColor = textColor ?? primaryColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.24),
          child: Image.asset(
            'assets/images/logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
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
                },//test commit
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
                  fontWeight: FontWeight.w600,
                  color: brandTextColor,
                  letterSpacing: -0.2,
                ),
          ),
        ],
      ],
    );
  }
}
