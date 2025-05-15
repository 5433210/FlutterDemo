import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../providers/character/character_management_provider.dart';
import '../../../viewmodels/states/character_management_state.dart';
import '../../../widgets/common/resizable_panel.dart';
import '../../../widgets/common/sidebar_toggle.dart';
import '../../../widgets/pagination/m3_pagination_controls.dart';
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
                ResizablePanel(
                  initialWidth: 300,
                  minWidth: 280,
                  maxWidth: 400,
                  isLeftPanel: true,
                  child: M3CharacterFilterPanel(
                    onToggleExpand: _toggleFilterPanel,
                  ),
                ),

              // 筛选面板切换按钮
              if (widget.showFilterPanel)
                SidebarToggle(
                  isOpen: _isFilterPanelExpanded,
                  onToggle: _toggleFilterPanel,
                  alignRight: false,
                ),

              // 主内容（字符网格或列表）
              Expanded(
                child: state.viewMode == ViewMode.grid
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
                      ),
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
        title: Text(l10n.characterManagementDeleteConfirm),
        content: Text(l10n.characterManagementDeleteMessage),
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
