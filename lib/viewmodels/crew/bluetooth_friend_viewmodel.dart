import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plansync/data/friend_repository.dart';
import 'package:plansync/data/user_repository.dart';
import 'package:plansync/models/friend_request.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/services/bluetooth_service.dart';

class BluetoothFriendViewModel extends ChangeNotifier {
  BluetoothFriendViewModel({
    required String userId,
    BluetoothFriendService? service,
    FriendRepository? friendRepository,
    UserRepository? userRepository,
  }) : _userId = userId,
       _service = service ?? BluetoothFriendService(localUserId: userId),
       _friendRepository = friendRepository ?? FriendRepository(),
       _userRepository = userRepository ?? UserRepository() {
    _nearbySub = _service.onNearbyUserFound.listen((device) {
      _nearby[device.deviceId] = device;
      _notify();
    });
    _requestSub = _service.onFriendRequestReceived.listen(
      _queueIncomingRequest,
    );
    _eventSub = _service.onEvent.listen(_handleServiceEvent);

    _friendsSub = _friendRepository
        .friendsForUser(_userId)
        .listen(
          (friends) {
            _friendUserIds = friends.map((friend) => friend.id).toSet();
            _friendsLoaded = true;
            _drainIncomingQueue();
          },
          onError: (Object error) {
            _error = 'Could not load friends: $error';
            _friendsLoaded = true;
            _drainIncomingQueue();
          },
        );
    _incomingRequestsSub = _friendRepository
        .pendingRequestsForUser(_userId)
        .listen(
          (requests) {
            _pendingIncomingUserIds = requests
                .map((request) => request.fromUserId)
                .toSet();
            _incomingRequestsLoaded = true;
            _drainIncomingQueue();
          },
          onError: (Object error) {
            _error = 'Could not load pending friend requests: $error';
            _incomingRequestsLoaded = true;
            _drainIncomingQueue();
          },
        );
  }

  final String _userId;
  final BluetoothFriendService _service;
  final FriendRepository _friendRepository;
  final UserRepository _userRepository;

  late final StreamSubscription<NearbyDevice> _nearbySub;
  late final StreamSubscription<FriendRequestMessage> _requestSub;
  late final StreamSubscription<BluetoothEvent> _eventSub;
  late final StreamSubscription<List<User>> _friendsSub;
  late final StreamSubscription<List<FriendRequest>> _incomingRequestsSub;

  final Map<String, NearbyDevice> _nearby = {};
  final Map<String, FriendRequestMessage> _queuedIncoming = {};
  final Set<String> _processingIncoming = {};
  final Set<String> _sendingToDevices = {};
  Set<String> _friendUserIds = {};
  Set<String> _pendingIncomingUserIds = {};

  bool _friendsLoaded = false;
  bool _incomingRequestsLoaded = false;
  bool _isStarting = false;
  bool _isScanning = false;
  bool _isAdvertising = false;
  bool _isDrainingIncoming = false;
  bool _disposed = false;
  String? _error;
  String? _statusMessage;

  List<NearbyDevice> get nearbyDevices {
    final devices = _nearby.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    return devices;
  }

  bool get isStarting => _isStarting;
  bool get isScanning => _isScanning;
  bool get isAdvertising => _isAdvertising;
  bool get isActive => _isScanning && _isAdvertising;
  bool get isLoadingFriendData => !_friendsLoaded || !_incomingRequestsLoaded;
  String? get error => _error;
  String? get statusMessage => _statusMessage;
  bool isSendingTo(String deviceId) => _sendingToDevices.contains(deviceId);

  Future<bool> start() async {
    if (_isStarting) return false;
    if (isActive) return true;

    _isStarting = true;
    _error = null;
    _statusMessage = 'Starting Bluetooth…';
    _notify();

    try {
      _isAdvertising = await _service.startAdvertising();
      _isScanning = await _service.startScanning();
      final started = isActive;
      _statusMessage = started
          ? 'Bluetooth is ready. Nearby users will appear here.'
          : null;
      if (!started && _error == null) {
        _error = 'Could not start Bluetooth scanning and advertising.';
      }
      return started;
    } catch (error) {
      _error = 'Could not start Bluetooth: $error';
      return false;
    } finally {
      _isStarting = false;
      _notify();
    }
  }

