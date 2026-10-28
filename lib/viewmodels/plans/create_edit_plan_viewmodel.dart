import 'package:flutter/material.dart';
import 'package:plansync/model/data/plan_repository.dart';
import 'package:plansync/model/models/invitations.dart';
import 'package:plansync/model/models/pending_write.dart';
import 'package:plansync/model/models/plan.dart';
import 'package:plansync/model/services/pending_write_service.dart';

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
  bool queued = false;

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
      await _repository.saveLocal(_creatorId, plan);
      final sent = await PendingWriteService.instance.submit(
        PendingWrite(
          kind: isEditing ? WriteKind.planUpdate : WriteKind.planCreate,
          docId: plan.id,
          payload: plan.toJson(),
        ),
      );
      queued = !sent;
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
