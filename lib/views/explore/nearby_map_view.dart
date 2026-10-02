import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/services/location_service.dart';
import 'package:plansync/viewmodels/nearby_map_viewmodel.dart';
import 'package:plansync/views/activities/activity_detail_view.dart';
import 'package:plansync/views/explore/public_plan_detail_view.dart';
import 'package:plansync/views/widgets/circle_back_button.dart';
import 'package:provider/provider.dart';

const _geoapifyKey = String.fromEnvironment('GEOAPIFY_KEY');

// Plans recommended by the analytics pipeline stand out in gold.
const _recommendedColor = Color(0xFFF2A900);

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

class _NearbyMap extends StatefulWidget {
  const _NearbyMap({required this.vm});

  final NearbyMapViewModel vm;

  @override
  State<_NearbyMap> createState() => _NearbyMapState();
}

class _NearbyMapState extends State<_NearbyMap> {
  // Space covered by the top bar and the recommendations card, so the whole
  // search radius stays visible between them.
  static const _topOverlay = 72.0;
  static const _bottomOverlay = 220.0;

  final _mapController = MapController();
  var _mapReady = false;
  late double _fittedRadiusKm = widget.vm.radiusKm;

  @override
  void didUpdateWidget(covariant _NearbyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mapReady || widget.vm.radiusKm == _fittedRadiusKm) return;
    _fittedRadiusKm = widget.vm.radiusKm;
    _mapController.fitCamera(_radiusFit(context));
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  CameraFit _radiusFit(BuildContext context) {
    final center = widget.vm.position!;
    final meters = widget.vm.radiusKm * 1000;
    const distance = Distance();
    final safe = MediaQuery.paddingOf(context);
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints([
        distance.offset(center, meters, 0),
        distance.offset(center, meters, 90),
        distance.offset(center, meters, 180),
        distance.offset(center, meters, 270),
      ]),
      padding: EdgeInsets.fromLTRB(
        16,
        safe.top + _topOverlay,
        16,
        safe.bottom + _bottomOverlay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final colors = Theme.of(context).colorScheme;
    final center = vm.position!;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCameraFit: _radiusFit(context),
            onMapReady: () => _mapReady = true,
          ),
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
          child: SafeArea(top: false, child: _NearbyPlansSheet(vm: vm)),
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
  const _ItemMarker({required this.item, required this.onTap});

  final NearbyItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    var background = colors.surface;
    var foreground = colors.primary;
    var border = colors.primary;
    var icon = Icons.place;
    if (item.isRecommended) {
      background = _recommendedColor;
      foreground = Colors.white;
      border = Colors.white;
      icon = Icons.auto_awesome;
    } else if (item.isPlan) {
      background = colors.primary;
      foreground = colors.onPrimary;
      border = Colors.white;
      icon = Icons.event;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 2),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Center(child: Icon(icon, size: 22, color: foreground)),
      ),
    );
  }
}

class _NearbyPlansSheet extends StatelessWidget {
  const _NearbyPlansSheet({required this.vm});

  final NearbyMapViewModel vm;

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Plans near you',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              children: [
                const _LegendDot(color: _recommendedColor, label: 'For you'),
                _LegendDot(color: colors.primary, label: 'Plan'),
                _LegendDot(
                  color: colors.surface,
                  border: colors.primary,
                  label: 'Activity',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (vm.nearbyPlans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No public plans within ${vm.radiusKm.toInt()} km. '
                'Try a bigger radius.',
              ),
            )
          else
            SizedBox(
              height: 96,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: vm.nearbyPlans.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _NearbyPlanCard(
                  item: vm.nearbyPlans[i],
                  onTap: () => _openItem(context, vm.nearbyPlans[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, this.border});

  final Color color;
  final Color? border;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    var borderColor = color;
    if (border != null) borderColor = border!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: text.bodySmall),
      ],
    );
  }
}

class _NearbyPlanCard extends StatelessWidget {
  const _NearbyPlanCard({required this.item, required this.onTap});

  final NearbyItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    var borderColor = colors.outline;
    if (item.isRecommended) borderColor = _recommendedColor;

    return SizedBox(
      width: 220,
      child: Card.outlined(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: borderColor,
            width: item.isRecommended ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (item.isRecommended)
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: _recommendedColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Recommended for you',
                        style: text.bodySmall?.copyWith(
                          color: _recommendedColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
