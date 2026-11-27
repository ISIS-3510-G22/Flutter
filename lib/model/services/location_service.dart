import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationError {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class LocationResult {
  final LatLng? position;
  final LocationError? error;

  const LocationResult.success(LatLng this.position) : error = null;
  const LocationResult.failure(LocationError this.error) : position = null;
}

class LocationService {
  Future<LocationResult> currentPosition({
    Duration timeLimit = const Duration(seconds: 15),
    bool allowLastKnown = false,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult.failure(LocationError.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.failure(
        LocationError.permissionDeniedForever,
      );
    }
    if (permission == LocationPermission.denied) {
      return const LocationResult.failure(LocationError.permissionDenied);
    }

    Position? position;
    if (allowLastKnown) position = await Geolocator.getLastKnownPosition();
    position ??= await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: timeLimit,
      ),
    );
    return LocationResult.success(
      LatLng(position.latitude, position.longitude),
    );
  }

  Future<void> openSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
