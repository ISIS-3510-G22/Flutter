import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

class NearbyDevice {
  final String deviceId;
  final int rssi;

  const NearbyDevice({required this.deviceId, required this.rssi});
}

class FriendRequestMessage {
  static const String typeRequest = 'friend_request';

  final String type;
  final String senderUserId;

  const FriendRequestMessage({
    this.type = typeRequest,
    required this.senderUserId,
  });

  Uint8List toBytes() => Uint8List.fromList(
    utf8.encode(jsonEncode({'t': type, 'uid': senderUserId})),
  );

  factory FriendRequestMessage.fromBytes(Uint8List bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['t'] != typeRequest ||
        decoded['uid'] is! String ||
        (decoded['uid'] as String).trim().isEmpty ||
        (decoded['uid'] as String).length > 128) {
      throw const FormatException('Invalid friend request payload');
    }
    return FriendRequestMessage(senderUserId: decoded['uid'] as String);
  }
}

enum BluetoothEventType { connected, disconnected, requestSent, error }

class BluetoothEvent {
  final BluetoothEventType type;
  final String? message;

  const BluetoothEvent(this.type, [this.message]);
}

class BluetoothFriendService {
  static const int _maxMessageBytes = 512;
  static final UUID _serviceUuid = UUID.fromString(
    'b7a1c2e0-5f3d-4a6b-9c1e-2d8f4a7b6c10',
  );
  static final UUID _characteristicUuid = UUID.fromString(
    'b7a1c2e1-5f3d-4a6b-9c1e-2d8f4a7b6c10',
  );

  final CentralManager _central = CentralManager();
  final PeripheralManager _peripheral = PeripheralManager();

  final String localUserId;

  BluetoothFriendService({required this.localUserId});

  final _nearbyController = StreamController<NearbyDevice>.broadcast();
  final _requestController = StreamController<FriendRequestMessage>.broadcast();
  final _eventController = StreamController<BluetoothEvent>.broadcast();

  Stream<NearbyDevice> get onNearbyUserFound => _nearbyController.stream;
  Stream<FriendRequestMessage> get onFriendRequestReceived =>
      _requestController.stream;
  Stream<BluetoothEvent> get onEvent => _eventController.stream;

  final Map<String, Peripheral> _found = {};
  final Map<String, _IncomingMessage> _incomingMessages = {};
  StreamSubscription<DiscoveredEventArgs>? _discoverySub;
  StreamSubscription<GATTCharacteristicWriteRequestedEventArgs>? _writeSub;
  StreamSubscription<PeripheralConnectionStateChangedEventArgs>? _connSub;
  bool _serviceAdded = false;
  bool _advertising = false;
  bool _scanning = false;

  Future<bool> ensureReady() async {
    try {
      final scanGranted = await _central.authorize();
      final advertiseGranted = await _peripheral.authorize();
      if (!scanGranted || !advertiseGranted) {
        _emitError('Bluetooth permission denied');
        return false;
      }
      if (_central.state != BluetoothLowEnergyState.poweredOn ||
          _peripheral.state != BluetoothLowEnergyState.poweredOn) {
        _emitError('Bluetooth is off or unavailable');
        return false;
      }
      return true;
    } catch (e) {
      _emitError('Bluetooth check failed: $e');
      return false;
    }
  }

  Future<bool> startAdvertising() async {
    if (_advertising) return true;
    if (!await ensureReady()) return false;

    try {
      if (!_serviceAdded) {
        final characteristic = GATTCharacteristic.mutable(
          uuid: _characteristicUuid,
          properties: [GATTCharacteristicProperty.write],
          permissions: [GATTCharacteristicPermission.write],
          descriptors: [],
        );
        await _peripheral.addService(
          GATTService(
            uuid: _serviceUuid,
            isPrimary: true,
            includedServices: [],
            characteristics: [characteristic],
          ),
        );
        _serviceAdded = true;
      }

      _writeSub ??= _peripheral.characteristicWriteRequested.listen(
        _handleWriteRequest,
      );

      await _peripheral.startAdvertising(
        Advertisement(serviceUUIDs: [_serviceUuid]),
      );
      _advertising = true;
      return true;
    } catch (e) {
      _emitError('Could not start advertising: $e');
      return false;
    }
  }

  Future<void> _handleWriteRequest(
    GATTCharacteristicWriteRequestedEventArgs args,
  ) async {
    try {
      if (args.characteristic.uuid != _characteristicUuid) {
        await _peripheral.respondWriteRequestWithError(
          args.request,
          error: GATTError.requestNotSupported,
        );
        return;
      }

      final senderDeviceId = args.central.uuid.toString();
      final payload = _appendIncomingFragment(
        senderDeviceId,
        args.request.value,
      );
      final message = payload == null
          ? null
          : FriendRequestMessage.fromBytes(payload);
      if (message?.senderUserId == localUserId) {
        throw const FormatException('Cannot receive a request from yourself');
      }
      await _peripheral.respondWriteRequest(args.request);
      if (message != null) _requestController.add(message);
    } catch (e) {
      try {
        await _peripheral.respondWriteRequestWithError(
          args.request,
          error: GATTError.requestNotSupported,
        );
      } catch (_) {}
      _emitError('Invalid friend request received');
    }
  }

