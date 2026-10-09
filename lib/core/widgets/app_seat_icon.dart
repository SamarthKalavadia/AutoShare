import 'package:flutter/material.dart';

/// AppSeatIcon renders the standard AutoShare passenger seat icon using
/// the official image assets (`assets/seats.png` / `assets/seats_white.png`)
/// with automatic dark/light theme adaptation and custom tinting.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assetPath = isDark ? 'assets/seats_white.png' : 'assets/seats.png';

    Widget image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (color != null) {
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: image,
      );
    }

    return Semantics(
      label: semanticsLabel ?? 'Seat',
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: image),
      ),
    );
  }
}
