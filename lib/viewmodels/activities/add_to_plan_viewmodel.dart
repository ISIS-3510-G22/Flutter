import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/data/plan_repository.dart';
import 'package:plansync/models/pending_write.dart';
import 'package:plansync/models/plan.dart';
import 'package:plansync/services/pending_write_service.dart';

class AddToPlanViewModel extends ChangeNotifier {
  AddToPlanViewModel(this.activityId, this._uid) {
    _sub = _planRepository.plansForUser(_uid).listen((all) {
      plans = all
          .where(
            (p) => p.date.isAfter(DateTime.now()) && p.goingIds.contains(_uid),
          )
          .toList();
      isLoading = false;
      notifyListeners();
    });
  }

  final String _uid;
  final String activityId;
  final _planRepository = PlanRepository();
  late final StreamSubscription<List<Plan>> _sub;

  bool isLoading = true;
  List<Plan> plans = [];
  bool isSaving = false;
  bool queued = false;

  String? selectedPlanId;

  void selectPlan(String planId) {
    if (selectedPlanId == planId) {
      selectedPlanId = null;
    } else {
      selectedPlanId = planId;
    }
    notifyListeners();
  }

  bool alreadyAdded(Plan plan) => plan.activityIds.contains(activityId);

  Future<bool> addToSelectedPlan() async {
    isSaving = true;
    notifyListeners();
    try {
      final plan = plans.firstWhere((p) => p.id == selectedPlanId);
      await _planRepository.saveLocal(
        _uid,
        plan.withActivityIds([...plan.activityIds, activityId]),
      );
      final sent = await PendingWriteService.instance.submit(
        PendingWrite(
          kind: WriteKind.planAddActivity,
          docId: plan.id,
          payload: {'activityId': activityId},
        ),
      );
      queued = !sent;
      return true;
    } catch (_) {
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
