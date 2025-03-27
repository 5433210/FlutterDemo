import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/character/work_image_provider.dart';
import 'image_view.dart';
import 'preview_toolbar.dart';
import 'thumbnail_list.dart';

class ImagePreviewPanel extends ConsumerWidget {
  const ImagePreviewPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageState = ref.watch(workImageProvider);

    return Column(
      children: [
        // 工具栏
        const PreviewToolbar(),

        // 主图像区域
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 图像视图
              const ImageView(),

              // 加载指示器
              if (imageState.loading)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          '加载图像中...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

              // 错误提示
              if (imageState.error != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.white, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          '加载图像失败: ${imageState.error}',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(workImageProvider.notifier).reload(),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 缩略图列表
        if (imageState.pageIds.length > 1) const ThumbnailList(),
      ],
    );
  }
}
