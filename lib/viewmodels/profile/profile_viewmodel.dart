import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plansync/model/data/auth_repository.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/pending_write_repository.dart';
import 'package:plansync/model/data/user_repository.dart';
import 'package:plansync/model/models/user.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this.user) {
    _queueSub = PendingWriteRepository.instance.changes.listen(
      (_) => refreshUser(),
    );
    _loadLocalPhoto();
  }

  User user;
  final _userRepository = UserRepository();
  final _picker = ImagePicker();
  bool isUploadingPhoto = false;
  String? localPhotoPath;
  late final StreamSubscription<void> _queueSub;

  String? get signOutWarning {
    if (PendingWriteRepository.instance.hasPending) {
      return "You have changes that haven't synced yet. If you log out now, they'll be lost.";
    }
    if (!ConnectivityRepository.instance.isOnline) {
      return "You can't log back in until you're online. Log out anyway?";
    }
    return null;
  }

  bool get isPending =>
      PendingWriteRepository.instance.pendingDocIds.contains(user.id);

  Future<void> _loadLocalPhoto() async {
    localPhotoPath = await _userRepository.pendingPhoto(user.id);
    notifyListeners();
  }

  Future<void> signOut() async {
    _queueSub.cancel();
    await PendingWriteRepository.instance.clear();
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
      final sent = await _userRepository.savePhoto(user.id, picked.path);
      final path = await _userRepository.pendingPhoto(user.id);
      if (path != null) await FileImage(File(path)).evict();
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
    _queueSub.cancel();
    super.dispose();
  }
}
