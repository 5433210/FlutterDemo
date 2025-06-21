import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/work/work_entity.dart';
import '../../../../../infrastructure/logging/logger.dart';
import '../../../../pages/library/components/box_selection_painter.dart';
import '../../../../viewmodels/states/work_browse_state.dart';
import 'm3_work_grid_view.dart';
import 'm3_work_list_view.dart';

/// 作品内容区域组件 - 支持框选功能
class M3WorkContentArea extends ConsumerStatefulWidget {
  final List<WorkEntity> works;
  final ViewMode viewMode;
  final bool batchMode;
  final Set<String> selectedWorks;
  final Function(String, bool) onSelectionChanged;
  final Function(String)? onItemTap;
  final Function(String)? onToggleFavorite;
  final Function(String)? onTagsEdited;

  const M3WorkContentArea({
    super.key,
    required this.works,
    required this.viewMode,
    required this.batchMode,
    required this.selectedWorks,
    required this.onSelectionChanged,
    this.onItemTap,
    this.onToggleFavorite,
    this.onTagsEdited,
  });

  @override
  ConsumerState<M3WorkContentArea> createState() => _M3WorkContentAreaState();
}

class _M3WorkContentAreaState extends ConsumerState<M3WorkContentArea> {
  // 框选相关变量
  bool _isBoxSelecting = false;
  Offset? _boxSelectionStart;
  Offset? _boxSelectionCurrent;
  final GlobalKey _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // 创建基础内容
    Widget content = widget.viewMode == ViewMode.grid
        ? M3WorkGridView(
            works: widget.works,
            batchMode: widget.batchMode,
            selectedWorks: widget.selectedWorks,
            onSelectionChanged: widget.onSelectionChanged,
            onItemTap: widget.onItemTap,
            onToggleFavorite: widget.onToggleFavorite,
            onTagsEdited: widget.onTagsEdited,
          )
        : M3WorkListView(
            works: widget.works,
            batchMode: widget.batchMode,
            selectedWorks: widget.selectedWorks,
            onSelectionChanged: widget.onSelectionChanged,
            onItemTap: widget.onItemTap,
            onToggleFavorite: widget.onToggleFavorite,
            onTagsEdited: widget.onTagsEdited,
          );

    // 如果不是批量模式，则不启用框选功能
    if (!widget.batchMode) {
      return content;
    }

