import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/models/activity.dart';

class ActivityRepository {
  final _activities = FirebaseFirestore.instance.collection("activities");

  Activity _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Activity(
      id: doc.id,
      name: data['name'] as String,
      address: data['address'] as String,
      expectedPrice: (data['expectedPrice'] as num).toDouble(),
      notes: data['notes'] as String,
      categories: (data['categories'] as List)
          .map((c) => ActivityCategory.values.byName(c as String))
          .toList(),
      visibility: ActivityVisibility.values.byName(
        data['visibility'] as String,
      ),
      ownerId: data['ownerId'] as String,
      likedBy: (data['likedBy'] as List).cast<String>(),
    );
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
    return _activities.add({
      'name': activity.name,
      'address': activity.address,
      'expectedPrice': activity.expectedPrice,
      'notes': activity.notes,
      'categories': activity.categories.map((c) => c.name).toList(),
      'visibility': activity.visibility.name,
      'ownerId': activity.ownerId,
      'likedBy': <String>[],
    });
  }
}
