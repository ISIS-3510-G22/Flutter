import 'dart:convert';
import 'dart:io';

import 'package:plansync/models/place.dart';

class PlaceRepository {
  final _client = HttpClient()..userAgent = 'PlanSync';

  Future<List<Place>> search(String query) async {
    final uri = Uri.https('photon.komoot.io', '/api/', {
      'q': query,
      'limit': '5',
      'lat': '4.65',
      'lon':
          '-74.06', // cuando el sensor de localizacion funcione se puede conectar aca para que se sugieran lugares cercanos al usuario, por ahora esta centrado en bogota.
    });
    final response = await (await _client.getUrl(uri)).close();
    final json = jsonDecode(await response.transform(utf8.decoder).join());

    return [
      for (final f in json['features'] as List)
        Place(
          address: [
            f['properties']['name'],
            f['properties']['street'],
            f['properties']['city'],
          ].whereType<String>().join(', '),
          lat: (f['geometry']['coordinates'][1] as num).toDouble(),
          lng: (f['geometry']['coordinates'][0] as num).toDouble(),
        ),
    ];
  }
}
