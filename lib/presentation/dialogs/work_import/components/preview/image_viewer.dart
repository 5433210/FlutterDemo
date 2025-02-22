import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../theme/app_sizes.dart';

class ImageViewer extends StatelessWidget {
  final File image;
  final double rotation;
  final double scale;
  final VoidCallback onResetView;
  final ValueChanged<double> onScaleChanged;

  const ImageViewer({
    super.key,
    required this.image,
    required this.rotation,
    required this.scale,
    required this.onResetView,
    required this.onScaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          onInteractionUpdate: (details) {
            if (details.scale != 1.0) {
              //onScaleChanged(details.scale);
            }
          },
          child: Center(
            child: Transform.rotate(
              angle: rotation * (3.1415927 / 180.0),
              child: Image.file(
                image,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Positioned(
          right: AppSizes.m,
          bottom: AppSizes.m,
          child: FloatingActionButton.small(
            onPressed: onResetView,
            tooltip: '重置视图',
            child: const Icon(Icons.zoom_out_map),
          ),
        ),
      ],
    );
  }
}