import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/services/services.dart';
import '../../../../domain/models/character/character_image_type.dart';
import '../../../../domain/models/character/character_view.dart';
import '../../../../theme/app_sizes.dart';
import 'character_card.dart';

/// Grid view for displaying character cards
class CharacterGridView extends ConsumerWidget {
  /// Characters to display
  final List<CharacterView> characters;

  /// Whether batch selection mode is active
  final bool isBatchMode;

  /// Set of selected character IDs
  final Set<String> selectedCharacters;

  /// Callback when a character is tapped
  final void Function(String) onCharacterTap;

  /// Callback when a character's favorite status is toggled
  final void Function(String)? onToggleFavorite;

  /// Whether the view is in loading state
  final bool isLoading;

  /// Error message to display (if any)
  final String? errorMessage;

  /// Constructor
  const CharacterGridView({
    super.key,
    required this.characters,
    required this.onCharacterTap,
    this.isBatchMode = false,
    this.selectedCharacters = const {},
    this.onToggleFavorite,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              color: Theme.of(context).colorScheme.outline,
              size: 48,
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            Text(
              '没有找到匹配的字符',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    // Calculate grid settings based on available width
    return LayoutBuilder(
      builder: (context, constraints) {
        // Each card has a minimum width of 280 pixels
        const minCardWidth = 180.0;
        final availableWidth = constraints.maxWidth;

        // Calculate how many cards can fit in the available width
        int crossAxisCount = (availableWidth / minCardWidth).floor();
        // Ensure at least 1 card and no more than 6 cards per row
        crossAxisCount = crossAxisCount.clamp(1, 6);

        return GridView.builder(
          padding: const EdgeInsets.all(AppSizes.spacingMedium),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSizes.spacingMedium,
            mainAxisSpacing: AppSizes.spacingMedium,
            childAspectRatio: 0.71, // Match card's aspect ratio (280/390)
          ),
          itemCount: characters.length,
          itemBuilder: (context, index) {
            final character = characters[index];
            final isSelected = selectedCharacters.contains(character.id);

            // Use FutureBuilder to handle the async operation
            return FutureBuilder<String>(
              future: ref.read(characterServiceProvider).getCharacterImagePath(
                  character.id, CharacterImageType.thumbnail),
              builder: (context, snapshot) {
                return CharacterCard(
                  character: character,
                  thumbnailPath: snapshot.data,
                  isSelected: isSelected,
                  isBatchMode: isBatchMode,
                  onTap: () {
                    if (isBatchMode) {
                      // In batch mode, tapping toggles selection
                      onCharacterTap(character.id);
                    } else {
                      // In normal mode, tapping opens details
                      onCharacterTap(character.id);
                    }
                  },
                  onToggleFavorite: onToggleFavorite != null
                      ? () => onToggleFavorite!(character.id)
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }
}
