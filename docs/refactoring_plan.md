# Image Preview Controls Refactoring Plan

## Phase 1: Enhance BaseImagePreview

### Current Issues

1. BaseImagePreview lacks some essential features:
   - Mouse wheel zoom support
   - Loading indicators
   - Advanced error handling

### Changes Needed

```dart
class BaseImagePreview {
  // Add new parameters
  final bool enableMouseWheel;
  final Widget Function(BuildContext)? loadingBuilder;
  final Widget Function(BuildContext, dynamic)? errorBuilder;
  final double minScale;
  final double maxScale;
  
  // Add new methods
  void handleMouseWheel(PointerScrollEvent event);
  void handleZoomReset();
  Widget buildErrorDisplay(BuildContext context, dynamic error);
  Widget buildLoadingIndicator(BuildContext context);
}
```

### Implementation Steps

1. Update BaseImagePreview constructor parameters
2. Add mouse wheel zoom support
3. Enhance error and loading states
4. Add zoom reset functionality
5. Update existing uses of BaseImagePreview

## Phase 2: Create EnhancedImagePreview

### New Component

```dart
class EnhancedImagePreview extends StatefulWidget {
  final PreviewMode mode;
  final List<WorkImage> images;
  final bool showThumbnails;
  final bool showToolbar;
  final Function(int)? onIndexChanged;
  final Function(List<WorkImage>)? onImagesChanged;
  
  // Mode specific callbacks
  final Function(WorkImage)? onImageAdded;
  final Function(String)? onImageDeleted;
  final Function(int, int)? onImagesReordered;
}
```

### Implementation Steps

1. Create new EnhancedImagePreview class
2. Migrate work import and edit previews to use EnhancedImagePreview
3. Add toolbar functionality
4. Integrate thumbnail strip

## Phase 3: Refactor Existing Components

### WorkImportPreview

1. Remove direct BaseImagePreview usage
2. Use EnhancedImagePreview with import mode
3. Move import-specific logic to callbacks

```dart
// Before
class WorkImportPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseImagePreview(...);
  }
}

// After
class WorkImportPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EnhancedImagePreview(
      mode: PreviewMode.import,
      images: state.images,
      showThumbnails: true,
      showToolbar: true,
      onImageAdded: viewModel.addImage,
      onImageDeleted: viewModel.removeImage,
    );
  }
}
```

### WorkImagesManagementView

1. Remove direct image preview implementation
2. Use EnhancedImagePreview with edit mode
3. Move edit-specific logic to callbacks

```dart
// Before
class WorkImagesManagementView extends ConsumerStatefulWidget {
  // Current implementation
}

// After
class WorkImagesManagementView extends ConsumerWidget {
  @override
  Widget build(BuildContext context) {
    return EnhancedImagePreview(
      mode: PreviewMode.edit,
      images: editorState.images,
      showThumbnails: true,
      showToolbar: true,
      onImagesReordered: handleReorder,
      onImageAdded: handleAdd,
      onImageDeleted: handleDelete,
    );
  }
}
```

### ViewModeImagePreview

1. Use EnhancedImagePreview with view mode
2. Enable zoom functionality
3. Keep simple interface

```dart
// Before
class ViewModeImagePreview extends ConsumerStatefulWidget {
  // Current implementation
}

// After
class ViewModeImagePreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context) {
    return EnhancedImagePreview(
      mode: PreviewMode.view,
      images: widget.images,
      showThumbnails: true,
      showToolbar: false,
      enableZoom: true,
    );
  }
}
```

### CharacterExtractionPreview

1. Add thumbnail strip
2. Keep specialized features
3. Use enhanced zoom controls

```dart
class CharacterExtractionPreview extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: EnhancedImagePreview(
            mode: PreviewMode.extract,
            images: widget.images,
            showThumbnails: true,
            enableZoom: true,
          ),
        ),
        CharacterExtractionPanel(...),
      ],
    );
  }
}
```

## Phase 4: Update Tests and Documentation

### Test Updates

1. Add tests for new BaseImagePreview features
2. Create test suite for EnhancedImagePreview
3. Update existing component tests
4. Add integration tests for mode transitions

### Documentation

1. Update component documentation
2. Add migration guide for existing usages
3. Document new features and capabilities
4. Provide usage examples for each mode

## Migration Order

1. Create and test enhanced BaseImagePreview
2. Implement EnhancedImagePreview
3. Migrate WorkImportPreview and WorkImagesManagementView
4. Update ViewModeImagePreview
5. Enhance CharacterExtractionPreview
6. Run full test suite
7. Deploy changes gradually

## Risks and Mitigations

### Risks

1. Breaking existing functionality
2. Performance impact
3. State management complexity
4. Migration challenges

### Mitigations

1. Comprehensive test coverage
2. Performance benchmarking
3. Clear state boundaries
4. Gradual rollout
5. Feature flags for new functionality
6. Fallback options
