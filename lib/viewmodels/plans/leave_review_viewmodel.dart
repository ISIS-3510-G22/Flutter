import 'package:flutter/material.dart';
import 'package:plansync/data/review_repository.dart';
import 'package:plansync/models/review.dart';
import 'package:plansync/models/user.dart';

class LeaveReviewViewModel extends ChangeNotifier {
  LeaveReviewViewModel(this._planId, this._user) {
    _loadExisting();
  }

  bool isLoading = true;
  bool hasExistingReview = false;

  final String _planId;
  final User _user;
  final _repository = ReviewRepository();

  final commentController = TextEditingController();
  int rating = 0;
  String? errorMessage;

  Future<void> _loadExisting() async {
    try {
      final existing = await _repository.reviewBy(_planId, _user.id);
      if (existing != null) {
        hasExistingReview = true;
        rating = existing.rating;
        commentController.text = existing.comment;
      }
    } catch (_) {
      errorMessage = "Couldn't load your previous review.";
    }
    isLoading = false;
    notifyListeners();
  }

  void setRating(int value) {
    if (value == rating) {
      rating = 0;
    } else {
      rating = value;
    }
    notifyListeners();
  }

  Future<bool> submit() async {
    if (rating == 0) {
      errorMessage = 'Pick a rating.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.submit(
        _planId,
        Review(
          userId: _user.id,
          userName: '${_user.name} ${_user.lastName}',
          rating: rating,
          comment: commentController.text.trim(),
          createdAt: DateTime.now(),
        ),
      );
      return true;
    } catch (_) {
      errorMessage = 'Something went wrong. Try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
}
