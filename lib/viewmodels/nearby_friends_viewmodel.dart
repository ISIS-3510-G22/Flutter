import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:plansync/data/friend_repository.dart';
import 'package:plansync/data/live_location_repository.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/services/location_service.dart';
import 'package:plansync/services/notification_service.dart';

class NearbyFriend {
  const NearbyFriend({required this.user, required this.distanceKm});

  final User user;
  final double distanceKm;
}

class NearbyFriendsViewModel extends ChangeNotifier
    with WidgetsBindingObserver {
  NearbyFriendsViewModel(this._userId, this._notificationService) {
    WidgetsBinding.instance.addObserver(this);
    _staleLocationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        _evaluateNearbyAlerts();
        _notify();
      },
    );
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
  final _distance = const Distance();
  static const notificationRadiusOptions = [1, 2];
  late final StreamSubscription<List<User>> _friendsSubscription;
  StreamSubscription<List<SharedLocation>>? _locationsSubscription;
  Timer? _refreshTimer;
  Future<void> _backgroundCleanup = Future<void>.value();
  late final Timer _staleLocationTimer;
  List<User> _friends = [];
  Map<String, SharedLocation> _sharedLocations = {};
  final Set<String> _alreadyAlerted = {};
  LatLng? _myPosition;
  int notificationRadiusKm = 2;
  bool isSharing = false;
  bool isLoading = false;
  bool _disposed = false;
  String? error;
  LocationError? locationError;

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

  void selectNotificationRadius(int radiusKm) {
    if (!notificationRadiusOptions.contains(radiusKm)) return;
    notificationRadiusKm = radiusKm;
    _evaluateNearbyAlerts();
    _notify();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isSharing) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_resumeSharing());
    } else {
      _refreshTimer?.cancel();
      _stopWatchingFriendLocations();
      _backgroundCleanup = _locationRepository.stopSharing(_userId);
    }
  }

  Future<void> startSharing() async {
    if (isSharing || isLoading) return;
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
    _myPosition = result.position;
    await _publish(result.position!);
    if (isSharing) {
      _watchFriendLocations();
      _startRefreshTimer();
      _evaluateNearbyAlerts();
    }
    _notify();
  }

  Future<void> stopSharing() async {
    isSharing = false;
    _refreshTimer?.cancel();
    _stopWatchingFriendLocations();
    _myPosition = null;
    _alreadyAlerted.clear();
    _notify();
    try {
      await _locationRepository.stopSharing(_userId);
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
    final result = await _locationService.currentPosition();
    if (_disposed || !isSharing) return;
    if (result.error != null) {
      locationError = result.error;
      await stopSharing();
      return;
    }
    _myPosition = result.position;
    await _publish(result.position!);
    _evaluateNearbyAlerts();
    _notify();
  }

  Future<void> _resumeSharing() async {
    try {
      await _backgroundCleanup;
    } catch (_) {}
    if (_disposed || !isSharing) return;
    await _refreshAndPublish();
    if (isSharing) {
      _watchFriendLocations();
      _startRefreshTimer();
      _evaluateNearbyAlerts();
    }
  }

  Future<void> _publish(LatLng position) async {
    try {
      await _locationRepository.publish(_userId, position);
      error = null;
    } catch (_) {
      isSharing = false;
      _refreshTimer?.cancel();
      error = 'Could not start location sharing. Check your connection.';
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
    unawaited(_locationsSubscription?.cancel());
    if (isSharing) unawaited(_locationRepository.stopSharing(_userId));
    super.dispose();
  }
}
