import 'package:flutter/material.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/views/activities/activity_detail_view.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    required this.activity,
    this.onTap,
    this.trailing,
    super.key,
  });

  final Activity activity;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final shownCategories = activity.categories.take(2).toList();
    final hasMore = activity.categories.length > 2;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            onTap ??
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActivityDetailView(activity: activity),
              ),
            ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 64,
                  height: 64,
                  color: colors.surfaceContainerHighest,
                  child: Icon(
                    Icons.image_outlined,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (trailing != null) trailing!,
                    Row(
                      children: [
                        Icon(
                          Icons.sell_outlined,
                          size: 14,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          [
                            for (final category in shownCategories)
                              category.label,
                            if (hasMore) '...',
                          ].join(', '),
                          style: text.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(activity.name, style: text.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      activity.address,
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
