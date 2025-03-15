import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/work/work_entity.dart';
import '../../../../theme/app_sizes.dart';
import '../../../providers/work_image_editor_provider.dart' as editor;
import 'thumbnail_strip.dart';

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
  PageController? _pageController;

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
                                SnackBar(content: Text('添加图片失败: $e')),
                              );
                            }
                          }
                        },
                  tooltip: '添加图片',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: editorState.isProcessing ||
                          editorState.images.isEmpty
                      ? null
                      : () async {
                          if (selectedIndex < editorState.images.length) {
                            final imageToDelete =
                                editorState.images[selectedIndex];
                            try {
                              await ref
                                  .read(editor.workImageEditorProvider.notifier)
                                  .deleteImage(imageToDelete.id);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('删除图片失败: $e')),
                                );
                              }
                            }
                          }
                        },
                  tooltip: '删除当前图片',
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
                      itemCount: editorState.images.length,
                      onPageChanged: (index) {
                        ref
                            .read(editor.currentWorkImageIndexProvider.notifier)
                            .state = index;
                      },
                      itemBuilder: (context, index) {
                        final image = editorState.images[index];
                        return Image.file(
                          File(image.path),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) {
                            return const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.broken_image,
                                      size: 64, color: Colors.red),
                                  SizedBox(height: 16),
                                  Text('图片加载失败',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            );
                          },
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
              child: ThumbnailStrip(
                images: editorState.images,
                selectedIndex: selectedIndex,
                isEditable: !editorState.isProcessing,
                onTap: (index) {
                  ref
                      .read(editor.currentWorkImageIndexProvider.notifier)
                      .state = index;
                  _pageController?.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                onReorder: editorState.isProcessing
                    ? null
                    : (oldIndex, newIndex) {
                        ref
                            .read(editor.workImageEditorProvider.notifier)
                            .reorderImages(oldIndex, newIndex);
                        _pageController?.jumpToPage(newIndex);
                      },
              ),
            ),

          // Processing indicator
          if (editorState.isProcessing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize images when component mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(editor.workImageEditorProvider.notifier)
          .initialize(widget.work.images);
      _initPageController();
    });
  }

  void _initPageController() {
    final currentIndex = ref.read(editor.currentWorkImageIndexProvider);
    _pageController = PageController(initialPage: currentIndex);
  }
}
