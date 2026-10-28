import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plansync/model/data/auth_repository.dart';
import 'package:plansync/model/data/user_repository.dart';
import 'package:plansync/model/models/pending_write.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/model/services/connectivity_service.dart';
import 'package:plansync/model/services/pending_write_service.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this.user) {
    PendingWriteService.instance.addListener(refreshUser);
    _loadLocalPhoto();
  }

  User user;
  final _userRepository = UserRepository();
  final _picker = ImagePicker();
  bool isUploadingPhoto = false;
  String? localPhotoPath;

  String? get signOutWarning {
    if (PendingWriteService.instance.hasPending) {
      return "You have changes that haven't synced yet. If you log out now, they'll be lost.";
    }
    if (!ConnectivityService.instance.isOnline) {
      return "You can't log back in until you're online. Log out anyway?";
    }
    return null;
  }

  Future<void> _loadLocalPhoto() async {
    localPhotoPath = await _userRepository.pendingPhoto(user.id);
    notifyListeners();
  }

  Future<void> signOut() async {
    PendingWriteService.instance.removeListener(refreshUser);
    await PendingWriteService.instance.clear();
    await AuthRepository().signOut();
  }

  Future<void> refreshUser() async {
    await _loadLocalPhoto();
    final refreshedUser = await _userRepository.currentUser(user.id);
    if (refreshedUser == null) return;
    user = refreshedUser;
    notifyListeners();
  }

  Future<bool> pickAndUploadPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 80,
    );
    if (picked == null) return false;

    isUploadingPhoto = true;
    notifyListeners();

    try {
      final path = await _userRepository.savePhotoLocal(user.id, picked.path);
      await FileImage(File(path)).evict();
      final sent = await PendingWriteService.instance.submit(
        PendingWrite(
          kind: WriteKind.profilePhoto,
          docId: user.id,
          payload: {'path': path},
        ),
      );
      await refreshUser();
      return !sent;
    } catch (_) {
      return false;
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
