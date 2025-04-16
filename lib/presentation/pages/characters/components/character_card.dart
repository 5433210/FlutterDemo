import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../domain/models/character/character_view.dart';
import '../../../../theme/app_sizes.dart';

class CharacterCard extends StatelessWidget {
  final CharacterView character;
  final String? thumbnailPath;
  final bool isSelected;
  final bool isBatchMode;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;
  final bool isInSelectionMode;

  const CharacterCard({
    super.key,
    required this.character,
    required this.isSelected,
    required this.onTap,
    this.onToggleFavorite,
    this.isBatchMode = false,
    this.isInSelectionMode = false,
    this.thumbnailPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation:
          isSelected ? AppSizes.cardElevation * 2 : AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              minWidth: 200, minHeight: 280, maxHeight: 280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Character image container with strict aspect ratio and explicit height
              Expanded(
                flex: 4, // Image takes more space
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSizes.cardRadius - 1),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Character image
                        _buildCharacterImage(theme),

                        // Selection indicator for batch mode
                        if (isBatchMode)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: theme.colorScheme.onPrimary,
                                      size: 14,
                                    )
                                  : null,
                            ),
                          ),

                        // Favorite indicator (not in batch mode)
                        if (!isBatchMode && character.isFavorite)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surface.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.star,
                                color: theme.colorScheme.primary,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Text information - strictly sized and constrained
              Container(
                height: 72,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingSmall, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Character text with overflow protection
                    Text(
                      character.character,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 1), // Minimal spacing

                    // Title with overflow protection
                    Text(
                      character.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11, // Smaller font to fit
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Author with overflow protection
                    if (character.author != null &&
                        character.author!.isNotEmpty)
                      Text(
                        character.author!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.8),
                          fontSize: 10, // Even smaller font for author
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterImage(ThemeData theme) {
    if (thumbnailPath == null || thumbnailPath!.isEmpty) {
      return Container(
        color: theme.colorScheme.surfaceContainerLowest,
        child: Center(
          child: Text(
            character.character,
            style: theme.textTheme.displayMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    final file = File(thumbnailPath!);
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        final fileExists = snapshot.data ?? false;

        if (fileExists) {
          return Container(
            color: theme.colorScheme.surfaceContainerLowest,
            child: Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (ctx, error, _) => _buildErrorImage(theme),
            ),
          );
        }

        return _buildErrorImage(theme);
      },
    );
  }

  Widget _buildErrorImage(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            character.character,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            Icons.broken_image,
            color: theme.colorScheme.error,
            size: 16,
          ),
        ],
      ),
    );
  }
}
