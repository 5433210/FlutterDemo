import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/value_objects/work/work_entity.dart';
import '../../../../domain/value_objects/work/work_image.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../theme/app_sizes.dart';
import '../../../providers/work_detail_provider.dart';

class WorkImagePreview extends ConsumerStatefulWidget {
  final WorkEntity work;

  const WorkImagePreview({
    super.key,
    required this.work,
  });

  @override
  ConsumerState<WorkImagePreview> createState() => _WorkImagePreviewState();
}

class _WorkImagePreviewState extends ConsumerState<WorkImagePreview> {
  double _scale = 1.0;
  final TransformationController _transformController =
      TransformationController();
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final imageCount = widget.work.images.length;

    // 监听当前图片索引
    _currentImageIndex = ref.watch(currentWorkImageIndexProvider);

    return Card(
      margin: const EdgeInsets.all(AppSizes.spacingMedium),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 图片预览区域
          Expanded(
            child: _buildImagePreview(),
          ),

          // 页面导航区 - 缩略图行
          if (imageCount > 0) _buildThumbnailStrip(imageCount),

          // 底部控制栏
          if (imageCount > 0) _buildBottomControls(imageCount),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _transformController.value = Matrix4.identity();
  }

  Widget _buildBottomControls(int totalImages) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // 缩放控制
          Text('缩放: ${(_scale * 100).toInt()}%'),
          const Spacer(),

          // 重置缩放按钮
          IconButton(
            icon: const Icon(Icons.center_focus_strong, size: 20),
            tooltip: '重置缩放',
            onPressed: _resetZoom,
          ),

          // 当前页码/总页数指示器
          Text('${_currentImageIndex + 1} / $totalImages'),
          const SizedBox(width: AppSizes.spacingMedium),

          // 翻页按钮
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: _currentImageIndex > 0
                ? () => _changePage(_currentImageIndex - 1)
                : null,
            tooltip: '上一页',
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: _currentImageIndex < totalImages - 1
                ? () => _changePage(_currentImageIndex + 1)
                : null,
            tooltip: '下一页',
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    final currentImage = _getCurrentImage();

    if (currentImage == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('没有可预览的图片', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 获取图片路径
    final imagePath =
        currentImage.imported?.path ?? currentImage.original?.path;
    if (imagePath == null) {
      return const Center(child: Text('图片路径无效'));
    }

    return InteractiveViewer(
      transformationController: _transformController,
      minScale: 0.5,
      maxScale: 4.0,
      // 确保支持鼠标拖拽平移
      panEnabled: true,
      boundaryMargin: const EdgeInsets.all(80),
      onInteractionEnd: (details) {
        setState(() {
          _scale = _transformController.value.getMaxScaleOnAxis();
        });
      },
      child: Center(
        child: Image.file(
          File(imagePath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            AppLogger.warning(
              'Failed to load image',
              tag: 'WorkImagePreview',
              error: error,
              data: {'path': imagePath},
            );
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('图片加载失败', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildThumbnailItem(int index) {
    final isSelected = index == _currentImageIndex;
    final image = widget.work.images[index];
    final thumbnailPath = image.thumbnail?.path ?? image.imported?.path;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => _changePage(index),
        child: Container(
          width: 60,
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  isSelected ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: thumbnailPath != null
                ? Image.file(
                    File(thumbnailPath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 24,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Text('${index + 1}',
                          style: theme.textTheme.bodySmall),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // 添加新的缩略图导航条
  Widget _buildThumbnailStrip(int totalImages) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: totalImages,
        itemBuilder: (context, index) => _buildThumbnailItem(index),
      ),
    );
  }

  void _changePage(int newIndex) {
    ref.read(currentWorkImageIndexProvider.notifier).state = newIndex;

    // 切换图片时重置缩放
    _resetZoom();
  }

  WorkImage? _getCurrentImage() {
    if (widget.work.images.isEmpty) {
      return null;
    }

    if (_currentImageIndex >= widget.work.images.length) {
      return widget.work.images[0];
    }

    return widget.work.images[_currentImageIndex];
  }

  void _resetZoom() {
    setState(() {
      _transformController.value = Matrix4.identity();
      _scale = 1.0;
    });
  }
}
