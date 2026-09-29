import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/models/friend_request.dart';
import 'package:plansync/models/user.dart';

class FriendRepository {
  final _db = FirebaseFirestore.instance;
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
    return User(
      id: id,
      name: data['name'] as String,
      lastName: data['lastName'] as String,
      username: data['username'] as String,
      email: data['email'] as String,
      phone: data['phone'] as String,
      photoUrl: data['photoUrl'] as String?,
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

  Stream<List<User>> friendsForUser(String uid) {
    final sent = _requests
        .where('fromUserId', isEqualTo: uid)
        .where('status', isEqualTo: FriendRequestStatus.accepted.name)
        .snapshots();
    final received = _requests
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: FriendRequestStatus.accepted.name)
        .snapshots();

    late List<QueryDocumentSnapshot<Map<String, dynamic>>> sentDocs;
    late List<QueryDocumentSnapshot<Map<String, dynamic>>> receivedDocs;

    final controller = StreamController<List<User>>();

    Future<void> emit() async {
      final friendIds = <String>{
        ...sentDocs.map((d) => d.data()['toUserId'] as String),
        ...receivedDocs.map((d) => d.data()['fromUserId'] as String),
      };
      final docs = await Future.wait(
        friendIds.map((id) => _users.doc(id).get()),
      );
      final friends = docs
          .where((d) => d.exists)
          .map((d) => _userFromData(d.id, d.data()!))
          .toList();
      controller.add(friends);
    }

    final sentSub = sent.listen((snap) {
      sentDocs = snap.docs;
      if (controller.hasListener) emit();
    });
    final receivedSub = received.listen((snap) {
      receivedDocs = snap.docs;
      if (controller.hasListener) emit();
    });

    controller.onCancel = () {
      sentSub.cancel();
      receivedSub.cancel();
    };

    return controller.stream;
  }
}