    // 包装在GestureDetector中以支持框选功能
    return Stack(
      children: [
        // 内容区域，带有key以便我们可以获取其大小
        GestureDetector(
          key: _contentKey,
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            if (!widget.batchMode) return;

            RenderBox? box =
                _contentKey.currentContext?.findRenderObject() as RenderBox?;
            if (box == null) return;

            Offset localPosition = box.globalToLocal(details.globalPosition);

            setState(() {
              _isBoxSelecting = true;
              _boxSelectionStart = localPosition;
              _boxSelectionCurrent = localPosition;
            });

            AppLogger.debug(
              '开始框选作品',
              data: {
                'startPosition': '${localPosition.dx},${localPosition.dy}',
                'operation': 'box_selection_start',
              },
              tag: 'work_content_area',
            );
          },
          onPanUpdate: (details) {
            if (!_isBoxSelecting) return;

            RenderBox? box =
                _contentKey.currentContext?.findRenderObject() as RenderBox?;
            if (box == null) return;

            Offset localPosition = box.globalToLocal(details.globalPosition);

            // 只有当位置确实发生明显变化时才更新
            if (_boxSelectionCurrent == null ||
                (_boxSelectionCurrent! - localPosition).distance > 2.0) {
              setState(() {
                _boxSelectionCurrent = localPosition;
              });
            }
          },
          onPanEnd: (details) {
            if (!_isBoxSelecting) return;

            // 如果选择矩形太小（可能是意外点击），则取消选择
            if (_boxSelectionStart != null && _boxSelectionCurrent != null) {
              final selectionRect =
                  Rect.fromPoints(_boxSelectionStart!, _boxSelectionCurrent!);
              if (selectionRect.width < 5 && selectionRect.height < 5) {
                // 取消选择操作 - 可能是意外点击
                setState(() {
                  _isBoxSelecting = false;
                  _boxSelectionStart = null;
                  _boxSelectionCurrent = null;
                });
                return;
              }
            }

            // 应用最终选择
            _handleBoxSelection();

            // 重置框选状态
            setState(() {
              _isBoxSelecting = false;
              _boxSelectionStart = null;
              _boxSelectionCurrent = null;
            });

            AppLogger.debug(
              '完成框选作品',
              data: {
                'operation': 'box_selection_end',
              },
              tag: 'work_content_area',
            );
          },
          child: content,
        ),

        // 绘制选择框
        if (_isBoxSelecting &&
            _boxSelectionStart != null &&
            _boxSelectionCurrent != null)
          Positioned.fill(
            child: CustomPaint(
              painter: BoxSelectionPainter(
                start: _boxSelectionStart!,
                end: _boxSelectionCurrent!,
              ),
            ),
          ),
      ],
    );
  }

  /// 查找所有作品项目的真实位置
  Map<String, Rect> _findRealWorkItemPositions(RenderBox containerBox) {
    final result = <String, Rect>{};

    void visitor(Element element) {
      // 检查元素的键是否包含作品项目ID
      final key = element.widget.key;
      if (key is ValueKey && key.value.toString().startsWith('work_item_')) {
        // 从键字符串中提取作品项目ID
        final itemId = key.value.toString().substring(10); // 'work_item_'.length

        // 获取位置信息
        final renderObj = element.renderObject;
        if (renderObj is RenderBox && renderObj.hasSize) {
          try {
            // 计算相对于容器的位置
            final pos =
                renderObj.localToGlobal(Offset.zero, ancestor: containerBox);
            final rect = Rect.fromLTWH(
                pos.dx, pos.dy, renderObj.size.width, renderObj.size.height);
            result[itemId] = rect;
          } catch (e) {
            // 处理可能的异常，例如元素已经不在视图树中
            AppLogger.warning(
              '获取作品项目位置时出错',
              error: e,
              data: {'itemId': itemId},
              tag: 'work_content_area',
            );
          }
        }
      }

      // 继续遍历子元素
      element.visitChildren(visitor);
    }

    // 开始遍历
    if (_contentKey.currentContext != null) {
      _contentKey.currentContext!.visitChildElements(visitor);
    }

    return result;
  }

  /// 处理框选完成
  void _handleBoxSelection() {
    if (_boxSelectionStart == null || _boxSelectionCurrent == null) return;

    if (!widget.batchMode) return;

    // 将选择框规范化为左上角到右下角的形式
    final selectionRect =
        Rect.fromPoints(_boxSelectionStart!, _boxSelectionCurrent!);

    // 获取内容区域的RenderBox对象
    RenderBox? contentBox =
        _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (contentBox == null) {
      AppLogger.warning(
        '无法获取内容区域的RenderBox对象',
        tag: 'work_content_area',
      );
      return;
    }

    // 使用元素遍历来找到实际的作品项目位置
    final workItems = _findRealWorkItemPositions(contentBox);
    if (workItems.isEmpty) {
      AppLogger.debug(
        '视图中未找到作品项目',
        tag: 'work_content_area',
      );
      return;
    }

    // 记录框选内的所有作品项目ID
    Set<String> boxSelectedIds = {};

    AppLogger.debug(
      '框选检测',
      data: {
        'selectionRect': '${selectionRect.left},${selectionRect.top},${selectionRect.width}x${selectionRect.height}',
        'workItemCount': workItems.length,
        'viewMode': widget.viewMode.name,
      },
      tag: 'work_content_area',
    );

    // 选中在选择框内的所有作品项目
    for (var entry in workItems.entries) {
      if (selectionRect.overlaps(entry.value)) {
        boxSelectedIds.add(entry.key);
        AppLogger.debug(
          '选中作品项目',
          data: {
            'workId': entry.key,
            'position': '${entry.value.left},${entry.value.top},${entry.value.width}x${entry.value.height}',
          },
          tag: 'work_content_area',
        );
      }
    }

    if (boxSelectedIds.isEmpty) {
      AppLogger.debug(
        '在选择框中未找到作品项目',
        data: {
          'selectionRect': selectionRect.toString(),
        },
        tag: 'work_content_area',
      );
      return;
    }

    AppLogger.info(
      '框选了作品项目',
      data: {
        'selectedCount': boxSelectedIds.length,
        'selectedIds': boxSelectedIds.toList(),
      },
      tag: 'work_content_area',
    );

    // 更新所有作品项目的选中状态
    for (final workId in boxSelectedIds) {
      final isCurrentlySelected = widget.selectedWorks.contains(workId);
      // 框选时添加到选择，不取消已有选择
      if (!isCurrentlySelected) {
        widget.onSelectionChanged(workId, true);
      }
    }
  }
} 