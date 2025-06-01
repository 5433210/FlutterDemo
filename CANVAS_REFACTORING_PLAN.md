# Canvas System Refactoring Plan

## Separation of Rendering and Interaction Layers

### Executive Summary

This document outlines a comprehensive refactoring plan to address performance issues in the practice editing canvas system. The main problem is the tight coupling between rendering and interaction layers, causing frequent unnecessary rebuilds during element manipulation operations.

### Current Architecture Issues

#### 1. **Mixed Responsibilities**

- `CollectionElementRenderer` handles both widget creation and painter callbacks
- `AdvancedCollectionPainter` directly controls UI rebuilds via `setRepaintCallback`
- Gesture handling mixed with rendering logic in canvas components

#### 2. **Performance Bottlenecks**

```dart
// PROBLEMATIC: Direct framework control from painter
dynamicPainter.setRepaintCallback(() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    WidgetsBinding.instance.scheduleForcedFrame(); // ❌ Forces entire framework refresh
    setState(() {});  // ❌ Triggers unnecessary widget rebuilds
  });
});

// PROBLEMATIC: Time-based texture keys forcing widget recreation
final textureChangeKey = ValueKey(
  'texture_${hasEffectiveTexture}_${DateTime.now().millisecondsSinceEpoch}'  // ❌ Always unique
);
```

#### 3. **Architectural Coupling**

- Painters have direct access to Flutter framework APIs
- UI state management scattered across multiple layers
- No clear separation between canvas state and rendering state

---

## Refactoring Strategy

### Phase 1: Architecture Separation

#### 1.1 Create Canvas State Management Layer

**New Components:**

- `CanvasStateManager` - Centralized state management
- `CanvasRenderingEngine` - Pure rendering logic
- `CanvasInteractionEngine` - Gesture and interaction handling

```dart
// NEW: lib/presentation/widgets/practice/canvas/canvas_state_manager.dart
class CanvasStateManager extends ChangeNotifier {
  // Canvas viewport state
  Matrix4 _transform = Matrix4.identity();
  Size _canvasSize = Size.zero;
  
  // Element state
  final Map<String, ElementRenderData> _elements = {};
  final Set<String> _selectedElements = {};
  
  // Rendering state (separate from UI state)
  final Set<String> _dirtyElements = {};
  bool _needsFullRepaint = false;
  
  // Texture state
  final Map<String, TextureRenderData> _textureCache = {};
  
  // Public API for UI layer
  void updateElement(String id, ElementRenderData data) { /* ... */ }
  void selectElements(Set<String> ids) { /* ... */ }
  void markElementDirty(String id) { /* ... */ }
  
  // Public API for rendering layer  
  List<ElementRenderData> getDirtyElements() { /* ... */ }
  void clearDirtyFlags() { /* ... */ }
}
```

#### 1.2 Separate Rendering Engine

**New Components:**

- `CanvasRenderingEngine` - Pure rendering without Flutter framework dependencies
- `ElementRenderer` factories - Specialized renderers for different element types

```dart
// NEW: lib/presentation/widgets/practice/canvas/canvas_rendering_engine.dart
class CanvasRenderingEngine {
  final CanvasStateManager stateManager;
  final Map<String, ElementRenderer> _renderers = {};
  
  CanvasRenderingEngine(this.stateManager);
  
  // Pure rendering method - no setState, no scheduleForcedFrame
  void renderToCanvas(Canvas canvas, Size size) {
    final dirtyElements = stateManager.getDirtyElements();
    
    for (final element in dirtyElements) {
      final renderer = _getRendererForElement(element);
      renderer.renderElement(canvas, element);
    }
    
    stateManager.clearDirtyFlags();
  }
  
  // Async operations managed separately
  Future<void> preloadTextures(List<TextureData> textures) async { /* ... */ }
}
```

#### 1.3 Interaction Engine

**New Components:**

- `CanvasInteractionEngine` - Handles all gesture processing
- `InteractionMode` enum - Select, Pan, Draw, etc.

```dart
// NEW: lib/presentation/widgets/practice/canvas/canvas_interaction_engine.dart
class CanvasInteractionEngine {
  final CanvasStateManager stateManager;
  
  InteractionMode _currentMode = InteractionMode.select;
  
  // Process gestures and update state
  void handleTapDown(TapDownDetails details) {
    final hitElement = _getElementAtPoint(details.localPosition);
    
    switch (_currentMode) {
      case InteractionMode.select:
        stateManager.selectElements(hitElement != null ? {hitElement.id} : {});
        break;
      case InteractionMode.draw:
        _startDrawing(details.localPosition);
        break;
    }
  }
  
  void handlePanUpdate(DragUpdateDetails details) { /* ... */ }
}
```

