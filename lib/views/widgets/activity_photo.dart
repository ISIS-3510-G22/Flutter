import 'package:flutter/material.dart';

class ActivityPhoto extends StatelessWidget {
  const ActivityPhoto({
    this.url,
    this.width,
    required this.height,
    this.radius = 12,
    super.key,
  });

  final String? url;
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Image.asset(
      'assets/images/activity_placeholder.png',
      width: width ?? double.infinity,
      height: height,
      fit: BoxFit.cover,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null
          ? placeholder
          : Image.network(
              url!,
              width: width ?? double.infinity,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}
