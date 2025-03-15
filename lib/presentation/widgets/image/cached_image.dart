import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/providers/storage_providers.dart';
import '../skeleton_loader.dart';

class CachedImage extends ConsumerWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final String? cacheKey;

  const CachedImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
    this.cacheKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(initializedStorageProvider);

    return FutureBuilder<bool>(
      // Add cache key to trigger rebuild when needed
      key: ValueKey('cached_image_${path}_${cacheKey ?? ''}'),
      future: _checkFile(storage),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return SkeletonLoader(
            width: width ?? 200,
            height: height ?? 200,
            borderRadius: borderRadius,
          );
        }

        return _buildImage();
      },
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        cacheWidth: width?.toInt(),
        cacheHeight: height?.toInt(),
        errorBuilder: (context, error, stackTrace) {
          return SkeletonLoader(
            width: width ?? 200,
            height: height ?? 200,
            borderRadius: borderRadius,
          );
        },
      ),
    );
  }

  Future<bool> _checkFile(storage) async {
    return await storage.fileExists(path);
  }
}
