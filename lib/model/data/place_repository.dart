import 'dart:convert';
import 'dart:io';

import 'package:plansync/model/data/place_search_cache.dart';
import 'package:plansync/model/models/place.dart';

class PlaceRepository {
  final _client = HttpClient();
  static const _apiKey = String.fromEnvironment('GEOAPIFY_KEY');
  static final _cache = PlaceSearchCache();

  Future<List<Place>> _fetch(String query) async {
    final uri = Uri.https('api.geoapify.com', '/v1/geocode/autocomplete', {
      'text': query,
      'format': 'json',
      'limit': '5',
      'lang': 'es',
      'filter': 'countrycode:co',
      'bias': 'proximity:-74.06,4.65',
      'apiKey': _apiKey,
    });
    final response = await (await _client.getUrl(uri)).close();
    final json = jsonDecode(await response.transform(utf8.decoder).join());

    return [
      for (final r in json['results'] as List)
        Place(
          address: r['formatted'] as String,
          lat: (r['lat'] as num).toDouble(),
          lng: (r['lon'] as num).toDouble(),
        ),
    ];
  }

  Future<List<Place>> search(String query) async {
    final key = query.trim().toLowerCase();
    final cached = _cache.get(key);
    if (cached != null) return cached;
    final places = await _fetch(key).timeout(const Duration(seconds: 8));
    _cache.put(key, places);
    return places;
  }
}
