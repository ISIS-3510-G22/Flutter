import 'package:latlong2/latlong.dart';

enum TravelMode { walk, drive }

class PlanRoute {
  final List<LatLng> points;
  final double distanceMeters;
  final double timeSeconds;

  const PlanRoute({
    required this.points,
    required this.distanceMeters,
    required this.timeSeconds,
  });

  Map<String, dynamic> toJson() => {
    'points': [
      for (final p in points) [p.latitude, p.longitude],
    ],
    'distanceMeters': distanceMeters,
    'timeSeconds': timeSeconds,
  };

  factory PlanRoute.fromJson(Map<String, dynamic> json) => PlanRoute(
    points: [
      for (final p in json['points'] as List)
        LatLng(((p as List)[0] as num).toDouble(), (p[1] as num).toDouble()),
    ],
    distanceMeters: (json['distanceMeters'] as num).toDouble(),
    timeSeconds: (json['timeSeconds'] as num).toDouble(),
  );
}
