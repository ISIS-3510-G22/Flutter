import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/crew_write_queue.dart';
import 'package:plansync/model/data/friend_repository.dart';
import 'package:plansync/model/data/user_repository.dart';
import 'package:plansync/model/logic/user_search.dart';
import 'package:plansync/model/models/friend_request.dart';
import 'package:plansync/model/models/user.dart';

class FriendsViewModel extends ChangeNotifier {
  FriendsViewModel(this._uid) {
    _friendsSub = _repository
        .friendsForUser(_uid)
        .listen(
          (friends) async {
            _friends = friends;
            if (_friendsStreamEmissions++ == 0) {
              _hasSavedFriends =
                  _hasSavedFriends || await _repository.hasSavedFriends();
            } else {
              _hasServerFriendResult = true;
              _hasSavedFriends = true;
            }
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
            await _saveRequestsToFile();
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
            _outgoingRequests = requests;
            _outgoingRequestUserIds = requests
                .map((request) => request.toUserId)
                .toSet();
            _saveRequestsToFile();
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
  List<FriendRequest> _outgoingRequests = [];
  Map<String, User> _requesters = {};
  List<User> _searchResults = [];
  List<User>? _searchableUsers;
  Future<List<User>>? _searchableUsersFuture;
  Set<String> _outgoingRequestUserIds = {};
  final Set<String> _busyIds = {};
  final Set<String> _waitingIds = {};
  final Map<String, String> _waitingDocIds = {};
  late final StreamSubscription<void> _queueSub = CrewWriteQueue
      .instance
      .changes
      .listen((_) {
        _waitingIds.removeWhere(
          (id) => !CrewWriteQueue.instance.pendingDocIds.contains(
            _waitingDocIds[id],
          ),
        );
        _waitingDocIds.removeWhere((id, docId) => !_waitingIds.contains(id));
        _notify();
      });

  bool _friendsLoaded = false;
  int _friendsStreamEmissions = 0;
  bool _hasSavedFriends = false;
  bool _hasServerFriendResult = false;
  bool _requestsLoaded = false;
  bool _outgoingLoaded = false;
  bool _searching = false;
  bool _searchDirectoryNeverStored = false;
  String? _searchMessage;
  int _searchGeneration = 0;
  bool _disposed = false;
  String? error;

  List<User> get friends => _friends;
  bool get hasSavedFriends => _hasSavedFriends || _hasServerFriendResult;
  bool get areFriendsLoading => !_friendsLoaded;
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
  bool get searchDirectoryNeverStored => _searchDirectoryNeverStored;
  String? get searchMessage => _searchMessage;

  User? requesterFor(FriendRequest request) => _requesters[request.fromUserId];

  Future<void> _saveRequestsToFile() async {
    try {
      await _repository.saveRequestsForUser(
        _uid,
        incoming: _requests,
        requesters: _requesters,
        outgoing: _outgoingRequests,
      );
    } catch (error) {
      this.error = 'Could not save friend requests: $error';
    }
  }

  bool isBusy(String id) => _busyIds.contains(id);
  bool isWaitingToSync(String id) => _waitingIds.contains(id);
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
      _searchMessage = null;
      _searchDirectoryNeverStored = false;
      error = null;
      _notify();
      return;
    }

    _searching = true;
    error = null;
    _searchMessage = null;
    _searchDirectoryNeverStored = false;
    _notify();
    try {
      final bool online = ConnectivityRepository.instance.isOnline;
      if (!online) {
        final hasSavedDirectory = await _userRepository
            .hasSavedSearchDirectory();
        if (generation != _searchGeneration) return;
        if (!hasSavedDirectory) {
          _searchDirectoryNeverStored = true;
          _searchMessage = 'Search needs a connection the first time.';
          _searchResults = [];
          return;
        }
        final users = await _userRepository.storedSearchDirectory();
        _searchableUsers = users;
        _searchMessage =
            'Offline: searching people saved on your phone. New users won\'t show up.';
        if (generation != _searchGeneration) return;
        _searchResults = await Isolate.run(() => rankUsers(users, normalized));
      } else {
        final users = _searchableUsers ??= await (_searchableUsersFuture ??=
            _userRepository.getUsersForSearch(excludingId: _uid));
        if (generation != _searchGeneration) return;
        _searchResults = await Isolate.run(() => rankUsers(users, normalized));
      }
      if (generation != _searchGeneration) return;
    } catch (_) {
      if (generation != _searchGeneration) return;
      _searchableUsersFuture = null;
      try {
        final hasSavedDirectory = await _userRepository
            .hasSavedSearchDirectory();
        if (generation != _searchGeneration) return;
        if (!hasSavedDirectory) {
          _searchDirectoryNeverStored = true;
          _searchMessage = 'Search needs a connection the first time.';
          _searchResults = [];
        } else {
          final users = await _userRepository.storedSearchDirectory();
          if (generation != _searchGeneration) return;
          _searchableUsers = users;
          _searchResults = await Isolate.run(
            () => rankUsers(users, normalized),
          );
          _searchMessage =
              'Offline: searching people saved on your phone. New users won\'t show up.';
        }
      } catch (localError) {
        if (generation != _searchGeneration) return;
        this.error = 'Could not search users: $localError';
        _searchResults = [];
      }
    } finally {
      if (generation != _searchGeneration) return;
      _searching = false;
      _notify();
    }
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    if (targetUserId == _uid ||
        isFriend(targetUserId) ||
        hasSentRequestTo(targetUserId)) {
      return;
    }
    if (await _repository.hasPendingOutgoingRequest(_uid, targetUserId)) {
      _outgoingRequestUserIds.add(targetUserId);
      _notify();
      return;
    }
    User? target;
    for (final user in [..._searchResults, ...?_searchableUsers]) {
      if (user.id == targetUserId) {
        target = user;
        break;
      }
    }
    final fullName = target == null
        ? ''
        : '${target.name} ${target.lastName}'.trim();
    final displayName = fullName.isNotEmpty
        ? fullName
        : target?.username.isNotEmpty == true
        ? target!.username
        : targetUserId;
    await _runQueued(targetUserId, () async {
      final requestId = _repository.newRequestId();
      final sentOn = DateTime.now();
      final request = FriendRequest(
        id: requestId,
        fromUserId: _uid,
        toUserId: targetUserId,
        sentOn: sentOn,
      );
      _outgoingRequestUserIds.add(targetUserId);
      _outgoingRequests = [..._outgoingRequests, request];
      _waitingDocIds[targetUserId] = requestId;
      _waitingIds.add(targetUserId);
      await _saveRequestsToFile();
      _notify();
      final synced = await _repository.sendRequest(
        _uid,
        targetUserId,
        requestId,
        sentOn,
        displayName,
      );
      if (!synced) {
        _waitingIds.add(targetUserId);
        _waitingDocIds[targetUserId] = requestId;
      } else {
        _waitingIds.remove(targetUserId);
        _waitingDocIds.remove(targetUserId);
      }
      await _saveRequestsToFile();
      return synced;
    }, 'Could not send friend request');
  }

  Future<void> acceptRequest(FriendRequest request) {
    return _runQueued(request.id, () async {
      _requests = _requests.where((item) => item.id != request.id).toList();
      final requester = _requesters[request.fromUserId];
      if (requester != null) await _repository.saveAcceptedFriend(requester);
      await _saveRequestsToFile();
      _notify();
      final itemName = _requesterName(requester, request.fromUserId);
      final synced = await _repository.acceptRequest(
        request.id,
        itemName: itemName,
      );
      if (!synced) _waitingIds.add(request.id);
      await _saveRequestsToFile();
      return synced;
    }, 'Could not accept friend request');
  }

  Future<void> denyRequest(FriendRequest request) {
    return _runQueued(request.id, () async {
      _requests = _requests.where((item) => item.id != request.id).toList();
      await _saveRequestsToFile();
      _notify();
      final requester = _requesters[request.fromUserId];
      final itemName = _requesterName(requester, request.fromUserId);
      final synced = await _repository.denyRequest(
        request.id,
        itemName: itemName,
      );
      if (!synced) _waitingIds.add(request.id);
      await _saveRequestsToFile();
      return synced;
    }, 'Could not deny friend request');
  }

  Future<void> _runQueued(
    String id,
    Future<bool> Function() action,
    String message,
  ) async {
    _busyIds.add(id);
    error = null;
    _notify();
    try {
      await action();
    } catch (e) {
      error = '$message: $e';
    } finally {
      _busyIds.remove(id);
      _notify();
    }
  }

  String _requesterName(User? requester, String fallback) {
    if (requester == null) return fallback;
    final fullName = '${requester.name} ${requester.lastName}'.trim();
    if (fullName.isNotEmpty) return fullName;
    return requester.username.isNotEmpty ? requester.username : fallback;
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
    _queueSub.cancel();
    super.dispose();
  }
}
