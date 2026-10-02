import 'package:flutter/material.dart';

Future<bool?> showDecisionDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required String message,
  required String acceptLabel,
  required String declineLabel,
  required String cancelLabel,
}) {
  final colors = Theme.of(context).colorScheme;
  final text = Theme.of(context).textTheme;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 28,
                backgroundColor: colors.surfaceContainerHighest,
                child: Icon(icon, color: colors.onSurface),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: text.titleLarge),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: text.bodyLarge),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.check),
              label: Text(acceptLabel),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.onSurface,
                side: BorderSide(color: colors.primary),
              ),
              icon: const Icon(Icons.close),
              label: Text(declineLabel),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: colors.onSurfaceVariant,
              ),
              child: Text(cancelLabel),
            ),
          ],
        ),
      ),
    ),
  );
}
