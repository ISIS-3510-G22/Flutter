import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class JsonFileStore {
  Future<File> _file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File(join(dir.path, name));
  }

  Future<String?> read(String name) async {
    final file = await _file(name);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  Future<void> write(String name, String json) async {
    final file = await _file(name);
    await file.parent.create(recursive: true);
    await file.writeAsString(json);
  }
}
