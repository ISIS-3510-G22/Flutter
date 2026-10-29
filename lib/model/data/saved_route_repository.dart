import 'dart:convert';

import 'package:plansync/model/data/local/json_file_store.dart';
import 'package:plansync/model/models/plan_route.dart';

/// Routes saved to `routes/<planId>_<mode>.json`, next to the stops they were
/// computed for. A file for other stops (the plan's activities changed) is
/// treated as not saved.
class SavedRouteRepository {
  final _files = JsonFileStore();

  String _file(String planId, TravelMode mode) =>
      'routes/${planId}_${mode.name}.json';

  Future<void> save(
    String planId,
    TravelMode mode,
    String stopsKey,
    PlanRoute route,
  ) => _files.write(
    _file(planId, mode),
    jsonEncode({'stopsKey': stopsKey, 'route': route.toJson()}),
  );

  Future<PlanRoute?> load(
    String planId,
    TravelMode mode,
    String stopsKey,
  ) async {
    final text = await _files.read(_file(planId, mode));
    if (text == null) return null;
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      if (json['stopsKey'] != stopsKey) return null;
      return PlanRoute.fromJson(json['route'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
