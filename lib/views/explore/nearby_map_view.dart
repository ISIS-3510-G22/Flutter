import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/services/location_service.dart';
import 'package:plansync/utils/text_format.dart';
import 'package:plansync/viewmodels/nearby_map_viewmodel.dart';
import 'package:plansync/views/activities/activity_detail_view.dart';
import 'package:plansync/views/explore/public_plan_detail_view.dart';
import 'package:plansync/views/widgets/circle_back_button.dart';
import 'package:provider/provider.dart';

const _geoapifyKey = String.fromEnvironment('GEOAPIFY_KEY');

class NearbyMapView extends StatelessWidget {
  const NearbyMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NearbyMapViewModel(context.read<User>().id),
      child: const _NearbyMapBody(),
    );
  }
}

class _NearbyMapBody extends StatelessWidget {
  const _NearbyMapBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NearbyMapViewModel>();

    Widget content;
    switch (vm.status) {
      case NearbyStatus.loading:
        content = const Center(child: CircularProgressIndicator());
      case NearbyStatus.locationError:
        content = _LocationErrorMessage(vm: vm);
      case NearbyStatus.error:
        content = _MessageWithAction(
          icon: Icons.cloud_off_outlined,
          message: 'Could not load what is near you.',
          actionLabel: 'Try again',
          onAction: vm.load,
        );
      case NearbyStatus.ready:
        content = _NearbyMap(vm: vm);
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: content),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _TopBar(vm: vm),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.vm});

  final NearbyMapViewModel vm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        const CircleBackButton(tooltip: 'Back to Explore'),
        const SizedBox(width: 8),
        Expanded(
          child: Material(
            color: colors.surface,
            elevation: 2,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Near you',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        if (vm.status == NearbyStatus.ready) ...[
          const SizedBox(width: 8),
          Material(
            color: colors.surface,
            elevation: 2,
            borderRadius: BorderRadius.circular(24),
            child: PopupMenuButton<double>(
              tooltip: 'Search radius',
              initialValue: vm.radiusKm,
              onSelected: vm.selectRadius,
              itemBuilder: (_) => [
                for (final km in NearbyMapViewModel.radiusOptions)
                  PopupMenuItem(value: km, child: Text('${km.toInt()} km')),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.radar, size: 18),
                    const SizedBox(width: 4),
                    Text('${vm.radiusKm.toInt()} km'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NearbyMap extends StatelessWidget {
  const _NearbyMap({required this.vm});

  final NearbyMapViewModel vm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final center = vm.position!;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 14),
          children: [
            TileLayer(
              urlTemplate:
                  'https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey={apiKey}',
              additionalOptions: const {'apiKey': _geoapifyKey},
              userAgentPackageName: 'com.example.plansync',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  radius: vm.radiusKm * 1000,
                  useRadiusInMeter: true,
                  color: colors.primary.withValues(alpha: 0.08),
                  borderColor: colors.primary.withValues(alpha: 0.5),
                  borderStrokeWidth: 1.5,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (final item in vm.items)
                  Marker(
                    point: item.point,
                    width: 44,
                    height: 44,
                    child: _ItemMarker(
                      item: item,
                      isRecommended: vm.recommendedIds.contains(item.id),
                      onTap: () => _openItem(context, item),
                    ),
                  ),
                Marker(
                  point: center,
                  width: 24,
                  height: 24,
                  child: const _UserMarker(),
                ),
              ],
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution('Powered by Geoapify'),
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(top: false, child: _RecommendationsSheet(vm: vm)),
        ),
      ],
    );
  }
}

void _openItem(BuildContext context, NearbyItem item) {
  final plan = item.plan;
  final activity = item.activity;
  Widget page;
  if (plan != null) {
    page = PublicPlanDetailView(plan: plan);
  } else {
    page = ActivityDetailView(activity: activity!);
  }
  Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
    );
  }
}

class _ItemMarker extends StatelessWidget {
  const _ItemMarker({
    required this.item,
    required this.isRecommended,
    required this.onTap,
  });

  final NearbyItem item;
  final bool isRecommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    var background = colors.surface;
    var foreground = colors.primary;
    if (item.isPlan) {
      background = colors.primary;
      foreground = colors.onPrimary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: Border.all(color: colors.primary, width: 2),
              boxShadow: const [
                BoxShadow(blurRadius: 4, color: Colors.black26),
              ],
            ),
            child: Center(
              child: Icon(
                item.isPlan ? Icons.event : Icons.place,
                size: 22,
                color: foreground,
              ),
            ),
          ),
          if (isRecommended)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecommendationsSheet extends StatelessWidget {
  const _RecommendationsSheet({required this.vm});

  final NearbyMapViewModel vm;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    var subtitle = 'Closest to you';
    if (vm.hasTasteProfile) {
      subtitle = 'Based on your past plans and activities';
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Recommended for you',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              subtitle,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),
          if (vm.recommended.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No public plans or activities within '
                '${vm.radiusKm.toInt()} km. Try a bigger radius.',
              ),
            )
          else
            SizedBox(
              height: 104,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: vm.recommended.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _RecommendationCard(
                  item: vm.recommended[i],
                  onTap: () => _openItem(context, vm.recommended[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item, required this.onTap});

  final NearbyItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    var reason = item.isPlan ? 'Public plan' : 'Activity';
    if (item.matchedTags.isNotEmpty) {
      reason =
          'You like ${item.matchedTags.take(2).map(capitalize).join(', ')}';
    }

    return SizedBox(
      width: 220,
      child: Card.outlined(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      item.isPlan ? Icons.event : Icons.place,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
                const Spacer(),
                Text(
                  _formatDistance(item.distanceKm),
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} m away';
  return '${km.toStringAsFixed(1)} km away';
}

class _LocationErrorMessage extends StatelessWidget {
  const _LocationErrorMessage({required this.vm});

  final NearbyMapViewModel vm;

  @override
  Widget build(BuildContext context) {
    var message = 'We need your location to show what is near you.';
    var actionLabel = 'Try again';
    VoidCallback action = vm.load;

    if (vm.locationError == LocationError.serviceDisabled) {
      message = 'Your location (GPS) is turned off.';
      actionLabel = 'Turn on location';
      action = vm.openSettings;
    } else if (vm.locationError == LocationError.permissionDeniedForever) {
      message = 'Location permission is blocked for PlanSync.';
      actionLabel = 'Open settings';
      action = vm.openSettings;
    }

    return _MessageWithAction(
      icon: Icons.location_off_outlined,
      message: message,
      actionLabel: actionLabel,
      onAction: action,
    );
  }
}

class _MessageWithAction extends StatelessWidget {
  const _MessageWithAction({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
