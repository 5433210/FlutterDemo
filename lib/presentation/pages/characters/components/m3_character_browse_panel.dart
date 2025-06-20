import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../providers/character/character_management_provider.dart';
import '../../../viewmodels/states/character_management_state.dart';
import '../../../widgets/common/persistent_resizable_panel.dart';
import '../../../widgets/common/persistent_sidebar_toggle.dart';
import '../../../widgets/pagination/m3_pagination_controls.dart';
import '../../library/components/box_selection_painter.dart';
import 'm3_character_filter_panel.dart';
import 'm3_character_grid_view.dart';
import 'm3_character_list_view.dart';

/// 集字浏览面板 - 可复用控件，集成了筛选面板、网格/列表视图和分页控件
class M3CharacterBrowsePanel extends ConsumerStatefulWidget {
  /// 初始视图模式（网格或列表）
  final ViewMode initialViewMode;

  /// 初始筛选面板是否展开
  final bool initialFilterPanelExpanded;

  /// 是否启用批量选择模式
  final bool enableBatchMode;

  /// 批量选择模式是否处于活动状态
  final bool isBatchMode;

  /// 批量选择模式切换回调
  final void Function()? onBatchModeToggled;

  /// 当选中字符时的回调
  final void Function(String)? onCharacterSelected;

  /// 当删除字符时的回调
  final void Function(String)? onCharacterDeleted;

  /// 当编辑字符时的回调
  final void Function(String)? onCharacterEdited;

  /// 当切换收藏状态时的回调
  final void Function(String)? onFavoriteToggled;

  /// 当删除选中字符时的回调
  final void Function()? onSelectedCharactersDeleted;

  /// 当搜索时的回调
  final void Function(String)? onSearch;

  /// 当视图模式改变时的回调
  final void Function(ViewMode)? onViewModeChanged;

  /// 是否显示分页控件
  final bool showPagination;

  /// 是否显示筛选面板
  final bool showFilterPanel;

  /// 构造函数
  const M3CharacterBrowsePanel({
    super.key,
    this.initialViewMode = ViewMode.grid,
    this.initialFilterPanelExpanded = true,
    this.enableBatchMode = true,
    this.isBatchMode = false,
    this.onBatchModeToggled,
    this.onCharacterSelected,
    this.onCharacterDeleted,
    this.onCharacterEdited,
    this.onFavoriteToggled,
    this.onSelectedCharactersDeleted,
    this.onSearch,
    this.onViewModeChanged,
    this.showPagination = true,
    this.showFilterPanel = true,
  });

  @override
  ConsumerState<M3CharacterBrowsePanel> createState() =>
      _M3CharacterBrowsePanelState();
}

