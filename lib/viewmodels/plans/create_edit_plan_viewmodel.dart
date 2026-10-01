import 'package:flutter/material.dart';
import 'package:plansync/data/plan_repository.dart';
import 'package:plansync/models/invitations.dart';
import 'package:plansync/models/plan.dart';

class CreateEditPlanViewModel extends ChangeNotifier {
  CreateEditPlanViewModel(
    this._creatorId,
    this.editingPlan, [
    this._activityId,
  ]) {
    nameController.text = editingPlan?.name ?? "";
    date = editingPlan?.date;
    isPublic = editingPlan?.isPublic ?? false;
  }

  final String _creatorId;
  final String? _activityId;
  final _repository = PlanRepository();

  final Plan? editingPlan;
  bool get isEditing => editingPlan != null;

  final nameController = TextEditingController();
  DateTime? date;
  bool isLoading = false;
  String? errorMessage;

  bool isPublic = false;
  void setPublic(bool value) {
    isPublic = value;
    notifyListeners();
  }

  void setDate(DateTime value) {
    date = value;
    notifyListeners();
  }

  Future<Plan?> save() async {
    if (nameController.text.trim().isEmpty) {
      errorMessage = 'Plan name is required.';
      notifyListeners();
      return null;
    }
    if (date == null) {
      errorMessage = 'Pick a date.';
      notifyListeners();
      return null;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final plan = Plan(
        id: editingPlan?.id ?? _repository.newId(),
        name: nameController.text.trim(),
        date: date!,
        creatorId: _creatorId,
        invitations:
            editingPlan?.invitations ??
            [Invitation(userId: _creatorId, rsvp: RsvpStatus.going)],
        activityIds: editingPlan?.activityIds ?? [?_activityId],
        tags: editingPlan?.tags ?? const [],
        isPublic: isPublic,
      );
      if (editingPlan == null) {
        await _repository.create(plan);
      } else {
        await _repository.update(plan);
      }
      return plan;
    } catch (_) {
      errorMessage = 'Something went wrong. Try again.';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}
