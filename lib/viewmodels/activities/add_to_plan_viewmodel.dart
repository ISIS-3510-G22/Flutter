import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/data/plan_repository.dart';
import 'package:plansync/models/plan.dart';

class AddToPlanViewModel extends ChangeNotifier {
  AddToPlanViewModel(this.activityId, String uid) {
    _sub = _planRepository.plansForUser(uid).listen((all) {
      plans = all
          .where(
            (p) => p.date.isAfter(DateTime.now()) && p.goingIds.contains(uid),
          )
          .toList();
      isLoading = false;
      notifyListeners();
    });
  }

  final String activityId;
  final _planRepository = PlanRepository();
  late final StreamSubscription<List<Plan>> _sub;

  bool isLoading = true;
  List<Plan> plans = [];
  bool isSaving = false;

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
      await _planRepository.addActivity(selectedPlanId!, activityId);
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