class _M3CharacterBrowsePanelState
    extends ConsumerState<M3CharacterBrowsePanel> {
  late bool _isFilterPanelExpanded;
  late TextEditingController _searchController;

  // 框选相关变量
  final GlobalKey _contentKey = GlobalKey();
  bool _isBoxSelecting = false;
  Offset? _boxSelectionStart;
  Offset? _boxSelectionCurrent;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(characterManagementProvider);

    return Column(
      children: [
        // 主要内容区域（筛选面板和字符网格/列表）
        Expanded(
          child: Row(
            children: [
              // 筛选面板（可折叠和调整大小）
              if (widget.showFilterPanel && _isFilterPanelExpanded)
                PersistentResizablePanel(
                  panelId: 'character_browse_filter_panel',
                  initialWidth: 300,
                  minWidth: 280,
                  maxWidth: 400,
                  isLeftPanel: true,
                  child: M3CharacterFilterPanel(
                    onToggleExpand: _toggleFilterPanel,
                    onRefresh: () {
                      // 触发集字数据刷新
                      ref.read(characterManagementProvider.notifier).refresh();
                    },
                  ),
                ),

              // 筛选面板切换按钮
              if (widget.showFilterPanel)
                PersistentSidebarToggle(
                  sidebarId: 'character_browse_filter_sidebar',
                  defaultIsOpen: _isFilterPanelExpanded,
                  onToggle: (isOpen) => _toggleFilterPanel(),
                  alignRight: false,
                ),

              // 主内容（字符网格或列表）
              Expanded(
                child: _buildContentArea(state),
              ),
            ],
          ),
        ),

        // 分页控件
        if (widget.showPagination)
          M3PaginationControls(
            currentPage: state.currentPage,
            pageSize: state.pageSize,
            totalItems: state.totalCount,
            onPageChanged: _handlePageChange,
            onPageSizeChanged: _handlePageSizeChange,
            availablePageSizes: const [10, 20, 50, 100],
          ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isFilterPanelExpanded = widget.initialFilterPanelExpanded;
    _searchController = TextEditingController();

    // 设置初始视图模式
    if (ref.read(characterManagementProvider).viewMode !=
        widget.initialViewMode) {
      Future.microtask(() {
        ref
            .read(characterManagementProvider.notifier)
            .setViewMode(widget.initialViewMode);
      });
    }

    // 加载初始数据
    Future.microtask(() {
      ref.read(characterManagementProvider.notifier).loadInitialData();
    });
  }

  Widget _buildContentArea(CharacterManagementState state) {
    // 创建基础内容
    Widget content = state.viewMode == ViewMode.grid
        ? M3CharacterGridView(
            characters: state.characters,
            isBatchMode: state.isBatchMode,
            selectedCharacters: state.selectedCharacters,
            onCharacterTap: _handleCharacterTap,
            onToggleFavorite: _handleToggleFavorite,
            isLoading: state.isLoading,
            errorMessage: state.errorMessage,
          )
        : M3CharacterListView(
            characters: state.characters,
            isBatchMode: state.isBatchMode,
            selectedCharacters: state.selectedCharacters,
            onCharacterSelect: _handleCharacterTap,
            onToggleFavorite: _handleToggleFavorite,
            onDelete: _handleDeleteCharacter,
            onEdit: _handleEditCharacter,
            isLoading: state.isLoading,
            errorMessage: state.errorMessage,
          );

    // 只有在批量模式下才启用框选功能
    if (!state.isBatchMode) {
      return content;
    }

    // 包装内容区域以支持框选
    return Stack(
      children: [
        // 内容区域，带有key以便我们可以获取其大小
        GestureDetector(
          key: _contentKey,
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            if (!state.isBatchMode) return;

            // 获取点击位置
            RenderBox? box =
                _contentKey.currentContext?.findRenderObject() as RenderBox?;
            if (box == null) return;

            Offset localPosition = box.globalToLocal(details.globalPosition);

            setState(() {
              _isBoxSelecting = true;
              _boxSelectionStart = localPosition;
              _boxSelectionCurrent = localPosition;
            });
          },
          onPanUpdate: (details) {
            if (!_isBoxSelecting) return;

            RenderBox? box =
                _contentKey.currentContext?.findRenderObject() as RenderBox?;
            if (box == null) return;

            Offset localPosition = box.globalToLocal(details.globalPosition);

            setState(() {
              _boxSelectionCurrent = localPosition;
            });
          },
          onPanEnd: (details) {
            if (!_isBoxSelecting) return;

            _handleBoxSelection();

            setState(() {
              _isBoxSelecting = false;
              _boxSelectionStart = null;
              _boxSelectionCurrent = null;
            });
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

  // 找到字符卡片的真实位置
  Map<String, Rect> _findRealCharacterPositions(RenderBox containerBox) {
    final result = <String, Rect>{};

    // 遍历所有元素并查找字符项
    void visitor(Element element) {
      String? characterId;

      // 检查元素的键是否包含字符ID，不再局限于特定widget类型
      final key = element.widget.key;
      if (key is ValueKey && key.value.toString().startsWith('character_')) {
        // 从键字符串中提取字符ID
        characterId = key.value.toString().substring(10);

        // 获取位置信息
        final renderObj = element.renderObject;
        if (renderObj is RenderBox && renderObj.hasSize) {
          try {
            // 计算相对于容器的位置
            final pos =
                renderObj.localToGlobal(Offset.zero, ancestor: containerBox);
            final rect = Rect.fromLTWH(
                pos.dx, pos.dy, renderObj.size.width, renderObj.size.height);
            result[characterId] = rect;
            debugPrint('Found character position for $characterId: $rect');
          } catch (e) {
            // 处理可能的异常，例如元素已经不在视图树中
            debugPrint('Error getting position for character $characterId: $e');
          }
        }
      }

      // 继续遍历子元素
      element.visitChildren(visitor);
    }

    // 开始遍历
    if (_contentKey.currentContext != null) {
      _contentKey.currentContext!.visitChildElements(visitor);
      debugPrint(
          'Element tree traversal complete, found ${result.length} characters');
    } else {
      debugPrint('Content key context is null, cannot traverse element tree');
    }

    return result;
  }

  // 这些方法已经在重构中移到了内联实现
  // 可以安全删除

  // 处理框选完成
  void _handleBoxSelection() {
    if (_boxSelectionStart == null || _boxSelectionCurrent == null) return;

    final state = ref.read(characterManagementProvider);
    if (!state.isBatchMode) return;

    // 将选择框规范化为左上角到右下角的形式
    final selectionRect =
        Rect.fromPoints(_boxSelectionStart!, _boxSelectionCurrent!);

    // 获取内容区域的RenderBox对象
    RenderBox? contentBox =
        _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (contentBox == null) {
      debugPrint('Content box is null, cannot find character positions');
      return;
    }

    // 输出当前视图模式用于调试
    debugPrint(
        'Current view mode: ${state.viewMode == ViewMode.grid ? "Grid" : "List"}');

    // 使用元素遍历来找到实际的字符项位置
    final characterItems = _findRealCharacterPositions(contentBox);
    if (characterItems.isEmpty) {
      debugPrint('No character items found in the view');
      return;
    }

    final notifier = ref.read(characterManagementProvider.notifier);

    // 记录框选内的所有字符ID
    Set<String> boxSelectedIds = {};

    // 调试信息
    debugPrint('Selection rect: $selectionRect');
    debugPrint('Found ${characterItems.length} character items');

    // 选中在选择框内的所有字符
    for (var entry in characterItems.entries) {
      if (selectionRect.overlaps(entry.value)) {
        boxSelectedIds.add(entry.key);
        debugPrint('Selected character: ${entry.key}, rect: ${entry.value}');
      }
    }

    if (boxSelectedIds.isEmpty) {
      debugPrint('No characters found in selection rectangle: $selectionRect');
      return;
    }

    debugPrint('Box selected ${boxSelectedIds.length} characters');

    // 更直接的方法：强制将框中所有的字符都设为选中状态
    for (final id in boxSelectedIds) {
      if (!state.selectedCharacters.contains(id)) {
        // 只有未选中的字符才需要切换状态
        notifier.toggleCharacterSelection(id);
        debugPrint('Toggling selection for character: $id');
      } else {
        debugPrint('Character already selected: $id');
      }
    }
  }

  void _handleCharacterTap(String characterId) {
    // 如果提供了外部回调，则调用
    if (widget.onCharacterSelected != null) {
      widget.onCharacterSelected!(characterId);
      return;
    }

    final state = ref.read(characterManagementProvider);

    if (state.isBatchMode) {
      // 批量模式下，切换选择状态
      ref
          .read(characterManagementProvider.notifier)
          .toggleCharacterSelection(characterId);
    } else {
      // 普通模式下，选择字符查看详情
      ref
          .read(characterManagementProvider.notifier)
          .selectCharacter(characterId);
    }
  }

  void _handleDeleteCharacter(String characterId) {
    // 如果提供了外部回调，则调用
    if (widget.onCharacterDeleted != null) {
      widget.onCharacterDeleted!(characterId);
      return;
    }

    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.deleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(characterManagementProvider.notifier)
                  .deleteCharacter(characterId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _handleEditCharacter(String characterId) {
    // 如果提供了外部回调，则调用
    if (widget.onCharacterEdited != null) {
      widget.onCharacterEdited!(characterId);
    }
  }

  void _handlePageChange(int page) {
    ref.read(characterManagementProvider.notifier).changePage(page);
  }

  void _handlePageSizeChange(int? size) {
    if (size != null) {
      ref.read(characterManagementProvider.notifier).updatePageSize(size);
    }
  }

  void _handleToggleFavorite(String characterId) async {
    // 如果提供了外部回调，则调用
    if (widget.onFavoriteToggled != null) {
      widget.onFavoriteToggled!(characterId);
      return;
    }

    await ref
        .read(characterManagementProvider.notifier)
        .toggleFavorite(characterId);
  }

  // ===== 事件处理方法 =====

  void _toggleFilterPanel() {
    setState(() {
      _isFilterPanelExpanded = !_isFilterPanelExpanded;
    });
  }

  // For future use when search field is added directly to this panel
  /*
  void _handleSearch(String query) {
    // 如果提供了外部回调，则调用
    if (widget.onSearch != null) {
      widget.onSearch!(query);
      return;
    }

    final filterNotifier = ref.read(characterFilterProvider.notifier);
    filterNotifier.updateSearchText(query);

    // 应用更新后的筛选器
    final filter = ref.read(characterFilterProvider);
    ref.read(characterManagementProvider.notifier).updateFilter(filter);
  }
  */
}
