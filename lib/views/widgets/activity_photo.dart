import 'dart:io';

import 'package:flutter/material.dart';

class ActivityPhoto extends StatelessWidget {
  const ActivityPhoto({
    this.url,
    this.file,
    this.width,
    required this.height,
    this.radius = 12,
    super.key,
  });

  final String? url;
  final String? file;
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

    final network = url == null
        ? placeholder
        : Image.network(
            url!,
            width: width ?? double.infinity,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => placeholder,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: file == null
          ? network
          : Image.file(
              File(file!),
              width: width ?? double.infinity,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => network,
            ),
    );
  }
}
