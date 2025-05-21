import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../providers/character/character_detail_provider.dart';
import '../../providers/character/character_filter_provider.dart';
import '../../providers/character/character_management_provider.dart';
import '../../utils/cross_navigation_helper.dart';
import '../../viewmodels/states/character_management_state.dart';
import '../../widgets/common/resizable_panel.dart';
import '../../widgets/page_layout.dart';
import 'components/m3_character_browse_panel.dart';
import 'components/m3_character_detail_panel.dart';
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
  late final TextEditingController _searchController;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(characterManagementProvider);

    return PageLayout(
      toolbar: M3CharacterManagementNavigationBar(
        isBatchMode: state.isBatchMode,
        onToggleBatchMode: _toggleBatchMode,
        selectedCount: state.selectedCharacters.length,
        onDeleteSelected: state.selectedCharacters.isNotEmpty
            ? _handleDeleteSelectedCharacters
            : null,
        onCopySelected: state.selectedCharacters.isNotEmpty ||
                state.selectedCharacterId != null
            ? _handleCopySelectedCharacters
            : null,
        onSelectAll: state.isBatchMode ? _handleSelectAll : null,
        onClearSelection:
            state.isBatchMode && state.selectedCharacters.isNotEmpty
                ? _handleClearSelection
                : null,
        isGridView: state.viewMode == ViewMode.grid,
        onToggleViewMode: _toggleViewMode,
        onSearch: _handleSearch,
        searchController: _searchController,
        onBackPressed: () {
          CrossNavigationHelper.handleBackNavigation(context, ref);
        },
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 800,
          minHeight: 600,
        ),
        child: Row(
          children: [
            // 主内容区域（包含筛选面板、字符列表和分页）
            Expanded(
              child: M3CharacterBrowsePanel(
                initialViewMode: state.viewMode,
                enableBatchMode: true,
                isBatchMode: state.isBatchMode,
                onCharacterSelected: _handleCharacterTap,
                onCharacterDeleted: _handleDeleteCharacter,
                onCharacterEdited: _handleEditCharacter,
                onFavoriteToggled: _handleToggleFavorite,
              ),
            ),

            // 详情面板（可折叠和调整大小）
            if (state.selectedCharacterId != null && state.isDetailOpen)
              ResizablePanel(
                initialWidth: 350,
                minWidth: 250,
                maxWidth: 500,
                isLeftPanel: false,
                child: M3CharacterDetailPanel(
                  characterId: state.selectedCharacterId!,
                  onClose: _closeDetailPanel,
                  onEdit: () =>
                      _handleEditCharacter(state.selectedCharacterId!),
                  onToggleFavorite: () =>
                      _handleToggleFavorite(state.selectedCharacterId!),
                ),
              ),
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

  /// Handle clear selection action
  void _handleClearSelection() {
    ref.read(characterManagementProvider.notifier).clearSelection();
  }

  void _handleCopySelectedCharacters() async {
    // 调用复制功能
    await ref
        .read(characterManagementProvider.notifier)
        .copySelectedCharactersToClipboard();

    // 显示成功提示
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${l10n.selectedCount(ref.read(characterManagementProvider).selectedCharacters.length)} ${l10n.practiceEditCopy.split(' ').first}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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

    // 使用命名路由导航到集字功能页，这样会在主窗体内容区域显示
    Navigator.of(context).pushNamed(
      AppRoutes.characterCollection,
      arguments: {
        'workId': character.workId,
        'pageId': character.pageId,
        'characterId': character.id,
      },
    );
  }

  void _handleSearch(String query) {
    final filterNotifier = ref.read(characterFilterProvider.notifier);
    filterNotifier.updateSearchText(query);

    // Apply the updated filter to the management provider
    final filter = ref.read(characterFilterProvider);
    ref.read(characterManagementProvider.notifier).updateFilter(filter);
  }

  /// Handle select all action
  void _handleSelectAll() {
    ref.read(characterManagementProvider.notifier).selectAllOnPage();
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

  void _toggleViewMode() {
    ref.read(characterManagementProvider.notifier).toggleViewMode();
  }
}
