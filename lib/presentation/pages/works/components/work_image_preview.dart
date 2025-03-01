import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/commands/work_edit_commands.dart';
import '../../../../application/providers/service_providers.dart';
import '../../../../domain/value_objects/work/work_entity.dart';
import '../../../../domain/value_objects/work/work_image.dart';
import '../../../providers/work_detail_provider.dart';

// 创建一个图片索引提供者
final selectedImageIndexProvider = StateProvider<int>((ref) => 0);

// 普通的图片列表组件
class ImageList extends StatelessWidget {
  final List<WorkImage> images;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const ImageList({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    return SizedBox(
      height: 120, // 高度保持不变
      child: Listener(
        // 使用 Listener 监听鼠标事件，这比 NotificationListener 更直接
        onPointerSignal: (signal) {
          if (signal is PointerScrollEvent) {
            // 将垂直滚动转换为水平滚动
            if (scrollController.hasClients) {
              final double scrollAmount = signal.scrollDelta.dy;
              final double target =
                  scrollController.offset + (scrollAmount * 3.0);

              // 使用 animateTo 平滑滚动，比 jumpTo 体验更好
              scrollController.animateTo(
                target.clamp(0.0, scrollController.position.maxScrollExtent),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
              );
            }
          }
        },
        child: ListView.builder(
          controller: scrollController, // 使用我们创建的控制器
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          itemBuilder: (context, index) {
            final image = images[index];
            final isSelected = index == selectedIndex;

            // 计算图片宽高比
            final double aspectRatio = image.imported != null
                ? image.imported!.width / image.imported!.height
                : 1.0; // 默认为1:1

            // 固定高度，根据比例计算宽度
            final double fixedHeight = 100.0;
            final double calculatedWidth = fixedHeight * aspectRatio;

            // 限制宽度范围，避免过宽或过窄
            final double constrainedWidth =
                calculatedWidth.clamp(fixedHeight * 0.5, fixedHeight * 2.0);

            return Stack(
              children: [
                // 缩略图容器 - 使用计算的宽度
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: constrainedWidth, // 使用计算后的宽度
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: InkWell(
                    onTap: () => onSelect(index),
                    child:
                        image.thumbnail != null && image.thumbnail?.path != null
                            ? Image.file(
                                File(image.thumbnail!.path),
                                width: constrainedWidth,
                                height: fixedHeight,
                                fit: BoxFit.contain, // 使用contain而非cover，保持原图比例
                                // 添加缓存打破参数，确保当路径相同但内容不同时能刷新显示
                                cacheWidth: (constrainedWidth * 1.5).toInt(),
                                cacheHeight: (fixedHeight * 1.5).toInt(),
                                // 确保每次刷新时都重新加载图片，避免缓存问题
                                key: ValueKey(
                                    '${image.thumbnail!.path}?v=${DateTime.now().millisecondsSinceEpoch}'),
                                errorBuilder: (context, error, stackTrace) {
                                  // 处理图片加载错误
                                  debugPrint('图片 $index 加载失败: $error');
                                  return Container(
                                    width: constrainedWidth,
                                    height: fixedHeight,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.red),
                                  );
                                },
                              )
                            : Container(
                                width: constrainedWidth,
                                height: fixedHeight,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported),
                              ),
                  ),
                ),
                // 添加序号标记
                Positioned(
                  left: 4,
                  top: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// 修改ReorderableImageList类以确保拖拽功能正常工作
class ReorderableImageList extends StatefulWidget {
  // 保持现有参数不变
  final List<WorkImage> images;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Function(int oldIndex, int newIndex) onReorder;

  const ReorderableImageList({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onSelect,
    required this.onReorder,
  });

  @override
  State<ReorderableImageList> createState() => _ReorderableImageListState();
}

class WorkImagePreview extends ConsumerWidget {
  final WorkEntity work;
  final bool isEditing;
  final bool fullscreen; // 新增参数，用于区分全屏模式和嵌入模式

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

    // 获取当前选中图片
    final selectedImage = selectedIndex < validImages.length
        ? validImages[selectedIndex]
        : validImages.isNotEmpty
            ? validImages[0]
            : null;

    // 是否启用图片编辑功能 - 临时设置为false来屏蔽这些功能
    const bool enableImageEditing = false;

    return Column(
      children: [
        // 主图片预览区域
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              fit: StackFit.expand, // 确保Stack填满容器
              children: [
                // 图片显示区域
                if (selectedImage != null && selectedImage.imported != null)
                  Positioned.fill(
                    // 使用Positioned.fill占满整个空间
                    child: InteractiveViewer(
                      boundaryMargin: const EdgeInsets.all(20.0),
                      minScale: 0.1,
                      maxScale: 4.0,
                      child: Center(
                        // 保留Center以确保图片居中
                        child: Image.file(
                          File(selectedImage.imported!.path),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('主图片加载失败: $error');
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
                        ),
                      ),
                    ),
                  )
                else
                  const Center(child: Text('没有图片')),

                // 编辑模式下显示操作工具栏 - 只在enableImageEditing为true时显示
                if (isEditing && selectedImage != null && enableImageEditing)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 添加图片按钮
                            IconButton(
                              icon: const Icon(Icons.add_photo_alternate),
                              tooltip: '添加图片',
                              onPressed: () => _addImage(context, ref),
                            ),

                            // 旋转图片按钮
                            IconButton(
                              icon: const Icon(Icons.rotate_90_degrees_cw),
                              tooltip: '旋转图片',
                              onPressed: selectedImage != null
                                  ? () => _rotateImage(
                                      ref, selectedImage, selectedIndex)
                                  : null,
                            ),

                            // 删除图片按钮
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: '删除图片',
                              onPressed: selectedImage != null
                                  ? () => _deleteImage(
                                      ref, selectedImage, selectedIndex)
                                  : null,
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 缩略图列表 - 无论编辑模式都使用普通ImageList
        if (validImages.isNotEmpty)
          ImageList(
            images: validImages,
            selectedIndex: selectedIndex,
            onSelect: (index) {
              ref.read(selectedImageIndexProvider.state).state = index;
            },
          )
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

      // 获取图片服务
      final imageService = ref.read(workImageServiceProvider);

      // 显示加载状态
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
        // 处理图片
        final imageInfo = await imageService.addImageToWork(
          work.id!,
          file,
          work.images.length, // 添加到最后
        );

        // 转换为 WorkImage
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

        // 使用命令添加图片
        if (context.mounted) {
          Navigator.pop(context); // 关闭加载对话框

          ref.read(workDetailProvider.notifier).executeCommand(
                AddImageCommand(
                  newImage: newImage,
                  position: work.images.length,
                ),
              );

          // 选中新添加的图片
          ref.read(selectedImageIndexProvider.state).state = work.images.length;
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // 关闭加载对话框
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('添加图片失败: ${e.toString()}')),
          );
        }
      }
    }
  }

  // 删除图片方法
  void _deleteImage(WidgetRef ref, WorkImage image, int index) {
    // 使用命令删除图片
    ref.read(workDetailProvider.notifier).executeCommand(
          RemoveImageCommand(
            removedImage: image,
            position: index,
          ),
        );

    // 调整选中索引
    if (index >= work.images.length - 1) {
      ref.read(selectedImageIndexProvider.state).state = work.images.length - 2;
    }
  }

  // 旋转图片方法
  Future<void> _rotateImage(WidgetRef ref, WorkImage image, int index) async {
    if (image.imported == null) return;

    // 获取图片服务
    final imageService = ref.read(imageServiceProvider);

    // 使用命令旋转图片
    ref.read(workDetailProvider.notifier).executeCommand(
          RotateImageCommand(
            imageIndex: index,
            angle: 90, // 默认旋转90度
            imageService: imageService,
          ),
        );
  }
}

class _ReorderableImageListState extends State<ReorderableImageList> {
  late ScrollController _scrollController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Listener(
        onPointerSignal: (signal) {
          if (signal is PointerScrollEvent && _scrollController.hasClients) {
            // 获取滚动事件的方向和大小
            double scrollDelta = signal.scrollDelta.dy;

            // 调整滚动敏感度
            final scrollFactor = 3.0;
            final double target =
                _scrollController.offset + (scrollDelta * scrollFactor);

            // 使用带有惯性的动画效果进行滚动
            _scrollController.animateTo(
              target.clamp(0.0, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          }
        },
        child: ReorderableListView.builder(
          scrollController: _scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: widget.images.length,
          itemBuilder: (context, index) =>
              _buildThumbnail(index, widget.images[index], context),
          // 处理拖拽排序逻辑 - 简化直接调用回调
          onReorder: (oldIndex, newIndex) {
            // ReorderableListView在移动过程中已经考虑了元素的移除和插入，
            // 但我们需要考虑实际的逻辑索引
            if (oldIndex < newIndex) {
              newIndex -= 1; // 这是因为移除oldIndex后，newIndex的位置会减1
            }
            widget.onReorder(oldIndex, newIndex);
          },
          // 自定义拖动时的样式
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Material(
                  elevation: 4.0,
                  color: Colors.transparent,
                  shadowColor:
                      Theme.of(context).colorScheme.shadow.withOpacity(0.5),
                  child: child,
                );
              },
              child: child,
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  // 构建缩略图项 - 与原来保持一致
  Widget _buildThumbnail(int index, WorkImage image, BuildContext context) {
    final isSelected = index == widget.selectedIndex;

    // 计算图片宽高比
    final double aspectRatio = image.imported != null
        ? image.imported!.width / image.imported!.height
        : 1.0; // 默认为1:1

    // 固定高度，根据比例计算宽度
    final double fixedHeight = 100.0;
    final double calculatedWidth = fixedHeight * aspectRatio;

    // 限制宽度范围，避免过宽或过窄
    final double constrainedWidth =
        calculatedWidth.clamp(fixedHeight * 0.5, fixedHeight * 2.0);

    return Stack(
      key: ValueKey('image-$index'),
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: constrainedWidth, // 使用计算后的宽度
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: InkWell(
            onTap: () => widget.onSelect(index),
            child: image.thumbnail != null && image.thumbnail?.path != null
                ? Image.file(
                    File(image.thumbnail!.path),
                    width: constrainedWidth,
                    height: fixedHeight,
                    fit: BoxFit.contain, // 使用contain以保持原图比例
                    cacheWidth: (constrainedWidth * 1.5).toInt(),
                    cacheHeight: (fixedHeight * 1.5).toInt(),
                    key: ValueKey(
                        '${image.thumbnail!.path}?v=${DateTime.now().millisecondsSinceEpoch}'),
                    errorBuilder: (context, error, stackTrace) {
                      // 处理图片加载错误
                      debugPrint('图片 $index 加载失败: $error');
                      return Container(
                        width: constrainedWidth,
                        height: fixedHeight,
                        color: Colors.grey.shade200,
                        child:
                            const Icon(Icons.broken_image, color: Colors.red),
                      );
                    },
                  )
                : Container(
                    width: constrainedWidth,
                    height: fixedHeight,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported),
                  ),
          ),
        ),
        // 添加序号标记
        Positioned(
          left: 4,
          top: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
