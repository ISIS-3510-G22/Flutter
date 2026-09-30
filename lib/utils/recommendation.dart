import 'dart:math';

/// Builds the user's taste profile: how often each tag shows up in what they
/// did, created or liked. Each list is the tags of one plan or activity.
Map<String, double> buildTagProfile(List<List<String>> tagLists) {
  final profile = <String, double>{};
  for (final tags in tagLists) {
    for (final tag in tags.map((t) => t.toLowerCase()).toSet()) {
      final current = profile[tag];
      if (current == null) {
        profile[tag] = 1;
      } else {
        profile[tag] = current + 1;
      }
    }
  }
  return profile;
}

/// Cosine similarity between the profile and a set of tags, from 0 to 1.
double tagAffinity(Map<String, double> profile, List<String> tags) {
  if (profile.isEmpty || tags.isEmpty) return 0;
  final normalized = tags.map((t) => t.toLowerCase()).toSet();

  var dot = 0.0;
  for (final tag in normalized) {
    final weight = profile[tag];
    if (weight != null) dot += weight;
  }
  if (dot == 0) return 0;

  var profileNorm = 0.0;
  for (final weight in profile.values) {
    profileNorm += weight * weight;
  }
  return dot / (sqrt(profileNorm) * sqrt(normalized.length));
}

/// Tags in [tags] that also appear in the profile, most relevant first.
List<String> matchingTags(Map<String, double> profile, List<String> tags) {
  final matches = tags.where((t) => profile.containsKey(t.toLowerCase()));
  final list = matches.toSet().toList();
  list.sort((a, b) {
    final wa = profile[a.toLowerCase()];
    final wb = profile[b.toLowerCase()];
    if (wa == null || wb == null) return 0;
    return wb.compareTo(wa);
  });
  return list;
}

/// Combines taste, distance and (for plans) how soon it happens into a
/// score from 0 to 1. [daysUntil] is null for activities, which have no date.
double recommendationScore({
  required double affinity,
  required double distanceKm,
  required double radiusKm,
  int? daysUntil,
}) {
  var closeness = 1 - distanceKm / radiusKm;
  if (closeness < 0) closeness = 0;

  if (daysUntil == null) {
    return 0.65 * affinity + 0.35 * closeness;
  }

  var soonness = 1 - daysUntil / 30;
  if (soonness < 0) soonness = 0;
  return 0.55 * affinity + 0.3 * closeness + 0.15 * soonness;
}
