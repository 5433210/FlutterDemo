import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/work_image_provider.dart';

class ThumbnailList extends ConsumerWidget {
  const ThumbnailList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageState = ref.watch(workImageProvider);

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // 页面指示器
          Container(
            padding: const EdgeInsets.all(8),
            alignment: Alignment.center,
            child: Text(
              '页面: ${imageState.pageIds.indexOf(imageState.currentPageId) + 1}/${imageState.pageIds.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          // 缩略图列表
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final ScrollController controller = ScrollController();
                return Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      final double scrollAmount = pointerSignal.scrollDelta.dy;
                      controller.position.moveTo(
                        controller.offset + scrollAmount,
                        curve: Curves.linear,
                        duration: const Duration(milliseconds: 100),
                      );
                    }
                  },
                  child: ListView.builder(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    itemCount: imageState.pageIds.length,
                    itemBuilder: (context, index) {
                      final pageId = imageState.pageIds[index];
                      final isSelected = pageId == imageState.currentPageId;

                      return _ThumbnailItem(
                        pageId: pageId,
                        index: index + 1,
                        isSelected: isSelected,
                        onTap: () {
                          final notifier = ref.read(workImageProvider.notifier);
                          // 切换页面
                          notifier.changePage(pageId);
                          // 加载该页的选区
                          ref
                              .read(characterCollectionProvider.notifier)
                              .loadWorkData(
                                imageState.workId,
                                pageId: pageId,
                              );
                          ref
                              .read(characterCollectionProvider.notifier)
                              .clearSelectedRegions(); // 清除选区
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // 导航按钮
          if (imageState.pageIds.length > 1)
            Row(
              children: [
                // 上一页
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: imageState.hasPrevious
                      ? () =>
                          ref.read(workImageProvider.notifier).previousPage()
                      : null,
                  tooltip: '上一页',
                ),

                // 下一页
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: imageState.hasNext
                      ? () => ref.read(workImageProvider.notifier).nextPage()
                      : null,
                  tooltip: '下一页',
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ThumbnailItem extends ConsumerWidget {
  final String pageId;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThumbnailItem({
    Key? key,
    required this.pageId,
    required this.index,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final imageState = ref.watch(workImageProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 实际缩略图
            FutureBuilder<String?>(
              future:
                  ref.read(workImageProvider.notifier).getThumbnailPath(pageId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Image.file(
                      File(snapshot.data!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image_outlined,
                          size: 24,
                          color: Colors.grey,
                        );
                      },
                    ),
                  );
                }
                return const Center(
                  child:
                      Icon(Icons.image_outlined, size: 24, color: Colors.grey),
                );
              },
            ),

            // 页码指示器
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isSelected ? theme.colorScheme.primary : Colors.black54,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(3),
                    bottomRight: Radius.circular(3),
                  ),
                ),
                child: Text(
                  '$index',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        isSelected ? theme.colorScheme.onPrimary : Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),

            // 加载指示器
            if (isSelected && imageState.loading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
