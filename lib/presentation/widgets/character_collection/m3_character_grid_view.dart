import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/character/character_grid_provider.dart';
import 'm3_character_tile.dart';
import 'm3_empty_state.dart';
import 'm3_search_filter_bar.dart';
import 'pagination_control.dart';

class M3CharacterGridView extends ConsumerWidget {
  final String workId;
  final Function(String) onCharacterSelected;

  const M3CharacterGridView({
    Key? key,
    required this.workId,
    required this.onCharacterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final gridState = ref.watch(characterGridProvider);

    // 显示空状态
    if (gridState.characters.isEmpty) {
      return M3EmptyState(
        icon: Icons.sentiment_satisfied_alt,
        title: l10n.characterCollectionNoCharacters,
        message: l10n.characterCollectionUseSelectionTool,
      );
    }

    return Column(
      children: [
        // 搜索筛选栏
        M3SearchFilterBar(
          searchTerm: gridState.searchTerm,
          filterType: gridState.filterType,
          onSearchChanged: (term) =>
              ref.read(characterGridProvider.notifier).updateSearch(term),
          onFilterChanged: (type) =>
              ref.read(characterGridProvider.notifier).updateFilter(type),
        ),

        // 字符网格
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: gridState.filteredCharacters.length,
            itemBuilder: (context, index) {
              final character = gridState.filteredCharacters[index];
              return M3CharacterTile(
                character: character,
                isSelected: gridState.selectedIds.contains(character.id),
                onTap: () => onCharacterSelected(character.id),
                onLongPress: () => ref
                    .read(characterGridProvider.notifier)
                    .toggleSelection(character.id),
              );
            },
          ),
        ),

        // 分页控制
        if (gridState.totalPages > 1)
          PaginationControl(
            currentPage: gridState.currentPage,
            totalPages: gridState.totalPages,
            onPageChanged: (page) =>
                ref.read(characterGridProvider.notifier).setPage(page),
          ),
      ],
    );
  }
}
