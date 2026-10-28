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
  Future<LocationResult> currentPosition() async {
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

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LocationResult.success(
      LatLng(position.latitude, position.longitude),
    );
  }

  Future<void> openSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
