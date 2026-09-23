import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plansync/data/user_repository.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/services/storage_service.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this.user);

  User user;
  final _userRepository = UserRepository();
  final _storageService = StorageService();
  final _picker = ImagePicker();
  bool isUploadingPhoto = false;

  Future<void> pickAndUploadPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    isUploadingPhoto = true;
    notifyListeners();

    try {
      final url = await _storageService.uploadProfilePicture(
        user.id,
        File(picked.path),
      );
      await _userRepository.updatePhotoUrl(user.id, url);
      user = User(
        id: user.id,
        name: user.name,
        lastName: user.lastName,
        username: user.username,
        email: user.email,
        phone: user.phone,
        photoUrl: url,
      );
    } finally {
      isUploadingPhoto = false;
      notifyListeners();
    }
  }
}
