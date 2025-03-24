# WorkImportPreview Migration Steps

## Current Implementation Analysis

The current WorkImportPreview has these key features:

1. Uses BaseImagePreview for core image display
2. Custom toolbar for adding images
3. Thumbnail strip for navigation
4. Image reordering support
5. Processing state handling
6. Error handling

## Step-by-Step Migration

### 1. Create WorkImportPreviewV2

```dart
class WorkImportPreviewV2 extends StatelessWidget {
  final WorkImportState state;
  final WorkImportViewModel viewModel;
  final bool isProcessing;
  final VoidCallback? onAddImages;

  const WorkImportPreviewV2({
    super.key,
    required this.state,
    required this.viewModel,
    this.isProcessing = false,
    this.onAddImages,
  });

  @override 
  Widget build(BuildContext context) {
    if (state.images.isEmpty) {
      return _buildEmptyState();
    }

    return EnhancedImagePreview(
      mode: PreviewMode.import,
      images: state.images
          .map((file) => WorkImage(
                id: file.path,
                path: file.path,
                workId: '',
                pageIndex: state.images.indexOf(file),
              ))
          .toList(),
      selectedIndex: state.selectedImageIndex,
      showThumbnails: true,
      showToolbar: true,
      isProcessing: isProcessing,
      onIndexChanged: viewModel.selectImage,
      onImageAdded: (_) => onAddImages?.call(),
      onImageDeleted: (id) => _handleRemoveImage(context, id),
      onImagesReordered: viewModel.reorderImages,
      toolbarActions: [
        ToolbarAction(
          icon: Icons.add_photo_alternate_outlined,
          tooltip: '追加图片',
          onPressed: isProcessing ? null : onAddImages,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return BaseCard(
      child: InkWell(
        onTap: onAddImages,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSizes.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 48),
                SizedBox(height: AppSizes.s),
                Text('点击或拖拽图片以添加'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRemoveImage(BuildContext context, String id) async {
    final index = state.images.indexWhere((file) => file.path == id);
    if (index == -1) return;

    if (state.images.length > 1) {
      viewModel.removeImage(index);
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => ConfirmDialog(
          title: '确认删除',
          content: '这是最后一张图片，删除后将退出导入。确定要删除吗？',
          onConfirm: () {
            viewModel.removeImage(index);
            Navigator.of(context).pop(true);
          },
        ),
      );
      
      if (confirmed == true) {
        Navigator.of(context).pop();
      }
    }
  }
}
```

### 2. Update ViewModel Interface

```dart
class WorkImportViewModel extends StateNotifier<WorkImportState> {
  // Update methods to work with WorkImage
  Future<void> reorderImages(int oldIndex, int newIndex);
  Future<void> removeImage(int index);
  void selectImage(int index);
  
  // New helper methods
  WorkImage _createWorkImage(File file, int index) {
    return WorkImage(
      id: file.path,
      path: file.path,
      workId: '',
      pageIndex: index,
    );
  }
}
```

### 3. Create Integration Tests

```dart
void main() {
  group('WorkImportPreviewV2', () {
    testWidgets('shows empty state when no images', (tester) async {
      // Test empty state
    });

    testWidgets('shows enhanced preview when has images', (tester) async {
      // Test preview state
    });

    testWidgets('handles image operations', (tester) async {
      // Test add/remove/reorder
    });
  });
}
```

### 4. Switch Implementation

1. Add feature flag:

```dart
// lib/config/feature_flags.dart
const bool useEnhancedImagePreview = true;
```

2. Update WorkImportDialog:

```dart
@override
Widget build(BuildContext context) {
  return useEnhancedImagePreview
      ? WorkImportPreviewV2(...)
      : WorkImportPreview(...);
}
```

### 5. Add Monitoring

```dart
// lib/utils/analytics.dart
class Analytics {
  static void logImagePreviewUsage({
    required String component,
    required String action,
    Map<String, dynamic>? parameters,
  });
}

// Usage in WorkImportPreviewV2
Analytics.logImagePreviewUsage(
  component: 'WorkImportPreviewV2',
  action: 'reorder_images',
  parameters: {'old_index': oldIndex, 'new_index': newIndex},
);
```

### 6. Migration Validation

1. Visual Validation:

- Compare screenshots between old and new
- Verify all UI states match
- Check animations and transitions

2. Functional Validation:

- Verify all operations work
- Test error states
- Check accessibility

3. Performance Validation:

- Measure load times
- Monitor memory usage
- Check animation smoothness

### 7. Rollback Plan

1. Keep old implementation:

```dart
// Mark as deprecated but keep for rollback
@Deprecated('Use WorkImportPreviewV2 instead')
class WorkImportPreview extends StatelessWidget {
  // Original implementation
}
```

2. Feature flag control:

```dart
// Quick rollback by changing flag
const bool useEnhancedImagePreview = false;
```

## Next Steps

1. Deploy to development environment
2. Gather feedback from team
3. Monitor analytics and error rates
4. Plan production rollout
5. Remove old implementation after successful migration

## Migration Schedule

1. Day 1: Implementation and initial testing
2. Day 2: Integration testing and monitoring setup
3. Day 3: Team review and feedback
4. Day 4: Deploy to development
5. Day 5: Monitor and validate
6. Day 6-7: Production rollout

## Success Criteria

1. No regression in functionality
2. Performance meets or exceeds current implementation
3. Positive team feedback
4. No increase in error rates
5. Successful usage analytics
6. Smooth rollout to production
