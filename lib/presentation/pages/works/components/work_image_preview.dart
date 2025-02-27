import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/work.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../utils/path_helper.dart';
import '../../../widgets/common/loading_indicator.dart';
import 'image_error_view.dart';
import 'image_viewer.dart';
import 'thumbnail_strip.dart';

/// Main widget that shows a work's images with pagination and thumbnails
class WorkImagePreview extends ConsumerStatefulWidget {
  final Work work;

  const WorkImagePreview({
    super.key,
    required this.work,
  });

  @override
  ConsumerState<WorkImagePreview> createState() => _WorkImagePreviewState();
}

class _WorkImagePreviewState extends ConsumerState<WorkImagePreview> {
  int _currentIndex = 0;
  final Map<int, String?> _imagePaths = {};
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final imageCount = widget.work.imageCount ?? 0;

    if (imageCount == 0) {
      return const Center(
        child: Text('此作品没有图片'),
      );
    }

    if (_loading) {
      return const Center(
        child: LoadingIndicator(message: '加载图片中...'),
      );
    }

    if (_error != null) {
      return ImageErrorView(
        error: _error!,
        onRetry: _preloadCurrentImage,
      );
    }

    return Column(
      children: [
        // 主图片区域
        Expanded(
          child: PageView.builder(
            itemCount: imageCount,
            onPageChanged: _handlePageChanged,
            itemBuilder: (context, index) {
              final imagePath = _imagePaths[index];

              if (imagePath == null) {
                // 尝试加载图片 - 使用post-frame回调避免在build中触发setState
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _preloadImage(index);
                });

                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return ImageViewer(
                imagePath: imagePath,
                index: index,
                onRetry: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _preloadImage(index);
                  });
                },
              );
            },
          ),
        ),

        // 底部缩略图导航栏
        ThumbnailStrip(
          workId: widget.work.id ?? '',
          imageCount: imageCount,
          currentIndex: _currentIndex,
          onThumbnailTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _preloadCurrentImage();
  }

  // 确保作品目录结构存在
  Future<void> _ensureWorkDirectoryExists() async {
    try {
      if (widget.work.id == null) return;
      await PathHelper.ensureWorkDirectoryExists(widget.work.id!);
    } catch (e, stack) {
      AppLogger.error(
        '确保作品目录结构失败',
        tag: 'WorkImagePreview',
        error: e,
        stackTrace: stack,
        data: {'workId': widget.work.id},
      );
    }
  }

  void _handlePageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Load image if not already loaded
    if (!_imagePaths.containsKey(_currentIndex)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preloadImage(_currentIndex);
      });
    }
  }

  Future<void> _preloadCurrentImage() async {
    if (widget.work.id == null ||
        widget.work.imageCount == null ||
        widget.work.imageCount == 0) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _ensureWorkDirectoryExists();
      final path =
          await PathHelper.getWorkImagePath(widget.work.id!, _currentIndex);

      if (mounted) {
        setState(() {
          _imagePaths[_currentIndex] = path;
          _loading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error(
        '加载图片失败',
        tag: 'WorkImagePreview',
        error: e,
        stackTrace: stack,
        data: {'workId': widget.work.id},
      );

      if (mounted) {
        setState(() {
          _error = '无法加载图片: ${e.toString()}';
          _loading = false;
        });
      }
    }
  }

  Future<void> _preloadImage(int index) async {
    if (widget.work.id == null) return;

    try {
      await _ensureWorkDirectoryExists();
      final path = await PathHelper.getWorkImagePath(widget.work.id!, index);

      if (mounted) {
        setState(() {
          _imagePaths[index] = path;
        });
      }
    } catch (e, stack) {
      AppLogger.error(
        '预加载图片失败',
        tag: 'WorkImagePreview',
        error: e,
        stackTrace: stack,
        data: {'workId': widget.work.id, 'index': index},
      );
    }
  }
}
