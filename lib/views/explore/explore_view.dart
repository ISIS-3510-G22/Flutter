import 'package:flutter/material.dart';
import 'package:plansync/data/explore_repository.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/utils/text_format.dart';
import 'package:plansync/viewmodels/explore_viewmodel.dart';
import 'package:plansync/views/activities/activity_card.dart';
import 'package:plansync/views/explore/nearby_map_view.dart';
import 'package:plansync/views/explore/public_plan_detail_view.dart';
import 'package:plansync/views/widgets/activity_photo.dart';
import 'package:plansync/views/widgets/view_header.dart';
import 'package:provider/provider.dart';

class ExploreView extends StatelessWidget {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExploreViewModel(context.read<User>().id)..load(),
      child: const _ExploreBody(),
    );
  }
}

class _ExploreBody extends StatelessWidget {
  const _ExploreBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExploreViewModel>();
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Row(
          children: [
            const Expanded(child: ViewHeader(title: 'Explore')),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.view_list_outlined),
                    label: Text('List'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.map_outlined),
                    label: Text('Map'),
                  ),
                ],
                selected: const {false},
                onSelectionChanged: (selection) {
                  if (!selection.first) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NearbyMapView()),
                  );
                },
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _SearchRow(
            controller: vm.searchController,
            onQueryChange: vm.onSearchQueryChange,
          ),
        ),
        if (vm.tagOptions.length > 1)
          _TagChipsRow(
            options: vm.tagOptions,
            selected: vm.selectedTag,
            onSelect: vm.onTagSelect,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _FilterGroupCard(
                      title: 'WHEN',
                      icon: Icons.calendar_today_outlined,
                      options: ExploreViewModel.whenOptions,
                      selected: vm.selectedWhen,
                      onSelect: vm.onWhenSelect,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FilterGroupCard(
                      title: 'PRICE',
                      icon: Icons.sell_outlined,
                      options: ExploreViewModel.priceOptions,
                      selected: vm.selectedPrice,
                      onSelect: vm.onPriceSelect,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _FilterGroupCard(
                title: 'RATING',
                icon: Icons.star_outline,
                options: ExploreViewModel.ratingOptions,
                selected: vm.selectedRating,
                onSelect: vm.onRatingSelect,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _DashedDivider(color: colors.primary),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Featured Plans',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (vm.isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (vm.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              vm.errorMessage!,
              style: TextStyle(color: colors.error),
            ),
          )
        else if (vm.filteredPlans.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'No plans match your filters.',
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          )
        else
          for (final item in vm.filteredPlans)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _FeaturedPlanCard(
                item: item,
                recommended: vm.isRecommended(item),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicPlanDetailView(plan: item.plan),
                  ),
                ),
              ),
            ),
        if (!vm.isLoading && vm.errorMessage == null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Activities',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (vm.filteredActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'No activities match your filters.',
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final activity in vm.filteredActivities)
              ActivityCard(activity: activity),
        ],
      ],
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.controller, required this.onQueryChange});

  final TextEditingController controller;
  final ValueChanged<String> onQueryChange;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onQueryChange,
            decoration: InputDecoration(
              hintText: 'Search plans or tags',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.tune, color: colors.onPrimary),
        ),
      ],
    );
  }
}

class _TagChipsRow extends StatelessWidget {
  const _TagChipsRow({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final option in options) ...[
            _SelectableChip(
              text: capitalize(option),
              selected: option == selected,
              onTap: () => onSelect(option),
              borderRadius: BorderRadius.circular(50),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterGroupCard extends StatelessWidget {
  const _FilterGroupCard({
    required this.title,
    required this.icon,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final IconData icon;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  List<List<String>> _chunked(List<String> items, int size) {
    return [
      for (var i = 0; i < items.length; i += size)
        items.skip(i).take(size).toList(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                title,
                style: text.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final row in _chunked(options, 2)) ...[
            Row(
              children: [
                for (final option in row) ...[
                  Expanded(
                    child: _SelectableChip(
                      text: option,
                      selected: option == selected,
                      onTap: () => onSelect(option),
                      borderRadius: BorderRadius.circular(10),
                      textStyle: text.labelSmall,
                      horizontalPadding: 6,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.text,
    required this.selected,
    required this.onTap,
    required this.borderRadius,
    this.textStyle,
    this.horizontalPadding = 12,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final TextStyle? textStyle;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = textStyle ?? Theme.of(context).textTheme.labelMedium;

    return Material(
      color: selected ? colors.primary : colors.surface,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: selected ? null : Border.all(color: colors.outline),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style?.copyWith(
              color: selected ? colors.onPrimary : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedLinePainter(color: color),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _FeaturedPlanCard extends StatelessWidget {
  const _FeaturedPlanCard({
    required this.item,
    required this.recommended,
    required this.onTap,
  });

  final ExplorePlan item;

  /// Recommended by the analytics pipeline for this user.
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: recommended ? colors.primary : colors.outline,
              width: recommended ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ActivityPhoto(
                          url: item.photoUrl,
                          height: 160,
                          radius: 0,
                        ),
                      ),
                      if (recommended)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: colors.onPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'For you',
                                  style: text.labelMedium?.copyWith(
                                    color: colors.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (item.rating != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  item.rating!.toStringAsFixed(1),
                                  style: text.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.plan.name,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.plan.activityIds.length} Activities   '
                      'Est. \$${item.totalCost.toStringAsFixed(0)}',
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
