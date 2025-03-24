# State Conversion Design for Image Preview Components

## Current State Models

### 1. Work Import State
```dart
class WorkImportState {
  final List<File> images;
  final int selectedImageIndex;
  final bool isProcessing;
}

class WorkImportViewModel {
  final state = WorkImportState();
  // Operations and methods
}
```

### 2. Work Image Editor State
```dart
class WorkImageEditorState {
  final List<WorkImage> images;
  final int currentIndex;
  final bool isProcessing;
  final String? error;
}

class WorkImageEditorNotifier extends StateNotifier<WorkImageEditorState> {
  // State management logic
}
```

## Enhanced Preview State

```dart
@freezed
class EnhancedWorkPreviewState with _$EnhancedWorkPreviewState {
  const factory EnhancedWorkPreviewState({
    required List<WorkImage> images,
    required int selectedIndex,
    required bool isProcessing,
    required bool isZoomed,
    String? error,
    bool? isDragging,
    bool? isToolbarVisible,
  }) = _EnhancedWorkPreviewState;
}
```

## State Conversion Strategy

### 1. Import State Conversion

```dart
extension WorkImportStateConversion on WorkImportState {
  EnhancedWorkPreviewState toEnhanced() {
    return EnhancedWorkPreviewState(
      images: images.map((file) => WorkImage(
        id: file.path,
        path: file.path,
        workId: '',  // Temporary work ID for import
        pageIndex: images.indexOf(file),
      )).toList(),
      selectedIndex: selectedImageIndex,
      isProcessing: isProcessing,
      isZoomed: false,
    );
  }
}

extension EnhancedToImportState on EnhancedWorkPreviewState {
  WorkImportState toImport() {
    return WorkImportState(
      images: images.map((image) => File(image.path)).toList(),
      selectedImageIndex: selectedIndex,
      isProcessing: isProcessing,
    );
  }
}
```

### 2. Editor State Conversion

```dart
extension WorkImageEditorStateConversion on WorkImageEditorState {
  EnhancedWorkPreviewState toEnhanced() {
    return EnhancedWorkPreviewState(
      images: images,
      selectedIndex: currentIndex,
      isProcessing: isProcessing,
      isZoomed: false,
      error: error,
    );
  }
}

extension EnhancedToEditorState on EnhancedWorkPreviewState {
  WorkImageEditorState toEditor() {
    return WorkImageEditorState(
      images: images,
      currentIndex: selectedIndex,
      isProcessing: isProcessing,
      error: error,
    );
  }
}
```

## Transitional Implementation

### 1. Import Preview Integration

```dart
class WorkImportPreviewV2 extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read old state
    final importState = ref.watch(workImportStateProvider);
    
    // Convert to enhanced state
    final enhancedState = importState.toEnhanced();
    
    return EnhancedWorkPreview(
      state: enhancedState,
      mode: PreviewMode.import,
      onStateChanged: (newState) {
        // Convert back and update old state
        final newImportState = newState.toImport();
        ref.read(workImportStateProvider.notifier)
           .updateState(newImportState);
      },
    );
  }
}
```

### 2. Management View Integration

```dart
class WorkImagesManagementViewV2 extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read editor state
    final editorState = ref.watch(workImageEditorProvider);
    
    // Convert to enhanced state
    final enhancedState = editorState.toEnhanced();
    
    return EnhancedWorkPreview(
      state: enhancedState,
      mode: PreviewMode.edit,
      onStateChanged: (newState) {
        // Convert back and update editor state
        final newEditorState = newState.toEditor();
        ref.read(workImageEditorProvider.notifier)
           .updateState(newEditorState);
      },
    );
  }
}
```

## State Synchronization

### 1. Direct Updates
```dart
// When enhanced state changes internally
void _handleInternalStateChange(EnhancedWorkPreviewState newState) {
  // Update internal state
  state = newState;
  
  // Notify parent through callback
  widget.onStateChanged?.call(newState);
}
```

### 2. External Updates
```dart
// When parent state changes
@override
void didUpdateWidget(EnhancedWorkPreview oldWidget) {
  super.didUpdateWidget(oldWidget);
  
  // Check if we need to update internal state
  if (widget.state != oldWidget.state) {
    _handleExternalStateUpdate(widget.state);
  }
}
```

## State Migration Path

1. **Phase 1: Parallel States**
```dart
class TransitionalState {
  final WorkImportState importState;
  final EnhancedWorkPreviewState enhancedState;
  
  void synchronize() {
    // Keep both states in sync during transition
  }
}
```

2. **Phase 2: Enhanced Primary**
```dart
// Start using enhanced state as source of truth
final enhancedState = ref.watch(enhancedWorkPreviewProvider);

// Convert only when needed for legacy components
final legacyState = needsLegacyState 
    ? enhancedState.toImport()
    : null;
```

3. **Phase 3: Enhanced Only**
```dart
// Remove old state completely
final state = ref.watch(enhancedWorkPreviewProvider);
```

## Testing Strategy

1. **Conversion Tests**
```dart
test('import state conversion preserves all data', () {
  final importState = WorkImportState(...);
  final enhanced = importState.toEnhanced();
  final backToImport = enhanced.toImport();
  
  expect(backToImport, equals(importState));
});
```

2. **Sync Tests**
```dart
test('state changes propagate correctly', () {
  final controller = EnhancedWorkPreviewController();
  
  controller.addImage(...);
  
  // Verify both new and old states updated
  expect(controller.state.images.length, equals(1));
  expect(oldStateProvider.images.length, equals(1));
});
```

## Migration Verification

1. **Data Integrity**
- Compare state contents before/after conversion
- Verify all operations maintain consistency
- Check edge cases and error states

2. **Performance Impact**
- Measure conversion overhead
- Monitor state update frequency
- Track memory usage

3. **Error Handling**
- Test invalid state conversions
- Verify error propagation
- Check recovery mechanisms