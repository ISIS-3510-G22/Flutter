import 'package:cached_network_image/cached_network_image.dart';
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
  static const _radius = 16.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final decodeWidth = (_radius * 2 * MediaQuery.devicePixelRatioOf(context))
        .round();

    return CircleAvatar(
      radius: _radius,
      backgroundColor: colors.surfaceContainerHighest,
      foregroundImage: photoUrl == null
          ? null
          : ResizeImage(
              CachedNetworkImageProvider(photoUrl!),
              width: decodeWidth,
            ),
      child: Icon(
        Icons.person_outline,
        size: 18,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}
