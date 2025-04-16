import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/character/character_view.dart';
import '../../../../theme/app_sizes.dart';

/// List view for displaying characters in a table-like format
class CharacterListView extends ConsumerWidget {
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
  const CharacterListView({
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

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            Text(errorMessage!),
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
              color: theme.colorScheme.outline,
              size: 48,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            Text(
              '没有找到匹配的字符',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      itemCount: characters.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final character = characters[index];
        final isSelected = selectedCharacters.contains(character.id);

        return ListTile(
          selected: isSelected,
          selectedTileColor:
              theme.colorScheme.primaryContainer.withOpacity(0.3),
          leading: _buildThumbnail(character, theme),
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
                  Icons.star,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('作品: ${character.title}'),
              if (character.author != null) Text('作者: ${character.author}'),
              Text('收集时间: ${_formatDateTime(character.collectionTime)}'),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBatchMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onCharacterSelect(character.id),
                )
              else ...[
                IconButton(
                  onPressed: () => onToggleFavorite(character.id),
                  icon: Icon(
                    character.isFavorite ? Icons.star : Icons.star_border,
                    color:
                        character.isFavorite ? theme.colorScheme.primary : null,
                  ),
                  tooltip: character.isFavorite ? '取消收藏' : '收藏',
                ),
                IconButton(
                  onPressed: () => onEdit(character.id),
                  icon: const Icon(Icons.edit),
                  tooltip: '编辑',
                ),
                IconButton(
                  onPressed: () => onDelete(character.id),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '删除',
                  color: theme.colorScheme.error,
                ),
              ],
            ],
          ),
          onTap: () {
            if (isBatchMode) {
              onCharacterSelect(character.id);
            } else {
              onCharacterSelect(character.id);
            }
          },
          isThreeLine: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingMedium,
            vertical: AppSizes.spacingSmall,
          ),
        );
      },
    );
  }

  Widget _buildErrorThumbnail(CharacterView character, ThemeData theme) {
    return Container(
      width: 50,
      height: 50,
      color: theme.colorScheme.surfaceContainerLowest,
      child: Center(
        child: Text(
          character.character,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(CharacterView character, ThemeData theme) {
    if (character.thumbnailPath.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        color: theme.colorScheme.surfaceContainerLowest,
        child: Center(
          child: Text(
            character.character,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    final file = File(character.thumbnailPath);
    return SizedBox(
      width: 50,
      height: 50,
      child: FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          final fileExists = snapshot.data ?? false;

          if (fileExists) {
            return Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  _buildErrorThumbnail(character, theme),
            );
          }

          return _buildErrorThumbnail(character, theme);
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays < 1) {
      return '今天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 2) {
      return '昨天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return DateFormat('yyyy年MM月dd日').format(dateTime);
    }
  }
}
