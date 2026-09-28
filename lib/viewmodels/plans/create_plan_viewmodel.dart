import 'package:flutter/material.dart';
import 'package:plansync/data/plan_repository.dart';
import 'package:plansync/models/invitations.dart';
import 'package:plansync/models/plan.dart';

class CreatePlanViewModel extends ChangeNotifier {
  CreatePlanViewModel(this._creatorId);

  final String _creatorId;
  final _repository = PlanRepository();

  final nameController = TextEditingController();
  DateTime? date;
  bool isLoading = false;
  String? errorMessage;

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
        id: _repository.newId(),
        name: nameController.text.trim(),
        date: date!,
        creatorId: _creatorId,
        invitations: [Invitation(userId: _creatorId, rsvp: RsvpStatus.going)],
      );
      await _repository.create(plan);
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
