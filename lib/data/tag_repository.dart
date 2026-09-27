import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/models/tag.dart';

class TagRepository {
  final _tags = FirebaseFirestore.instance.collection('tags');

  Future<List<Tag>> allTags() async {
    final snapshot = await _tags.orderBy('count', descending: true).get();
    return snapshot.docs
        .map((d) => Tag(name: d['name'] as String, count: d['count'] as int))
        .toList();
  }
}
