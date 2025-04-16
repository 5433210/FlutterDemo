import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../domain/models/character/character_view.dart';
import '../../../../theme/app_sizes.dart';

class CharacterCard extends StatelessWidget {
  final CharacterView character;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Character preview image area
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  // Character image
                  Positioned.fill(
                    child: _buildCharacterImage(theme),
                  ),

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
                          color: theme.colorScheme.surface.withOpacity(0.7),
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

            // Character information - Wrap in Expanded to prevent overflow
            Flexible(
              fit: FlexFit.tight,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacingSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Use minimum space needed
                  children: [
                    // Character text
                    Text(
                      character.character,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),

                    const SizedBox(height: 2), // Reduced vertical spacing

                    // Work name
                    Text(
                      character.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),

                    // Author name if available
                    if (character.author != null &&
                        character.author!.isNotEmpty)
                      Text(
                        character.author!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11, // Slightly smaller font for author
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterImage(ThemeData theme) {
    if (character.thumbnailPath.isEmpty) {
      return Container(
        color: theme.colorScheme.surfaceContainerLowest,
        child: Center(
          child: Text(
            character.character,
            style: theme.textTheme.displayMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    final file = File(character.thumbnailPath);
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        final fileExists = snapshot.data ?? false;

        if (fileExists) {
          return Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (ctx, error, _) => _buildErrorImage(theme),
          );
        }

        return _buildErrorImage(theme);
      },
    );
  }

  Widget _buildErrorImage(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              character.character,
              style: theme.textTheme.displayMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              Icons.broken_image,
              color: theme.colorScheme.error,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
