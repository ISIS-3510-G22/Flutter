import 'package:flutter/material.dart';
import 'package:plansync/models/plan.dart';
import 'package:plansync/viewmodels/plans/public_plan_detail_viewmodel.dart';
import 'package:plansync/views/activities/activity_card.dart';
import 'package:plansync/views/activities/activity_detail_view.dart';
import 'package:plansync/views/widgets/circle_back_button.dart';
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
    final vm = context.watch<PublicPlanDetailViewModel>();
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: CircleBackButton(),
        ),
        title: Text(vm.plan.name),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                for (final a in vm.activities)
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
            ),
    );
  }
}
