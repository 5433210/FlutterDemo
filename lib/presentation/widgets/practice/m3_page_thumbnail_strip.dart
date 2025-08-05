import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../l10n/app_localizations.dart';
import 'page_operations.dart';

/// Material 3 version of the page thumbnail strip
class M3PageThumbnailStrip extends StatefulWidget {
  final List<Map<String, dynamic>> pages;
  final int currentPageIndex;
  final Function(int) onPageSelected;
  final VoidCallback onAddPage;
  final Function(int) onDeletePage;
  final Function(int, int)? onReorderPages;

  const M3PageThumbnailStrip({
    super.key,
    required this.pages,
    required this.currentPageIndex,
    required this.onPageSelected,
    required this.onAddPage,
    required this.onDeletePage,
    this.onReorderPages,
  });

  @override
  State<M3PageThumbnailStrip> createState() => _M3PageThumbnailStripState();
}

class _M3PageThumbnailStripState extends State<M3PageThumbnailStrip> {
  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  // Scroll multiplier
  final double _scrollMultiplier = 3.0;

  // Scroll animation duration
  final Duration _scrollAnimationDuration = const Duration(milliseconds: 200);

  // Drag scroll variables
  bool _isDraggingStrip = false;
  double _dragStartX = 0.0;
  double _scrollStartOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 120,
      color: colorScheme.surfaceContainerLow,
      child: Material(
        color: colorScheme.surfaceContainerLow,
        child: GestureDetector(
          // Add drag scroll support
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: Listener(
            onPointerSignal: _handlePointerSignal,
            child: Row(
              children: [
                // Page thumbnail list
                Expanded(
                  child: widget.onReorderPages != null
                      ? _buildReorderablePageList(context)
                      : _buildSimplePageList(context),
                ),

                // Add page button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onAddPage, // 簡化，直接呼叫回調
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add,
                            size: 24,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Build page thumbnail
  Widget _buildPageThumbnail(Map<String, dynamic> page, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Use PageOperations to get background color for consistency
    Color color = PageOperations.getPageBackgroundColor(page);

    // Get page elements
    final elements = page['elements'] as List<dynamic>? ?? [];

    return Container(
      color: color,
      child: elements.isNotEmpty
          ? Center(
              child: Text(
                l10n.preview,
                style: const TextStyle(fontSize: 10),
              ),
            )
          : Center(
              child: Text(
                l10n.empty,
                style: const TextStyle(fontSize: 10),
              ),
            ),
    );
  }

  Widget _buildReorderablePageList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      scrollController: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      proxyDecorator: (child, index, animation) {
        // Add nice visual effect during drag
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final double animValue =
                Curves.easeInOut.transform(animation.value);
            final double elevation = lerpDouble(0, 6, animValue)!;
            final double scale = lerpDouble(1, 1.05, animValue)!;

            return Material(
              elevation: elevation,
              color: Colors.transparent,
              shadowColor: colorScheme.shadow,
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (widget.onReorderPages != null) {
          try {
            widget.onReorderPages!(oldIndex, newIndex);
            
            EditPageLogger.editPageInfo(
              '頁面排序成功',
              data: {
                'fromIndex': oldIndex,
                'toIndex': newIndex,
              },
            );
          } catch (error, stackTrace) {
            EditPageLogger.editPageError(
              '頁面排序失敗',
              error: error,
              stackTrace: stackTrace,
              data: {
                'fromIndex': oldIndex,
                'toIndex': newIndex,
              },
            );
          }
        }
      },
      itemCount: widget.pages.length,
      itemBuilder: (context, index) {
        final page = widget.pages[index];
        final isSelected = index == widget.currentPageIndex;

        return Padding(
          key: ValueKey('page_${page['id']}'),
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => widget.onPageSelected(index), // 簡化選擇操作
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Stack(
                children: [
                  // Page thumbnail
                  Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.description,
                        size: 24,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  // Delete button
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, size: 18),
                      color: colorScheme.error,
                      onPressed: () => widget.onDeletePage(index),
                      splashRadius: 18,
                      tooltip: l10n.deletePage,
                    ),
                  ),

                  // Page number indicator
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withAlpha(179) // 0.7 opacity
                            : colorScheme.surfaceContainerHighest
                                .withAlpha(153), // 0.6 opacity
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(7),
                          bottomRight: Radius.circular(7),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimplePageList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.pages.length,
      itemBuilder: (context, index) {
        final page = widget.pages[index];
        final isSelected = index == widget.currentPageIndex;

        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => widget.onPageSelected(index), // 簡化選擇操作
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thumbnail
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary
                                  .withAlpha(77), // 0.3 opacity
                              spreadRadius: 1,
                              blurRadius: 4,
                            )
                          ]
                        : null,
                  ),
                  child: _buildPageThumbnail(page, context),
                ),

                const SizedBox(height: 4),

                // Page name and delete button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      page['name'] as String? ?? 'Page ${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (widget.pages.length > 1)
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 14, color: colorScheme.error),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => widget.onDeletePage(index),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Handle drag end
  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDraggingStrip = false;
    });
  }

  /// Handle drag start
  void _handleDragStart(DragStartDetails details) {
    if (!_scrollController.hasClients) return;

    setState(() {
      _isDraggingStrip = true;
      _dragStartX = details.globalPosition.dx;
      _scrollStartOffset = _scrollController.offset;
    });
  }

  /// Handle drag update
  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_scrollController.hasClients || !_isDraggingStrip) return;

    // Calculate drag distance
    final dragDelta = _dragStartX - details.globalPosition.dx;

    // Calculate new scroll position, constrained to valid range
    final newOffset = (_scrollStartOffset + dragDelta)
        .clamp(0.0, _scrollController.position.maxScrollExtent);

    // Jump to new position (no animation)
    _scrollController.jumpTo(newOffset);
  }

  /// Handle mouse wheel events
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Return if scroll controller is not ready
      if (!_scrollController.hasClients) return;

      // Calculate scroll delta, converting vertical scroll to horizontal
      final delta = event.scrollDelta;
      final adjustedDelta =
          (delta.dx != 0 ? delta.dx : delta.dy) * _scrollMultiplier;

      // Calculate new scroll position, constrained to valid range
      final newOffset = (_scrollController.offset + adjustedDelta)
          .clamp(0.0, _scrollController.position.maxScrollExtent);

      // Animate to new position
      _scrollController.animateTo(
        newOffset,
        duration: _scrollAnimationDuration,
        curve: Curves.easeOutCubic,
      );
    }
  }
}
