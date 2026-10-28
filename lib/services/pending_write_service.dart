import 'package:plansync/data/activity_repository.dart';
import 'package:plansync/data/plan_repository.dart';
import 'package:plansync/data/review_repository.dart';
import 'package:plansync/data/tag_repository.dart';
import 'package:plansync/data/user_repository.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/models/pending_write.dart';
import 'package:plansync/models/plan.dart';
import 'package:plansync/models/review.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/services/write_queue.dart';

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
}

class PendingWriteService extends WriteQueue<WriteKind> {
  PendingWriteService._internal() : super('pending_writes', WriteKind.values);

  static final instance = PendingWriteService._internal();

  final _activities = ActivityRepository();
  final _plans = PlanRepository();
  final _tags = TagRepository();
  final _reviews = ReviewRepository();
  final _users = UserRepository();

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
    };
  }
}