  Future<void> stop() async {
    try {
      await _service.stop();
    } catch (error) {
      _error = 'Could not stop Bluetooth: $error';
    } finally {
      _isScanning = false;
      _isAdvertising = false;
      _nearby.clear();
      _statusMessage = null;
      _notify();
    }
  }

  Future<bool> sendFriendRequest(String deviceId) async {
    if (_sendingToDevices.contains(deviceId)) return false;
    _sendingToDevices.add(deviceId);
    _error = null;
    _statusMessage = null;
    _notify();

    try {
      final sent = await _service.sendFriendRequest(deviceId);
      if (sent) {
        _statusMessage = 'Request sent to the nearby device.';
      } else {
        _error ??= 'Could not send the Bluetooth friend request.';
      }
      return sent;
    } catch (error) {
      _error = 'Could not send the Bluetooth friend request: $error';
      return false;
    } finally {
      _sendingToDevices.remove(deviceId);
      _notify();
    }
  }

  void clearError() {
    _error = null;
    _notify();
  }

  void _handleServiceEvent(BluetoothEvent event) {
    switch (event.type) {
      case BluetoothEventType.connected:
        _statusMessage = 'Connected to a nearby device.';
      case BluetoothEventType.disconnected:
        _statusMessage = 'Disconnected from the nearby device.';
      case BluetoothEventType.requestSent:
        _statusMessage = 'Friend request sent to the nearby device.';
      case BluetoothEventType.error:
        _error = event.message ?? 'Bluetooth encountered an error.';
    }
    _notify();
  }

  void _queueIncomingRequest(FriendRequestMessage message) {
    final senderId = message.senderUserId;
    if (senderId.isEmpty || senderId == _userId) return;
    _queuedIncoming[senderId] = message;
    _drainIncomingQueue();
  }

  void _drainIncomingQueue() {
    if (_disposed ||
        _isDrainingIncoming ||
        !_friendsLoaded ||
        !_incomingRequestsLoaded ||
        _queuedIncoming.isEmpty) {
      return;
    }
    unawaited(_saveQueuedRequests());
  }

  Future<void> _saveQueuedRequests() async {
    if (_isDrainingIncoming) return;
    _isDrainingIncoming = true;
    try {
      while (!_disposed && _queuedIncoming.isNotEmpty) {
        final senderId = _queuedIncoming.keys.first;
        final message = _queuedIncoming.remove(senderId)!;
        await _saveIncomingRequest(message);
      }
    } finally {
      _isDrainingIncoming = false;
      _notify();
      if (_queuedIncoming.isNotEmpty) _drainIncomingQueue();
    }
  }

  Future<void> _saveIncomingRequest(FriendRequestMessage message) async {
    final senderId = message.senderUserId;
    if (_processingIncoming.contains(senderId) ||
        _friendUserIds.contains(senderId) ||
        _pendingIncomingUserIds.contains(senderId)) {
      return;
    }

    _processingIncoming.add(senderId);
    _error = null;
    try {
      final sender = await _userRepository.getUser(senderId);
      if (sender == null) {
        _error = 'The nearby device belongs to an unknown account.';
        return;
      }

      await _friendRepository.sendRequest(senderId, _userId);
      _pendingIncomingUserIds.add(senderId);
      _statusMessage = 'Friend request received from ${sender.name}.';
    } catch (error) {
      _error = 'Could not save the received friend request: $error';
    } finally {
      _processingIncoming.remove(senderId);
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_nearbySub.cancel());
    unawaited(_requestSub.cancel());
    unawaited(_eventSub.cancel());
    unawaited(_friendsSub.cancel());
    unawaited(_incomingRequestsSub.cancel());
    unawaited(_service.dispose());
    super.dispose();
  }
}
