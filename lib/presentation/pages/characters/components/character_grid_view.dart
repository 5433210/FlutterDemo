import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    // Calculate responsive grid settings
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;

    if (width > 600) crossAxisCount = 3;
    if (width > 900) crossAxisCount = 4;
    if (width > 1200) crossAxisCount = 5;
    if (width > 1500) crossAxisCount = 6;

    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSizes.spacingMedium,
        mainAxisSpacing: AppSizes.spacingMedium,
        childAspectRatio: 0.8, // Card is slightly taller than wide
      ),
      itemCount: characters.length,
      itemBuilder: (context, index) {
        final character = characters[index];
        final isSelected = selectedCharacters.contains(character.id);

        return CharacterCard(
          character: character,
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
  }
}
