import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/work/work_entity.dart';
import '../../../widgets/common/image_preview.dart';

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

    // 获取图片路径列表
    final imagePaths = validImages.map((img) => img.path).toList();

    return Stack(
      children: [
        // 图片预览
        ImagePreview(
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
      ],
    );
  }
}
