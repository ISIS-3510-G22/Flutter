import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/models/tag.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TagRepository {
  final _tags = FirebaseFirestore.instance.collection('tags');

  static const _prefsKey = 'top_tags';

  Future<List<Tag>> allTags() async {
    final prefs = SharedPreferencesAsync();
    try {
      final snapshot = await _tags
          .orderBy('count', descending: true)
          .limit(20)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      final tags = snapshot.docs
          .map((d) => Tag(name: d.id, count: d['count'] as int))
          .toList();
      await prefs.setStringList(_prefsKey, [for (final t in tags) t.name]);
      return tags;
    } catch (_) {
      final names = await prefs.getStringList(_prefsKey) ?? [];
      return [for (final name in names) Tag(name: name, count: 0)];
    }
  }

  Future<void> updateCounts(List<String> added, List<String> removed) {
    final batch = FirebaseFirestore.instance.batch();
    for (final name in added) {
      batch.set(_tags.doc(name), {
        'name': name,
        'count': FieldValue.increment(1),
      }, SetOptions(merge: true));
    }
    for (final name in removed) {
      batch.set(_tags.doc(name), {
        'name': name,
        'count': FieldValue.increment(-1),
      }, SetOptions(merge: true));
    }
    return batch.commit();
  }
}
