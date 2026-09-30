import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> upload(String path, File file) async {
    final ref = _storage.ref(path);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
