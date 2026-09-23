import 'package:flutter/material.dart';
import 'package:plansync/models/plan.dart';
import 'package:plansync/utils/avatar.dart';
import 'package:plansync/utils/date_format.dart';
import 'package:plansync/viewmodels/plans/plan_viewmodel.dart';
import 'package:plansync/views/plans/plan_detail_view.dart';

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
        ? '${formatShortDate(plan.date)} • $peopleLabel'
        : '${formatShortDate(plan.date)} · ${_formatTime(TimeOfDay.fromDateTime(plan.date))} • $peopleLabel';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlanDetailView(plan: plan)),
        ),
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
                    InitialsAvatar(name: plan.name)
                  else
                    AvatarRow(count: count),
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
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
