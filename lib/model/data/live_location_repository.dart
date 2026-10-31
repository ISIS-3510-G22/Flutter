import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class SharedLocation {
  const SharedLocation({
    required this.userId,
    required this.position,
    required this.updatedAt,
  });

  final String userId;
  final LatLng position;
  final DateTime updatedAt;
}

class LiveLocationRepository {
  final _locations = FirebaseFirestore.instance.collection('liveLocations');

  Future<void> publish(String userId, LatLng position) =>
      _locations.doc(userId).set({
        'latitude': _round(position.latitude),
        'longitude': _round(position.longitude),
        'updatedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 3)),
        ),
      });

  double _round(double coordinate) =>
      (coordinate * 1000).roundToDouble() / 1000;

  Future<void> stopSharing(String userId) => _locations.doc(userId).delete();

  Stream<List<SharedLocation>> watchFriends(List<String> userIds) {
    final ids = userIds.toSet().toList();
    if (ids.isEmpty) return Stream.value(const <SharedLocation>[]);

    final controller = StreamController<List<SharedLocation>>();
    final locations = <String, SharedLocation>{};
    final subscriptions = <StreamSubscription<dynamic>>[];
    var disposed = false;

    void emit() {
      if (!disposed) controller.add(locations.values.toList());
    }

    for (final id in ids) {
      final subscription = _locations
          .doc(id)
          .snapshots()
          .listen(
            (snapshot) {
              final data = snapshot.data();
              final expiresAt = data?['expiresAt'];
              final latitude = data?['latitude'];
              final longitude = data?['longitude'];
              if (data == null ||
                  expiresAt is! Timestamp ||
                  latitude is! num ||
                  longitude is! num ||
                  !expiresAt.toDate().isAfter(DateTime.now())) {
                locations.remove(id);
              } else {
                final updatedAt = data['updatedAt'];
                locations[id] = SharedLocation(
                  userId: id,
                  position: LatLng(latitude.toDouble(), longitude.toDouble()),
                  updatedAt: updatedAt is Timestamp
                      ? updatedAt.toDate()
                      : DateTime.now(),
                );
              }
              emit();
            },
            onError: (Object error) {
              debugPrint('Could not read a friend location: $error');
              locations.remove(id);
              if (!disposed) controller.addError(error);
              emit();
            },
          );
      subscriptions.add(subscription);
    }

    controller.onCancel = () async {
      disposed = true;
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };
    return controller.stream;
  }
}
