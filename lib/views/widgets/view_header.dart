import 'package:flutter/material.dart';

class ViewHeader extends StatelessWidget {
  const ViewHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}
