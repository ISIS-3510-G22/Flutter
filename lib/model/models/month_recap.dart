import 'package:plansync/model/models/activity.dart';

typedef RecapPlace = ({Activity activity, int times});

class MonthRecap {
  final String month;
  final int plans;
  final int activities;
  final double spend;
  final List<String> topTags;
  final List<RecapPlace> places;
  final DateTime updatedAt;

  const MonthRecap({
    required this.month,
    required this.plans,
    required this.activities,
    required this.spend,
    required this.topTags,
    required this.places,
    required this.updatedAt,
  });
}
