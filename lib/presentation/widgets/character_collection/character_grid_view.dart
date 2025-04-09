import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/character/character_grid_provider.dart';
import '../../viewmodels/states/character_grid_state.dart';
import 'character_tile.dart';
import 'pagination_control.dart';
import 'search_filter_bar.dart';

class CharacterGridView extends ConsumerWidget {
  final String workId;
  final Function(String) onCharacterSelected;

  const CharacterGridView({
    Key? key,
    required this.workId,
    required this.onCharacterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gridState = ref.watch(characterGridProvider);

    // 显示空状态
    if (gridState.characters.isEmpty) {
      return const EmptyState(
        icon: Icons.sentiment_satisfied_alt,
        title: '还没有收集任何字符',
        message: '使用左侧的框选工具从图片中提取字符',
      );
    }

    return Column(
      children: [
        // 搜索筛选栏
        SearchFilterBar(
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
              return CharacterTile(
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

// 空状态组件
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
