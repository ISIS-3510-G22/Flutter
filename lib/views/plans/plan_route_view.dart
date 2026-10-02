import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:plansync/data/route_repository.dart';
import 'package:plansync/models/activity.dart';
import 'package:plansync/models/plan.dart';
import 'package:plansync/viewmodels/plans/plan_route_viewmodel.dart';
import 'package:plansync/views/activities/activity_detail_view.dart';
import 'package:plansync/views/widgets/circle_back_button.dart';
import 'package:provider/provider.dart';

const _geoapifyKey = String.fromEnvironment('GEOAPIFY_KEY');

class PlanRouteView extends StatelessWidget {
  const PlanRouteView({
    required this.plan,
    required this.activities,
    super.key,
  });

  final Plan plan;
  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlanRouteViewModel(plan, activities),
      child: const _PlanRouteBody(),
    );
  }
}

class _PlanRouteBody extends StatelessWidget {
  const _PlanRouteBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlanRouteViewModel>();

    Widget content;
    if (vm.stops.isEmpty) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'None of the activities in this plan has a location yet. '
            'Edit them and pick the address from the suggestions.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      content = _RouteMap(vm: vm);
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: content),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _TopBar(vm: vm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.vm});

  final PlanRouteViewModel vm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        const CircleBackButton(tooltip: 'Back to plan'),
        const SizedBox(width: 8),
        Expanded(
          child: Material(
            color: colors.surface,
            elevation: 2,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                vm.plan.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.vm});

  final PlanRouteViewModel vm;

  // Space covered by the top bar and the summary card.
  static const _topOverlay = 72.0;
  static const _bottomOverlay = 230.0;

  CameraFit _fit(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    final padding = EdgeInsets.fromLTRB(
      40,
      safe.top + _topOverlay,
      40,
      safe.bottom + _bottomOverlay,
    );
    if (vm.stops.length == 1) {
      return CameraFit.coordinates(
        coordinates: vm.stopPoints,
        padding: padding,
        maxZoom: 16,
      );
    }
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(vm.stopPoints),
      padding: padding,
      maxZoom: 17,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(initialCameraFit: _fit(context)),
          children: [
            TileLayer(
              urlTemplate:
                  'https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey={apiKey}',
              additionalOptions: const {'apiKey': _geoapifyKey},
              userAgentPackageName: 'com.example.plansync',
            ),
            if (vm.stops.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: vm.linePoints,
                    strokeWidth: 5,
                    color: colors.primary,
                    pattern: vm.usingStraightLines
                        ? StrokePattern.dashed(segments: const [12, 8])
                        : const StrokePattern.solid(),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final stop in vm.stops)
                  Marker(
                    point: stop.point,
                    width: 36,
                    height: 36,
                    child: _StopMarker(
                      number: stop.number,
                      onTap: () => _openActivity(context, stop.activity),
                    ),
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
          child: SafeArea(top: false, child: _RouteSummary(vm: vm)),
        ),
      ],
    );
  }
}

void _openActivity(BuildContext context, Activity activity) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          ActivityDetailView(activity: activity, showAddToPlan: false),
    ),
  );
}

class _StopMarker extends StatelessWidget {
  const _StopMarker({required this.number, required this.onTap});

  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              color: colors.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.vm});

  final PlanRouteViewModel vm;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

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
          if (vm.stops.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _RouteTotals(vm: vm)),
                  SegmentedButton<TravelMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: TravelMode.walk,
                        icon: Icon(Icons.directions_walk),
                      ),
                      ButtonSegment(
                        value: TravelMode.drive,
                        icon: Icon(Icons.directions_car),
                      ),
                    ],
                    selected: {vm.mode},
                    onSelectionChanged: (s) => vm.selectMode(s.first),
                  ),
                ],
              ),
            ),
          if (vm.missingLocation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                '${vm.missingLocation.length} '
                '${vm.missingLocation.length == 1 ? 'activity has' : 'activities have'} '
                'no location and ${vm.missingLocation.length == 1 ? 'is' : 'are'} '
                'not on the map.',
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: vm.stops.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final stop = vm.stops[i];
                return ActionChip(
                  avatar: CircleAvatar(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    child: Text('${stop.number}'),
                  ),
                  label: Text(stop.activity.name),
                  onPressed: () => _openActivity(context, stop.activity),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteTotals extends StatelessWidget {
  const _RouteTotals({required this.vm});

  final PlanRouteViewModel vm;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final route = vm.route;

    if (vm.isLoading) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (route == null) {
      return Text(
        'Route unavailable, showing straight lines',
        style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatDuration(route.timeSeconds),
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          formatRouteDistance(route.distanceMeters),
          style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

String formatDuration(double seconds) {
  final minutes = (seconds / 60).round();
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return '$hours h';
  return '$hours h $rest min';
}

String formatRouteDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}
