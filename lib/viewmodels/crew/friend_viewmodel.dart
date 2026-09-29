import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/data/friend_repository.dart';
import 'package:plansync/data/user_repository.dart';
import 'package:plansync/models/friend_request.dart';
import 'package:plansync/models/user.dart';

class FriendsViewModel extends ChangeNotifier {
  FriendsViewModel(this._uid) {
    _friendsSub = _repository
        .friendsForUser(_uid)
        .listen(
          (friends) {
            _friends = friends;
            _friendsLoaded = true;
            _notify();
          },
          onError: (Object error) {
            this.error = 'Could not load friends: $error';
            _friendsLoaded = true;
            _notify();
          },
        );

    _requestsSub = _repository
        .pendingRequestsForUser(_uid)
        .listen(
          (requests) async {
            _requests = requests;
            try {
              final requesterIds = requests
                  .map((request) => request.fromUserId)
                  .toList();
              final users = await _userRepository.getUsers(requesterIds);
              _requesters = {for (final user in users) user.id: user};
            } catch (error) {
              this.error = 'Could not load requesters: $error';
            }
            _requestsLoaded = true;
            _notify();
          },
          onError: (Object error) {
            this.error = 'Could not load friend requests: $error';
            _requestsLoaded = true;
            _notify();
          },
        );
  }

  final String _uid;
  final _repository = FriendRepository();
  final _userRepository = UserRepository();

  late final StreamSubscription<List<User>> _friendsSub;
  late final StreamSubscription<List<FriendRequest>> _requestsSub;

  List<User> _friends = [];
  List<FriendRequest> _requests = [];
  Map<String, User> _requesters = {};
  final Set<String> _busyIds = {};

  bool _friendsLoaded = false;
  bool _requestsLoaded = false;
  bool _disposed = false;
  String? error;

  List<User> get friends => _friends;
  List<FriendRequest> get pendingRequests => _requests;
  bool get isLoading => !_friendsLoaded || !_requestsLoaded;

  User? requesterFor(FriendRequest request) => _requesters[request.fromUserId];
  bool isBusy(String id) => _busyIds.contains(id);

  Future<void> sendFriendRequest(String targetUserId) {
    return _run(
      targetUserId,
      () => _repository.sendRequest(_uid, targetUserId),
      'Could not send friend request',
    );
  }

  Future<void> acceptRequest(FriendRequest request) {
    return _run(
      request.id,
      () => _repository.acceptRequest(request.id),
      'Could not accept friend request',
    );
  }

  Future<void> denyRequest(FriendRequest request) {
    return _run(
      request.id,
      () => _repository.denyRequest(request.id),
      'Could not deny friend request',
    );
  }

  Future<void> _run(
    String id,
    Future<void> Function() action,
    String message,
  ) async {
    _busyIds.add(id);
    error = null;
    _notify();

    try {
      await action();
    } catch (error) {
      this.error = '$message: $error';
    } finally {
      _busyIds.remove(id);
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _friendsSub.cancel();
    _requestsSub.cancel();
    super.dispose();
  }
}
