import 'package:flutter/material.dart';
import 'package:plansync/data/activity_repository.dart';
import 'package:plansync/models/activity.dart';

class ActivityDetailViewmodel extends ChangeNotifier {
  ActivityDetailViewmodel(this.activity, this._uid);

  Activity activity;
  final String _uid;
  final _repository = ActivityRepository();
  bool isLoading = false;
  String? errorMessage;

  bool get isOwner => activity.ownerId == _uid;
  bool get isLiked => activity.likedBy.contains(_uid);

  Future<void> toggleLike() async {
    final liked = !isLiked;
    await _repository.toggleLiked(activity.id, _uid, liked);

    final likedBy = List<String>.from(activity.likedBy);
    liked ? likedBy.add(_uid) : likedBy.remove(_uid);
    activity = Activity(
      id: activity.id,
      name: activity.name,
      address: activity.address,
      expectedPrice: activity.expectedPrice,
      notes: activity.notes,
      categories: activity.categories,
      visibility: activity.visibility,
      ownerId: activity.ownerId,
      likedBy: likedBy,
    );
    notifyListeners();
  }

  Future<bool> delete() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.delete(activity.id);
      return true;
    } catch (_) {
      errorMessage = 'Something went wrong. Try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