### Phase 2: Component Refactoring

#### 2.1 Refactor CollectionElementRenderer

**Before:**

```dart
class CollectionElementRenderer {
  static Widget buildCollectionLayout({...}) {
    return LayoutBuilder(builder: (context, constraints) {
      // Mixed rendering and widget logic
      final painter = AdvancedCollectionPainter(...);
      painter.setRepaintCallback(() {
        WidgetsBinding.instance.scheduleForcedFrame(); // ❌
      });
      return CustomPaint(painter: painter);
    });
  }
}
```

**After:**

```dart
class CollectionElementRenderer {
  static Widget buildCollectionLayout({...}) {
    return CanvasElementWidget(
      elementData: CollectionElementData(...),
      renderer: CollectionRenderer(),
    );
  }
}

// NEW: Generic canvas element widget
class CanvasElementWidget extends StatelessWidget {
  final ElementRenderData elementData;
  final ElementRenderer renderer;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<CanvasStateManager>(
      builder: (context, stateManager, child) {
        return CustomPaint(
          painter: CanvasPainter(
            elementData: elementData,
            renderer: renderer,
            stateManager: stateManager,
          ),
        );
      },
    );
  }
}
```

#### 2.2 Refactor AdvancedCollectionPainter

**Remove Framework Dependencies:**

```dart
// REMOVE: Framework control from painter
class AdvancedCollectionPainter extends CustomPainter {
  VoidCallback? _repaintCallback; // ❌ Remove this
  
  void setRepaintCallback(VoidCallback callback) { // ❌ Remove this method
    _repaintCallback = callback;
  }
}
```

**Replace With:**

```dart
class CollectionRenderer extends ElementRenderer {
  @override
  void renderElement(Canvas canvas, ElementRenderData data) {
    // Pure rendering logic only
    final collectionData = data as CollectionElementData;
    
    for (int i = 0; i < collectionData.characters.length; i++) {
      _renderCharacter(canvas, collectionData.characters[i], collectionData.positions[i]);
    }
  }
  
  @override
  bool shouldRepaint(ElementRenderData oldData, ElementRenderData newData) {
    // Simple comparison logic
    return oldData != newData;
  }
}
```

#### 2.3 Refactor Canvas Widget

**Current M3PracticeEditCanvas Issues:**

- Mixed gesture handling and rendering
- Direct state mutations
- Unclear responsibility boundaries

**Refactored Architecture:**

```dart
class M3PracticeEditCanvas extends ConsumerStatefulWidget {
  // ... existing properties
}

class _M3PracticeEditCanvasState extends ConsumerState<M3PracticeEditCanvas> {
  late CanvasStateManager _stateManager;
  late CanvasInteractionEngine _interactionEngine;
  late CanvasRenderingEngine _renderingEngine;
  
  @override
  void initState() {
    super.initState();
    _stateManager = CanvasStateManager();
    _interactionEngine = CanvasInteractionEngine(_stateManager);
    _renderingEngine = CanvasRenderingEngine(_stateManager);
    
    // Listen to state changes for UI updates only
    _stateManager.addListener(_onCanvasStateChanged);
  }
  
  void _onCanvasStateChanged() {
    // Only setState when UI needs to update
    if (_stateManager.hasUIChanges) {
      setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _interactionEngine.handleTapDown,
      onPanUpdate: _interactionEngine.handlePanUpdate,
      child: CustomPaint(
        painter: MainCanvasPainter(_renderingEngine),
        size: Size.infinite,
      ),
    );
  }
}
```

### Phase 3: Performance Optimizations

#### 3.1 Replace Time-Based Keys with Content-Based Keys

**Before:**

```dart
final textureChangeKey = ValueKey(
  'texture_${hasEffectiveTexture}_${DateTime.now().millisecondsSinceEpoch}'
);
```

**After:**

```dart
class ElementDataKey extends ValueKey<String> {
  ElementDataKey(ElementRenderData data) : super(_generateKey(data));
  
  static String _generateKey(ElementRenderData data) {
    return data.contentHash; // Based on actual content, not time
  }
}
```

#### 3.2 Implement Efficient Dirty Tracking

