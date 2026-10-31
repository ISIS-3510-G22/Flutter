import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/model/data/plan_repository.dart';
import 'package:plansync/model/models/plan.dart';

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
      final sent = await _planRepository.setActivity(
        _uid,
        plan.withActivityIds([...plan.activityIds, activityId]),
        activityId,
        added: true,
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
