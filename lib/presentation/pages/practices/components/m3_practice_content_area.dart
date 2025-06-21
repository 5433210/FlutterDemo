import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pages/library/components/box_selection_painter.dart';
import '../../../viewmodels/states/practice_list_state.dart';
import 'm3_practice_grid_view.dart';
import 'm3_practice_list_view.dart';

/// 字帖内容区域组件 - 支持框选功能
class M3PracticeContentArea extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> practices;
  final PracticeViewMode viewMode;
  final bool isBatchMode;
  final Set<String> selectedPractices;
  final Function(String) onPracticeTap;
  final Function(String)? onPracticeLongPress;
  final Function(String)? onToggleFavorite;
  final Function(String, List<String>)? onTagsEdited;
  final bool isLoading;
  final String? errorMessage;

  const M3PracticeContentArea({
    super.key,
    required this.practices,
    required this.viewMode,
    required this.isBatchMode,
    required this.selectedPractices,
    required this.onPracticeTap,
    this.onPracticeLongPress,
    this.onToggleFavorite,
    this.onTagsEdited,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  ConsumerState<M3PracticeContentArea> createState() => _M3PracticeContentAreaState();
}

class _M3PracticeContentAreaState extends ConsumerState<M3PracticeContentArea> {
  // 框选相关变量
  bool _isBoxSelecting = false;
  Offset? _boxSelectionStart;
  Offset? _boxSelectionCurrent;
  final GlobalKey _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (widget.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.loading,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (widget.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              widget.errorMessage!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ),
      );
    }

    if (widget.practices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.emptyStateNoPractices,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    // 创建基础内容
    Widget content = widget.viewMode == PracticeViewMode.grid
        ? M3PracticeGridView(
            practices: widget.practices,
            isBatchMode: widget.isBatchMode,
            selectedPractices: widget.selectedPractices,
            onPracticeTap: widget.onPracticeTap,
            onPracticeLongPress: widget.onPracticeLongPress,
            onToggleFavorite: widget.onToggleFavorite,
            onTagsEdited: widget.onTagsEdited,
          )
        : M3PracticeListView(
            practices: widget.practices,
            isBatchMode: widget.isBatchMode,
            selectedPractices: widget.selectedPractices,
            onPracticeTap: widget.onPracticeTap,
            onPracticeLongPress: widget.onPracticeLongPress,
            onToggleFavorite: widget.onToggleFavorite,
            onTagsEdited: widget.onTagsEdited,
          );

    // 如果不是批量模式，则不启用框选功能
    if (!widget.isBatchMode) {
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
            if (!widget.isBatchMode) return;

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
              '开始框选字帖',
              data: {
                'startPosition': '${localPosition.dx},${localPosition.dy}',
                'operation': 'box_selection_start',
              },
              tag: 'practice_content_area',
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
              '完成框选字帖',
              data: {
                'operation': 'box_selection_end',
              },
              tag: 'practice_content_area',
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

  /// 查找所有字帖项目的真实位置
  Map<String, Rect> _findRealPracticeItemPositions(RenderBox containerBox) {
    final result = <String, Rect>{};

    void visitor(Element element) {
      // 检查元素的键是否包含字帖项目ID
      final key = element.widget.key;
      if (key is ValueKey && key.value.toString().startsWith('practice_item_')) {
        // 从键字符串中提取字帖项目ID
        final itemId = key.value.toString().substring(14); // 'practice_item_'.length

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
              '获取字帖项目位置时出错',
              error: e,
              data: {'itemId': itemId},
              tag: 'practice_content_area',
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

    if (!widget.isBatchMode) return;

    // 将选择框规范化为左上角到右下角的形式
    final selectionRect =
        Rect.fromPoints(_boxSelectionStart!, _boxSelectionCurrent!);

    // 获取内容区域的RenderBox对象
    RenderBox? contentBox =
        _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (contentBox == null) {
      AppLogger.warning(
        '无法获取内容区域的RenderBox对象',
        tag: 'practice_content_area',
      );
      return;
    }

    // 使用元素遍历来找到实际的字帖项目位置
    final practiceItems = _findRealPracticeItemPositions(contentBox);
    if (practiceItems.isEmpty) {
      AppLogger.debug(
        '视图中未找到字帖项目',
        tag: 'practice_content_area',
      );
      return;
    }

    // 记录框选内的所有字帖项目ID
    Set<String> boxSelectedIds = {};

    AppLogger.debug(
      '框选检测',
      data: {
        'selectionRect': '${selectionRect.left},${selectionRect.top},${selectionRect.width}x${selectionRect.height}',
        'practiceItemCount': practiceItems.length,
        'viewMode': widget.viewMode.name,
      },
      tag: 'practice_content_area',
    );

    // 选中在选择框内的所有字帖项目
    for (var entry in practiceItems.entries) {
      if (selectionRect.overlaps(entry.value)) {
        boxSelectedIds.add(entry.key);
        AppLogger.debug(
          '选中字帖项目',
          data: {
            'practiceId': entry.key,
            'position': '${entry.value.left},${entry.value.top},${entry.value.width}x${entry.value.height}',
          },
          tag: 'practice_content_area',
        );
      }
    }

    if (boxSelectedIds.isEmpty) {
      AppLogger.debug(
        '在选择框中未找到字帖项目',
        data: {
          'selectionRect': selectionRect.toString(),
        },
        tag: 'practice_content_area',
      );
      return;
    }

    AppLogger.info(
      '框选了字帖项目',
      data: {
        'selectedCount': boxSelectedIds.length,
        'selectedIds': boxSelectedIds.toList(),
      },
      tag: 'practice_content_area',
    );

    // 更新所有字帖项目的选中状态
    for (final practiceId in boxSelectedIds) {
      final isCurrentlySelected = widget.selectedPractices.contains(practiceId);
      // 框选时添加到选择，不取消已有选择
      if (!isCurrentlySelected) {
        widget.onPracticeTap(practiceId);
      }
    }
  }
} 