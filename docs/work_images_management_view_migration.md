# WorkImagesManagementView Migration Steps

## Current Implementation Analysis

WorkImagesManagementView has these unique features:

1. Custom PageView-based navigation
2. Advanced zoom with mouse wheel support
3. Processing state management with Riverpod
4. Complex image operations (add/delete/reorder)
5. Loading states and animations
6. Strong type safety with WorkImage model

## Step-by-Step Migration

### 1. Create WorkImagesManagementViewV2

```dart
class WorkImagesManagementViewV2 extends ConsumerWidget {
  final WorkEntity work;

  const WorkImagesManagementViewV2({
    super.key,
    required this.work,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editor.workImageEditorProvider);
    final selectedIndex = ref.watch(editor.currentWorkImageIndexProvider);
    
    return Container(
      padding: const EdgeInsets.all(AppSizes.m),
      child: EnhancedImagePreview(
        mode: PreviewMode.edit,
        images: editorState.images,
        selectedIndex: selectedIndex,
        showThumbnails: true,
        showToolbar: true,
        isProcessing: editorState.isProcessing,
        enableMouseWheel: true,
        onIndexChanged: (index) {
          ref.read(editor.currentWorkImageIndexProvider.notifier).state = index;
        },
        onImageAdded: (_) => _handleAddImage(ref),
        onImageDeleted: (id) => _handleDeleteImage(ref, id),
        onImagesReordered: (oldIndex, newIndex) => 
            _handleReorderImages(ref, oldIndex, newIndex),
        toolbarActions: [
          ToolbarAction(
            icon: Icons.add_photo_alternate,
            tooltip: '添加图片',
            onPressed: editorState.isProcessing
                ? null 
                : () => _handleAddImage(ref),
          ),
          ToolbarAction(
            icon: Icons.delete,
            tooltip: '删除当前图片',
            onPressed: editorState.isProcessing || 
                      editorState.images.isEmpty ||
                      selectedIndex >= editorState.images.length
                ? null
                : () => _handleDeleteImage(
                    ref,
                    editorState.images[selectedIndex].id,
                  ),
          ),
        ],
        errorBuilder: (context, error) => Text(
          error.toString(),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        loadingBuilder: (context) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Future<void> _handleAddImage(WidgetRef ref) async {
    try {
      await ref.read(editor.workImageEditorProvider.notifier).addImage();
    } catch (e) {
      // Error handling remains in the widget to maintain UI context
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('添加图片失败: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleDeleteImage(WidgetRef ref, String imageId) async {
    try {
      await ref.read(editor.workImageEditorProvider.notifier)
          .deleteImage(imageId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除图片失败: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleReorderImages(
    WidgetRef ref,
    int oldIndex,
    int newIndex,
  ) async {
    // Adjust index for removal
    if (oldIndex < newIndex) newIndex--;
    
    try {
      await ref.read(editor.workImageEditorProvider.notifier)
          .reorderImages(oldIndex, newIndex);
          
      // Update selected index
      ref.read(editor.currentWorkImageIndexProvider.notifier).state = newIndex;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('重排序失败: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
```

### 2. Update Editor State Management

```dart
// lib/presentation/providers/work_image_editor_provider.dart

@freezed
class WorkImageEditorState with _$WorkImageEditorState {
  const factory WorkImageEditorState({
    required List<WorkImage> images,
    required bool isProcessing,
    String? error,
  }) = _WorkImageEditorState;
}

class WorkImageEditorNotifier extends StateNotifier<WorkImageEditorState> {
  final WorkImageService _imageService;
  
  // Keep existing methods but improve error handling
  Future<void> addImage() async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      // Existing implementation
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }
  
  // Similar updates to other methods
}
```

### 3. Add Integration Tests

```dart
void main() {
  group('WorkImagesManagementViewV2', () {
    late WorkImageService mockImageService;
    
    setUp(() {
      mockImageService = MockWorkImageService();
      // Setup providers
    });

    testWidgets('handles image operations correctly', (tester) async {
      final work = WorkEntity(...); // Create test work
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workImageServiceProvider.overrideWithValue(mockImageService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: WorkImagesManagementViewV2(work: work),
            ),
          ),
        ),
      );

      // Test scenarios
      await _testAddImage(tester);
      await _testDeleteImage(tester);
      await _testReorderImages(tester);
      await _testErrorStates(tester);
      await _testLoadingStates(tester);
    });
  });
}
```

### 4. Feature Flag Implementation

```dart
// lib/config/feature_flags.dart
class FeatureFlags {
  static const useEnhancedImageManagement = true;
}

// Usage in parent widget
Widget build(BuildContext context) {
  return FeatureFlags.useEnhancedImageManagement
      ? WorkImagesManagementViewV2(work: work)
      : WorkImagesManagementView(work: work);
}
```

### 5. Performance Monitoring

```dart
// lib/utils/performance.dart
class PerformanceMonitor {
  static void logImageOperation({
    required String operation,
    required Duration duration,
    required bool success,
    String? error,
  }) {
    // Log to analytics
  }
}

// Usage in handlers
Future<void> _handleAddImage(WidgetRef ref) async {
  final stopwatch = Stopwatch()..start();
  try {
    await ref.read(editor.workImageEditorProvider.notifier).addImage();
    PerformanceMonitor.logImageOperation(
      operation: 'add_image',
      duration: stopwatch.elapsed,
      success: true,
    );
  } catch (e) {
    PerformanceMonitor.logImageOperation(
      operation: 'add_image',
      duration: stopwatch.elapsed,
      success: false,
      error: e.toString(),
    );
    rethrow;
  }
}
```

### 6. Migration Validation

1. Manual Testing Matrix:

- Image operations (add/delete/reorder)
- Zoom functionality
- Navigation
- Error states
- Loading indicators
- Performance
- Accessibility

2. Automated Testing:

- Unit tests for state management
- Widget tests for UI components
- Integration tests for full flows

3. Performance Metrics:

- Operation latency
- Memory usage
- Frame drops
- Load times

### 7. Rollback Strategy

1. Feature Flag Control:

- Immediate toggle between implementations
- Gradual rollout capability
- A/B testing support

2. State Preservation:

- Ensure state can be restored if rollback needed
- Maintain compatibility between versions

## Comparison with WorkImportPreview

### Shared Aspects

1. Both use EnhancedImagePreview
2. Similar toolbar structure
3. Thumbnail strip integration
4. Basic image operations

### Key Differences

1. State Management:
   - WorkImportPreview: Simpler ViewModel
   - WorkImagesManagement: Complex Riverpod state

2. Navigation:
   - WorkImportPreview: Basic swipe/tap
   - WorkImagesManagement: PageView with animations

3. Error Handling:
   - WorkImportPreview: Basic error display
   - WorkImagesManagement: Detailed error states

4. Performance Requirements:
   - WorkImportPreview: Standard
   - WorkImagesManagement: Higher requirements

## Timeline

1. Day 1-2: Implementation
2. Day 3: Testing setup
3. Day 4: Performance optimization
4. Day 5: Team review
5. Day 6-7: Initial rollout
6. Day 8-14: Monitor and adjust

## Success Metrics

1. Performance:

- Operation latency < 100ms
- No frame drops during animations
- Memory usage within limits

2. User Experience:

- Smooth transitions
- Responsive controls
- Clear error feedback

3. Code Quality:

- Test coverage > 80%
- No new tech debt
- Clear documentation

4. Stability:

- Error rate < 0.1%
- No critical bugs
- Successful rollback if needed
