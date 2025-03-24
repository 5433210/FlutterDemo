# ViewModeImagePreview and CharacterExtractionPreview Migration Plan

## 1. ViewModeImagePreview Migration

### Current Features

- Simple image display
- Basic thumbnail navigation
- Error handling with retry
- File existence checks
- Uses WorkImage model

### Migration Steps

```dart
class ViewModeImagePreviewV2 extends ConsumerWidget {
  final List<WorkImage> images;
  final int selectedIndex;
  final Function(int) onImageSelect;

  const ViewModeImagePreviewV2({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onImageSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EnhancedImagePreview(
      mode: PreviewMode.view,
      images: images,
      selectedIndex: selectedIndex,
      showThumbnails: true,
      showToolbar: false,
      enableZoom: true, // New feature
      onIndexChanged: onImageSelect,
      errorBuilder: (context, error) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '无法加载图片: $error',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Trigger reload
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
```

### Testing Strategy

```dart
void main() {
  group('ViewModeImagePreviewV2', () {
    testWidgets('enables zoom functionality', (tester) async {
      // Test zoom gestures
    });

    testWidgets('shows thumbnails correctly', (tester) async {
      // Test thumbnail display
    });

    testWidgets('handles errors appropriately', (tester) async {
      // Test error states
    });
  });
}
```

## 2. CharacterExtractionPreview Migration

### Current Features

- Region selection
- Multi-select capability
- Side panel integration
- Complex mouse interactions
- Tool modes (box selection, multi-select)

### Migration Steps

```dart
class CharacterExtractionPreviewV2 extends StatefulWidget {
  final List<String> imagePaths;
  final List<CharacterRegion>? collectedRegions;
  final Function(CharacterRegion)? onRegionCreated;
  final Function(CharacterRegion)? onRegionSelected;
  final Function(List<CharacterRegion>)? onRegionsDeleted;
  final String? workId;

  const CharacterExtractionPreviewV2({
    super.key,
    required this.imagePaths,
    this.collectedRegions,
    this.onRegionCreated,
    this.onRegionSelected,
    this.onRegionsDeleted,
    this.workId,
  });

  @override
  State<CharacterExtractionPreviewV2> createState() =>
      _CharacterExtractionPreviewV2State();
}

class _CharacterExtractionPreviewV2State
    extends State<CharacterExtractionPreviewV2> {
  final _selectedRegions = <CharacterRegion>{};
  bool _isBoxSelectionMode = false;
  bool _isMultiSelectMode = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 75,
          child: Column(
            children: [
              _buildToolbar(),
              Expanded(
                child: EnhancedImagePreview(
                  mode: PreviewMode.extract,
                  images: widget.imagePaths
                      .map((path) => WorkImage(
                            id: path,
                            path: path,
                            workId: widget.workId ?? '',
                            pageIndex: widget.imagePaths.indexOf(path),
                          ))
                      .toList(),
                  showThumbnails: true, // New feature
                  enableZoom: true,
                  customPainter: (context, child) => CustomPaint(
                    painter: RegionPainter(
                      regions: _getRegionsForCurrentPage(),
                      selectedRegions: _selectedRegions,
                      isSelecting: _isBoxSelectionMode,
                    ),
                    child: child,
                  ),
                  onTapDown: _handleTapDown,
                  onPanStart: _isBoxSelectionMode
                      ? _handleBoxSelectionStart
                      : _handleRegionStart,
                  onPanUpdate: _isBoxSelectionMode
                      ? _handleBoxSelectionUpdate
                      : _handleRegionUpdate,
                  onPanEnd: _isBoxSelectionMode
                      ? _handleBoxSelectionEnd
                      : _handleRegionEnd,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 300,
          child: CharacterPreviewPanel(
            region: _getSelectedRegion(),
            onSave: _handleSaveRegion,
            onClear: _handleClearRegion,
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        IconButton(
          icon: Icon(_isBoxSelectionMode ? Icons.crop_din : Icons.crop_free),
          onPressed: _toggleBoxSelectionMode,
          tooltip: '框选工具',
        ),
        IconButton(
          icon: Icon(_isMultiSelectMode ? Icons.select_all : Icons.touch_app),
          onPressed: _toggleMultiSelectMode,
          tooltip: '多选工具',
        ),
        if (_selectedRegions.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _handleDeleteSelectedRegions,
            tooltip: '删除选中区域',
          ),
          Text('已选择: ${_selectedRegions.length}'),
        ],
      ],
    );
  }

  // Implement other methods...
}
```

### Feature Integration

1. Base Preview Features:

- Add thumbnail navigation
- Keep zoom functionality
- Maintain page navigation

2. Region Management:

- Integrate with EnhancedImagePreview's overlay system
- Keep custom region selection tools
- Maintain multi-select functionality

3. State Management:

- Handle region selection state
- Manage tool modes
- Coordinate with preview panel

### Testing Plan

```dart
void main() {
  group('CharacterExtractionPreviewV2', () {
    testWidgets('supports thumbnail navigation', (tester) async {
      // Test thumbnail functionality
    });

    testWidgets('maintains region selection', (tester) async {
      // Test region operations
    });

    testWidgets('handles tool mode switching', (tester) async {
      // Test mode transitions
    });
  });
}
```

## Common Patterns

### 1. Zoom Enhancement

Both components benefit from:

- Mouse wheel zoom
- Pinch-to-zoom
- Double-tap to zoom
- Zoom reset

### 2. Navigation

- ViewModeImagePreview: Simple navigation with thumbnails
- CharacterExtractionPreview: Navigation with region preservation

### 3. Error Handling

- ViewModeImagePreview: Retry mechanism
- CharacterExtractionPreview: Operation-specific errors

## Migration Timeline

### ViewModeImagePreview

1. Day 1: Implement base changes
2. Day 2: Add zoom functionality
3. Day 3: Testing and refinement

### CharacterExtractionPreview

1. Days 1-2: Base integration
2. Days 3-4: Region management
3. Day 5: Thumbnail integration
4. Days 6-7: Testing and optimization

## Success Metrics

### ViewModeImagePreview

1. Performance
   - Smooth zooming
   - Quick navigation
   - Responsive UI

2. User Experience
   - Intuitive zoom controls
   - Clear error states
   - Easy navigation

### CharacterExtractionPreview

1. Functionality
   - Accurate region selection
   - Proper tool interaction
   - Reliable state management

2. Integration
   - Smooth thumbnail navigation
   - Consistent zoom behavior
   - Maintained custom features
