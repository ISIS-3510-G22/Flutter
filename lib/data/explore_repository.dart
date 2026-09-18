import 'package:plansync/models/plan.dart';

class ExploreRepository {
  Future<List<Plan>> getPlans() async {
    await Future.delayed(const Duration(milliseconds: 800));

    return const [
      Plan(
        id: 'p1',
        title: 'Downtown Art Walk & Cafe Crawl',
        date: 'Nov 8, 2025',
        estimatedCostPerPerson: 45,
        participants: [],
        activityCount: 3,
        rating: 4.8,
        category: 'Food & Drink',
        planType: 'Group',
      ),
      Plan(
        id: 'p2',
        title: 'Sunset Hike & Picnic',
        date: 'Nov 15, 2025',
        estimatedCostPerPerson: 15,
        participants: [],
        activityCount: 2,
        rating: 4.5,
        category: 'Outdoors',
        planType: 'Couple',
      ),
      Plan(
        id: 'p3',
        title: 'Weekend Getaway to the Coast',
        date: 'Nov 22, 2025',
        estimatedCostPerPerson: 120,
        participants: [],
        activityCount: 5,
        rating: 4.9,
        category: 'Weekend Getaways',
        planType: 'Family',
      ),
      Plan(
        id: 'p4',
        title: 'Solo Museum Afternoon',
        date: 'Nov 29, 2025',
        estimatedCostPerPerson: 0,
        participants: [],
        activityCount: 1,
        rating: 4.2,
        category: 'Culture',
        planType: 'Solo',
      ),
    ];
  }
}
