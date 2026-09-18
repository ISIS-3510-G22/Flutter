import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plansync/models/plan.dart';
import 'package:plansync/viewmodels/explore_viewmodel.dart';

class ExploreView extends StatelessWidget {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExploreViewModel()..loadPlans(),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text('Explore', style: text.headlineMedium),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _SearchRow(
            controller: vm.searchController,
            onQueryChange: vm.onSearchQueryChange,
          ),
        ),
        _CategoryChipsRow(
          options: ExploreViewModel.categoryOptions,
          selected: vm.selectedCategory,
          onSelect: vm.onCategorySelect,
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
                      title: 'PLAN TYPE',
                      icon: Icons.groups_outlined,
                      options: ExploreViewModel.planTypeOptions,
                      selected: vm.selectedPlanType,
                      onSelect: vm.onPlanTypeSelect,
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
            child: Text(vm.errorMessage!, style: TextStyle(color: colors.error)),
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
          for (final plan in vm.filteredPlans)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _FeaturedPlanCard(plan: plan, onTap: () {}),
            ),
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
              hintText: 'Search plans or activities',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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

class _CategoryChipsRow extends StatelessWidget {
  const _CategoryChipsRow({required this.options, required this.selected, required this.onSelect});

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
              text: option,
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
  final String selected;
  final ValueChanged<String> onSelect;

  List<List<String>> _chunked(List<String> items, int size) {
    return [for (var i = 0; i < items.length; i += size) items.skip(i).take(size).toList()];
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
              Text(title, style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
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
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style?.copyWith(color: selected ? colors.onPrimary : colors.onSurface),
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
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
}

class _FeaturedPlanCard extends StatelessWidget {
  const _FeaturedPlanCard({required this.plan, required this.onTap});

  final Plan plan;
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
            border: Border.all(color: colors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  width: double.infinity,
                  height: 160,
                  color: colors.surfaceContainerHighest,
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(Icons.image_outlined, size: 40, color: colors.onSurfaceVariant),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 14, color: colors.primary),
                              const SizedBox(width: 2),
                              Text(
                                plan.rating.toString(),
                                style: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
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
                    Text(plan.title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${plan.activityCount} Activities   ${plan.priceTier}',
                      style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
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
