import 'package:flutter/material.dart';
import 'package:plansync/services/location_service.dart';
import 'package:plansync/viewmodels/nearby_friends_viewmodel.dart';
import 'package:plansync/views/plans/create_edit_plan_view.dart';
import 'package:plansync/views/widgets/crew_friends_card.dart';
import 'package:provider/provider.dart';

class NearbyFriendsView extends StatelessWidget {
  const NearbyFriendsView({super.key});

  @override
  Widget build(BuildContext context) => const _NearbyFriendsBody();
}

class _NearbyFriendsBody extends StatelessWidget {
  const _NearbyFriendsBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NearbyFriendsViewModel>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Friends nearby')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('See who’s around', style: text.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Share your location while PlanSync is open to find friends nearby. Friends must turn on sharing too. Sharing pauses when the app goes into the background.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: vm.isLoading
                      ? null
                      : vm.isSharing
                      ? vm.stopSharing
                      : vm.startSharing,
                  icon: Icon(
                    vm.isSharing ? Icons.location_off : Icons.my_location,
                  ),
                  label: Text(
                    vm.isLoading
                        ? 'Getting location…'
                        : vm.isSharing
                        ? 'Stop sharing location'
                        : 'Share my location',
                  ),
                ),
                if (vm.locationError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    vm.locationError == LocationError.serviceDisabled
                        ? 'Turn on GPS to share your location.'
                        : 'Location permission is needed to share your location.',
                  ),
                  TextButton(
                    onPressed: vm.openSettings,
                    child: Text(
                      vm.locationError == LocationError.serviceDisabled
                          ? 'Location settings'
                          : 'App settings',
                    ),
                  ),
                ],
                if (vm.error != null) ...[
                  const SizedBox(height: 8),
                  Text(vm.error!, style: TextStyle(color: colors.error)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('NEARBY FRIENDS', style: text.labelLarge),
          const SizedBox(height: 12),
          if (!vm.isSharing)
            const _EmptyMessage(
              text: 'Turn on sharing to see friends who are nearby.',
            )
          else if (vm.nearbyFriends.isEmpty)
            const _EmptyMessage(
              text: 'No friends nearby are sharing their location right now.',
            )
          else
            for (final nearby in vm.nearbyFriends) ...[
              CrewFriendsCard(
                name: '${nearby.user.name} ${nearby.user.lastName}'.trim(),
                email:
                    '@${nearby.user.username} · ${_formatDistance(nearby.distanceKm)}',
                initials:
                    '${nearby.user.name.isNotEmpty ? nearby.user.name[0] : ''}'
                    '${nearby.user.lastName.isNotEmpty ? nearby.user.lastName[0] : ''}',
                avatarColors: const Color(0xFFFFB5A6),
                photoUrl: nearby.user.photoUrl,
                trailing: IconButton(
                  tooltip: 'Make a plan',
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CreateEditPlanView(),
                      ),
                    ),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 8),
          Text(
            'Distances are approximate. Shares older than a few minutes are hidden.',
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double km) => km < 1
      ? '${(km * 1000).round()} m away'
      : '${km.toStringAsFixed(1)} km away';
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Text(text, textAlign: TextAlign.center),
  );
}
