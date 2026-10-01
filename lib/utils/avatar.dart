import 'package:flutter/material.dart';

class AvatarRow extends StatelessWidget {
  const AvatarRow({required this.photoUrls, required this.count, super.key});

  final List<String?> photoUrls;
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
            child: UserAvatar(photoUrl: photoUrls.elementAtOrNull(i)),
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

class UserAvatar extends StatelessWidget {
  const UserAvatar({required this.photoUrl, super.key});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: 16,
      backgroundColor: colors.surfaceContainerHighest,
      foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
      child: Icon(
        Icons.person_outline,
        size: 18,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}
