import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_sizes.dart';
import '../../providers/persistent_panel_provider.dart';

/// A panel that can be resized by dragging its edge with persistent state.
/// The panel width will be remembered between app sessions.
class PersistentResizablePanel extends ConsumerStatefulWidget {
  /// Unique identifier for this panel to persist its state
  final String panelId;

  /// The child widget to display inside the panel.
  final Widget child;

  /// The initial width of the panel (used if no saved state exists).
  final double initialWidth;

  /// The minimum width the panel can be resized to.
  final double minWidth;

  /// The maximum width the panel can be resized to.
  final double maxWidth;

  /// Whether the panel is on the left side (true) or right side (false).
  final bool isLeftPanel;

  /// Callback when the panel width changes.
  final Function(double)? onWidthChanged;

  /// Creates a persistent resizable panel.
  const PersistentResizablePanel({
    Key? key,
    required this.panelId,
    required this.child,
    this.initialWidth = AppSizes.filterPanelWidth,
    this.minWidth = 200.0,
    this.maxWidth = 600.0,
    this.isLeftPanel = true,
    this.onWidthChanged,
  }) : super(key: key);

  @override
  ConsumerState<PersistentResizablePanel> createState() =>
      _PersistentResizablePanelState();
}

class _PersistentResizablePanelState
    extends ConsumerState<PersistentResizablePanel> {
  double? _width;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    // Watch for width changes from the provider
    final persistentWidth = ref.watch(panelWidthProvider((
      panelId: widget.panelId,
      defaultWidth: widget.initialWidth,
    )));

    // Use persistent width as the current width
    final currentWidth = _width ?? persistentWidth;

    return SizedBox(
      width: currentWidth,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // The panel content with available width constraints
              SizedBox(
                width: constraints.maxWidth,
                child: widget.child,
              ),

              // The resize handle
              Positioned(
                top: 0,
                bottom: 0,
                right: widget.isLeftPanel ? 0 : null,
                left: widget.isLeftPanel ? null : 0,
                child: GestureDetector(
                  onHorizontalDragStart: _handleDragStart,
                  onHorizontalDragUpdate: _handleDragUpdate,
                  onHorizontalDragEnd: _handleDragEnd,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: Container(
                      width: 8.0,
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          width: 4.0,
                          height: 30.0,
                          decoration: BoxDecoration(
                            color: _isDragging
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Width will be initialized from persistent state in build method
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      // Get current width (from local state or persistent state)
      final persistentWidth = ref.read(panelWidthProvider((
        panelId: widget.panelId,
        defaultWidth: widget.initialWidth,
      )));

      double currentWidth = _width ?? persistentWidth;

      if (widget.isLeftPanel) {
        currentWidth += details.delta.dx;
      } else {
        currentWidth -= details.delta.dx;
      }

      // Constrain the width to the min and max values
      currentWidth = currentWidth.clamp(widget.minWidth, widget.maxWidth);

      // Update local width
      _width = currentWidth;

      // Persist the new width
      ref
          .read(persistentPanelProvider.notifier)
          .setPanelWidth(widget.panelId, currentWidth);

      // Notify the parent about the width change
      widget.onWidthChanged?.call(currentWidth);
    });

    // Request a layout update to ensure proper resizing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }
}
