import 'package:flutter/material.dart';
import '../../../../core/constants/assets.dart';

/// Animated AutoShare Logo with smooth scaling and fade animation.
class AnimatedLogo extends StatefulWidget {
  final double size;
  final bool animate;

  const AnimatedLogo({
    super.key,
    this.size = 100.0,
    this.animate = true,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.size * 0.22),
              child: Image.asset(
                AppAssets.logo,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}
