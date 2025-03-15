import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/work/work_entity.dart';
import '../../../../domain/models/work/work_image.dart';
import '../../../../theme/app_sizes.dart';
import '../../../providers/work_image_editor_provider.dart' as editor;
import 'thumbnail_strip.dart';

/// 作品图片管理视图
class WorkImagesManagementView extends ConsumerStatefulWidget {
  final WorkEntity work;

  const WorkImagesManagementView({
    super.key,
    required this.work,
  });

  @override
  ConsumerState<WorkImagesManagementView> createState() =>
      _WorkImagesManagementViewState();
}

class _WorkImagesManagementViewState
    extends ConsumerState<WorkImagesManagementView> {
  static const double _minScale = 0.5;
  static const double _maxScale = 4.0;
  PageController? _pageController;
  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editorState = ref.watch(editor.workImageEditorProvider);
    final selectedIndex = ref.watch(editor.currentWorkImageIndexProvider);

    return Container(
      padding: const EdgeInsets.all(AppSizes.m),
      child: Column(
        children: [
          // Tools bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate),
                  onPressed: editorState.isProcessing
                      ? null
                      : () async {
                          try {
                            await ref
                                .read(editor.workImageEditorProvider.notifier)
                                .addImage();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('添加图片失败: $e'),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                  tooltip: '添加图片',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: editorState.isProcessing ||
                          editorState.images.isEmpty ||
                          selectedIndex >= editorState.images.length
                      ? null
                      : () async {
                          try {
                            final imageToDelete =
                                editorState.images[selectedIndex];
                            await ref
                                .read(editor.workImageEditorProvider.notifier)
                                .deleteImage(imageToDelete.id);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('删除图片失败: $e'),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                  tooltip: '删除当前图片',
                ),
                if (_isZoomed)
                  IconButton(
                    icon: const Icon(Icons.zoom_out_map),
                    onPressed: _resetZoom,
                    tooltip: '重置缩放',
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Image preview
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(4),
              ),
              child: editorState.images.isEmpty
                  ? const Center(
                      child: Text('暂无图片，点击上方"添加"按钮添加图片'),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      physics: _isZoomed
                          ? const NeverScrollableScrollPhysics()
                          : null,
                      itemCount: editorState.images.length,
                      onPageChanged: (index) {
                        ref
                            .read(editor.currentWorkImageIndexProvider.notifier)
                            .state = index;
                      },
                      itemBuilder: (context, index) {
                        final image = editorState.images[index];
                        final imagePath = image.originalPath.isNotEmpty
                            ? image.originalPath
                            : image.path;

                        return InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: _minScale,
                          maxScale: _maxScale,
                          onInteractionStart: (details) {
                            if (details.pointerCount > 1) {
                              setState(() => _isZoomed = true);
                            }
                          },
                          onInteractionEnd: (details) {
                            // 检查是否恢复到原始大小
                            final matrix = _transformationController.value;
                            if (matrix == Matrix4.identity()) {
                              setState(() => _isZoomed = false);
                            }
                          },
                          child: Center(
                            child: Image.file(
                              File(imagePath),
                              fit: BoxFit.contain,
                              frameBuilder: (context, child, frame,
                                  wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded) return child;
                                return AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: frame != null
                                      ? child
                                      : Container(
                                          color: theme.colorScheme
                                              .surfaceContainerHighest,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                        ),
                                );
                              },
                              errorBuilder: (context, error, stack) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.broken_image,
                                          size: 64,
                                          color: theme.colorScheme.error),
                                      const SizedBox(height: 16),
                                      Text(
                                        '图片加载失败',
                                        style: TextStyle(
                                            color: theme.colorScheme.error),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          const SizedBox(height: 8),

          // Error message
          if (editorState.error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                editorState.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),

          // Thumbnail strip
          if (editorState.images.isNotEmpty)
            SizedBox(
              height: 100,
              child: ThumbnailStrip<WorkImage>(
                images: editorState.images,
                selectedIndex: selectedIndex,
                isEditable: !editorState.isProcessing,
                useOriginalImage: true,
                onTap: _handleThumbnailTap,
                pathResolver: (image) => image.originalPath.isNotEmpty
                    ? image.originalPath
                    : image.path,
                keyResolver: (image) => image.id,
                onReorder: editorState.isProcessing
                    ? null
                    : (oldIndex, newIndex) {
                        // 重置缩放
                        _resetZoom();

                        // 处理索引
                        if (oldIndex < newIndex) newIndex--;

                        // 更新状态
                        ref
                            .read(editor.workImageEditorProvider.notifier)
                            .reorderImages(oldIndex, newIndex);

                        // 更新选中项
                        _updateSelectedIndex(newIndex);

                        // 平滑切换预览
                        _pageController?.animateToPage(
                          newIndex,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
              ),
            ),

          // Processing indicator
          if (editorState.isProcessing)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LinearProgressIndicator(),
                  if (editorState.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        editorState.error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(editor.workImageEditorProvider.notifier)
          .initialize(widget.work.images);
      _initPageController();
    });
  }

  // 处理缩略图点击
  void _handleThumbnailTap(int index) {
    _resetZoom();
    _updateSelectedIndex(index);
    _pageController?.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _initPageController() {
    final currentIndex = ref.read(editor.currentWorkImageIndexProvider);
    _pageController = PageController(initialPage: currentIndex);
  }

  // 重置缩放
  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _isZoomed = false);
  }

  // 更新选中索引
  void _updateSelectedIndex(int index) {
    ref.read(editor.currentWorkImageIndexProvider.notifier).state = index;
  }
}
