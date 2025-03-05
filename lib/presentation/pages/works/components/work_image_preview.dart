import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/commands/work_edit_commands.dart';
import '../../../../application/providers/service_providers.dart';
import '../../../../domain/models/work/work_entity.dart';
import '../../../../domain/models/work/work_image.dart';
import '../../../providers/work_detail_provider.dart';
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
        work.images.where((img) => img.imported != null).toList();

    // 获取图片路径列表
    final imagePaths = validImages.map((img) => img.imported!.path).toList();

    // 是否启用图片编辑功能
    const bool enableImageEditing = false;

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

        // 编辑按钮工具栏
        if (isEditing && imagePaths.isNotEmpty && enableImageEditing)
          Positioned(
            top: 24,
            right: 24,
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_photo_alternate),
                      tooltip: '添加图片',
                      onPressed: () => _addImage(context, ref),
                    ),
                    IconButton(
                      icon: const Icon(Icons.rotate_90_degrees_cw),
                      tooltip: '旋转图片',
                      onPressed: () => _rotateImage(
                          ref, validImages[selectedIndex], selectedIndex),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: '删除图片',
                      onPressed: () => _deleteImage(
                          ref, validImages[selectedIndex], selectedIndex),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 添加图片方法
  Future<void> _addImage(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null &&
        result.files.isNotEmpty &&
        result.files.first.path != null) {
      final file = File(result.files.first.path!);
      final imageService = ref.read(workImageServiceProvider);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const SimpleDialog(
          title: Text('添加图片'),
          children: [
            Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在处理图片...'),
                ],
              ),
            ),
          ],
        ),
      );

      try {
        final imageInfo = await imageService.addImageToWork(
          work.id!,
          file,
          work.images.length,
        );

        final newImage = WorkImage(
          index: work.images.length,
          imported: ImageDetail(
            path: imageInfo.path,
            width: imageInfo.size.width,
            height: imageInfo.size.height,
            format: imageInfo.format,
            size: imageInfo.fileSize,
          ),
          thumbnail: imageInfo.thumbnail != null
              ? ImageThumbnail(
                  path: imageInfo.thumbnail,
                  width: 120,
                  height: 120,
                )
              : null,
        );

        if (context.mounted) {
          Navigator.pop(context);

          ref.read(workDetailProvider.notifier).executeCommand(
                AddImageCommand(
                  newImage: newImage,
                  position: work.images.length,
                ),
              );

          ref.read(selectedImageIndexProvider.notifier).state =
              work.images.length;
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('添加图片失败: ${e.toString()}')),
          );
        }
      }
    }
  }

  // 删除图片方法
  void _deleteImage(WidgetRef ref, WorkImage image, int index) {
    ref.read(workDetailProvider.notifier).executeCommand(
          RemoveImageCommand(
            removedImage: image,
            position: index,
          ),
        );

    if (index >= work.images.length - 1) {
      ref.read(selectedImageIndexProvider.notifier).state =
          work.images.length - 2;
    }
  }

  // 旋转图片方法
  Future<void> _rotateImage(WidgetRef ref, WorkImage image, int index) async {
    if (image.imported == null) return;

    final imageService = ref.read(imageServiceProvider);

    ref.read(workDetailProvider.notifier).executeCommand(
          RotateImageCommand(
            imageIndex: index,
            angle: 90,
            imageService: imageService,
          ),
        );
  }
}
