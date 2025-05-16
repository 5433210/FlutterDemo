import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';
import '../../viewmodels/states/character_grid_state.dart';
import '../image/cached_image.dart';

class M3CharacterTile extends StatelessWidget {
  final CharacterViewModel character;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const M3CharacterTile({
    super.key,
    required this.character,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Character image
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildImage(context),
                  ),
                ),

                // Character info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(7.0),
                      bottomRight: Radius.circular(7.0),
                    ),
                  ),
                  child: Text(
                    character.character.isEmpty
                        ? l10n.characterCollectionNoCharacter
                        : character.character,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),

            // Selection indicator
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),

            // Favorite indicator
            if (character.isFavorite)
              Positioned(
                top: AppSizes.s,
                left: AppSizes.s,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.favorite,
                    size: AppSizes.iconMedium,
                    color: colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    // Try to load the thumbnail
    try {
      return CachedImage(
        path: character.thumbnailPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(context);
        },
      );
    } catch (e) {
      return _buildPlaceholder(context);
    }
  }

  Widget _buildPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 32,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
