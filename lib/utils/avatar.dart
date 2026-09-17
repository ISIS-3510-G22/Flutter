import 'package:flutter/material.dart';

class _AvatarRow extends StatelessWidget {
  const _AvatarRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shown = count.clamp(0, 2);
    final overflow = count - shown;

    return Row(
      children: [
        for (var i = 0; i < shown; i++)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: colors.surfaceContainerHighest,
              child: Icon(
                Icons.person_outline,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        if (overflow > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: colors.primaryContainer,
              child: Text(
                '+$overflow',
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    final initials = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'
        : words.isNotEmpty
        ? words[0].substring(0, 1)
        : '?';

    return CircleAvatar(
      radius: 16,
      backgroundColor: colors.primary,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(color: colors.onPrimary, fontSize: 12),
      ),
    );
  }
}
