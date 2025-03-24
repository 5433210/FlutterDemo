# Simplified Image Preview Components Migration Plan

## Core Components

1. **ThumbnailStrip** (Existing)
   - Already implements all needed thumbnail functionality
   - Use directly in all preview implementations
   - No additional wrapper needed

2. **ZoomableImageView** (New)

```dart
class ZoomableImageView extends StatefulWidget {
  final String imagePath;
  final bool enableMouseWheel;
  final double minScale;
  final double maxScale;
  final Widget Function(BuildContext, dynamic)? errorBuilder;
  final Widget Function(BuildContext)? loadingBuilder;
  final Function(double)? onScaleChanged;
  
  // For specialized uses
  final bool enableGestures;
  final Function(Offset)? onTapDown;
  final VoidCallback? onResetZoom;
}
```

## Migration Steps by Component

### 1. WorkImportPreview & WorkImagesManagementView

These share similar functionality and can use a common enhanced preview:

```dart
class EnhancedWorkPreview extends StatefulWidget {
  final List<WorkImage> images;
  final int selectedIndex;
  final bool isEditing;
  final bool showToolbar;
  final List<ToolbarAction>? toolbarActions;
  final Function(int)? onIndexChanged;
  final Function(WorkImage)? onImageAdded;
  final Function(String)? onImageDeleted;
  final Function(int, int)? onImagesReordered;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showToolbar) _buildToolbar(),
        Expanded(
          child: ZoomableImageView(
            imagePath: images[selectedIndex].path,
            enableMouseWheel: true,
          ),
        ),
        ThumbnailStrip<WorkImage>(
          images: images,
          selectedIndex: selectedIndex,
          isEditable: isEditing,
          onTap: onIndexChanged,
          onReorder: onImagesReordered,
          pathResolver: (image) => image.path,
          keyResolver: (image) => image.id,
        ),
      ],
    );
  }
}
```

### 2. ViewModeImagePreview

Keep simple, just add zoom:

```dart
class ViewModeImagePreviewV2 extends ConsumerWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ZoomableImageView(
            imagePath: images[selectedIndex].path,
            enableMouseWheel: true,
          ),
        ),
        ThumbnailStrip<WorkImage>(
          images: images,
          selectedIndex: selectedIndex,
          onTap: onImageSelect,
          pathResolver: (image) => image.path,
          keyResolver: (image) => image.id,
        ),
      ],
    );
  }
}
```

### 3. CharacterExtractionPreview

Keep specialized features, integrate shared components:

```dart
class CharacterExtractionPreviewV2 extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Main content (75%)
              Expanded(
                flex: 75,
                child: Stack(
                  children: [
                    ZoomableImageView(
                      imagePath: currentImage.path,
                      enableMouseWheel: true,
                      enableGestures: !isBoxSelectionMode,
                      onTapDown: handleImageTap,
                    ),
                    RegionOverlay(regions: regions),
                    if (isBoxSelectionMode)
                      SelectionGestureDetector(...),
                  ],
                ),
              ),
              // Side panel (25%)
              CharacterPreviewPanel(...),
            ],
          ),
        ),
        // Add thumbnail navigation
        ThumbnailStrip<String>(
          images: widget.imagePaths,
          selectedIndex: currentIndex,
          onTap: handleIndexChanged,
          pathResolver: (path) => path,
          keyResolver: (path) => path,
        ),
      ],
    );
  }
}
```

## Implementation Timeline

### Phase 1: ZoomableImageView (Week 1)

1. Create component
2. Add mouse wheel support
3. Add gesture handling
4. Implement error states
5. Add tests

### Phase 2: ViewModeImagePreview Update (Week 1)

1. Add ZoomableImageView
2. Verify ThumbnailStrip integration
3. Update tests
4. Deploy changes

### Phase 3: Enhanced Work Preview (Week 2)

1. Create EnhancedWorkPreview
2. Migrate WorkImportPreview
3. Migrate WorkImagesManagementView
4. Add comprehensive tests

### Phase 4: Character Extraction Update (Week 2-3)

1. Add ZoomableImageView
2. Add ThumbnailStrip
3. Test interactions
4. Verify region selection

## Success Metrics

1. Code Quality

- Reduced duplicate code
- Better component reuse
- Clear interfaces
- Comprehensive tests

2. User Experience

- Consistent zoom behavior
- Smooth thumbnail navigation
- Clear error states
- Responsive controls

3. Performance

- Fast image loading
- Smooth zooming
- Efficient memory use
- Quick thumbnail rendering

## Migration Risks and Mitigations

1. **Risks**

- Gesture conflicts in CharacterExtractionPreview
- Performance impact from ZoomableImageView
- State management complexity
- Migration bugs

2. **Mitigations**

- Comprehensive gesture testing
- Performance benchmarking
- Clear state boundaries
- Feature flags
- Gradual rollout
- Easy rollback paths

## Testing Strategy

1. **Unit Tests**

- ZoomableImageView functionality
- Gesture handling
- State management
- Error cases

2. **Integration Tests**

- Component interactions
- Navigation flows
- Error handling
- State preservation

3. **Performance Tests**

- Image loading times
- Memory usage
- Frame rates
- Interaction latency

## Documentation Updates

1. **Component Documentation**

- Usage examples
- Props reference
- Common patterns
- Best practices

2. **Migration Guides**

- Step-by-step instructions
- Breaking changes
- Upgrade paths
- Troubleshooting
