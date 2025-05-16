import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../application/services/character/character_service.dart';
import '../../../../domain/models/character/character_image_type.dart';
import '../../../../domain/models/character/character_view.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';

/// Material 3 version of the list view for displaying characters in a table-like format
class M3CharacterListView extends ConsumerWidget {
  /// Characters to display
  final List<CharacterView> characters;

  /// Whether batch selection mode is active
  final bool isBatchMode;

  /// Set of selected character IDs
  final Set<String> selectedCharacters;

  /// Callback when a character is selected
  final void Function(String) onCharacterSelect;

  /// Callback when a character's favorite status is toggled
  final void Function(String) onToggleFavorite;

  /// Callback when a character is deleted
  final void Function(String) onDelete;

  /// Callback when a character should be edited
  final void Function(String) onEdit;

  /// Whether the view is in loading state
  final bool isLoading;

  /// Error message to display (if any)
  final String? errorMessage;

  /// Constructor
  const M3CharacterListView({
    super.key,
    required this.characters,
    required this.onCharacterSelect,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onEdit,
    this.isBatchMode = false,
    this.selectedCharacters = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Store WidgetRef reference to use in async operations
    final stateRef = ref;

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.characterManagementLoading),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.characterManagementError(errorMessage!),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ),
      );
    }

    if (characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              color: theme.colorScheme.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.characterManagementNoCharacters,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.characterManagementNoCharactersHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 设置最小容器宽度
        const double minContainerWidth = 600.0;

        // 判断是否需要裁剪显示
        final bool needsClipping = constraints.maxWidth < minContainerWidth;

        // 如果需要裁剪，使用水平滚动视图
        if (needsClipping) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              // 设置一个固定的内容宽度
              width: minContainerWidth,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSizes.spacingMedium),
                itemCount: characters.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final character = characters[index];
                  final isSelected = selectedCharacters.contains(character.id);

                  return FutureBuilder<String>(
                    future: stateRef
                        .read(characterServiceProvider)
                        .getCharacterImagePath(
                            character.id, CharacterImageType.thumbnail),
                    builder: (context, snapshot) {
                      final thumbnailPath = snapshot.data ?? '';

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: theme.colorScheme.primaryContainer
                            .withAlpha(77), // 0.3 opacity = 77 alpha
                        leading:
                            _buildThumbnail(character, thumbnailPath, theme),
                        title: Row(
                          children: [
                            Text(
                              character.character,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // const SizedBox(width: AppSizes.spacingSmall),
                            // if (character.isFavorite)
                            //   Icon(
                            //     Icons.favorite,
                            //     color: theme.colorScheme.error,
                            //     size: 16,
                            //   ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${l10n.workFormTitle}: ${character.title}'),
                            if (character.author != null)
                              Text(
                                  '${l10n.workFormAuthor}: ${character.author}'),
                            Text(
                                '${l10n.characterDetailCollectionTime}: ${_formatDateTime(character.collectionTime)}'),
                          ],
                        ),
                        trailing: isBatchMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  onCharacterSelect(character.id);
                                },
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      character.isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: character.isFavorite
                                          ? theme.colorScheme.error
                                          : null,
                                    ),
                                    onPressed: () =>
                                        onToggleFavorite(character.id),
                                    tooltip: character.isFavorite
                                        ? l10n.workBrowseRemoveFavorite
                                        : l10n.workBrowseAddFavorite,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => onEdit(character.id),
                                    tooltip: l10n.edit,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => onDelete(character.id),
                                    tooltip: l10n.delete,
                                  ),
                                ],
                              ),
                        onTap: () {
                          // Only proceed if the widget is still mounted in the tree
                          if (context.mounted) {
                            onCharacterSelect(character.id);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          );
        } else {
          // 正常模式：使用自适应列表
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.spacingMedium),
            itemCount: characters.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final character = characters[index];
              final isSelected = selectedCharacters.contains(character.id);

              return FutureBuilder<String>(
                future: stateRef
                    .read(characterServiceProvider)
                    .getCharacterImagePath(
                        character.id, CharacterImageType.thumbnail),
                builder: (context, snapshot) {
                  final thumbnailPath = snapshot.data ?? '';

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: theme.colorScheme.primaryContainer
                        .withAlpha(77), // 0.3 opacity = 77 alpha
                    leading: _buildThumbnail(character, thumbnailPath, theme),
                    title: Row(
                      children: [
                        Text(
                          character.character,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacingSmall),
                        if (character.isFavorite)
                          Icon(
                            Icons.favorite,
                            color: theme.colorScheme.error,
                            size: 16,
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${l10n.workFormTitle}: ${character.title}'),
                        if (character.author != null)
                          Text('${l10n.workFormAuthor}: ${character.author}'),
                        Text(
                            '${l10n.characterDetailCollectionTime}: ${_formatDateTime(character.collectionTime)}'),
                      ],
                    ),
                    trailing: isBatchMode
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              onCharacterSelect(character.id);
                            },
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  character.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: character.isFavorite
                                      ? theme.colorScheme.error
                                      : null,
                                ),
                                onPressed: () => onToggleFavorite(character.id),
                                tooltip: character.isFavorite
                                    ? l10n.workBrowseRemoveFavorite
                                    : l10n.workBrowseAddFavorite,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => onEdit(character.id),
                                tooltip: l10n.edit,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => onDelete(character.id),
                                tooltip: l10n.delete,
                              ),
                            ],
                          ),
                    onTap: () {
                      // Only proceed if the widget is still mounted in the tree
                      if (context.mounted) {
                        onCharacterSelect(character.id);
                      }
                    },
                  );
                },
              );
            },
          );
        }
      },
    );
  }

  Widget _buildThumbnail(
    CharacterView character,
    String thumbnailPath,
    ThemeData theme,
  ) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.colorScheme.outline
              .withAlpha(128), // 0.5 opacity = 128 alpha
        ),
      ),
      child: thumbnailPath.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                File(thumbnailPath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      character.character,
                      style: theme.textTheme.titleLarge,
                    ),
                  );
                },
              ),
            )
          : Center(
              child: Text(
                character.character,
                style: theme.textTheme.titleLarge,
              ),
            ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
}
