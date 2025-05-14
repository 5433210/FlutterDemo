import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

/// A panel that can be resized by dragging its edge.
class ResizablePanel extends StatefulWidget {
  /// The child widget to display inside the panel.
  final Widget child;

  /// The initial width of the panel.
  final double initialWidth;

  /// The minimum width the panel can be resized to.
  final double minWidth;

  /// The maximum width the panel can be resized to.
  final double maxWidth;

  /// Whether the panel is on the left side (true) or right side (false).
  final bool isLeftPanel;

  /// Callback when the panel width changes.
  final Function(double)? onWidthChanged;

  /// Creates a resizable panel.
  const ResizablePanel({
    Key? key,
    required this.child,
    this.initialWidth = AppSizes.filterPanelWidth,
    this.minWidth = 200.0,
    this.maxWidth = 600.0,
    this.isLeftPanel = true,
    this.onWidthChanged,
  }) : super(key: key);

  @override
  State<ResizablePanel> createState() => _ResizablePanelState();
}

class _ResizablePanelState extends State<ResizablePanel> {
  late double _width;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
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
    _width = widget.initialWidth;
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
      if (widget.isLeftPanel) {
        _width += details.delta.dx;
      } else {
        _width -= details.delta.dx;
      }

      // Constrain the width to the min and max values
      _width = _width.clamp(widget.minWidth, widget.maxWidth);

      // Notify the parent about the width change
      widget.onWidthChanged?.call(_width);
    });

    // Request a layout update to ensure proper resizing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }
}
