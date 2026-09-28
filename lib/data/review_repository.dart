import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/models/review.dart';

class ReviewRepository {
  CollectionReference<Map<String, dynamic>> _reviews(String planId) =>
      FirebaseFirestore.instance
          .collection('plans')
          .doc(planId)
          .collection('reviews');

  Review _fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data()!;
    return Review(
      userId: d.id,
      userName: data['userName'] as String,
      rating: data['rating'] as int,
      comment: data['comment'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Future<void> submit(String planId, Review review) {
    return _reviews(planId).doc(review.userId).set({
      'userName': review.userName,
      'rating': review.rating,
      'comment': review.comment,
      'createdAt': Timestamp.fromDate(review.createdAt),
    });
  }

  Future<List<Review>> reviewsForPlan(String planId) async {
    final snapshot = await _reviews(
      planId,
    ).orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(_fromDoc).toList();
  }

  Future<Review?> reviewBy(String planId, String userId) async {
    final doc = await _reviews(planId).doc(userId).get();
    return doc.exists ? _fromDoc(doc) : null;
  }
}
