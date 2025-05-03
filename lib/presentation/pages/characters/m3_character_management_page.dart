import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';
import '../../providers/character/character_detail_provider.dart';
import '../../providers/character/character_filter_provider.dart';
import '../../providers/character/character_management_provider.dart';
import '../../viewmodels/states/character_management_state.dart';
import '../../widgets/common/sidebar_toggle.dart';
import '../../widgets/page_layout.dart';
import '../works/m3_character_collection_page.dart';
import 'components/m3_character_detail_panel.dart';
import 'components/m3_character_filter_panel.dart';
import 'components/m3_character_grid_view.dart';
import 'components/m3_character_list_view.dart';
import 'components/m3_character_management_navigation_bar.dart';

/// Material 3 version of the character management page
class M3CharacterManagementPage extends ConsumerStatefulWidget {
  /// Constructor
  const M3CharacterManagementPage({super.key});

  @override
  ConsumerState<M3CharacterManagementPage> createState() =>
      _M3CharacterManagementPageState();
}

class _M3CharacterManagementPageState
    extends ConsumerState<M3CharacterManagementPage> {
  bool _isFilterPanelExpanded = true;
  late final TextEditingController _searchController;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(characterManagementProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return PageLayout(
      toolbar: M3CharacterManagementNavigationBar(
        isBatchMode: state.isBatchMode,
        onToggleBatchMode: _toggleBatchMode,
        selectedCount: state.selectedCharacters.length,
        onDeleteSelected: state.selectedCharacters.isNotEmpty
            ? _handleDeleteSelectedCharacters
            : null,
        isGridView: state.viewMode == ViewMode.grid,
        onToggleViewMode: _toggleViewMode,
        onSearch: _handleSearch,
        searchController: _searchController,
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 800,
          minHeight: 600,
        ),
        child: Column(
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
                        ? M3CharacterFilterPanel(
                            onToggleExpand: _toggleFilterPanel,
                          )
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

                  // Detail panel (collapsible)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: (state.selectedCharacterId != null &&
                            state.isDetailOpen)
                        ? 350
                        : 0,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(),
                    child: (state.selectedCharacterId != null &&
                            state.isDetailOpen)
                        ? M3CharacterDetailPanel(
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
            _buildPaginationControls(state, l10n),
          ],
        ),
      ),
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
    _searchController = TextEditingController();
    // Load initial data when the page is created
    Future.microtask(() {
      ref.read(characterManagementProvider.notifier).loadInitialData();
    });
  }

  Widget _buildPaginationControls(
    CharacterManagementState state,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final totalPages = (state.totalCount / state.pageSize).ceil();

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Total count
          Text(
            '${state.totalCount} ${l10n.characters}',
            style: theme.textTheme.bodyMedium,
          ),

          // Pagination
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed:
                    state.currentPage > 1 ? () => _handlePageChange(1) : null,
                tooltip: 'First Page',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: state.currentPage > 1
                    ? () => _handlePageChange(state.currentPage - 1)
                    : null,
                tooltip: 'Previous Page',
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 40),
                alignment: Alignment.center,
                child: Text(
                  '${state.currentPage} / $totalPages',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: state.currentPage < totalPages
                    ? () => _handlePageChange(state.currentPage + 1)
                    : null,
                tooltip: 'Next Page',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: state.currentPage < totalPages
                    ? () => _handlePageChange(totalPages)
                    : null,
                tooltip: 'Last Page',
              ),
            ],
          ),

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
                        child: Text(
                          l10n.characterManagementItemsPerPage('$size'),
                        ),
                      ))
                  .toList(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.characterManagementItemsPerPage('${state.pageSize}'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _closeDetailPanel() {
    ref.read(characterManagementProvider.notifier).closeDetailPanel();
  }

  void _handleCharacterTap(String characterId) {
    // Skip state updates if the widget is no longer mounted
    if (!mounted) return;

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
    // Skip if the widget is no longer mounted
    if (!mounted) return;

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
              if (mounted) {
                // Check again after dialog is closed
                ref
                    .read(characterManagementProvider.notifier)
                    .deleteCharacter(characterId);
              }
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

  void _handleDeleteSelectedCharacters() {
    final state = ref.read(characterManagementProvider);
    final l10n = AppLocalizations.of(context);

    if (state.selectedCharacters.isEmpty) return;

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
                  .deleteSelectedCharacters();
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
    final state = ref.read(characterManagementProvider);
    final character = state.characters.firstWhere((c) => c.id == characterId);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => M3CharacterCollectionPage(
          workId: character.workId,
          initialCharacterId: character.id,
          initialPageId: character.pageId,
        ),
      ),
    );
    // Navigator.pushNamed(
    //   context,
    //   '/character_collection',
    //   arguments: {
    //     'workId': character.workId,
    //     'pageId': character.pageId,
    //     'characterId': character.id,
    //   },
    // );
  }

  void _handlePageChange(int page) {
    ref.read(characterManagementProvider.notifier).changePage(page);
  }

  void _handlePageSizeChange(int? size) {
    if (size != null) {
      ref.read(characterManagementProvider.notifier).updatePageSize(size);
    }
  }

  void _handleSearch(String query) {
    final filterNotifier = ref.read(characterFilterProvider.notifier);
    filterNotifier.updateSearchText(query);

    // Apply the updated filter to the management provider
    final filter = ref.read(characterFilterProvider);
    ref.read(characterManagementProvider.notifier).updateFilter(filter);
  }

  Future<void> _handleToggleFavorite(String characterId) async {
    await ref
        .read(characterManagementProvider.notifier)
        .toggleFavorite(characterId);
    if (characterId ==
        ref.read(characterManagementProvider).selectedCharacterId) {
      ref.invalidate(characterDetailProvider(characterId));
    }
  }

  void _toggleBatchMode() {
    ref.read(characterManagementProvider.notifier).toggleBatchMode();
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
