import 'package:flutter/material.dart';
import 'package:plansync/model/models/plan.dart';
import 'package:plansync/viewmodels/explore/public_plan_detail_viewmodel.dart';
import 'package:plansync/viewmodels/global/connectivity_viewmodel.dart';
import 'package:plansync/views/activities/activity_card.dart';
import 'package:plansync/views/activities/activity_detail_view.dart';
import 'package:plansync/views/widgets/circle_back_button.dart';
import 'package:plansync/views/widgets/offline_banner.dart';
import 'package:provider/provider.dart';

class PublicPlanDetailView extends StatelessWidget {
  const PublicPlanDetailView({required this.plan, super.key});
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PublicPlanDetailViewModel(plan),
      child: const _PublicPlanDetailBody(),
    );
  }
}

class _PublicPlanDetailBody extends StatelessWidget {
  const _PublicPlanDetailBody();

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityViewModel>().isOnline;
    final vm = context.watch<PublicPlanDetailViewModel>();
    final activities = vm.activities;

    Widget content;
    if (vm.isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (activities == null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            "Connect to see this plan's activities.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      content = ListView(
        children: [
          for (final a in activities)
            ActivityCard(
              activity: a,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActivityDetailView(activity: a),
                ),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: CircleBackButton(),
        ),
        title: Text(vm.plan.name),
      ),
      body: Column(
        children: [
          if (!online && activities != null)
            const OfflineBanner(
              message: "You're offline. Showing this plan as you last saw it.",
            ),
          Expanded(child: content),
        ],
      ),
    );
  }
}
