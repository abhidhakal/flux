import 'package:flutter/material.dart';

/// Small icon + text label placed above a form field, replacing icons
/// embedded inside the field itself (prefixIcon).
class FieldLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const FieldLabel({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 16, color: colorScheme.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
