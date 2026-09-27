import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plansync/data/activity_repository.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/services/storage_service.dart';

class CreateEditActivityViewmodel extends ChangeNotifier {
  CreateEditActivityViewmodel(this._ownerId, [this._editingActivity]) {
    if (_editingActivity case final activity?) {
      nameController.text = activity.name;
      addressController.text = activity.address;
      notesController.text = activity.notes;
      expectedPriceController.text = activity.expectedPrice.toString();
      categories = activity.categories.toSet();
      activityVisibility = activity.visibility;
    }
  }

  final String _ownerId;
  final _repository = ActivityRepository();
  final Activity? _editingActivity;

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final notesController = TextEditingController();
  final expectedPriceController = TextEditingController();

  final _picker = ImagePicker();
  final _storageService = StorageService();
  File? pickedPhoto;

  Set<ActivityCategory> categories = {};
  ActivityVisibility activityVisibility = ActivityVisibility.private;

  bool get isEditing => _editingActivity != null;

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

  Future<Activity?> save() async {
    final price = double.tryParse(expectedPriceController.text.trim());
    if (nameController.text.trim().isEmpty) {
      errorMessage = 'Place name is required.';
      notifyListeners();
      return null;
    }
    if (addressController.text.trim().isEmpty) {
      errorMessage = 'Address is required';
      notifyListeners();
      return null;
    }
    if (price == null) {
      errorMessage = 'Enter a valid price.';
      notifyListeners();
      return null;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final id = _editingActivity?.id ?? _repository.newId();
      final photoUrl = pickedPhoto == null
          ? _editingActivity?.photoUrl
          : await _storageService.upload(
              'activity_pictures/$id.jpg',
              pickedPhoto!,
            );

      final activity = Activity(
        id: id,
        name: nameController.text.trim(),
        address: addressController.text.trim(),
        expectedPrice: price,
        notes: notesController.text.trim(),
        categories: categories.toList(),
        visibility: activityVisibility,
        ownerId: _editingActivity?.ownerId ?? _ownerId,
        likedBy: _editingActivity?.likedBy ?? [],
        photoUrl: photoUrl,
      );

      if (_editingActivity == null) {
        await _repository.create(activity);
      } else {
        await _repository.update(activity);
      }

      return activity;
    } catch (_) {
      errorMessage = 'Something went wrong. Try again.';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String? get currentPhotoUrl => _editingActivity?.photoUrl;

  Future<void> pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 80,
    );
    if (picked == null) return;
    pickedPhoto = File(picked.path);
    notifyListeners();
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
