import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final TextStyle? textStyle;
  final Color? iconColor;
  final Color? textColor;
  final Color? shareColor;
  final bool showTagline;

  const AppLogo({
    super.key,
    this.size = 32.0,
    this.showText = true,
    this.textStyle,
    this.iconColor,
    this.textColor,
    this.shareColor,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = iconColor ?? (isDark ? const Color(0xFF10B981) : const Color(0xFF084E31));
    final autoTextColor = textColor ?? (isDark ? Colors.white : const Color(0xFF084E31));
    final goldShareColor = shareColor ?? const Color(0xFFE5A93C);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                    },
                  );
                },
              ),
            ),
            if (showText) ...[
              SizedBox(width: size * 0.3),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Auto',
                      style: textStyle ??
                          GoogleFonts.inter(
                            fontSize: size * 0.65,
                            fontWeight: FontWeight.w800,
                            color: autoTextColor,
                            letterSpacing: -0.3,
                          ),
                    ),
                    TextSpan(
                      text: 'Share',
                      style: (textStyle ??
                              GoogleFonts.inter(
                                fontSize: size * 0.65,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ))
                          .copyWith(color: goldShareColor),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 3),
          Text(
            'Rides Together, A Greener Tomorrow',
            style: GoogleFonts.inter(
              fontSize: size * 0.32,
              fontWeight: FontWeight.w500,
              color: autoTextColor.withValues(alpha: 0.8),
              letterSpacing: -0.1,
            ),
          ),
        ],
      ],
    );
  }
}
