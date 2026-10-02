import 'package:flutter/material.dart';

class TabButton extends StatelessWidget {
  const TabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: selected ? colors.primary : Colors.transparent,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: Text(
        label,
        style: text.labelLarge?.copyWith(
          color: selected ? colors.onPrimary : colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class TabTrack extends StatelessWidget {
  const TabTrack({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [for (final child in children) Expanded(child: child)],
      ),
    );
  }
}
