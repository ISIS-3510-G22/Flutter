import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plansync/data/user_repository.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/services/auth_service.dart';
import 'package:plansync/services/connectivity_service.dart';
import 'package:plansync/services/pending_write_service.dart';
import 'package:plansync/services/storage_service.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this.user) {
    PendingWriteService.instance.addListener(refreshUser);
  }

  User user;
  final _userRepository = UserRepository();
  final _storageService = StorageService();
  final _picker = ImagePicker();
  bool isUploadingPhoto = false;

  String? get signOutWarning {
    if (PendingWriteService.instance.hasPending) {
      return "You have changes that haven't synced yet. If you log out now, they'll be lost.";
    }
    if (!ConnectivityService.instance.isOnline) {
      return "You can't log back in until you're online. Log out anyway?";
    }
    return null;
  }

  Future<void> signOut() async {
    PendingWriteService.instance.removeListener(refreshUser);
    await PendingWriteService.instance.clear();
    await AuthService().signOut();
  }

  Future<void> refreshUser() async {
    final refreshedUser = await _userRepository.currentUser(user.id);
    if (refreshedUser == null) return;
    user = refreshedUser;
    notifyListeners();
  }

  Future<void> pickAndUploadPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    isUploadingPhoto = true;
    notifyListeners();

    try {
      final url = await _storageService.upload(
        "profile_pictures/${user.id}.jpg",
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
        reimbursementMethods: user.reimbursementMethods,
      );
    } finally {
      isUploadingPhoto = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    PendingWriteService.instance.removeListener(refreshUser);
    super.dispose();
  }
}
