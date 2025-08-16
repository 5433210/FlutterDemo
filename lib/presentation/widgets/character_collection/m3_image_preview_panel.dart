import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/logging/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/character/work_image_provider.dart';
import 'adaptive_image_view.dart';
import 'm3_thumbnail_list.dart';

class M3ImagePreviewPanel extends ConsumerStatefulWidget {
  const M3ImagePreviewPanel({super.key});

  @override
  ConsumerState<M3ImagePreviewPanel> createState() =>
      _M3ImagePreviewPanelState();
}

class _M3ImagePreviewPanelState extends ConsumerState<M3ImagePreviewPanel> {
  final FocusNode _panelFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final imageState = ref.watch(workImageProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Main image area - 移除了工具栏
        Expanded(
          child: MouseRegion(
            onEnter: (_) {
              if (!_panelFocusNode.hasFocus) {
                _panelFocusNode.requestFocus();
                AppLogger.debug(
                    'Image preview panel gained focus from mouse enter');

                // Also request focus for the AdaptiveImageView
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    // 直接使用FocusScope来请求焦点
                    // final currentFocus = FocusScope.of(context);
                    // if (!currentFocus.hasPrimaryFocus) {
                    //   currentFocus.requestFocus();
                    // }
                  }
                });
              }
            },
            onHover: (_) {
              // Ensure panel has focus when mouse is hovering
              if (!_panelFocusNode.hasFocus) {
                _panelFocusNode.requestFocus();
              }
            },
            child: Focus(
              focusNode: _panelFocusNode,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image view - 使用自适应实现
                  const AdaptiveImageView(),

                  // Loading indicator
                  if (imageState.loading)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.scrim.withAlpha(179),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                                color: colorScheme.onSurface),
                            const SizedBox(height: 16),
                            Text(
                              l10n.loadingImage,
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
                          color: colorScheme.error.withAlpha(230),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                color: colorScheme.onError, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              l10n.error(imageState.error!),
                              style: TextStyle(color: colorScheme.onError),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () =>
                                  ref.read(workImageProvider.notifier).reload(),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Thumbnail list
        if (imageState.pageIds.length > 1) const M3ThumbnailList(),
      ],
    );
  }

  @override
  void dispose() {
    _panelFocusNode.removeListener(_onFocusChange);
    _panelFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // _panelFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_panelFocusNode.hasFocus) {
      AppLogger.debug('M3ImagePreviewPanel gained focus');

      // Request focus for the AdaptiveImageView when the panel gets focus
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // 直接使用FocusScope来请求焦点
          final currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.requestFocus();
            AppLogger.debug(
                'Requested focus using FocusScope from panel focus change');
          }
        }
      });
    }
  }
}
