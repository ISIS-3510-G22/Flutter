import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/data/local/json_file_store.dart';
import 'package:plansync/model/data/pending_write_repository.dart';
import 'package:plansync/model/models/review.dart';

class ReviewRepository {
  CollectionReference<Map<String, dynamic>> _reviews(String planId) =>
      FirebaseFirestore.instance
          .collection('plans')
          .doc(planId)
          .collection('reviews');

  final _files = JsonFileStore();

  PendingWriteRepository get _queue => PendingWriteRepository.instance;

  String _reviewFile(String planId, String userId) =>
      'review_${planId}_$userId.json';

  Future<void> saveLocal(String planId, Review review) => _files.write(
    _reviewFile(planId, review.userId),
    jsonEncode(review.toJson()),
  );

  Future<Review?> _readReview(String name) async {
    final text = await _files.read(name);
    if (text == null) return null;
    try {
      return Review.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

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
    final file = _reviewFile(planId, userId);
    try {
      final doc = await _reviews(planId)
          .doc(userId)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      if (!doc.exists) return _readReview(file);
      final review = _fromDoc(doc);
      await saveLocal(planId, review);
      return review;
    } catch (_) {
      return _readReview(file);
    }
  }
}
