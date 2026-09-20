import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePicture(String userId, File file) async {
    final ref = _storage.ref('profile_pictures/$userId.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
