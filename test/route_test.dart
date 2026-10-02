import 'package:flutter_test/flutter_test.dart';
import 'package:plansync/data/route_repository.dart';
import 'package:plansync/views/plans/plan_route_view.dart';

void main() {
  group('parseGeoapifyRoute', () {
    test('reads a MultiLineString route as lat/lng points', () {
      final route = parseGeoapifyRoute({
        'features': [
          {
            'geometry': {
              'type': 'MultiLineString',
              'coordinates': [
                [
                  [-74.06, 4.65],
                  [-74.05, 4.66],
                ],
                [
                  [-74.05, 4.66],
                  [-74.04, 4.67],
                ],
              ],
            },
            'properties': {'distance': 2500, 'time': 1800.5},
          },
        ],
      })!;

      expect(route.points.length, 4);
      expect(route.points.first.latitude, 4.65);
      expect(route.points.first.longitude, -74.06);
      expect(route.distanceMeters, 2500);
      expect(route.timeSeconds, 1800.5);
    });

    test('also accepts a LineString', () {
      final route = parseGeoapifyRoute({
        'features': [
          {
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [-74.06, 4.65],
                [-74.05, 4.66],
              ],
            },
            'properties': {'distance': 800, 'time': 600},
          },
        ],
      })!;
      expect(route.points.length, 2);
    });

    test('returns null without features', () {
      expect(parseGeoapifyRoute({'features': []}), isNull);
    });
  });

  group('formatting', () {
    test('durations', () {
      expect(formatDuration(600), '10 min');
      expect(formatDuration(3600), '1 h');
      expect(formatDuration(5400), '1 h 30 min');
    });

    test('distances', () {
      expect(formatRouteDistance(850), '850 m');
      expect(formatRouteDistance(2500), '2.5 km');
    });
  });
}
