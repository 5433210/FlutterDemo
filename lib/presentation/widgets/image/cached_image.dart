import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../skeleton_loader.dart';

class CachedImage extends ConsumerWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;

  const CachedImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageService = ref.watch(storageServiceProvider);

    return FutureBuilder<bool>(
      future: storageService.fileExists(path),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return SkeletonLoader(
            width: width ?? 200,
            height: height ?? 200,
            borderRadius: borderRadius,
          );
        }

        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: Image.file(
            File(path),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return SkeletonLoader(
                width: width ?? 200,
                height: height ?? 200,
                borderRadius: borderRadius,
              );
            },
          ),
        );
      },
    );
  }
}
