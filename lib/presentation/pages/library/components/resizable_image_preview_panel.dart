import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/library_item.dart';
import '../../../widgets/common/advanced_image_preview.dart';

// State provider for the resizable image preview panel's height
final imagePreviewPanelHeightProvider = StateProvider<double>((ref) => 300);

/// A resizable image preview panel for the library management page
class ResizableImagePreviewPanel extends ConsumerStatefulWidget {
  /// The library item to preview
  final LibraryItem? selectedItem;

  /// Whether the preview panel is visible
  final bool isVisible;

  /// The callback for when the user wants to close the panel
  final VoidCallback? onClose;

  /// Creates a resizable image preview panel
  const ResizableImagePreviewPanel({
    super.key,
    required this.selectedItem,
    required this.isVisible,
    this.onClose,
  });

  @override
  ConsumerState<ResizableImagePreviewPanel> createState() =>
      _ResizableImagePreviewPanelState();
}

class _ResizableImagePreviewPanelState
    extends ConsumerState<ResizableImagePreviewPanel> {
  /// Whether the user is currently dragging the resize handle
  bool _isDragging = false;

  /// The last position where the drag happened
  Offset? _lastDragPosition;

  /// Whether the panel has a dark background
  bool _isDarkBackground = false;

  @override
  Widget build(BuildContext context) {
    // If panel is not visible or no item is selected, return an empty container
    if (!widget.isVisible || widget.selectedItem == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final currentHeight = ref.watch(imagePreviewPanelHeightProvider);

    // Ensure the panel doesn't get too small or too large
    // Use MediaQuery to make sure the panel isn't too large for the current window
    final maxAllowedHeight =
        MediaQuery.of(context).size.height * 0.6; // Max 60% of window height
    final safeHeight = currentHeight.clamp(100.0, maxAllowedHeight);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: safeHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top toolbar with controls
          _buildToolbar(theme),

          // Preview content area
          Expanded(
            child: _buildPreviewContent(),
          ),

          // Resize handle
          _buildResizeHandle(theme),
        ],
      ),
    );
  }

  @override
  void deactivate() {
    // Save current height when deactivated (but before dispose)
    // This is a safer place to use ref than in dispose()
    final height = ref.read(imagePreviewPanelHeightProvider);
    ref.read(imagePreviewPanelHeightProvider.notifier).state = height;
    super.deactivate();
  }

  @override
  void didUpdateWidget(ResizableImagePreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the selected item changes, we may need to reset states
    if (widget.selectedItem?.id != oldWidget.selectedItem?.id) {
      // New image selected, reset zoom if needed
      _resetZoom();

      // Print debug info to confirm we detected the change
      print(
          '【ResizableImagePreviewPanel】Image changed: ${oldWidget.selectedItem?.fileName} -> ${widget.selectedItem?.fileName}');
    }

    // If visibility changes, animate properly
    if (widget.isVisible != oldWidget.isVisible) {
      // Could add additional animation logic here if needed
    }
  }

  @override
  void dispose() {
    // No longer try to read or update the provider in dispose()
    // This avoids "Cannot use ref after widget was disposed" errors
    super.dispose();
  }

  /// Builds the main content area with the image preview
  Widget _buildPreviewContent() {
    if (widget.selectedItem?.thumbnail == null) {
      return const Center(
        child: Text('No preview available'),
      );
    }

    // Get the library item's image path
    final imagePath = widget.selectedItem!.path;
    final itemId = widget.selectedItem!.id;

    print(
        '【ResizableImagePreviewPanel】Building preview for: ${widget.selectedItem!.fileName} (ID: $itemId)');
    return Container(
      color: _isDarkBackground ? Colors.black : Colors.white,
      child: AdvancedImagePreview(
        // Use a ValueKey with the selectedItem's ID to ensure rebuild when a new image is selected
        key: ValueKey(itemId),
        imagePaths: [imagePath],
        initialIndex: 0,
        enableZoom: true,
        showThumbnails: false,
        previewDecoration: BoxDecoration(
          color: _isDarkBackground ? Colors.black : Colors.white,
          border: Border.all(color: Colors.transparent),
        ),
      ),
    );
  }

  /// Builds the resize handle at the bottom of the panel
  Widget _buildResizeHandle(ThemeData theme) {
    return GestureDetector(
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeUpDown,
        child: Container(
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: Container(
              width: 30,
              height: 4,
              decoration: BoxDecoration(
                color: _isDragging
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the toolbar with controls for the preview panel
  Widget _buildToolbar(ThemeData theme) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.selectedItem?.fileName ?? '',
              style: theme.textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              // Toggle background color button
              IconButton(
                icon: const Icon(Icons.brightness_6, size: 20),
                tooltip: '切换背景',
                onPressed: _toggleBackgroundColor,
              ),

              // Reset zoom button
              IconButton(
                icon: const Icon(Icons.zoom_out_map, size: 20),
                tooltip: '重置缩放',
                onPressed: _resetZoom,
              ),

              // Full screen button
              IconButton(
                icon: const Icon(Icons.fullscreen, size: 20),
                tooltip: '全屏显示',
                onPressed: _openFullScreen,
              ),

              // Close button
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: '关闭',
                onPressed: widget.onClose,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Handles the end of a drag operation on the resize handle
  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _lastDragPosition = null;
    });
  }

  // Action handlers for toolbar buttons

  /// Handles the start of a drag operation on the resize handle
  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _lastDragPosition = details.globalPosition;
    });
  }

  /// Handles the drag update on the resize handle
  void _handleDragUpdate(DragUpdateDetails details) {
    if (_lastDragPosition == null) return;

    // Calculate the change in position
    final delta = details.globalPosition.dy - _lastDragPosition!.dy;
    _lastDragPosition = details.globalPosition;

    // Update the height using Riverpod
    final currentHeight = ref.read(imagePreviewPanelHeightProvider);
    ref.read(imagePreviewPanelHeightProvider.notifier).state =
        currentHeight + delta;
  }

  /// Opens the image in full screen mode
  void _openFullScreen() {
    if (widget.selectedItem == null) return;

    // Show the image in fullscreen using an existing dialog or component
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Stack(
          children: [
            // Full screen preview
            AdvancedImagePreview(
              imagePaths: [widget.selectedItem!.path],
              initialIndex: 0,
              enableZoom: true,
              showThumbnails: true, // Enable thumbnails in full screen mode
              isFullScreen: true,
              previewDecoration: const BoxDecoration(
                color: Colors.black,
              ),
            ),

            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Resets the zoom level of the image
  void _resetZoom() {
    // The AdvancedImagePreview has internal zoom management
    // We can use a rebuild to reset it to default state
    print('【ResizableImagePreviewPanel】Resetting zoom state');
    setState(() {
      // Force a complete rebuild of the preview component
    });
  }

  /// Toggles the background color (light/dark)
  void _toggleBackgroundColor() {
    setState(() {
      _isDarkBackground = !_isDarkBackground;
    });
  }
}
