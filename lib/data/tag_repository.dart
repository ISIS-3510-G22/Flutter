import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/models/tag.dart';

class TagRepository {
  final _tags = FirebaseFirestore.instance.collection('tags');

  Future<List<Tag>> allTags() async {
    final snapshot = await _tags
        .orderBy('count', descending: true)
        .limit(20)
        .get();
    return snapshot.docs
        .map((d) => Tag(name: d.id, count: d['count'] as int))
        .toList();
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
