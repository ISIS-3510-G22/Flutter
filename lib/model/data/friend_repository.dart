import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/data/local/crew_local_store.dart';
import 'package:plansync/model/models/friend_request.dart';
import 'package:plansync/model/models/reimbursement_method.dart';
import 'package:plansync/model/models/user.dart';

class FriendRepository {
  final _db = FirebaseFirestore.instance;
  final _local = CrewLocalStore();
  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('friendRequests');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  FriendRequest _fromData(String id, Map<String, dynamic> data) {
    return FriendRequest(
      id: id,
      fromUserId: data['fromUserId'] as String,
      toUserId: data['toUserId'] as String,
      sentOn: (data['sentOn'] as Timestamp).toDate(),
      status: FriendRequestStatus.values.byName(data['status'] as String),
    );
  }

  Map<String, dynamic> _toMap(FriendRequest request) => {
    'fromUserId': request.fromUserId,
    'toUserId': request.toUserId,
    'sentOn': Timestamp.fromDate(request.sentOn),
    'status': request.status.name,
  };

  User _userFromData(String id, Map<String, dynamic> data) {
    final methods = data['reimbursementMethods'] as List<dynamic>? ?? [];

    return User(
      id: id,
      name: data['name'] as String,
      lastName: data['lastName'] as String,
      username: data['username'] as String,
      email: data['email'] as String,
      phone: data['phone'] as String,
      photoUrl: data['photoUrl'] as String?,
      reimbursementMethods: methods.map((item) {
        final method = Map<String, dynamic>.from(item as Map);
        return ReimbursementMethod(
          id: method['id'] as String? ?? '',
          type: method['type'] as String? ?? '',
          account: method['account'] as String? ?? '',
        );
      }).toList(),
    );
  }

  Future<void> sendRequest(String fromUserId, String toUserId) {
    final request = FriendRequest(
      id: '',
      fromUserId: fromUserId,
      toUserId: toUserId,
      sentOn: DateTime.now(),
    );
    return _requests.add(_toMap(request));
  }

  Stream<List<FriendRequest>> pendingRequestsForUser(String uid) {
    return _requests
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .snapshots()
        .map((s) => s.docs.map((d) => _fromData(d.id, d.data())).toList());
  }

  Stream<List<FriendRequest>> outgoingPendingRequestsForUser(String uid) {
    return _requests
        .where('fromUserId', isEqualTo: uid)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .snapshots()
        .map((s) => s.docs.map((d) => _fromData(d.id, d.data())).toList());
  }

  Future<void> acceptRequest(String requestId) {
    return _requests.doc(requestId).update({
      'status': FriendRequestStatus.accepted.name,
    });
  }

  Future<void> denyRequest(String requestId) {
    return _requests.doc(requestId).update({
      'status': FriendRequestStatus.denied.name,
    });
  }

  Stream<List<User>> friendsForUser(String uid) async* {
    yield await _local.friends();
    yield* _serverFriendsForUser(uid);
  }

  Future<bool> hasSavedFriends() => _local.hasSavedFriends();

  Stream<List<User>> _serverFriendsForUser(String uid) {
    final sent = _requests
        .where('fromUserId', isEqualTo: uid)
        .where('status', isEqualTo: FriendRequestStatus.accepted.name)
        .snapshots(includeMetadataChanges: true);
    final received = _requests
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: FriendRequestStatus.accepted.name)
        .snapshots(includeMetadataChanges: true);

    var sentDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    var receivedDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    var sentInitialized = false;
    var receivedInitialized = false;

    final controller = StreamController<List<User>>();
    var pendingEmission = Future<void>.value();

    Future<void> emit() async {
      final friendIds = <String>{
        ...sentDocs.map((d) => d.data()['toUserId'] as String),
        ...receivedDocs.map((d) => d.data()['fromUserId'] as String),
      };
      final docs = await Future.wait(
        friendIds.map(
          (id) => _users.doc(id).get(const GetOptions(source: Source.server)),
        ),
      );
      final friends = docs
          .where((d) => d.exists)
          .map((d) => _userFromData(d.id, d.data()!))
          .toList();
      await _local.saveFriends(friends);
      if (!controller.isClosed) controller.add(friends);
    }

    void handleServerSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot, {
      required bool isSent,
    }) {
      if (snapshot.metadata.isFromCache) return;
      if (isSent) {
        sentDocs = snapshot.docs;
        sentInitialized = true;
      } else {
        receivedDocs = snapshot.docs;
        receivedInitialized = true;
      }
      if (sentInitialized && receivedInitialized && controller.hasListener) {
        pendingEmission = pendingEmission
            .then((_) => emit())
            .catchError((Object _) {});
      }
    }

    final sentSub = sent.listen(
      (snapshot) => handleServerSnapshot(snapshot, isSent: true),
      onError: (Object _) {},
    );
    final receivedSub = received.listen(
      (snapshot) => handleServerSnapshot(snapshot, isSent: false),
      onError: (Object _) {},
    );

    controller.onCancel = () {
      sentSub.cancel();
      receivedSub.cancel();
    };

    return controller.stream;
  }
}
