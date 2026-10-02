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

    _outgoingRequestsSub = _repository
        .outgoingPendingRequestsForUser(_uid)
        .listen(
          (requests) {
            _outgoingRequestUserIds = requests
                .map((request) => request.toUserId)
                .toSet();
            _outgoingLoaded = true;
            _notify();
          },
          onError: (Object error) {
            this.error = 'Could not load sent friend requests: $error';
            _outgoingLoaded = true;
            _notify();
          },
        );
  }

  final String _uid;
  final _repository = FriendRepository();
  final _userRepository = UserRepository();

  late final StreamSubscription<List<User>> _friendsSub;
  late final StreamSubscription<List<FriendRequest>> _requestsSub;
  late final StreamSubscription<List<FriendRequest>> _outgoingRequestsSub;

  List<User> _friends = [];
  List<FriendRequest> _requests = [];
  Map<String, User> _requesters = {};
  List<User> _searchResults = [];
  List<User>? _searchableUsers;
  Future<List<User>>? _searchableUsersFuture;
  Set<String> _outgoingRequestUserIds = {};
  final Set<String> _busyIds = {};

  bool _friendsLoaded = false;
  bool _requestsLoaded = false;
  bool _outgoingLoaded = false;
  bool _searching = false;
  int _searchGeneration = 0;
  bool _disposed = false;
  String? error;

  List<User> get friends => _friends;
  List<User> get searchResults => _searchResults;
  List<FriendRequest> get pendingRequests => _requests;
  bool get isLoading => !_friendsLoaded || !_requestsLoaded || !_outgoingLoaded;
  bool get areRequestsLoading => !_requestsLoaded;
  String? get requestError =>
      error?.startsWith('Could not load friend request') == true ||
          error?.startsWith('Could not load requesters') == true
      ? error
      : null;
  bool get isSearching => _searching;

  User? requesterFor(FriendRequest request) => _requesters[request.fromUserId];
  bool isBusy(String id) => _busyIds.contains(id);
  bool hasSentRequestTo(String userId) =>
      _outgoingRequestUserIds.contains(userId);
  bool isFriend(String userId) => _friends.any((user) => user.id == userId);

  Future<void> searchUsers(String query) async {
    final generation = ++_searchGeneration;
    final normalized = query
        .trim()
        .replaceFirst(RegExp(r'^@'), '')
        .toLowerCase();
    if (normalized.isEmpty) {
      _searchResults = [];
      _searching = false;
      error = null;
      _notify();
      return;
    }

    _searching = true;
    error = null;
    _notify();
    try {
      final users = _searchableUsers ??= await (_searchableUsersFuture ??=
          _userRepository.getUsersForSearch(excludingId: _uid));
      if (generation != _searchGeneration) return;
      _searchResults = users.where((user) {
        final fullName = '${user.name} ${user.lastName}'.trim().toLowerCase();
        return user.name.toLowerCase().contains(normalized) ||
            user.lastName.toLowerCase().contains(normalized) ||
            fullName.contains(normalized) ||
            user.username.toLowerCase().contains(normalized);
      }).toList();
    } catch (error) {
      if (generation != _searchGeneration) return;
      if (_searchableUsers == null) _searchableUsersFuture = null;
      this.error = 'Could not search users: $error';
      _searchResults = [];
    } finally {
      if (generation != _searchGeneration) return;
      _searching = false;
      _notify();
    }
  }

  Future<void> sendFriendRequest(String targetUserId) {
    if (targetUserId == _uid ||
        isFriend(targetUserId) ||
        hasSentRequestTo(targetUserId)) {
      return Future.value();
    }
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
    _outgoingRequestsSub.cancel();
    super.dispose();
  }
}
