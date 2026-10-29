import 'package:flutter/material.dart';
import 'package:plansync/model/data/activity_repository.dart';
import 'package:plansync/model/models/activity.dart';

class ActivityDetailViewmodel extends ChangeNotifier {
  ActivityDetailViewmodel(this.activity, this._uid) {
    _loadLocalPhoto();
  }

  Activity activity;
  final String _uid;
  final _repository = ActivityRepository();
  bool isLoading = false;
  String? errorMessage;

  bool get isOwner => activity.ownerId == _uid;
  bool get isLiked => activity.likedBy.contains(_uid);

  String? localPhotoPath;

  Future<void> _loadLocalPhoto() async {
    localPhotoPath = await _repository.pendingPhoto(activity.id);
    notifyListeners();
  }

  Future<void> applyUpdate(Activity updated) async {
    activity = updated;
    notifyListeners();
    final fresh = await _repository.planActivities(_uid, [updated.id]);
    if (fresh.isNotEmpty) activity = fresh.first;
    await _loadLocalPhoto();
  }

  Future<bool> toggleLike() {
    final liked = !isLiked;
    final before = activity;
    final likedBy = List<String>.from(activity.likedBy);
    liked ? likedBy.add(_uid) : likedBy.remove(_uid);
    activity = Activity(
      id: activity.id,
      name: activity.name,
      address: activity.address,
      expectedPrice: activity.expectedPrice,
      notes: activity.notes,
      tags: activity.tags,
      visibility: activity.visibility,
      ownerId: activity.ownerId,
      likedBy: likedBy,
      photoUrl: activity.photoUrl,
      lat: activity.lat,
      lng: activity.lng,
    );
    notifyListeners();

    return _repository
        .setLiked(_uid, activity, liked: liked)
        .then((sent) => !sent)
        .catchError((_) {
          activity = before;
          notifyListeners();
          return false;
        });
  }
}
