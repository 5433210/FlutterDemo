import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/character/character_grid_provider.dart';
import '../pagination/m3_persistent_pagination_controls.dart';
import 'm3_character_tile.dart';
import 'm3_empty_state.dart';
import 'm3_search_filter_bar.dart';

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
    final gridState = ref.watch(characterGridProvider(workId));

    // 显示空状态
    if (gridState.characters.isEmpty) {
      return M3EmptyState(
        icon: Icons.sentiment_satisfied_alt,
        title: l10n.noCharacters,
        message: l10n.characterCollectionUseBoxTool,
      );
    }

    return Column(
      children: [
        // 搜索筛选栏
        M3SearchFilterBar(
          searchTerm: gridState.searchTerm,
          filterType: gridState.filterType,
          onSearchChanged: (term) => ref
              .read(characterGridProvider(workId).notifier)
              .updateSearch(term),
          onFilterChanged: (type) => ref
              .read(characterGridProvider(workId).notifier)
              .updateFilter(type),
        ),

        // 字符网格
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 设置固定的卡片宽度和最小宽度
              const double fixedCardWidth = 120.0; // 固定卡片宽度
              const double minContainerWidth = 300.0; // 最小容器宽度
              const double spacing = 8.0;
              const double padding = 16.0;

              // 计算可用宽度
              final double availableWidth = constraints.maxWidth;

              // 判断是否需要裁剪显示
              final bool needsClipping = availableWidth < minContainerWidth;

              // 如果需要裁剪，使用固定列数和固定卡片宽度
              if (needsClipping) {
                // 固定显示2列
                const int fixedColumnCount = 2;

                // 创建一个固定宽度的容器，允许水平滚动
                return SizedBox(
                  width: availableWidth,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      // 设置一个固定的内容宽度，确保卡片大小不变
                      width: fixedColumnCount * fixedCardWidth +
                          (fixedColumnCount - 1) * spacing +
                          padding * 2,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(padding),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: fixedColumnCount,
                          childAspectRatio: 1.0, // 正方形卡片
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                        ),
                        itemCount: gridState.filteredCharacters.length,
                        itemBuilder: (context, index) {
                          final character = gridState.filteredCharacters[index];
                          return M3CharacterTile(
                            character: character,
                            isSelected:
                                gridState.selectedIds.contains(character.id),
                            onTap: () => onCharacterSelected(character.id),
                            onLongPress: () => ref
                                .read(characterGridProvider(workId).notifier)
                                .toggleSelection(character.id),
                          );
                        },
                      ),
                    ),
                  ),
                );
              } else {
                // 正常模式：根据可用宽度动态调整列数
                // 计算最佳列数
                // 设置最小卡片宽度为100像素，最大为150像素
                const double minCardWidth = 100.0;
                const double maxCardWidth = 150.0;

                // 计算可用宽度（减去padding）
                final double adjustedWidth = availableWidth - padding * 2;

                // 计算可以放置的最大列数（基于最小卡片宽度）
                int maxColumns = (adjustedWidth / minCardWidth).floor();

                // 确保至少有2列，最多有8列
                int crossAxisCount = maxColumns.clamp(2, 8);

                // 计算实际卡片宽度
                double actualCardWidth =
                    (adjustedWidth - (spacing * (crossAxisCount - 1))) /
                        crossAxisCount;

                // 确保卡片宽度不超过最大值
                if (actualCardWidth > maxCardWidth && crossAxisCount < 8) {
                  // 如果卡片太宽，增加列数
                  crossAxisCount += 1;
                  actualCardWidth =
                      (adjustedWidth - (spacing * (crossAxisCount - 1))) /
                          crossAxisCount;
                }

                // 使用正方形卡片
                double childAspectRatio = 1.0;

                return GridView.builder(
                  padding: const EdgeInsets.all(padding),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                  ),
                  itemCount: gridState.filteredCharacters.length,
                  itemBuilder: (context, index) {
                    final character = gridState.filteredCharacters[index];
                    return M3CharacterTile(
                      character: character,
                      isSelected: gridState.selectedIds.contains(character.id),
                      onTap: () => onCharacterSelected(character.id),
                      onLongPress: () => ref
                          .read(characterGridProvider(workId).notifier)
                          .toggleSelection(character.id),
                    );
                  },
                );
              }
            },
          ),
        ), // 分页控制
        if (gridState.characters.isNotEmpty)
          M3PersistentPaginationControls(
            pageId: 'character_grid_$workId',
            currentPage: gridState.currentPage,
            totalItems: gridState.characters.length, // 使用实际的字符总数
            onPageChanged: (page) =>
                ref.read(characterGridProvider(workId).notifier).setPage(page),
            onPageSizeChanged: (pageSize) => ref
                .read(characterGridProvider(workId).notifier)
                .setPageSize(pageSize),
            availablePageSizes: const [8, 12, 16, 20, 24, 32, 48, 64],
            defaultPageSize: 20,
          ),
      ],
    );
  }
}
