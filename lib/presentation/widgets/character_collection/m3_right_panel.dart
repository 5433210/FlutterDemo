import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/services/character/character_service.dart';
import '../../../domain/models/character/character_region.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/providers/character/erase_providers.dart'
    as erase;
import '../../../widgets/character_edit/m3_character_edit_panel.dart';
import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/character_grid_provider.dart';
import '../../providers/character/character_refresh_notifier.dart';
import '../../providers/character/selected_region_provider.dart';
import '../../providers/character/work_image_provider.dart';
import '../common/tab_bar_theme_wrapper.dart';
import 'm3_character_grid_view.dart';

class M3RightPanel extends ConsumerStatefulWidget {
  final String workId;

  const M3RightPanel({
    super.key,
    required this.workId,
  });

  @override
  ConsumerState<M3RightPanel> createState() => _M3RightPanelState();
}

class _M3RightPanelState extends ConsumerState<M3RightPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  ui.Image? _characterImage;
  bool _wasAdjusting = false;

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(workImageProvider);
    final selectedRegion = ref.watch(selectedRegionProvider);

    // Monitor region adjustment state
    final isAdjusting = ref.watch(characterCollectionProvider).isAdjusting;

    // Handle region adjustment state changes
    if (isAdjusting != _wasAdjusting) {
      _wasAdjusting = isAdjusting;
      if (!isAdjusting) {
        // Region adjustment complete, update image
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _characterImage?.dispose();
              _characterImage = null;
            });
          }
        });
      }
    }

    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Character Preview
              _buildPreviewTab(selectedRegion, imageState),
              // Tab 2: Collection Results
              _buildGridTab(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _characterImage?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void handleTabChange() async {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });

      // If switching to the grid tab, refresh characters to ensure latest data
      if (_tabController.index == 1) {
        await _refreshCharacterGrid(widget.workId);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(handleTabChange);

    // Clear erase state on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(erase.eraseStateProvider.notifier).clear();

      // Setup listener for character refresh events
      ref.listenManual(characterRefreshNotifierProvider, (previous, current) {
        if (previous != current) {
          // Only refresh if we're on the grid tab or we've just deleted a character
          final refreshEvent =
              ref.read(characterRefreshNotifierProvider.notifier).lastEventType;
          if (_currentIndex == 1 ||
              refreshEvent == RefreshEventType.characterDeleted ||
              refreshEvent == RefreshEventType.characterSaved) {
            _refreshCharacterGrid(widget.workId);

            // If a character was deleted and we're in preview tab with no selected region,
            // consider switching to grid tab
            if (refreshEvent == RefreshEventType.characterDeleted &&
                _currentIndex == 0 &&
                ref.read(selectedRegionProvider) == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _tabController.animateTo(1); // Switch to grid tab
                }
              });
            }
          }
        }
      });
    });
  }

  Widget _buildCharacterEditor(
    CharacterRegion selectedRegion,
    WorkImageState imageState,
  ) {
    // 使用RepaintBoundary包装编辑面板，并使用Consumer来隔离处理选项的刷新
    return RepaintBoundary(
      child: Consumer(
        builder: (context, ref, _) {
          // 使用memoized选项提供者，避免整个编辑面板因其他状态变化而重建
          final processingOptions =
              ref.watch(erase.memoizedProcessingOptionsProvider);

          // Use selectedRegion's id, rect and rotation as part of the key
          return M3CharacterEditPanel(
            key: ValueKey(
                'editor_${selectedRegion.id}_${selectedRegion.rect.left}_${selectedRegion.rect.top}_${selectedRegion.rect.width}_${selectedRegion.rect.height}_${selectedRegion.rotation}'),
            selectedRegion: selectedRegion,
            workId: widget.workId,
            pageId: imageState.currentPageId,
            imageData: imageState.imageData,
            processingOptions: processingOptions,
            onEditComplete: _handleEditComplete,
          );
        },
      ),
    );
  }

  Widget _buildGridTab() {
    final l10n = AppLocalizations.of(context);

    // 确保 workId 不为空
    if (widget.workId.isEmpty) {
      return Center(
        child: Text(
          l10n.characterCollectionNoCharacters,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return M3CharacterGridView(
      workId: widget.workId,
      onCharacterSelected: _handleCharacterSelected,
    );
  }

  Widget _buildPreviewTab(
    CharacterRegion? selectedRegion,
    WorkImageState imageState,
  ) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (selectedRegion == null) {
      return Center(
        child: Text(
          l10n.characterCollectionSelectRegion,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return _buildCharacterEditor(selectedRegion, imageState);
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context);

    // 使用 TabBarThemeWrapper 包装 TabBar，确保一致的样式
    return TabBarThemeWrapper(
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: l10n.characterCollectionPreviewTab),
          Tab(text: l10n.characterCollectionResultsTab),
        ],
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }

  Future<void> _handleCharacterSelected(String characterId) async {
    final l10n = AppLocalizations.of(context);
    try {
      // 1. Get current page state
      final currentState = ref.read(workImageProvider);
      final currentPageId = currentState.currentPageId;
      final currentWorkId = widget.workId;

      // 2. Get character service to query character details
      final characterServiceValue = ref.read(characterServiceProvider);
      final character = await characterServiceValue.when(
        data: (service) => service.getCharacterDetails(characterId),
        loading: () => throw Exception('Character service is loading'),
        error: (error, stack) =>
            throw Exception('Character service error: $error'),
      );

      if (character == null) {
        throw Exception('Character information not found');
      }

      // 3. Check if character is on current page
      final isOnCurrentPage = character.pageId == currentPageId &&
          character.workId == currentWorkId;

      if (!isOnCurrentPage) {
        // 4. If not on current page, need to switch pages
        // 4.1 Show loading message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.characterCollectionSwitchingPage),
              duration: const Duration(seconds: 1),
            ),
          );
        }

        // 4.2 Load target page
        final imageProvider = ref.read(workImageProvider.notifier);
        await imageProvider.loadWorkImage(character.workId, character.pageId);

        // 4.3 Load character region data for that page
        await ref.read(characterCollectionProvider.notifier).loadWorkData(
              character.workId,
              pageId: character.pageId,
              defaultSelectedRegionId: characterId,
            );

        // Notify about page change
        ref
            .read(characterRefreshNotifierProvider.notifier)
            .notifyEvent(RefreshEventType.pageChanged);

        // 4.4 Switch to preview tab
        _tabController.animateTo(0);
      } else {
        // 5. If on current page, directly load region data
        await ref.read(characterCollectionProvider.notifier).loadWorkData(
              currentWorkId,
              pageId: currentPageId,
              defaultSelectedRegionId: characterId,
            );

        // Still notify, as we've changed the selected character
        ref
            .read(characterRefreshNotifierProvider.notifier)
            .notifyEvent(RefreshEventType.pageChanged);

        // 5.1 Switch to preview tab
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(l10n.characterCollectionFindSwitchFailed(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleEditComplete(Map<String, dynamic> result) async {
    final characterId = result['characterId'];
    // Check if this is a new character or just an edit
    final isNewCharacter = result['isNewCharacter'] == true;

    if (characterId != null && isNewCharacter) {
      // Only switch to the results tab if it's a new character
      _tabController.animateTo(1);
    }

    // Refresh grid in any case
    await _refreshCharacterGrid(widget.workId);
  }

  // Helper method to refresh the character grid
  Future<void> _refreshCharacterGrid(String workId) async {
    try {
      await ref.read(characterGridProvider(workId).notifier).loadCharacters();
    } catch (e) {
      debugPrint('Failed to refresh character grid: $e');
    }
  }
}