  Uint8List? _appendIncomingFragment(String deviceId, Uint8List fragment) {
    var incoming = _incomingMessages[deviceId];
    if (incoming == null) {
      if (fragment.length < 3) {
        throw const FormatException('Friend request frame is too short');
      }
      final expectedLength = (fragment[0] << 8) | fragment[1];
      if (expectedLength == 0 || expectedLength > _maxMessageBytes) {
        throw const FormatException('Friend request frame has invalid length');
      }
      incoming = _IncomingMessage(expectedLength);
      _incomingMessages[deviceId] = incoming;
      incoming.bytes.addAll(fragment.skip(2));
    } else {
      incoming.bytes.addAll(fragment);
    }

    if (incoming.bytes.length > incoming.expectedLength) {
      _incomingMessages.remove(deviceId);
      throw const FormatException('Friend request frame exceeds its length');
    }
    if (incoming.bytes.length == incoming.expectedLength) {
      _incomingMessages.remove(deviceId);
      return Uint8List.fromList(incoming.bytes);
    }
    return null;
  }

  Future<bool> startScanning() async {
    if (_scanning) return true;
    if (!await ensureReady()) return false;

    try {
      _discoverySub ??= _central.discovered.listen((args) {
        final id = args.peripheral.uuid.toString();
        _found[id] = args.peripheral;
        _nearbyController.add(NearbyDevice(deviceId: id, rssi: args.rssi));
      });

      _connSub ??= _central.connectionStateChanged.listen((args) {
        _eventController.add(
          BluetoothEvent(
            args.state == ConnectionState.connected
                ? BluetoothEventType.connected
                : BluetoothEventType.disconnected,
            args.peripheral.uuid.toString(),
          ),
        );
      });

      await _central.startDiscovery(serviceUUIDs: [_serviceUuid]);
      _scanning = true;
      return true;
    } catch (e) {
      _emitError('Could not start scanning: $e');
      return false;
    }
  }

  Future<bool> sendFriendRequest(String recipientDeviceId) async {
    final peripheral = _found[recipientDeviceId];
    if (peripheral == null) {
      _emitError('Device no longer nearby');
      return false;
    }

    try {
      await _central.connect(peripheral);

      final services = await _central.discoverGATT(peripheral);
      if (Platform.isAndroid) {
        try {
          await _central.requestMTU(peripheral, mtu: 517);
        } catch (_) {}
      }
      final service = services.firstWhere((s) => s.uuid == _serviceUuid);
      final characteristic = service.characteristics.firstWhere(
        (c) => c.uuid == _characteristicUuid,
      );

      final payload = FriendRequestMessage(senderUserId: localUserId).toBytes();
      if (payload.isEmpty || payload.length > _maxMessageBytes) {
        throw StateError('Friend request payload is too large');
      }

      final writeType = GATTCharacteristicWriteType.withResponse;
      final fragmentSize = await _central.getMaximumWriteLength(
        peripheral,
        type: writeType,
      );
      if (fragmentSize < 3) {
        throw StateError('Bluetooth write size is too small');
      }

      final framed = Uint8List(payload.length + 2)
        ..[0] = (payload.length >> 8) & 0xff
        ..[1] = payload.length & 0xff
        ..setRange(2, payload.length + 2, payload);
      for (var start = 0; start < framed.length;) {
        final remaining = framed.length - start;
        final end =
            start + (remaining < fragmentSize ? remaining : fragmentSize);
        await _central.writeCharacteristic(
          peripheral,
          characteristic,
          value: Uint8List.sublistView(framed, start, end),
          type: writeType,
        );
        start = end;
      }

      _eventController.add(
        BluetoothEvent(BluetoothEventType.requestSent, recipientDeviceId),
      );
      return true;
    } catch (e) {
      _emitError('Could not send friend request: $e');
      return false;
    } finally {
      try {
        await _central.disconnect(peripheral);
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    await _discoverySub?.cancel();
    await _writeSub?.cancel();
    await _connSub?.cancel();
    _discoverySub = null;
    _writeSub = null;
    _connSub = null;

    try {
      if (_scanning) await _central.stopDiscovery();
    } catch (_) {}
    try {
      if (_advertising) await _peripheral.stopAdvertising();
    } catch (_) {}

    _scanning = false;
    _advertising = false;
    _found.clear();
    _incomingMessages.clear();
  }

  Future<void> dispose() async {
    await stop();
    try {
      await _peripheral.removeAllServices();
      _serviceAdded = false;
    } catch (_) {}
    await _nearbyController.close();
    await _requestController.close();
    await _eventController.close();
  }

  void _emitError(String message) =>
      _eventController.add(BluetoothEvent(BluetoothEventType.error, message));
}

class _IncomingMessage {
  final int expectedLength;
  final List<int> bytes = [];

  _IncomingMessage(this.expectedLength);
}
