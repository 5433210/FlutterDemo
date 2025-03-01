import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/value_objects/work/work_entity.dart';
import '../../../../theme/app_sizes.dart';
import 'work_image_preview.dart';

class WorkImagesManagementView extends ConsumerWidget {
  final WorkEntity work;

  const WorkImagesManagementView({
    super.key,
    required this.work,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和操作按钮区域
        Row(
          children: [
            Text(
              '图片管理',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: () => _addImages(context, ref),
              icon: const Icon(Icons.add_photo_alternate, size: 18),
              label: const Text('添加图片'),
            ),
          ],
        ),

        const SizedBox(height: AppSizes.spacingMedium),

        // 图片预览区域 - 带有更多编辑功能
        Expanded(
          child: WorkImagePreview(
            work: work,
            isEditing: true,
            fullscreen: true,
          ),
        ),

        const SizedBox(height: AppSizes.spacingSmall),

        // 图片管理说明
        Text(
          '提示: 通过拖拽可以调整图片顺序，点击图片可以查看大图',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    );
  }

  Future<void> _addImages(BuildContext context, WidgetRef ref) async {
    // 实现添加图片的逻辑 - 可以复用 WorkImagePreview 中的方法
  }
}
