import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/work/work_entity.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../providers/work_detail_provider.dart';
import '../../../providers/work_image_editor_provider.dart';
import '../../../widgets/common/base_image_preview.dart';

class WorkImageEditor extends ConsumerWidget {
  final WorkEntity work;

  const WorkImageEditor({
    super.key,
    required this.work,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(workImageEditorProvider(work));
    final selectedIndex = ref.watch(selectedImageIndexProvider);
    final scrollController = ScrollController();
    final theme = Theme.of(context);

    return Column(
      children: [
        // Main image preview area
        Expanded(
          child: BaseImagePreview(
            imagePaths: images.map((img) => img.path).toList(),
            initialIndex: selectedIndex,
            onIndexChanged: (index) {
              ref.read(selectedImageIndexProvider.notifier).state = index;
            },
            padding: const EdgeInsets.all(16),
            previewDecoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),

        // Thumbnail list with drag-drop reordering
        if (images.isNotEmpty)
          Container(
            height: 120,
            margin: const EdgeInsets.all(8),
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  // Convert vertical scroll to horizontal
                  scrollController.jumpTo(
                    (scrollController.offset + pointerSignal.scrollDelta.dy)
                        .clamp(0, scrollController.position.maxScrollExtent),
                  );
                }
              },
              child: ReorderableListView(
                scrollController: scrollController,
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                physics: const BouncingScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  AppLogger.debug('重排序图片', tag: 'WorkImageEditor', data: {
                    'oldIndex': oldIndex,
                    'newIndex': newIndex,
                  });

                  ref
                      .read(workImageEditorProvider(work).notifier)
                      .reorderImages(oldIndex, newIndex);

                  // 标记作品已修改
                  ref.read(workDetailProvider.notifier).markAsChanged();
                },
                footer: IconButton(
                  onPressed: () => _handleAddImage(context, ref),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(80, 0),
                    padding: EdgeInsets.zero,
                  ),
                  icon: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(child: Icon(Icons.add_photo_alternate)),
                  ),
                ),
                children: List.generate(images.length, (index) {
                  final image = images[index];
                  return Stack(
                    key: ValueKey(image.id),
                    children: [
                      // Thumbnail container with drag handle
                      ReorderableDragStartListener(
                        index: index,
                        child: GestureDetector(
                          onTap: () {
                            ref
                                .read(selectedImageIndexProvider.notifier)
                                .state = index;
                          },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedIndex == index
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                                width: selectedIndex == index ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Stack(
                              children: [
                                // Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: Image.file(
                                    File(image.path),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // Index label
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Delete button - only shown if more than one image
                      if (images.length > 1)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(4),
                            ),
                            onPressed: () => _handleDeleteImage(ref, image.id),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleAddImage(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          AppLogger.debug('添加新图片', tag: 'WorkImageEditor', data: {
            'filePath': filePath,
          });

          await ref
              .read(workImageEditorProvider(work).notifier)
              .addImage(File(filePath));

          // 标记作品已修改
          ref.read(workDetailProvider.notifier).markAsChanged();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加图片失败：$e')),
        );
      }
    }
  }

  void _handleDeleteImage(WidgetRef ref, String imageId) {
    AppLogger.debug('删除图片', tag: 'WorkImageEditor', data: {
      'imageId': imageId,
    });

    ref.read(workImageEditorProvider(work).notifier).deleteImage(imageId);
    // 标记作品已修改
    ref.read(workDetailProvider.notifier).markAsChanged();
  }
}
