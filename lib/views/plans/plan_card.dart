import 'package:flutter/material.dart';
import 'package:plansync/model/models/app_notification.dart';
import 'package:plansync/model/models/plan.dart';
import 'package:plansync/viewmodels/plans/plan_viewmodel.dart';
import 'package:plansync/views/formatters/date_format.dart';
import 'package:plansync/views/plans/leave_review_view.dart';
import 'package:plansync/views/plans/manage_splits_view.dart';
import 'package:plansync/views/plans/plan_detail_view.dart';
import 'package:plansync/views/widgets/avatar.dart';
import 'package:plansync/views/widgets/waiting_to_sync.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.tab,
    required this.going,
    required this.notification,
    required this.photoUrls,
    this.pending = false,
  });

  final Plan plan;
  final PlanTab tab;
  final bool going;
  final AppNotification? notification;
  final List<String?> photoUrls;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final count = plan.goingIds.length;
    final peopleLabel = count == 1 ? 'Solo Trip' : '$count People';
    final subtitle = tab == PlanTab.upcoming
        ? '${formatShortDate(plan.date)} • $peopleLabel'
        : '${formatShortDate(plan.date)} · ${_formatTime(TimeOfDay.fromDateTime(plan.date))} • $peopleLabel';
    final notification = this.notification;

    return Card(
      color: notification != null ? colors.errorContainer : null,
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
                            going ? 'Confirmed' : 'Not going',
                            style: text.labelMedium?.copyWith(
                              color: going
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        Text(
                          plan.name,
                          style: text.titleLarge?.copyWith(
                            fontWeight: notification != null
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: text.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (pending) ...[
                          const SizedBox(height: 4),
                          const WaitingToSync(),
                        ],
                      ],
                    ),
                  ),
                  AvatarRow(photoUrls: photoUrls, count: count),
                ],
              ),
              if (notification != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: colors.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notification.message,
                        style: text.bodyMedium?.copyWith(
                          color: colors.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (tab == PlanTab.past) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManageSplitsView(
                            planId: plan.id,
                            participantIds: plan.goingIds,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: const Text('Manage Split'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LeaveReviewView(plan: plan),
                        ),
                      ),
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
