import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:plansync/model/data/friend_repository.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/live_location_repository.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/model/services/location_service.dart';
import 'package:plansync/model/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NearbyFriend {
  const NearbyFriend({required this.user, required this.distanceKm});

  final User user;
  final double distanceKm;
}

class NearbyFriendsViewModel extends ChangeNotifier
    with WidgetsBindingObserver {
  NearbyFriendsViewModel(this._userId, this._notificationService) {
    WidgetsBinding.instance.addObserver(this);
    isOnline = _connectivity.isOnline;
    _connectivitySubscription = _connectivity.changes.listen(
      _handleConnectivityChange,
    );
    unawaited(_loadNotificationRadius());
    _staleLocationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _evaluateNearbyAlerts();
      _notify();
    });
    _friendsSubscription = _friendRepository
        .friendsForUser(_userId)
        .listen(
          (friends) {
            _friends = friends;
            if (isSharing &&
                WidgetsBinding.instance.lifecycleState ==
                    AppLifecycleState.resumed) {
              _watchFriendLocations();
            }
          },
          onError: (Object error) {
            this.error = 'Could not load your friends.';
            _notify();
          },
        );
  }

  final String _userId;
  final NotificationService _notificationService;
  final _friendRepository = FriendRepository();
  final _locationRepository = LiveLocationRepository();
  final _locationService = LocationService();
  final _connectivity = ConnectivityRepository.instance;
  final _preferences = SharedPreferencesAsync();
  final _distance = const Distance();
  static const notificationRadiusOptions = [1, 2];
  late final StreamSubscription<List<User>> _friendsSubscription;
  late final StreamSubscription<bool> _connectivitySubscription;
  StreamSubscription<List<SharedLocation>>? _locationsSubscription;
  Timer? _refreshTimer;
  Future<void> _backgroundCleanup = Future<void>.value();
  late final Timer _staleLocationTimer;
  List<User> _friends = [];
  Map<String, SharedLocation> _sharedLocations = {};
  final Set<String> _alreadyAlerted = {};
  LatLng? _myPosition;
  int notificationRadiusKm = 2;
  bool isOnline = true;
  bool isSharing = false;
  bool isSharingPaused = false;
  bool isLoading = false;
  bool _disposed = false;
  int _connectivityRevision = 0;
  String? error;
  LocationError? locationError;

  String? get sharingMessage => isSharingPaused ? 'Sharing paused.' : null;

  List<NearbyFriend> get nearbyFriends {
    final position = _myPosition;
    if (!isSharing || position == null) return const [];
    final usersById = {for (final friend in _friends) friend.id: friend};
    final matches = <NearbyFriend>[];
    for (final location in _sharedLocations.values) {
      final friend = usersById[location.userId];
      if (friend == null ||
          DateTime.now().difference(location.updatedAt) >
              const Duration(minutes: 3)) {
        continue;
      }
      final km =
          _distance.as(LengthUnit.Meter, position, location.position) / 1000;
      if (km <= 10) matches.add(NearbyFriend(user: friend, distanceKm: km));
    }
    matches.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return matches;
  }

  Future<void> selectNotificationRadius(int radiusKm) async {
    if (!notificationRadiusOptions.contains(radiusKm)) return;
    notificationRadiusKm = radiusKm;
    _evaluateNearbyAlerts();
    _notify();
    await _preferences.setInt('nearby_radius_km', radiusKm);
  }

  Future<void> _loadNotificationRadius() async {
    try {
      final savedRadius = await _preferences.getInt('nearby_radius_km');
      if (savedRadius != null &&
          notificationRadiusOptions.contains(savedRadius)) {
        notificationRadiusKm = savedRadius;
        _notify();
      }
    } catch (_) {}
  }

  void _handleConnectivityChange(bool online) {
    _connectivityRevision++;
    isOnline = online;
    if (!online && isSharing) {
      isSharingPaused = true;
      error = null;
      _refreshTimer?.cancel();
      _stopWatchingFriendLocations();
      _notify();
      return;
    }
    if (online && isSharing && isSharingPaused) {
      unawaited(_resumeAfterReconnect());
      return;
    }
    _notify();
  }

  Future<void> _resumeAfterReconnect() async {
    await _resumeSharing();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isSharing) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_resumeSharing());
    } else {
      _refreshTimer?.cancel();
      _stopWatchingFriendLocations();
      if (_connectivity.isOnline) {
        _backgroundCleanup = _locationRepository.stopSharing(_userId);
      }
    }
  }

  Future<void> startSharing() async {
    if (isSharing || isLoading) return;
    if (!_connectivity.isOnline) {
      isOnline = false;
      error = 'Sharing needs a connection.';
      _notify();
      return;
    }
    isLoading = true;
    error = null;
    locationError = null;
    _notify();

    final result = await _locationService.currentPosition();
    if (_disposed) return;
    isLoading = false;
    if (result.error != null) {
      locationError = result.error;
      _notify();
      return;
    }

    isSharing = true;
    isSharingPaused = false;
    _myPosition = result.position;
    final published = await _publish(result.position!);
    if (isSharing && published) {
      _watchFriendLocations();
      _startRefreshTimer();
      _evaluateNearbyAlerts();
    }
    _notify();
  }

  Future<void> stopSharing() async {
    isSharing = false;
    isSharingPaused = false;
    _refreshTimer?.cancel();
    _stopWatchingFriendLocations();
    _myPosition = null;
    _alreadyAlerted.clear();
    _notify();
    try {
      if (_connectivity.isOnline) {
        await _locationRepository.stopSharing(_userId);
      }
    } catch (_) {
      error = 'Could not stop sharing. Please try again.';
      _notify();
    }
  }

  Future<void> openSettings() {
    if (locationError == LocationError.serviceDisabled) {
      return _locationService.openLocationSettings();
    }
    return _locationService.openSettings();
  }

  void _watchFriendLocations() {
    if (!isSharing) return;
    unawaited(_locationsSubscription?.cancel());
    _sharedLocations = {};
    _locationsSubscription = _locationRepository
        .watchFriends(_friends.map((friend) => friend.id).toList())
        .listen(
          (locations) {
            _sharedLocations = {
              for (final item in locations) item.userId: item,
            };
            _evaluateNearbyAlerts();
            _notify();
          },
          onError: (Object error) {
            this.error =
                'Could not read friend locations. Check access and connection.';
            _notify();
          },
        );
  }

  void _stopWatchingFriendLocations() {
    unawaited(_locationsSubscription?.cancel());
    _locationsSubscription = null;
    _sharedLocations = {};
    _notify();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_refreshAndPublish()),
    );
  }

  Future<void> _refreshAndPublish() async {
    if (!isSharing) return;
    if (!_connectivity.isOnline) {
      isOnline = false;
      isSharingPaused = true;
      _refreshTimer?.cancel();
      _stopWatchingFriendLocations();
      _notify();
      return;
    }
    final result = await _locationService.currentPosition();
    if (_disposed || !isSharing) return;
    if (result.error != null) {
      locationError = result.error;
      await stopSharing();
      return;
    }
    _myPosition = result.position;
    if (!await _publish(result.position!)) return;
    _evaluateNearbyAlerts();
    _notify();
  }

  Future<void> _resumeSharing() async {
    try {
      await _backgroundCleanup;
    } catch (_) {}
    if (_disposed || !isSharing) return;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    if (!_connectivity.isOnline) {
      isOnline = false;
      isSharingPaused = true;
      _notify();
      return;
    }
    await _refreshAndPublish();
    if (isSharing && !isSharingPaused) {
      _watchFriendLocations();
      _startRefreshTimer();
      _evaluateNearbyAlerts();
    }
  }

  Future<bool> _publish(LatLng position) async {
    if (!_connectivity.isOnline) {
      isOnline = false;
      isSharingPaused = true;
      error = null;
      _notify();
      return false;
    }
    final connectivityRevision = _connectivityRevision;
    try {
      await _locationRepository
          .publish(_userId, position)
          .timeout(const Duration(seconds: 8));
      isSharingPaused = false;
      error = null;
      return true;
    } catch (_) {
      if (connectivityRevision != _connectivityRevision) return false;
      _refreshTimer?.cancel();
      if (!_connectivity.isOnline) {
        isOnline = false;
        isSharingPaused = true;
        error = null;
      } else {
        isSharing = false;
        isSharingPaused = false;
        error = 'Could not start location sharing. Check your connection.';
      }
      _notify();
      return false;
    }
  }

  void _evaluateNearbyAlerts() {
    if (!isSharing ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    final friends = nearbyFriends;
    final distances = {for (final friend in friends) friend.user.id: friend};
    final inRange = distances.entries
        .where((entry) => entry.value.distanceKm <= notificationRadiusKm)
        .toList();

    for (final entry in inRange) {
      if (_alreadyAlerted.add(entry.key)) {
        final name = '${entry.value.user.name} ${entry.value.user.lastName}'
            .trim();
        unawaited(
          _notificationService.showNearbyFriendAlert(
            friendId: entry.key,
            friendName: name.isEmpty ? entry.value.user.username : name,
          ),
        );
      }
    }

    final outsideHysteresis = distances.entries
        .where((entry) => entry.value.distanceKm > notificationRadiusKm + 0.25)
        .map((entry) => entry.key)
        .toSet();
    _alreadyAlerted.removeAll(outsideHysteresis);
    _alreadyAlerted.removeWhere((id) => !distances.containsKey(id));
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _staleLocationTimer.cancel();
    _refreshTimer?.cancel();
    unawaited(_friendsSubscription.cancel());
    unawaited(_connectivitySubscription.cancel());
    unawaited(_locationsSubscription?.cancel());
    if (isSharing && _connectivity.isOnline) {
      unawaited(_locationRepository.stopSharing(_userId));
    }
    super.dispose();
  }
}
