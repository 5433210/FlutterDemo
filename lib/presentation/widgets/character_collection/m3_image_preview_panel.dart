import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/character/tool_mode_provider.dart';
import '../../providers/character/work_image_provider.dart';
import 'm3_image_view.dart';
import 'm3_preview_toolbar.dart';
import 'm3_thumbnail_list.dart';

class M3ImagePreviewPanel extends ConsumerWidget {
  const M3ImagePreviewPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final imageState = ref.watch(workImageProvider);
    final toolMode = ref.watch(toolModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Toolbar
        const M3PreviewToolbar(),
        // Main image area
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image view
              const M3ImageView(),

              // Loading indicator
              if (imageState.loading)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.scrim.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: colorScheme.onSurface),
                        const SizedBox(height: 16),
                        Text(
                          l10n.characterCollectionLoadingImage,
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),

              // Error message
              if (imageState.error != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            color: colorScheme.onError, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          l10n.characterCollectionError(imageState.error!),
                          style: TextStyle(color: colorScheme.onError),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () =>
                              ref.read(workImageProvider.notifier).reload(),
                          child: Text(l10n.characterCollectionRetry),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Thumbnail list
        if (imageState.pageIds.length > 1) const M3ThumbnailList(),
      ],
    );
  }
}
