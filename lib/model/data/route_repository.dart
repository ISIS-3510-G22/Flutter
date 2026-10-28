import 'dart:convert';
import 'dart:io';

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
}

PlanRoute? parseGeoapifyRoute(Map<String, dynamic> json) {
  final features = json['features'];
  if (features is! List || features.isEmpty) return null;
  final feature = features.first as Map<String, dynamic>;
  final geometry = feature['geometry'] as Map<String, dynamic>;
  final properties = feature['properties'] as Map<String, dynamic>;

  var lines = geometry['coordinates'] as List;
  if (geometry['type'] == 'LineString') lines = [lines];

  final points = <LatLng>[
    for (final line in lines)
      for (final coordinate in line as List)
        LatLng(
          ((coordinate as List)[1] as num).toDouble(),
          (coordinate[0] as num).toDouble(),
        ),
  ];
  return PlanRoute(
    points: points,
    distanceMeters: (properties['distance'] as num).toDouble(),
    timeSeconds: (properties['time'] as num).toDouble(),
  );
}

class RouteRepository {
  final _client = HttpClient();
  static const _apiKey = String.fromEnvironment('GEOAPIFY_KEY');

  Future<PlanRoute?> route(List<LatLng> stops, TravelMode mode) async {
    if (stops.length < 2) return null;
    final uri = Uri.https('api.geoapify.com', '/v1/routing', {
      'waypoints': stops.map((p) => '${p.latitude},${p.longitude}').join('|'),
      'mode': mode.name,
      'apiKey': _apiKey,
    });
    final response = await (await _client.getUrl(uri)).close();
    if (response.statusCode != 200) {
      throw HttpException('Routing failed (${response.statusCode})');
    }
    final json = jsonDecode(await response.transform(utf8.decoder).join());
    return parseGeoapifyRoute(json as Map<String, dynamic>);
  }
}
