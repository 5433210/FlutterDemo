import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/logger.dart';

/// Widget that displays an image with support for zooming
class ImageViewer extends StatelessWidget {
  final String imagePath;
  final int index;
  final VoidCallback onRetry;

  const ImageViewer({
    super.key,
    required this.imagePath,
    required this.index,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // 确保文件存在
    final file = File(imagePath);
    if (!file.existsSync()) {
      return _buildMissingFileError();
    }

    // 如果文件存在，显示图片查看器
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        child: Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            AppLogger.error(
              '图片显示失败',
              tag: 'ImageViewer',
              error: error,
              stackTrace: stackTrace,
              data: {'path': imagePath},
            );
            return _buildLoadError(error);
          },
        ),
      ),
    );
  }

  Widget _buildLoadError(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text('无法加载图片: $error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingFileError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, size: 48, color: Colors.orange),
          const SizedBox(height: 8),
          Text('图片文件不存在: ${imagePath.split('/').last}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
