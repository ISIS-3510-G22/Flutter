import 'package:flutter_test/flutter_test.dart';
import 'package:plansync/utils/recommendation.dart';

void main() {
  group('buildTagProfile', () {
    test('counts each tag once per item, case insensitive', () {
      final profile = buildTagProfile([
        ['Coffee', 'coffee', 'Outdoors'],
        ['coffee'],
      ]);
      expect(profile, {'coffee': 2, 'outdoors': 1});
    });
  });

  group('tagAffinity', () {
    final profile = buildTagProfile([
      ['coffee', 'food'],
      ['coffee'],
      ['museum'],
    ]);

    test('is 0 without shared tags', () {
      expect(tagAffinity(profile, ['hiking']), 0);
    });

    test('prefers the tags the user repeats most', () {
      final coffee = tagAffinity(profile, ['coffee']);
      final museum = tagAffinity(profile, ['museum']);
      expect(coffee, greaterThan(museum));
    });

    test('stays between 0 and 1', () {
      final value = tagAffinity(profile, ['coffee', 'food', 'museum']);
      expect(value, inInclusiveRange(0, 1));
    });

    test('is 0 for a new user without history', () {
      expect(tagAffinity({}, ['coffee']), 0);
    });
  });

  group('matchingTags', () {
    test('returns shared tags, most relevant first', () {
      final profile = {'coffee': 3.0, 'food': 1.0};
      expect(matchingTags(profile, ['Food', 'hiking', 'Coffee']), [
        'Coffee',
        'Food',
      ]);
    });
  });

  group('recommendationScore', () {
    test('closer places score higher with the same taste', () {
      final near = recommendationScore(
        affinity: 0.5,
        distanceKm: 0.5,
        radiusKm: 5,
      );
      final far = recommendationScore(
        affinity: 0.5,
        distanceKm: 4.5,
        radiusKm: 5,
      );
      expect(near, greaterThan(far));
    });

    test('taste weighs more than distance', () {
      final likedFar = recommendationScore(
        affinity: 1,
        distanceKm: 4,
        radiusKm: 5,
      );
      final unlikedNear = recommendationScore(
        affinity: 0,
        distanceKm: 0,
        radiusKm: 5,
      );
      expect(likedFar, greaterThan(unlikedNear));
    });

    test('sooner plans score higher', () {
      final soon = recommendationScore(
        affinity: 0.5,
        distanceKm: 1,
        radiusKm: 5,
        daysUntil: 1,
      );
      final later = recommendationScore(
        affinity: 0.5,
        distanceKm: 1,
        radiusKm: 5,
        daysUntil: 25,
      );
      expect(soon, greaterThan(later));
    });
  });
}
