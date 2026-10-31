import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plansync/model/data/activity_repository.dart';
import 'package:plansync/model/data/place_repository.dart';
import 'package:plansync/model/data/tag_repository.dart';
import 'package:plansync/model/logic/validators.dart';
import 'package:plansync/model/models/activity.dart';
import 'package:plansync/model/models/place.dart';
import 'package:plansync/model/models/tag.dart';

class CreateEditActivityViewmodel extends ChangeNotifier {
  CreateEditActivityViewmodel(this._ownerId, [this._editingActivity]) {
    if (_editingActivity case final activity?) {
      nameController.text = activity.name;
      addressController.text = activity.address;
      notesController.text = activity.notes;
      expectedPriceController.text = activity.expectedPrice.toStringAsFixed(0);
      tags = activity.tags.toSet();
      activityVisibility = activity.visibility;
      if (activity.lat != null) {
        _place = Place(
          address: activity.address,
          lat: activity.lat!,
          lng: activity.lng!,
        );
      }
      _loadLocalPhoto(activity.id);
    }

    _loadTags();
  }

  final String _ownerId;
  final _repository = ActivityRepository();
  final _tagRepository = TagRepository();
  final _placeRepository = PlaceRepository();
  final addressFocus = FocusNode();
  final Activity? _editingActivity;

  String? localPhotoPath;

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final notesController = TextEditingController();
  final expectedPriceController = TextEditingController();
  final newTagController = TextEditingController();

  final _picker = ImagePicker();
  File? pickedPhoto;

  String? tagError;

  Set<String> tags = {};
  List<Tag> allTags = [];
  ActivityVisibility activityVisibility = ActivityVisibility.private;
  Place? _place;

  bool get isEditing => _editingActivity != null;

  bool isLoading = false;
  String? errorMessage;
  bool queued = false;

  bool isLoadingTags = true;
  bool searchFailed = false;

  Future<void> _loadTags() async {
    allTags = await _tagRepository.allTags();
    isLoadingTags = false;
    notifyListeners();
  }

  Future<void> _loadLocalPhoto(String id) async {
    localPhotoPath = await _repository.pendingPhoto(id);
    notifyListeners();
  }

  void toggleTag(String name) {
    if (tags.contains(name)) {
      tags.remove(name);
    } else {
      tags.add(name);
    }
    notifyListeners();
  }

  void addNewTag() {
    final name = newTagController.text.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    tagError = name.isEmpty ? null : validateTag(name);
    if (name.isNotEmpty && tagError == null) {
      tags.add(name);
      newTagController.clear();
    }
    notifyListeners();
  }

  List<String> get tagOptions =>
      {...allTags.map((t) => t.name), ...tags}.toList();

  void selectVisibility(ActivityVisibility visibility) {
    activityVisibility = visibility;
    notifyListeners();
  }

  Future<List<Place>> searchPlaces(String query) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (query != addressController.text || query.trim().length < 3) return [];
    try {
      final places = await _placeRepository.search(query);
      _setSearchFailed(false);
      return places;
    } catch (_) {
      _setSearchFailed(true);
      return [];
    }
  }

  void _setSearchFailed(bool failed) {
    if (searchFailed == failed) return;
    searchFailed = failed;
    notifyListeners();
  }

  void pickPlace(Place place) => _place = place;

  Future<Activity?> save() async {
    final price = parsePrice(expectedPriceController.text.trim());
    final place = _place?.address == addressController.text.trim()
        ? _place
        : null;
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
      errorMessage = 'Enter the price as a whole number, e.g. 120500.';
      notifyListeners();
      return null;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final id = _editingActivity?.id ?? _repository.newId();

      final activity = Activity(
        id: id,
        name: nameController.text.trim(),
        address: addressController.text.trim(),
        expectedPrice: price,
        notes: notesController.text.trim(),
        tags: tags.toList(),
        visibility: activityVisibility,
        ownerId: _editingActivity?.ownerId ?? _ownerId,
        likedBy: _editingActivity?.likedBy ?? [],
        photoUrl: _editingActivity?.photoUrl,
        lat: place?.lat,
        lng: place?.lng,
      );

      final sent = await _repository.save(
        _ownerId,
        activity,
        previous: _editingActivity,
      );
      queued = !sent;
      if (pickedPhoto != null) {
        final photoSent = await _repository.savePhoto(id, pickedPhoto!.path);
        final path = await _repository.pendingPhoto(id);
        if (path != null) await FileImage(File(path)).evict();
        if (!photoSent) queued = true;
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
    newTagController.dispose();
    addressFocus.dispose();
    super.dispose();
  }
}
