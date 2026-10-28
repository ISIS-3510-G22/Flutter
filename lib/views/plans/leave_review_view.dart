import 'package:flutter/material.dart';
import 'package:plansync/model/models/plan.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/model/services/connectivity_service.dart';
import 'package:plansync/viewmodels/plans/leave_review_viewmodel.dart';
import 'package:plansync/views/formatters/date_format.dart';
import 'package:plansync/views/widgets/offline_banner.dart';
import 'package:provider/provider.dart';

class LeaveReviewView extends StatelessWidget {
  const LeaveReviewView({required this.plan, super.key});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LeaveReviewViewModel(plan.id, context.read<User>()),
      child: _LeaveReviewBody(plan: plan),
    );
  }
}

class _LeaveReviewBody extends StatelessWidget {
  const _LeaveReviewBody({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LeaveReviewViewModel>();
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final online = context.watch<ConnectivityService>().isOnline;

    return Scaffold(
      appBar: AppBar(title: const Text('Leave a Review')),
      body: Column(
        children: [
          if (!online)
            const OfflineBanner(
              message:
                  "Offline: we couldn't check for an earlier review. Sending replaces it.",
            ),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card.outlined(
                        child: ListTile(
                          title: Text(plan.name, style: text.titleMedium),
                          subtitle: Text(formatShortDate(plan.date)),
                        ),
                      ),
                      if (vm.hasExistingReview)
                        Card(
                          color: colors.primaryContainer,
                          child: ListTile(
                            leading: Icon(
                              Icons.info_outline,
                              color: colors.primary,
                            ),
                            title: const Text('You already reviewed this plan'),
                            subtitle: const Text(
                              'Submitting will replace your previous review.',
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'How would you rate your experience?',
                        textAlign: TextAlign.center,
                        style: text.titleMedium,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 1; i <= 5; i++)
                            IconButton(
                              icon: Icon(
                                i <= vm.rating ? Icons.star : Icons.star_border,
                                color: colors.primary,
                                size: 32,
                              ),
                              onPressed: () => vm.setRating(i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: vm.commentController,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          hintText:
                              'How was this plan? Share your experience...',
                        ),
                      ),
                      if (vm.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            vm.errorMessage!,
                            style: TextStyle(color: colors.error),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: vm.isLoading
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await vm.submit();
                  if (!ok || !context.mounted) return;
                  Navigator.pop(context);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        vm.queued
                            ? "Review saved on your phone. It'll be posted when you're back online."
                            : 'Thanks for your review!',
                      ),
                    ),
                  );
                },
          child: Text(vm.hasExistingReview ? 'Update Review' : 'Submit Review'),
        ),
      ),
    );
  }
}
