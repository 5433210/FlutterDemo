import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../integration/practice_canvas_integration.dart';

/// Enhanced gesture detector that works with Canvas integration
class CanvasGestureDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Function(DragStartDetails)? onPanStart;
  final Function(DragUpdateDetails)? onPanUpdate;
  final Function(DragEndDetails)? onPanEnd;
  final Function(LongPressStartDetails)? onLongPressStart;
  final HitTestBehavior? behavior;

  const CanvasGestureDetector({
    Key? key,
    required this.child,
    this.onTap,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onLongPressStart,
    this.behavior,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final integration = CanvasIntegrationProvider.of(context);

    return GestureDetector(
      onTap: () {
        onTap?.call();
      },
      onPanStart: (details) {
        integration?.handlePanStart(details);
        onPanStart?.call(details);
      },
      onPanUpdate: (details) {
        integration?.handlePanUpdate(details);
        onPanUpdate?.call(details);
      },
      onPanEnd: (details) {
        integration?.handlePanEnd(details);
        onPanEnd?.call(details);
      },
      onLongPressStart: (details) {
        integration?.handleLongPress(details);
        onLongPressStart?.call(details);
      },
      behavior: behavior ?? HitTestBehavior.translucent,
      child: child,
    );
  }
}

/// Widget that intercepts gestures and routes them through the new Canvas event system
/// while maintaining compatibility with existing widgets
class CanvasGestureInterceptor extends StatefulWidget {
  final Widget child;
  final PracticeCanvasIntegration integration;
  final bool enabled;

  const CanvasGestureInterceptor({
    Key? key,
    required this.child,
    required this.integration,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<CanvasGestureInterceptor> createState() =>
      _CanvasGestureInterceptorState();
}

/// Mixin for widgets that need Canvas integration
mixin CanvasIntegrationMixin<T extends StatefulWidget> on State<T> {
  PracticeCanvasIntegration? _integration;

  PracticeCanvasIntegration? get canvasIntegration => _integration;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _integration = CanvasIntegrationProvider.of(context);
  }
}

/// Widget that provides Canvas system integration context
class CanvasIntegrationProvider extends InheritedWidget {
  final PracticeCanvasIntegration integration;

  const CanvasIntegrationProvider({
    Key? key,
    required this.integration,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(CanvasIntegrationProvider oldWidget) {
    return integration != oldWidget.integration;
  }

  static PracticeCanvasIntegration? of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<CanvasIntegrationProvider>();
    return provider?.integration;
  }
}

/// Canvas keyboard shortcuts handler
class CanvasKeyboardHandler extends StatefulWidget {
  final Widget child;
  final PracticeCanvasIntegration? integration;

  const CanvasKeyboardHandler({
    Key? key,
    required this.child,
    this.integration,
  }) : super(key: key);

  @override
  State<CanvasKeyboardHandler> createState() => _CanvasKeyboardHandlerState();
}

/// Canvas-aware mouse region
class CanvasMouseRegion extends StatelessWidget {
  final Widget child;
  final MouseCursor cursor;
  final Function(PointerEnterEvent)? onEnter;
  final Function(PointerExitEvent)? onExit;
  final Function(PointerHoverEvent)? onHover;

  const CanvasMouseRegion({
    Key? key,
    required this.child,
    this.cursor = MouseCursor.defer,
    this.onEnter,
    this.onExit,
    this.onHover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final integration = CanvasIntegrationProvider.of(context);

    return MouseRegion(
      cursor: cursor,
      onEnter: onEnter,
      onExit: onExit,
      onHover: (event) {
        // Update hover state in selection manager
        if (integration != null) {
          final canvasPosition =
              integration.interactionSystem.screenToCanvas(event.localPosition);
          // Could implement hover effects here
        }
        onHover?.call(event);
      },
      child: child,
    );
  }
}

class _CanvasGestureInterceptorState extends State<CanvasGestureInterceptor> {
  final Map<int, Offset> _pointers = {};

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: GestureDetector(
        // Enable all gesture types but handle them through our system
        onTapUp: _handleTapUp,
        onLongPressStart: _handleLongPressStart,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        onScaleEnd: _handleScaleEnd,
        behavior: HitTestBehavior.translucent,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _pointers.clear();
    super.dispose();
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    widget.integration.handleLongPress(details);
  }

