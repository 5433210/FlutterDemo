import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/work_image_provider.dart';

class M3ThumbnailList extends ConsumerWidget {
  const M3ThumbnailList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageState = ref.watch(workImageProvider);
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        children: [
          // Page indicator
          Container(
            padding: const EdgeInsets.all(4),
            alignment: Alignment.center,
            child: Text(
              '${imageState.pageIds.indexOf(imageState.currentPageId) + 1}/${imageState.pageIds.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          // Thumbnail list
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final ScrollController controller = ScrollController();
                return Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      final double scrollAmount = pointerSignal.scrollDelta.dy;
                      controller.position.moveTo(
                        controller.offset + scrollAmount,
                        curve: Curves.linear,
                        duration: const Duration(milliseconds: 100),
                      );
                    }
                  },
                  child: ListView.builder(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    itemCount: imageState.pageIds.length,
                    itemBuilder: (context, index) {
                      final pageId = imageState.pageIds[index];
                      final isSelected = pageId == imageState.currentPageId;

                      return _M3ThumbnailItem(
                        pageId: pageId,
                        index: index + 1,
                        isSelected: isSelected,
                        onTap: () async {
                          final notifier = ref.read(workImageProvider.notifier);
                          // Change page
                          await notifier.changePage(pageId);
                          // Load regions for this page
                          await ref
                              .read(characterCollectionProvider.notifier)
                              .loadWorkData(
                                imageState.workId,
                                pageId: pageId,
                              );
                          // Clear selected regions
                          ref
                              .read(characterCollectionProvider.notifier)
                              .clearSelectedRegions();
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Navigation buttons
          if (imageState.pageIds.length > 1)
            Row(
              children: [
                // Previous page
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: imageState.hasPrevious
                      ? () async {
                          // Switch page first
                          await ref
                              .read(workImageProvider.notifier)
                              .previousPage();

                          // Get updated state
                          final updatedState = ref.read(workImageProvider);

                          // Load regions for this page
                          await ref
                              .read(characterCollectionProvider.notifier)
                              .loadWorkData(
                                updatedState.workId,
                                pageId: updatedState.currentPageId,
                              );
                          // Clear selected regions
                          ref
                              .read(characterCollectionProvider.notifier)
                              .clearSelectedRegions();
                        }
                      : null,
                  tooltip: l10n.characterCollectionPreviousPage,
                ),

                // Next page
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: imageState.hasNext
                      ? () async {
                          // Switch page first
                          await ref.read(workImageProvider.notifier).nextPage();

                          // Get updated state
                          final updatedState = ref.read(workImageProvider);

                          // Load regions for this page
                          await ref
                              .read(characterCollectionProvider.notifier)
                              .loadWorkData(
                                updatedState.workId,
                                pageId: updatedState.currentPageId,
                              );
                          // Clear selected regions
                          ref
                              .read(characterCollectionProvider.notifier)
                              .clearSelectedRegions();
                        }
                      : null,
                  tooltip: l10n.characterCollectionNextPage,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _M3ThumbnailItem extends ConsumerWidget {
  final String pageId;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _M3ThumbnailItem({
    required this.pageId,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final imageState = ref.watch(workImageProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Actual thumbnail
            FutureBuilder<String?>(
              future:
                  ref.read(workImageProvider.notifier).getThumbnailPath(pageId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(
                      File(snapshot.data!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.broken_image_outlined,
                          size: 24,
                          color: theme.colorScheme.error,
                        );
                      },
                    ),
                  );
                }
                return Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 24,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),

            // Page number indicator
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(7),
                    bottomRight: Radius.circular(7),
                  ),
                ),
                child: Text(
                  '$index',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ),

            // Loading indicator
            if (isSelected && imageState.loading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.scrim.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
