import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/crew_write_queue.dart';
import 'package:plansync/model/data/local/crew_local_store.dart';
import 'package:plansync/model/data/local/json_file_store.dart';
import 'package:plansync/model/models/friend_request.dart';
import 'package:plansync/model/models/reimbursement_method.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/model/models/pending_write.dart';

class FriendRepository {
  final _db = FirebaseFirestore.instance;
  final _local = CrewLocalStore();
  final _files = JsonFileStore();
  Future<void> _requestFileWrite = Future<void>.value();
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

  Future<void> saveAcceptedFriend(User user) => _local.addFriend(user);

  Future<void> saveRequestsForUser(
    String uid, {
    required List<FriendRequest> incoming,
    required Map<String, User> requesters,
    required List<FriendRequest> outgoing,
  }) {
    final contents = jsonEncode({
      'incoming': incoming.map((request) {
        final requester = requesters[request.fromUserId];
        return {
          ..._requestToJson(request),
          'requester': requester == null
              ? null
              : {
                  'id': requester.id,
                  'name': requester.name,
                  'lastName': requester.lastName,
                  'username': requester.username,
                  'photoUrl': requester.photoUrl,
                },
        };
      }).toList(),
      'outgoing': outgoing.map(_requestToJson).toList(),
    });
    _requestFileWrite = _requestFileWrite
        .catchError((Object _) {})
        .then((_) => _files.write('friend_requests_$uid.json', contents));
    return _requestFileWrite;
  }

  Map<String, dynamic> _requestToJson(FriendRequest request) => {
    'id': request.id,
    'fromUserId': request.fromUserId,
    'toUserId': request.toUserId,
    'sentOn': request.sentOn.toIso8601String(),
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

  String newRequestId() => _requests.doc().id;

  Future<bool> sendRequest(
    String fromUserId,
    String toUserId, [
    String? requestId,
    DateTime? sentOn,
  ]) {
    requestId ??= newRequestId();
    final requestRef = _requests.doc(requestId);
    sentOn ??= DateTime.now();
    return CrewWriteQueue.instance.submit(
      PendingWrite(
        kind: CrewWriteKind.requestSend,
        docId: requestRef.id,
        payload: {
          'requestId': requestRef.id,
          'fromUserId': fromUserId,
          'toUserId': toUserId,
          'sentOn': sentOn.toIso8601String(),
        },
      ),
    );
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

  Future<bool> acceptRequest(String requestId) {
    return CrewWriteQueue.instance.submit(
      PendingWrite(
        kind: CrewWriteKind.requestAccept,
        docId: requestId,
        payload: const {},
      ),
    );
  }

  Future<bool> denyRequest(String requestId) {
    return CrewWriteQueue.instance.submit(
      PendingWrite(
        kind: CrewWriteKind.requestDeny,
        docId: requestId,
        payload: const {},
      ),
    );
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
      ConnectivityRepository.instance.ensureOnline();
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
