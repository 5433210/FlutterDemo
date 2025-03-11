import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/work/work_entity.dart';
import '../../../widgets/common/base_image_preview.dart';

// 创建一个图片索引提供者
final selectedImageIndexProvider = StateProvider<int>((ref) => 0);

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
    final validImages =
        work.images.where((img) => img.path.isNotEmpty).toList();
    final imagePaths = validImages.map((img) => img.path).toList();

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
            padding: const EdgeInsets.all(8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: imagePaths.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    ref.read(selectedImageIndexProvider.notifier).state = index;
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Image.file(
                        File(imagePaths[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
