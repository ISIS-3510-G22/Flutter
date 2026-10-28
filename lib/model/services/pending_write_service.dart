import 'dart:io';

import 'package:plansync/model/data/activity_repository.dart';
import 'package:plansync/model/data/plan_repository.dart';
import 'package:plansync/model/data/review_repository.dart';
import 'package:plansync/model/data/tag_repository.dart';
import 'package:plansync/model/data/user_repository.dart';
import 'package:plansync/model/models/activity.dart';
import 'package:plansync/model/models/pending_write.dart';
import 'package:plansync/model/models/plan.dart';
import 'package:plansync/model/models/review.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/model/services/storage_service.dart';
import 'package:plansync/model/services/write_queue.dart';

enum WriteKind {
  activityCreate,
  activityUpdate,
  activityLike,
  activityDelete,
  tagCounts,
  planCreate,
  planUpdate,
  planAddActivity,
  planRemoveActivity,
  reviewSubmit,
  profileUpdate,
  profilePhoto,
}

class PendingWriteService extends WriteQueue<WriteKind> {
  PendingWriteService._internal() : super('pending_writes', WriteKind.values);

  static final instance = PendingWriteService._internal();

  final _activities = ActivityRepository();
  final _plans = PlanRepository();
  final _tags = TagRepository();
  final _reviews = ReviewRepository();
  final _users = UserRepository();
  final _storage = StorageService();

  Future<void> _uploadProfilePhoto(String uid, String path) async {
    final file = File(path);
    if (!await file.exists()) return;
    final modified = await file.lastModified();
    final url = await _storage.upload('profile_pictures/$uid.jpg', file);
    await _users.updatePhotoUrl(uid, url);
    if (await file.exists() && await file.lastModified() == modified) {
      await file.delete();
    }
  }

  @override
  Future<void> send(PendingWrite<WriteKind> write) async {
    final payload = write.payload;
    await switch (write.kind) {
      WriteKind.activityCreate => _activities.create(
        Activity.fromJson(payload),
      ),
      WriteKind.activityUpdate => _activities.update(
        Activity.fromJson(payload),
      ),
      WriteKind.activityLike => _activities.toggleLiked(
        write.docId,
        payload['uid'] as String,
        payload['liked'] as bool,
      ),
      WriteKind.activityDelete => _activities.delete(write.docId),
      WriteKind.tagCounts => _tags.updateCounts(
        (payload['added'] as List).cast<String>(),
        (payload['removed'] as List).cast<String>(),
      ),
      WriteKind.planCreate => _plans.create(Plan.fromJson(payload)),
      WriteKind.planUpdate => _plans.update(Plan.fromJson(payload)),
      WriteKind.planAddActivity => _plans.addActivity(
        write.docId,
        payload['activityId'] as String,
      ),
      WriteKind.planRemoveActivity => _plans.removeActivity(
        write.docId,
        payload['activityId'] as String,
      ),
      WriteKind.reviewSubmit => _reviews.submit(
        write.docId,
        Review.fromJson(payload),
      ),
      WriteKind.profileUpdate => _users.updateProfile(User.fromJson(payload)),
      WriteKind.profilePhoto => _uploadProfilePhoto(
        write.docId,
        payload['path'] as String,
      ),
    };
  }

  @override
  String describeDropped(PendingWrite<WriteKind> write) {
    final name = write.payload['name'];
    return switch (write.kind) {
      WriteKind.activityCreate ||
      WriteKind.planCreate => "We couldn't publish $name.",
      WriteKind.activityUpdate || WriteKind.planUpdate =>
        "$name was deleted, so your changes couldn't sync.",
      WriteKind.activityLike =>
        "An activity you liked was deleted, so your like couldn't sync.",
      WriteKind.activityDelete =>
        "We couldn't delete an activity on the server.",
      WriteKind.tagCounts =>
        "Your activity's tags couldn't update the suggestions.",
      WriteKind.planAddActivity || WriteKind.planRemoveActivity =>
        "A plan you edited was deleted, so its activity changes couldn't sync.",
      WriteKind.reviewSubmit => "We couldn't post your review.",
      WriteKind.profileUpdate => "We couldn't save your profile changes.",
      WriteKind.profilePhoto => "We couldn't upload your profile photo.",
    };
  }
}
