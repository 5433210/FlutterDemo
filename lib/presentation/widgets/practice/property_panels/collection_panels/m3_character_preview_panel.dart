import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../application/providers/service_providers.dart';
import '../../../../../l10n/app_localizations.dart';

/// Material 3 character preview panel
class M3CharacterPreviewPanel extends ConsumerWidget {
  final Map<String, dynamic> element;
  final int selectedCharIndex;
  final Function(int) onCharacterSelected;

  const M3CharacterPreviewPanel({
    Key? key,
    required this.element,
    required this.selectedCharIndex,
    required this.onCharacterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final content = element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    final wordMatchingMode = content['wordMatchingPriority'] as bool? ?? false;
    final segments = content['segments'] as List<dynamic>? ?? [];

    // Debug: Log current preview panel state
    print('[WORD_MATCHING_DEBUG] === M3CharacterPreviewPanel Debug ===');
    print('[WORD_MATCHING_DEBUG] characters: "$characters"');
    print('[WORD_MATCHING_DEBUG] wordMatchingMode: $wordMatchingMode');
    print('[WORD_MATCHING_DEBUG] segments: $segments');
    print('[WORD_MATCHING_DEBUG] segments.length: ${segments.length}');

    // Show empty state when no characters available
    if (characters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest
              .withAlpha((0.3 * 255).toInt()),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Center(
          child: Text(
            l10n.noCharacters,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Character preview grid
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color:
            colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: _buildPreviewItems(
          context,
          ref,
          characters,
          wordMatchingMode,
          segments,
        ),
      ),
    );
  }

  /// Build preview items based on matching mode
  List<Widget> _buildPreviewItems(
    BuildContext context,
    WidgetRef ref,
    String characters,
    bool wordMatchingMode,
    List<dynamic> segments,
  ) {
    print('[WORD_MATCHING_DEBUG] === _buildPreviewItems Debug ===');
    print('[WORD_MATCHING_DEBUG] wordMatchingMode: $wordMatchingMode');
    print('[WORD_MATCHING_DEBUG] segments.isNotEmpty: ${segments.isNotEmpty}');

    if (wordMatchingMode && segments.isNotEmpty) {
      // Word matching mode: group characters by segments
      print(
          '[WORD_MATCHING_DEBUG] Using word matching mode - building segment tiles');
      final items = <Widget>[];

      for (int segmentIndex = 0;
          segmentIndex < segments.length;
          segmentIndex++) {
        final segment = segments[segmentIndex] as Map<String, dynamic>;
        final text = segment['text'] as String;
        final startIndex = segment['startIndex'] as int;

        print(
            '[WORD_MATCHING_DEBUG] Segment $segmentIndex: text="$text", startIndex=$startIndex');

        // For single character segments, show character image
        if (text.length == 1) {
          print(
              '[WORD_MATCHING_DEBUG] Building character tile for single char: "$text"');
          items.add(_buildCharacterTile(
            context,
            ref,
            startIndex,
            text,
          ));
        } else {
          // For multi-character segments, show as a group
          print(
              '[WORD_MATCHING_DEBUG] Building segment tile for multi-char: "$text"');
          items.add(_buildSegmentTile(
            context,
            ref,
            segmentIndex,
            text,
            startIndex,
          ));
        }
      }

      print('[WORD_MATCHING_DEBUG] Total items built: ${items.length}');
      return items;
    } else {
      // Character matching mode: show each character individually
      print(
          '[WORD_MATCHING_DEBUG] Using character matching mode - building individual character tiles');
      final items = List.generate(
        characters.characters.length,
        (index) => _buildCharacterTile(
          context,
          ref,
          index,
          characters.characters.elementAt(index),
        ),
      );
      print(
          '[WORD_MATCHING_DEBUG] Total character tiles built: ${items.length}');
      return items;
    }
  }

  /// Build segment tile for multi-character segments
  Widget _buildSegmentTile(
    BuildContext context,
    WidgetRef ref,
    int segmentIndex,
    String segmentText,
    int startIndex,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Check if this segment contains the selected character
    final isSelected = selectedCharIndex >= startIndex &&
        selectedCharIndex < startIndex + segmentText.length;

    return GestureDetector(
      onTap: () => onCharacterSelected(startIndex),
      child: Container(
        width: 80, // 调整回原始宽度，因为现在只显示文本
        height: 60, // 调整回原始高度
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 显示分段文本（作为整体）
            Expanded(
              child: Center(
                child: Text(
                  segmentText,
                  style: textTheme.bodyLarge?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : colorScheme.outline,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '词组',
                style: textTheme.labelSmall?.copyWith(
                  color:
                      isSelected ? colorScheme.onPrimary : colorScheme.surface,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build character image from memory or show character text
  Widget _buildCharacterImage(
    BuildContext context,
    WidgetRef ref,
    String character, {
    bool isSelected = false,
    int? index,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final idx = index ?? selectedCharIndex;
    final content = element['content'] as Map<String, dynamic>? ?? {};
    final characterImages =
        content['characterImages'] as Map<String, dynamic>? ?? {};

    // If we have image info for this character
    if (characterImages.containsKey('$idx')) {
      final imageInfo = characterImages['$idx'] as Map<String, dynamic>;
      final characterId = imageInfo['characterId'] as String?;
      final type = imageInfo['type'] as String?;
      final format = imageInfo['format'] as String?;

      if (characterId != null && type != null && format != null) {
        return FutureBuilder<Uint8List?>(
          future: Future.any([
            ref
                .read(characterImageServiceProvider)
                .getCharacterImage(characterId, type, format),
            // Add a 3-second timeout
            Future.delayed(const Duration(seconds: 3), () => null),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.secondary,
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return _buildDefaultCharacterText(context, character, isSelected);
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
                color: isSelected
                    ? colorScheme.primary.withAlpha((0.2 * 255).toInt())
                    : null,
                colorBlendMode: isSelected ? BlendMode.srcATop : null,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultCharacterText(
                      context, character, isSelected);
                },
              ),
            );
          },
        );
      }
    }

    return _buildDefaultCharacterText(context, character, isSelected);
  }

  /// Builds a single character tile
  Widget _buildCharacterTile(
      BuildContext context, WidgetRef ref, int index, String character) {
    final colorScheme = Theme.of(context).colorScheme;

    final isSelected = selectedCharIndex == index;

    return InkWell(
      onTap: () => onCharacterSelected(index),
      borderRadius: BorderRadius.circular(8.0),
      child: Ink(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color:
              isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color:
                isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: _buildCharacterImage(context, ref, character,
            isSelected: isSelected, index: index),
      ),
    );
  }

  /// Build default text representation of character
  Widget _buildDefaultCharacterText(
      BuildContext context, String character, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Text(
        character,
        style: textTheme.headlineMedium?.copyWith(
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
