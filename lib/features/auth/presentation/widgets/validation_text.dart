import 'package:flutter/material.dart';

/// Password Strength Indicator & Real-Time Criteria Validation Widget.
class ValidationText extends StatelessWidget {
  final String password;

  const ValidationText({
    super.key,
    required this.password,
  });

  bool get _hasMinLength => password.length >= 8;
  bool get _hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get _hasDigits => password.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar => password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  int get _score {
    if (password.isEmpty) return 0;
    int s = 0;
    if (_hasMinLength) s++;
    if (_hasUppercase) s++;
    if (_hasDigits) s++;
    if (_hasSpecialChar) s++;
    return s;
  }

  String get _strengthLabel {
    switch (_score) {
      case 0:
        return '';
      case 1:
        return 'Weak';
      case 2:
      case 3:
        return 'Medium';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  Color _getStrengthColor(BuildContext context) {
    switch (_score) {
      case 1:
        return Colors.redAccent;
      case 2:
      case 3:
        return Colors.orangeAccent;
      case 4:
        return Colors.green;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final strengthColor = _getStrengthColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _score / 4.0,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _strengthLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: strengthColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _RequirementItem(label: '8+ chars', isMet: _hasMinLength),
            _RequirementItem(label: '1 Uppercase', isMet: _hasUppercase),
            _RequirementItem(label: '1 Number', isMet: _hasDigits),
            _RequirementItem(label: '1 Special symbol', isMet: _hasSpecialChar),
          ],
        ),
      ],
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final String label;
  final bool isMet;

  const _RequirementItem({
    required this.label,
    required this.isMet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isMet ? Colors.green : theme.colorScheme.onSurface.withValues(alpha: 0.4);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
