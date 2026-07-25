import 'package:flutter/material.dart';

/// Shared chrome for modal bottom sheets: rounded-top container + drag
/// handle, so screens stop hand-rolling this per dialog.
class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    double radius = 20,
    bool isScrollControlled = true,
    bool showHandle = true,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHandle) ...[
                Center(child: _Handle(colorScheme)),
                const SizedBox(height: 20),
              ],
              builder(sheetContext),
            ],
          ),
        );
      },
    );
  }
}

class _Handle extends StatelessWidget {
  final ColorScheme colorScheme;
  const _Handle(this.colorScheme);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
