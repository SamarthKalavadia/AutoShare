import 'package:flutter/material.dart';

/// Standard Material 3 Dropdown Field with rounded borders and responsive styling.
class AppDropdownField<T> extends StatelessWidget {
  final T? value;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const AppDropdownField({
    super.key,
    this.value,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    required this.items,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface),
          dropdownColor: theme.colorScheme.surfaceContainerHighest,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 22) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.colorScheme.error),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}
