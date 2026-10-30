import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class UploadStore {
  Future<File> _file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File(join(dir.path, 'uploads', name));
  }

  Future<String?> pending(String name) async {
    final file = await _file(name);
    return await file.exists() ? file.path : null;
  }

  Future<String> save(String name, String pickedPath) async {
    final file = await _file(name);
    await file.parent.create(recursive: true);
    await File(pickedPath).copy(file.path);
    return file.path;
  }
}
