import 'dart:io';

import 'package:demo/domain/value_objects/work/work_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final totalImages = widget.work.imageCount;

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

          // 底部控制栏
          if (totalImages > 0) _buildBottomControls(totalImages),
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
    final imagePath = _getImagePath();

    if (imagePath == null) {
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

    return InteractiveViewer(
      transformationController: _transformController,
      minScale: 0.5,
      maxScale: 4.0,
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

  void _changePage(int newIndex) {
    ref.read(currentWorkImageIndexProvider.notifier).state = newIndex;

    // 切换图片时重置缩放
    setState(() {
      _transformController.value = Matrix4.identity();
      _scale = 1.0;
    });
  }

  String? _getImagePath() {
    // 这里应该从作品对象中获取实际图片路径
    // 简化示例，实际应用中应该从已处理的图片或服务获取
    try {
      if (widget.work.images.isNotEmpty &&
          _currentImageIndex < widget.work.images.length) {
        final image = widget.work.images[_currentImageIndex];
        return image.imported?.path;
      }
    } catch (e) {
      AppLogger.error(
        'Error retrieving image path',
        tag: 'WorkImagePreview',
        error: e,
      );
    }
    return null;
  }
}
