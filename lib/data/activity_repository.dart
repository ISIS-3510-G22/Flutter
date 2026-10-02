import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/models/activity.dart';

class ActivityRepository {
  final _activities = FirebaseFirestore.instance.collection("activities");

  final _recommendationRuns = FirebaseFirestore.instance
      .collection('transferConfigs')
      .doc('6ad7a48c-0000-2678-8aba-fc4116908b71')
      .collection('runs');

  String newId() => _activities.doc().id;

  Activity _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Activity(
      id: doc.id,
      name: data['name'] as String,
      address: data['address'] as String,
      expectedPrice: (data['expectedPrice'] as num).toDouble(),
      notes: data['notes'] as String,
      tags: (data['tags'] as List? ?? []).cast<String>(),
      visibility: ActivityVisibility.values.byName(
        data['visibility'] as String,
      ),
      ownerId: data['ownerId'] as String,
      likedBy: (data['likedBy'] as List).cast<String>(),
      photoUrl: data['photoUrl'] as String?,
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as double?)?.toDouble(),
    );
  }

  Future<List<Activity>> recommended(String uid) async {
    final latest = await _recommendationRuns.doc('latest').get();
    final runId = latest.data()?['latestRunId'] as String?;
    if (runId == null) return [];

    final output = await _recommendationRuns
        .doc(runId)
        .collection('output')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    if (output.docs.isEmpty) return [];

    final map = output.docs.first['activity_ids'] as Map<String, dynamic>;
    final ids = List.generate(map.length, (i) => map['$i'] as String);
    final activities = await getByIds(ids);
    return activities
      ..sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
  }

  Stream<List<Activity>> ownedActivities(String uid) {
    return _activities
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  Stream<List<Activity>> likedActivities(String uid) {
    return _activities
        .where('likedBy', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  Future<void> create(Activity activity) {
    return _activities.doc(activity.id).set({
      'name': activity.name,
      'address': activity.address,
      'expectedPrice': activity.expectedPrice,
      'notes': activity.notes,
      'tags': activity.tags,
      'visibility': activity.visibility.name,
      'ownerId': activity.ownerId,
      'likedBy': <String>[],
      'photoUrl': activity.photoUrl,
      'lat': activity.lat,
      'lng': activity.lng,
    });
  }

  Future<void> delete(String activityId) {
    return _activities.doc(activityId).delete();
  }

  Future<void> update(Activity activity) {
    return _activities.doc(activity.id).update({
      'name': activity.name,
      'address': activity.address,
      'expectedPrice': activity.expectedPrice,
      'notes': activity.notes,
      'tags': activity.tags.toList(),
      'visibility': activity.visibility.name,
      'photoUrl': activity.photoUrl,
      'lat': activity.lat,
      'lng': activity.lng,
    });
  }

  Future<void> toggleLiked(String activityId, String uid, bool liked) {
    return _activities.doc(activityId).update({
      'likedBy': liked
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  Future<List<Activity>> publicActivities() async {
    final snapshot = await _activities
        .where('visibility', isEqualTo: ActivityVisibility.public.name)
        .get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  Future<List<Activity>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snapshot = await _activities
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    return snapshot.docs.map(_fromDoc).toList();
  }
}
