import 'package:flutter/material.dart';
import 'package:plansync/models/plan.dart';

class ExploreRepository {
  Future<List<Plan>> getPlans() async {
    await Future.delayed(const Duration(milliseconds: 800));

    return [
      Plan(
        id: 'p1',
        name: 'Downtown Art Walk & Cafe Crawl',
        date: DateTime(2025, 11, 8),
        meetupTime: const TimeOfDay(hour: 11, minute: 0),
        creatorId: 'u1',
        tags: const ['Food & Drink'],
        activityIds: const ['a1', 'a2', 'a3'],
      ),
      Plan(
        id: 'p2',
        name: 'Sunset Hike & Picnic',
        date: DateTime(2025, 11, 15),
        meetupTime: const TimeOfDay(hour: 16, minute: 0),
        creatorId: 'u1',
        tags: const ['Outdoors'],
        activityIds: const ['a4', 'a5'],
      ),
      Plan(
        id: 'p3',
        name: 'Weekend Getaway to the Coast',
        date: DateTime(2025, 11, 22),
        meetupTime: const TimeOfDay(hour: 9, minute: 0),
        creatorId: 'u1',
        tags: const ['Weekend Getaways'],
        activityIds: const ['a6', 'a7', 'a8', 'a9', 'a10'],
      ),
      Plan(
        id: 'p4',
        name: 'Solo Museum Afternoon',
        date: DateTime(2025, 11, 29),
        meetupTime: const TimeOfDay(hour: 13, minute: 0),
        creatorId: 'u1',
        tags: const ['Culture'],
        activityIds: const ['a11'],
      ),
    ];
  }
}
