import 'package:flutter/material.dart';
import 'package:plansync/data/activity_repository.dart';
import 'package:plansync/models/activity.dart';

class CreateActivityViewmodel extends ChangeNotifier {
  CreateActivityViewmodel(this._ownerId);
  final String _ownerId;
  final _repository = ActivityRepository();

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final notesController = TextEditingController();
  final expectedPriceController = TextEditingController();
  Set<ActivityCategory> categories = {};
  ActivityVisibility activityVisibility = ActivityVisibility.private;

  bool isLoading = false;
  String? errorMessage;

  void toggleCategory(ActivityCategory category) {
    if (categories.contains(category)) {
      categories.remove(category);
    } else {
      categories.add(category);
    }
    notifyListeners();
  }

  void selectVisibility(ActivityVisibility visibility) {
    activityVisibility = visibility;
    notifyListeners();
  }

  Future<bool> save() async {
    final price = double.tryParse(expectedPriceController.text.trim());
    if (nameController.text.trim().isEmpty) {
      errorMessage = 'Place name is required.';
      notifyListeners();
      return false;
    }
    if (addressController.text.trim().isEmpty) {
      errorMessage = 'Address is required';
      notifyListeners();
      return false;
    }
    if (price == null) {
      errorMessage = 'Enter a valid price.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.create(
        Activity(
          id: '',
          name: nameController.text.trim(),
          address: addressController.text.trim(),
          expectedPrice: price,
          notes: notesController.text.trim(),
          categories: categories.toList(),
          visibility: activityVisibility,
          ownerId: _ownerId,
          likedBy: [],
        ),
      );
      return true;
    } catch (_) {
      errorMessage = 'Something went wrong. Try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    expectedPriceController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
