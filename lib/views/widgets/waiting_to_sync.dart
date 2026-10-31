import 'package:flutter/material.dart';

class WaitingToSync extends StatelessWidget {
  const WaitingToSync({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 14,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          'Waiting to sync',
          style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
