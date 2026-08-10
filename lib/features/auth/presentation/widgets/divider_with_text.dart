import 'package:flutter/material.dart';

/// Horizontal divider with centered text.
class DividerWithText extends StatelessWidget {
  final String text;

  const DividerWithText({
    super.key,
    this.text = 'OR',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface.withValues(alpha: 0.4);

    return Row(
      children: [
        Expanded(
          child: Divider(color: color.withValues(alpha: 0.3), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: color.withValues(alpha: 0.3), thickness: 1),
        ),
      ],
    );
  }
}
