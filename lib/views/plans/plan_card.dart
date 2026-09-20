import 'package:flutter/material.dart';
import 'package:plansync/models/plan.dart';
import 'package:plansync/viewmodels/plans/plan_viewmodel.dart';

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

class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan, required this.tab});

  final Plan plan;
  final PlanTab tab;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final count = plan.invitations.length;
    final peopleLabel = count == 1 ? 'Solo Trip' : '$count People';
    final subtitle = tab == PlanTab.upcoming
        ? '${_formatDate(plan.date)} • $peopleLabel'
        : '${_formatDate(plan.date)} · ${_formatTime(TimeOfDay.fromDateTime(plan.date))} • $peopleLabel';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tab == PlanTab.upcoming)
                        Text(
                          'Confirmed',
                          style: text.labelMedium?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      Text(plan.name, style: text.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: text.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tab == PlanTab.past)
                  _InitialsAvatar(name: plan.name)
                else
                  _AvatarRow(count: count),
              ],
            ),
            if (tab == PlanTab.past) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('Manage Split'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.star_border, size: 18),
                    label: const Text('Leave a Review'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
