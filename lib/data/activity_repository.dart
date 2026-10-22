import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/data/local/activity_local_store.dart';
import 'package:plansync/models/activity.dart';

class ActivityRepository {
  final _activities = FirebaseFirestore.instance.collection("activities");

  final _local = ActivityLocalStore();

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

  Stream<List<Activity>> _savedThenServer(
    String uid,
    ActivityList list,
    Query<Map<String, dynamic>> query,
  ) async* {
    yield await _local.list(uid, list);
    yield* query
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .asyncMap((snapshot) async {
          final activities = snapshot.docs.map(_fromDoc).toList();
          await _local.saveList(uid, list, activities);
          return activities;
        });
  }

  Future<List<Activity>> _recommendedFromServer(String uid) async {
    final latest = await _recommendationRuns
        .doc('latest')
        .get(const GetOptions(source: Source.server));
    final runId = latest.data()?['latestRunId'] as String?;
    if (runId == null) return [];

    final output = await _recommendationRuns
        .doc(runId)
        .collection('output')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get(const GetOptions(source: Source.server));
    if (output.docs.isEmpty) return [];

    final map = output.docs.first['activity_ids'] as Map<String, dynamic>;
    final ids = List.generate(map.length, (i) => map['$i'] as String);
    final activities = await getByIds(ids);
    return activities
      ..sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
  }

  Stream<List<Activity>> recommended(String uid) async* {
    yield await _local.list(uid, ActivityList.recommended);
    try {
      final activities = await _recommendedFromServer(
        uid,
      ).timeout(const Duration(seconds: 8));
      await _local.saveList(uid, ActivityList.recommended, activities);
      yield activities;
    } catch (_) {}
  }

  Stream<List<Activity>> ownedActivities(String uid) => _savedThenServer(
    uid,
    ActivityList.owned,
    _activities.where('ownerId', isEqualTo: uid),
  );

  Stream<List<Activity>> likedActivities(String uid) => _savedThenServer(
    uid,
    ActivityList.liked,
    _activities.where('likedBy', arrayContains: uid),
  );

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
