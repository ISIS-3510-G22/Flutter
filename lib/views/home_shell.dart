import 'package:flutter/material.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/services/notification_service.dart';
import 'package:plansync/views/activities/my_activities_view.dart';
import 'package:plansync/views/crew/my_crew_view.dart';
import 'package:plansync/viewmodels/nearby_friends_viewmodel.dart';
import 'package:plansync/views/explore/explore_view.dart';
import 'package:plansync/views/plans/plan_view.dart';
import 'package:plansync/views/profile/my_profile_view.dart';
import 'package:provider/provider.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.notificationService});

  final NotificationService notificationService;

  @override
  HomeShellState createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  void showExplore() {
    if (_selectedIndex == 0) return;
    setState(() => _selectedIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const ExploreView(),
      const PlanView(),
      const MyActivitiesView(),
      const MyCrewView(),
      const MyProfileView(),
    ];

    return ChangeNotifierProvider(
      create: (_) => NearbyFriendsViewModel(
        context.read<User>().id,
        widget.notificationService,
      ),
      child: Scaffold(
        body: SafeArea(child: tabs[_selectedIndex]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'My Plans',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: 'Activities',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'My Crew',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
