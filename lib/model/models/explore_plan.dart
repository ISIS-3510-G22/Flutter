import 'package:plansync/model/models/plan.dart';

class ExplorePlan {
  final Plan plan;
  final double totalCost;
  final double? rating;
  final String? photoUrl;

  const ExplorePlan({
    required this.plan,
    required this.totalCost,
    required this.rating,
    required this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
    'plan': plan.toJson(),
    'totalCost': totalCost,
    'rating': rating,
    'photoUrl': photoUrl,
  };

  factory ExplorePlan.fromJson(Map<String, dynamic> json) => ExplorePlan(
    plan: Plan.fromJson(json['plan'] as Map<String, dynamic>),
    totalCost: (json['totalCost'] as num).toDouble(),
    rating: (json['rating'] as num?)?.toDouble(),
    photoUrl: json['photoUrl'] as String?,
  );
}
