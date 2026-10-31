import 'package:flutter/material.dart';

class PrivateTag extends StatelessWidget {
  const PrivateTag({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          'Private',
          style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
