import 'package:flutter/material.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/model/services/notification_service.dart';
import 'package:plansync/viewmodels/crew/nearby_friends_viewmodel.dart';
import 'package:plansync/viewmodels/home/home_shell_viewmodel.dart';
import 'package:plansync/views/activities/my_activities_view.dart';
import 'package:plansync/views/crew/my_crew_view.dart';
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

  Widget _dot(BuildContext context, bool show, IconData icon) => Badge(
    isLabelVisible: show,
    backgroundColor: Theme.of(context).colorScheme.primary,
    child: Icon(icon),
  );

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const ExploreView(),
      const PlanView(),
      const MyActivitiesView(),
      const MyCrewView(),
      const MyProfileView(),
    ];

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => NearbyFriendsViewModel(
            context.read<User>().id,
            widget.notificationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeShellViewModel(context.read<User>().id),
        ),
      ],
      child: Scaffold(
        body: SafeArea(child: tabs[_selectedIndex]),
        bottomNavigationBar: Builder(
          builder: (context) {
            final vm = context.watch<HomeShellViewModel>();
            return NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'Explore',
                ),
                NavigationDestination(
                  icon: _dot(
                    context,
                    vm.hasPlanInvites,
                    Icons.calendar_today_outlined,
                  ),
                  selectedIcon: _dot(
                    context,
                    vm.hasPlanInvites,
                    Icons.calendar_today,
                  ),
                  label: 'My Plans',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.checklist_outlined),
                  selectedIcon: Icon(Icons.checklist),
                  label: 'Activities',
                ),
                NavigationDestination(
                  icon: _dot(
                    context,
                    vm.hasCrewRequests,
                    Icons.groups_outlined,
                  ),
                  selectedIcon: _dot(context, vm.hasCrewRequests, Icons.groups),
                  label: 'My Crew',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