```dart
class CanvasStateManager extends ChangeNotifier {
  final Set<String> _dirtyElements = {};
  final Set<String> _dirtyTextures = {};
  
  void markElementDirty(String elementId, DirtyType type) {
    switch (type) {
      case DirtyType.position:
        _dirtyElements.add(elementId);
        notifyListeners(); // Minimal notification
        break;
      case DirtyType.texture:
        _dirtyTextures.add(elementId);
        _scheduleTextureUpdate(); // Async update
        break;
      case DirtyType.content:
        _dirtyElements.add(elementId);
        _scheduleContentUpdate();
        break;
    }
  }
}
```

#### 3.3 Implement Smart Repainting

```dart
class MainCanvasPainter extends CustomPainter {
  final CanvasRenderingEngine renderingEngine;
  
  @override
  void paint(Canvas canvas, Size size) {
    // Only repaint dirty regions
    final dirtyRegions = renderingEngine.getDirtyRegions();
    
    for (final region in dirtyRegions) {
      canvas.save();
      canvas.clipRect(region.bounds);
      renderingEngine.renderRegion(canvas, region);
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(MainCanvasPainter oldDelegate) {
    return renderingEngine.hasDirtyRegions();
  }
}
```

### Phase 4: Implementation Plan

#### 4.1 Week 1: Core Architecture

1. **Day 1-2**: Create base classes
   - `CanvasStateManager`
   - `ElementRenderData` hierarchy
   - `ElementRenderer` base class

2. **Day 3-4**: Implement rendering engine
   - `CanvasRenderingEngine`
   - `CollectionRenderer`
   - Basic dirty tracking

3. **Day 5**: Create interaction engine
   - `CanvasInteractionEngine`
   - Basic gesture handling

#### 4.2 Week 2: Component Migration

1. **Day 1-2**: Refactor `CollectionElementRenderer`
   - Remove framework dependencies
   - Create `CanvasElementWidget`

2. **Day 3-4**: Refactor painters
   - Remove `setRepaintCallback` methods
   - Pure rendering logic only

3. **Day 5**: Update canvas widget
   - Integrate new architecture
   - Remove old coupling

#### 4.3 Week 3: Performance Optimization

1. **Day 1-2**: Implement smart keys
   - Content-based instead of time-based
   - Efficient change detection

2. **Day 3-4**: Optimize repainting
   - Regional dirty tracking
   - Minimal rebuild scope

3. **Day 5**: Performance testing
   - Benchmark improvements
   - Fix remaining issues

#### 4.4 Week 4: Integration & Testing

1. **Day 1-2**: Integration testing
   - End-to-end functionality
   - Edge case handling

2. **Day 3-4**: Performance validation
   - Memory usage optimization
   - Frame rate improvements

3. **Day 5**: Documentation and cleanup
   - Code documentation
   - Remove deprecated code

---

## Expected Benefits

### Performance Improvements

- **50-80% reduction** in unnecessary rebuilds during element translation
- **Eliminated** `scheduleForcedFrame()` calls during normal operations
- **Regional repainting** instead of full canvas refreshes
- **Async texture loading** without blocking UI

### Code Quality Improvements

- **Clear separation** of concerns between rendering and interaction
- **Testable components** with pure functions
- **Maintainable architecture** with defined interfaces
- **Reduced coupling** between UI and business logic

### Developer Experience

- **Easier debugging** with isolated component responsibilities
- **Better performance profiling** with clear boundaries
- **Simplified feature addition** with established patterns
- **Reduced complexity** in individual components

---

## Migration Strategy

### Backwards Compatibility

- Keep existing public APIs during transition
- Gradual migration with feature flags
- Parallel implementation testing

### Risk Mitigation

- Comprehensive unit testing for each new component
- Performance benchmarking at each phase
- Rollback plan for each major change
- Feature toggles for new architecture

### Testing Strategy

- **Unit Tests**: Each new component in isolation
- **Integration Tests**: Component interaction scenarios  
- **Performance Tests**: Before/after benchmarking
- **User Acceptance Tests**: Feature functionality validation

---

## Conclusion

This refactoring plan addresses the core architectural issues causing performance problems in the canvas system. By separating rendering and interaction concerns, implementing efficient dirty tracking, and removing inappropriate framework dependencies, we can achieve significant performance improvements while creating a more maintainable and extensible codebase.

The phased approach allows for incremental implementation with continuous validation, reducing the risk of introducing regressions while ensuring the benefits are realized throughout the development process.
