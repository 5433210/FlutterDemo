import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_filter.dart';
import '../../../theme/app_sizes.dart';
import '../../providers/character/character_detail_provider.dart';
import '../../providers/character/character_filter_provider.dart';
import '../../providers/character/character_management_provider.dart';
import '../../viewmodels/states/character_management_state.dart';
import '../../widgets/common/sidebar_toggle.dart';
import '../../widgets/page_layout.dart';
import 'components/character_detail_panel.dart';
import 'components/character_filter_panel.dart';
import 'components/character_grid_view.dart';
import 'components/character_list_view.dart';

/// Character management page
class CharacterManagementPage extends ConsumerStatefulWidget {
  /// Constructor
  const CharacterManagementPage({super.key});

  @override
  ConsumerState<CharacterManagementPage> createState() =>
      _CharacterManagementPageState();
}

class _CharacterManagementPageState
    extends ConsumerState<CharacterManagementPage> {
  bool _isFilterPanelExpanded = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(characterManagementProvider);
    final filter = ref.watch(characterFilterProvider);
    final theme = Theme.of(context);

    return PageLayout(
      toolbar: _buildToolbar(theme, state),
      body: Column(
        children: [
          // Main content with filter, list and detail panels
          Expanded(
            child: Row(
              children: [
                // Filter panel (collapsible)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _isFilterPanelExpanded ? 250 : 0,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(),
                  child: _isFilterPanelExpanded
                      ? const CharacterFilterPanel()
                      : null,
                ),

                // Filter panel toggle
                SidebarToggle(
                  isOpen: _isFilterPanelExpanded,
                  onToggle: _toggleFilterPanel,
                  alignRight: false,
                ),

                // Main content (character grid or list)
                Expanded(
                  child: state.viewMode == ViewMode.grid
                      ? CharacterGridView(
                          characters: state.characters,
                          isBatchMode: state.isBatchMode,
                          selectedCharacters: state.selectedCharacters,
                          onCharacterTap: _handleCharacterTap,
                          onToggleFavorite: _handleToggleFavorite,
                          isLoading: state.isLoading,
                          errorMessage: state.errorMessage,
                        )
                      : CharacterListView(
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

                // Detail panel toggle (only visible when detail panel should be shown)
                if (state.selectedCharacterId != null)
                  SidebarToggle(
                    isOpen: state.isDetailOpen,
                    onToggle: _toggleDetailPanel,
                    alignRight: true,
                  ),

                // Detail panel (collapsible)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width:
                      (state.selectedCharacterId != null && state.isDetailOpen)
                          ? 600
                          : 0,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(),
                  child: (state.selectedCharacterId != null &&
                          state.isDetailOpen)
                      ? CharacterDetailPanel(
                          characterId: state.selectedCharacterId!,
                          onClose: _closeDetailPanel,
                          onEdit: state.selectedCharacterId != null
                              ? () => _handleEditCharacter(
                                  state.selectedCharacterId!)
                              : null,
                          onToggleFavorite: state.selectedCharacterId != null
                              ? () => _handleToggleFavorite(
                                  state.selectedCharacterId!)
                              : null,
                        )
                      : null,
                ),
              ],
            ),
          ),

          // Pagination controls
          _buildPaginationControls(state),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Load initial data when page is created
    Future.microtask(() {
      ref.read(characterManagementProvider.notifier).loadInitialData();
    });
  }

  Widget _buildPageButton(int page, int currentPage) {
    final theme = Theme.of(context);
    final isCurrentPage = page == currentPage;

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: isCurrentPage ? null : () => _handlePageChange(page),
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isCurrentPage ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isCurrentPage
              ? null
              : Border.all(color: theme.colorScheme.outline),
        ),
        child: Center(
          child: Text(
            '$page',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isCurrentPage
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: isCurrentPage ? FontWeight.bold : null,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPageNumbers(int currentPage, int totalPages) {
    final result = <Widget>[];
    const maxVisiblePages = 5;

    if (totalPages <= maxVisiblePages) {
      // Show all pages if total is small
      for (int i = 1; i <= totalPages; i++) {
        result.add(_buildPageButton(i, currentPage));
      }
    } else {
      // Show first page
      result.add(_buildPageButton(1, currentPage));

      // Calculate range of pages to show around current page
      int rangeStart = currentPage - 1;
      int rangeEnd = currentPage + 1;

      // Adjust range to fit within bounds
      if (rangeStart < 2) {
        rangeEnd += (2 - rangeStart);
        rangeStart = 2;
      }

      if (rangeEnd > totalPages - 1) {
        rangeStart -= (rangeEnd - (totalPages - 1));
        rangeStart = rangeStart < 2 ? 2 : rangeStart;
        rangeEnd = totalPages - 1;
      }

      // Add ellipsis if needed
      if (rangeStart > 2) {
        result.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('...'),
        ));
      }

      // Add middle pages
      for (int i = rangeStart; i <= rangeEnd; i++) {
        result.add(_buildPageButton(i, currentPage));
      }

      // Add ellipsis if needed
      if (rangeEnd < totalPages - 1) {
        result.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('...'),
        ));
      }

      // Show last page
      result.add(_buildPageButton(totalPages, currentPage));
    }

    return result;
  }

  Widget _buildPaginationControls(CharacterManagementState state) {
    final totalPages = (state.totalCount / state.pageSize).ceil();
    final theme = Theme.of(context);

    return Container(
      height: AppSizes.appBarHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingMedium,
        vertical: AppSizes.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // First page button
          IconButton(
            onPressed:
                state.currentPage > 1 ? () => _handlePageChange(1) : null,
            icon: const Icon(Icons.first_page),
            tooltip: '第一页',
          ),

          // Previous page button
          IconButton(
            onPressed: state.currentPage > 1
                ? () => _handlePageChange(state.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: '上一页',
          ),

          const SizedBox(width: AppSizes.spacingMedium),

          // Page numbers
          ..._buildPageNumbers(state.currentPage, totalPages),

          const SizedBox(width: AppSizes.spacingMedium),

          // Next page button
          IconButton(
            onPressed: state.currentPage < totalPages
                ? () => _handlePageChange(state.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: '下一页',
          ),

          // Last page button
          IconButton(
            onPressed: state.currentPage < totalPages
                ? () => _handlePageChange(totalPages)
                : null,
            icon: const Icon(Icons.last_page),
            tooltip: '最后页',
          ),

          const SizedBox(width: AppSizes.spacingLarge),

          // Page size selector
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
            ),
            child: PopupMenuButton<int>(
              initialValue: state.pageSize,
              onSelected: _handlePageSizeChange,
              itemBuilder: (context) => [10, 20, 50, 100]
                  .map((size) => PopupMenuItem<int>(
                        value: size,
                        height: 36,
                        child: Text('$size 项/页'),
                      ))
                  .toList(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${state.pageSize} 项/页',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        )),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSizes.spacingMedium),

          // Total count
          Text(
            '总计: ${state.totalCount} 个字符',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme, CharacterManagementState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: kToolbarHeight + 8,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.98),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.only(
        left: AppSizes.spacingMedium,
        right: AppSizes.spacingMedium,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        children: [
          // Left side: Title
          Text(
            '集字管理',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),

          const Spacer(),

          // Search box
          SizedBox(
            width: 220,
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索字符、作品或作者',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.5),
                  ),
                ),
              ),
              onChanged: _handleSearch,
              textInputAction: TextInputAction.search,
            ),
          ),

          const SizedBox(width: 8),

          // Right side actions
          Container(
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 1,
            color: theme.dividerColor.withOpacity(0.2),
          ),

          // Actions section
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Batch mode toggle
              IconButton(
                onPressed: _toggleBatchMode,
                icon: Icon(
                  state.isBatchMode ? Icons.cancel : Icons.check_box_outlined,
                  color: state.isBatchMode ? theme.colorScheme.primary : null,
                ),
                tooltip: state.isBatchMode ? '退出批量模式' : '批量操作',
                visualDensity: VisualDensity.compact,
              ),

              // View mode toggle
              IconButton(
                onPressed: _toggleViewMode,
                icon: Icon(
                  state.viewMode == ViewMode.grid
                      ? Icons.view_list
                      : Icons.grid_view,
                  color: theme.colorScheme.onSurface,
                ),
                tooltip: state.viewMode == ViewMode.grid ? '列表视图' : '网格视图',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          // Filter toggle - styled as a button similar to WorkBrowsePage
          FilledButton.icon(
            onPressed: _toggleFilterPanel,
            icon: const Icon(Icons.filter_list, size: 18),
            label: const Text('筛选'),
            style: FilledButton.styleFrom(
              backgroundColor: _isFilterPanelExpanded
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondaryContainer,
              foregroundColor: _isFilterPanelExpanded
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSecondaryContainer,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          if (state.isBatchMode && state.selectedCharacters.isNotEmpty) ...[
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _showDeleteConfirmation,
              icon: const Icon(Icons.delete, size: 18),
              label: Text('删除 (${state.selectedCharacters.length})'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _closeDetailPanel() {
    ref.read(characterManagementProvider.notifier).closeDetailPanel();
  }

  void _handleCharacterTap(String characterId) {
    final state = ref.read(characterManagementProvider);

    if (state.isBatchMode) {
      // In batch mode, toggle selection
      ref
          .read(characterManagementProvider.notifier)
          .toggleCharacterSelection(characterId);
    } else {
      // In normal mode, select for detail view
      ref
          .read(characterManagementProvider.notifier)
          .selectCharacter(characterId);
    }
  }

  void _handleDeleteCharacter(String characterId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个字符吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(characterManagementProvider.notifier)
                  .deleteCharacter(characterId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _handleEditCharacter(String characterId) {
    final state = ref.read(characterManagementProvider);
    final character = state.characters.firstWhere((c) => c.id == characterId);

    Navigator.pushNamed(
      context,
      '/works/${character.workId}/collection',
      arguments: {
        'regionId': character.region.id,
        'action': 'edit',
      },
    );
  }

  void _handleFilterChanged(CharacterFilter filter) {
    ref.read(characterManagementProvider.notifier).updateFilter(filter);
  }

  void _handlePageChange(int page) {
    ref.read(characterManagementProvider.notifier).changePage(page);
  }

  void _handlePageSizeChange(int? size) {
    if (size != null) {
      ref.read(characterManagementProvider.notifier).updatePageSize(size);
    }
  }

  // Event handlers

  void _handleSearch(String searchText) {
    final filterNotifier = ref.read(characterFilterProvider.notifier);
    filterNotifier.updateSearchText(searchText);

    final filter = ref.read(characterFilterProvider);
    ref.read(characterManagementProvider.notifier).updateFilter(filter);
  }

  void _handleToggleFavorite(String characterId) async {
    await ref
        .read(characterManagementProvider.notifier)
        .toggleFavorite(characterId);

    // 刷新详情面板数据
    // if (ref.read(characterManagementProvider).selectedCharacterId ==
    //     characterId) {
    ref.refresh(characterDetailProvider(characterId));
    // }

    // 刷新列表状态以更新卡片显示
    // ref.invalidate(characterManagementProvider);
    // await ref.read(characterDetailProvider(characterId).)
  }

  void _showDeleteConfirmation() {
    final state = ref.read(characterManagementProvider);

    if (state.selectedCharacters.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认批量删除'),
        content:
            Text('确定要删除选中的 ${state.selectedCharacters.length} 个字符吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(characterManagementProvider.notifier)
                  .deleteSelectedCharacters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _toggleBatchMode() {
    ref.read(characterManagementProvider.notifier).toggleBatchMode();
  }

  void _toggleDetailPanel() {
    ref.read(characterManagementProvider.notifier).toggleDetailPanel();
  }

  void _toggleFilterPanel() {
    setState(() {
      _isFilterPanelExpanded = !_isFilterPanelExpanded;
    });
  }

  void _toggleViewMode() {
    ref.read(characterManagementProvider.notifier).toggleViewMode();
  }
}