  void _handlePanEnd(DragEndDetails details) {
    widget.integration.handlePanEnd(details);
  }

  void _handlePanStart(DragStartDetails details) {
    widget.integration.handlePanStart(details);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    widget.integration.handlePanUpdate(details);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
    // Treat cancel as pointer up
    final upEvent = PointerUpEvent(
      pointer: event.pointer,
      position: event.position,
    );
    widget.integration.handlePointerUp(upEvent);
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.localPosition;

    // Update canvas size if needed
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      widget.integration.setCanvasSize(renderBox.size);
    }

    widget.integration.handlePointerDown(event);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    _pointers[event.pointer] = event.localPosition;
    widget.integration.handlePointerMove(event);
  }

  void _handlePointerUp(PointerUpEvent event) {
    _pointers.remove(event.pointer);
    widget.integration.handlePointerUp(event);
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    // Handle pinch-to-zoom end
    // The pointer up events will be handled by the pointer listeners
  }

  void _handleScaleStart(ScaleStartDetails details) {
    // Handle pinch-to-zoom start
    if (_pointers.length > 1) {
      // Convert to pointer down events for consistency
      int pointerId = 0;
      for (final entry in _pointers.entries) {
        final pointerEvent = PointerDownEvent(
          pointer: entry.key,
          position: entry.value,
        );
        widget.integration.handlePointerDown(pointerEvent);
        pointerId++;
      }
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // Handle pinch-to-zoom update
    if (_pointers.length > 1) {
      // Update zoom level based on scale
      final currentZoom = widget.integration.zoomLevel;
      final newZoom = currentZoom * details.scale;
      widget.integration.zoomLevel = newZoom.clamp(0.1, 5.0);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    widget.integration.handleTap(details);
  }
}

class _CanvasKeyboardHandlerState extends State<CanvasKeyboardHandler> {
  late final FocusNode _focusNode;

  @override
  Widget build(BuildContext context) {
    final integration =
        widget.integration ?? CanvasIntegrationProvider.of(context);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        return _handleKeyEvent(event, integration);
      },
      child: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
        },
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  KeyEventResult _handleKeyEvent(
      KeyEvent event, PracticeCanvasIntegration? integration) {
    if (integration == null) return KeyEventResult.ignored;

    // Handle common canvas shortcuts
    if (event is KeyDownEvent) {
      final isCtrlPressed =
          event.logicalKey == LogicalKeyboardKey.controlLeft ||
              event.logicalKey == LogicalKeyboardKey.controlRight;
      final isShiftPressed = event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight;

      // Delete selected elements
      if (event.logicalKey == LogicalKeyboardKey.delete) {
        // This would trigger delete through the practice controller
        return KeyEventResult.handled;
      }

      // Copy/Paste shortcuts
      if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyC) {
        // Copy selected elements
        return KeyEventResult.handled;
      }

      if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyV) {
        // Paste elements
        return KeyEventResult.handled;
      }

      // Select all
      if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
        // Select all elements
        return KeyEventResult.handled;
      }

      // Zoom shortcuts
      if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.equal) {
        // Zoom in
        integration.zoomLevel = (integration.zoomLevel * 1.2).clamp(0.1, 5.0);
        return KeyEventResult.handled;
      }

      if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.minus) {
        // Zoom out
        integration.zoomLevel = (integration.zoomLevel / 1.2).clamp(0.1, 5.0);
        return KeyEventResult.handled;
      }

      if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.digit0) {
        // Zoom to fit
        integration.zoomToFit();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }
}
