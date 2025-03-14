import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/work/work_entity.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../providers/work_image_editor_provider.dart';
import '../../../widgets/common/base_image_preview.dart';

class WorkImagePreview extends ConsumerWidget {
  final WorkEntity work;
  final bool isEditing;
  final bool fullscreen;

  const WorkImagePreview({
    super.key,
    required this.work,
    this.isEditing = false,
    this.fullscreen = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedImageIndexProvider);
    final images = isEditing
        ? ref.watch(workImageEditorProvider(work))
        : work.images.where((img) => img.path.isNotEmpty).toList();
    final scrollController = ScrollController();

    AppLogger.debug('WorkImagePreview build', tag: 'WorkImagePreview', data: {
      'workId': work.id,
      'totalImages': work.images.length,
      'validImages': images.length,
      'imagePaths': images.map((img) => img.path).toList(),
    });

    final imagePaths = images.map((img) => img.path).toList();

    return Column(
      children: [
        // 主图片预览区域
        Expanded(
          child: BaseImagePreview(
            imagePaths: imagePaths,
            initialIndex: selectedIndex,
            onIndexChanged: (index) {
              ref.read(selectedImageIndexProvider.notifier).state = index;
            },
            padding: const EdgeInsets.all(16),
            previewDecoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),

        // 缩略图列表
        if (imagePaths.length > 1)
          Container(
            height: 100,
            margin: const EdgeInsets.all(8),
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  // 将垂直滚动转换为水平滚动
                  scrollController.jumpTo(
                    (scrollController.offset + pointerSignal.scrollDelta.dy)
                        .clamp(0, scrollController.position.maxScrollExtent),
                  );
                }
              },
              child: ListView.builder(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(8),
                itemCount: imagePaths.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      ref.read(selectedImageIndexProvider.notifier).state =
                          index;
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedIndex == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
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
                              File(imagePaths[index]),
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
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
