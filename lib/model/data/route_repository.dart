import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:latlong2/latlong.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/route_cache.dart';
import 'package:plansync/model/data/saved_route_repository.dart';
import 'package:plansync/model/models/plan_route.dart';

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

/// Runs inside the isolate: route geometry can be thousands of coordinates,
/// the heaviest parse in the app, so it stays off the UI isolate.
PlanRoute? decodeRoute(String body) =>
    parseGeoapifyRoute(jsonDecode(body) as Map<String, dynamic>);

// Top-level on purpose: the closure only captures `body` (plain text), never
// the repository with its HttpClient, which can't be sent to an isolate.
Future<PlanRoute?> _decodeInIsolate(String body) =>
    Isolate.run(() => decodeRoute(body));

class RouteRepository {
  final _client = HttpClient();
  static const _apiKey = String.fromEnvironment('GEOAPIFY_KEY');

  // `static`: repositories are created per view model, so an instance field
  // would be thrown away every time the route view closes.
  static final _cache = RouteCache(maxPoints: 20000);
  final _saved = SavedRouteRepository();
  final _connectivity = ConnectivityRepository.instance;

  /// The stops' coordinates joined in order: same stops and mode give the
  /// same route, whichever plan they belong to.
  static String _stopsKey(List<LatLng> stops) =>
      stops.map((p) => '${p.latitude},${p.longitude}').join('|');

  /// LRU → saved file → network (8 s, decoded in an isolate) → `null`
  /// (the view draws straight lines). `saved` tells the view whether the
  /// route came from the phone instead of the network.
  Future<({PlanRoute route, bool saved})?> route(
    String planId,
    List<LatLng> stops,
    TravelMode mode,
  ) async {
    if (stops.length < 2) return null;
    final stopsKey = _stopsKey(stops);
    final key = '$stopsKey|${mode.name}';

    final cached = _cache.get(key);
    if (cached != null) return (route: cached, saved: true);

    final fromFile = await _saved.load(planId, mode, stopsKey);
    if (fromFile != null) {
      _cache.put(key, fromFile);
      return (route: fromFile, saved: true);
    }

    try {
      _connectivity.ensureOnline();
      final body = await _fetch(
        stopsKey,
        mode,
      ).timeout(const Duration(seconds: 8));
      final route = await _decodeInIsolate(body);
      if (route == null) return null;
      _cache.put(key, route);
      await _saved.save(planId, mode, stopsKey, route);
      return (route: route, saved: false);
    } catch (_) {
      return null;
    }
  }

  Future<String> _fetch(String stopsKey, TravelMode mode) async {
    final uri = Uri.https('api.geoapify.com', '/v1/routing', {
      'waypoints': stopsKey,
      'mode': mode.name,
      'apiKey': _apiKey,
    });
    final response = await (await _client.getUrl(uri)).close();
    if (response.statusCode != 200) {
      throw HttpException('Routing failed (${response.statusCode})');
    }
    return response.transform(utf8.decoder).join();
  }
}
