import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/logger.dart';
import '../../../../utils/path_helper.dart';

/// Widget that displays thumbnails for all images in a work
class ThumbnailStrip extends StatefulWidget {
  final String workId;
  final int imageCount;
  final int currentIndex;
  final Function(int) onThumbnailTap;

  const ThumbnailStrip({
    super.key,
    required this.workId,
    required this.imageCount,
    required this.currentIndex,
    required this.onThumbnailTap,
  });

  @override
  State<ThumbnailStrip> createState() => _ThumbnailStripState();
}

class _ThumbnailStripState extends State<ThumbnailStrip> {
  // Cache thumbnail futures to prevent rebuilds
  final Map<int, Future<String?>> _thumbnailPathFutures = {};

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.imageCount,
        itemBuilder: (context, index) {
          return _buildThumbnail(index);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Pre-fetch thumbnail paths
    for (int i = 0; i < widget.imageCount; i++) {
      _getThumbnailPathFuture(i);
    }
  }

  Widget _buildThumbnail(int index) {
    return GestureDetector(
      onTap: () => widget.onThumbnailTap(index),
      child: Container(
        margin: const EdgeInsets.all(4),
        width: 100,
        decoration: BoxDecoration(
          border: Border.all(
            color:
                widget.currentIndex == index ? Colors.blue : Colors.grey[300]!,
            width: widget.currentIndex == index ? 3 : 1,
          ),
        ),
        child: FutureBuilder<String?>(
          future: _getThumbnailPathFuture(index),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: Icon(Icons.image_not_supported),
              );
            }

            final file = File(snapshot.data!);
            if (!file.existsSync()) {
              return const Center(
                child: Icon(Icons.broken_image),
              );
            }

            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.broken_image),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<String?> _getThumbnailPath(int index) async {
    try {
      final path = await PathHelper.getWorkThumbnailPath(widget.workId, index);

      // Ensure directory exists if needed
      if (path != null) {
        final dir = Directory(path).parent;
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }

      return path;
    } catch (e, stack) {
      AppLogger.error(
        '获取缩略图路径失败',
        tag: 'ThumbnailStrip',
        error: e,
        stackTrace: stack,
        data: {'workId': widget.workId, 'index': index},
      );
      return null;
    }
  }

  // Get cached future for thumbnail path or create new one
  Future<String?> _getThumbnailPathFuture(int index) {
    return _thumbnailPathFutures[index] ??= _getThumbnailPath(index);
  }
}
