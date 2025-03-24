# Mode-Specific Behaviors and Toolbar Implementation

## Mode Definitions

```dart
enum PreviewMode {
  import,    // Work import dialog
  edit,      // Work edit page
  view,      // Work preview page
  extract    // Character extraction
}
```

## Mode-Specific Requirements

### 1. Import Mode

```dart
class ImportModeConfig {
  static const toolbarActions = [
    ToolbarAction(
      icon: Icons.add_photo_alternate,
      tooltip: '添加图片',
      actionType: ToolbarActionType.add,
    ),
    ToolbarAction(
      icon: Icons.delete,
      tooltip: '删除图片',
      actionType: ToolbarActionType.delete,
      requiresSelection: true,
    ),
  ];

  static const behaviors = PreviewBehaviors(
    allowMultipleImages: true,
    allowDeletion: true,
    allowReordering: true,
    showThumbnails: true,
    enableZoom: true,
    confirmLastImageDeletion: true,
    exitOnEmpty: true,
  );
  
  static const deletionDialogs = DialogConfig(
    lastImageTitle: '确认删除',
    lastImageContent: '这是最后一张图片，删除后将退出导入。确定要删除吗？',
    normalTitle: '确认删除',
    normalContent: '确定要删除选中的图片吗？',
  );
}
```

### 2. Edit Mode

```dart
class EditModeConfig {
  static const toolbarActions = [
    ToolbarAction(
      icon: Icons.add_photo_alternate,
      tooltip: '添加图片',
      actionType: ToolbarActionType.add,
    ),
    ToolbarAction(
      icon: Icons.delete,
      tooltip: '删除图片',
      actionType: ToolbarActionType.delete,
      requiresSelection: true,
    ),
    ToolbarAction(
      icon: Icons.save,
      tooltip: '保存更改',
      actionType: ToolbarActionType.save,
      showProcessing: true,
    ),
  ];

  static const behaviors = PreviewBehaviors(
    allowMultipleImages: true,
    allowDeletion: true,
    allowReordering: true,
    showThumbnails: true,
    enableZoom: true,
    persistChanges: true,
    showProcessingIndicator: true,
  );
  
  static const deletionDialogs = DialogConfig(
    title: '确认删除',
    content: '确定要删除选中的图片吗？此操作无法撤销。',
  );
}
```

### 3. View Mode

```dart
class ViewModeConfig {
  static const toolbarActions = [];  // No toolbar in view mode

  static const behaviors = PreviewBehaviors(
    allowMultipleImages: true,
    allowDeletion: false,
    allowReordering: false,
    showThumbnails: true,
    enableZoom: true,
    enableMouseWheelZoom: true,
    showZoomControls: true,
  );
}
```

### 4. Extract Mode

```dart
class ExtractModeConfig {
  static const toolbarActions = [
    ToolbarAction(
      icon: Icons.crop_free,
      tooltip: '框选工具',
      actionType: ToolbarActionType.boxSelect,
      isToggleable: true,
    ),
    ToolbarAction(
      icon: Icons.select_all,
      tooltip: '多选工具',
      actionType: ToolbarActionType.multiSelect,
      isToggleable: true,
    ),
    ToolbarAction(
      icon: Icons.delete,
      tooltip: '删除选中区域',
      actionType: ToolbarActionType.delete,
      requiresSelection: true,
    ),
  ];

  static const behaviors = PreviewBehaviors(
    allowMultipleImages: true,
    allowDeletion: false,
    allowReordering: false,
    showThumbnails: true,
    enableZoom: true,
    enableRegionSelection: true,
    showSidePanel: true,
  );
}
```

## Toolbar Implementation

```dart
class EnhancedWorkPreview extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_shouldShowToolbar()) _buildToolbar(),
        Expanded(child: _buildPreviewArea()),
        if (_shouldShowThumbnails()) _buildThumbnailStrip(),
      ],
    );
  }

  Widget _buildToolbar() {
    final config = _getModeConfig();
    final actions = config.toolbarActions;

    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Left section - Primary actions
          Row(
            children: actions
                .where((a) => a.placement == ToolbarPlacement.left)
                .map(_buildToolbarAction)
                .toList(),
          ),
          
          // Middle section - Status/info
          if (_shouldShowStatus())
            Expanded(child: _buildStatusSection()),
            
          // Right section - Secondary actions  
          Row(
            children: actions
                .where((a) => a.placement == ToolbarPlacement.right)
                .map(_buildToolbarAction)
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarAction(ToolbarAction action) {
    // Handle toggleable actions
    if (action.isToggleable) {
      final isActive = _isToolActive(action.actionType);
      return IconButton(
        icon: Icon(action.icon),
        color: isActive ? theme.primaryColor : null,
        onPressed: () => _handleToolToggle(action),
        tooltip: action.tooltip,
      );
    }

    // Handle normal actions
    return IconButton(
      icon: Icon(action.icon),
      onPressed: action.requiresSelection && !_hasSelection()
          ? null
          : () => _handleToolbarAction(action),
      tooltip: action.tooltip,
    );
  }
}
```

## Mode-Specific Action Handlers

```dart
mixin ModeSpecificHandlers on State<EnhancedWorkPreview> {
  void _handleToolbarAction(ToolbarAction action) {
    switch (widget.mode) {
      case PreviewMode.import:
        _handleImportAction(action);
        break;
      case PreviewMode.edit:
        _handleEditAction(action);
        break;
      case PreviewMode.extract:
        _handleExtractAction(action);
        break;
      default:
        break;
    }
  }

  Future<void> _handleImportAction(ToolbarAction action) async {
    switch (action.actionType) {
      case ToolbarActionType.add:
        await _handleAddImages();
        break;
      case ToolbarActionType.delete:
        final isLastImage = widget.state.images.length == 1;
        if (isLastImage) {
          final confirmed = await _showLastImageDeleteDialog();
          if (confirmed) {
            await _handleDeleteImage();
            Navigator.of(context).pop(); // Exit import
          }
        } else {
          await _handleDeleteImage();
        }
        break;
    }
  }

  Future<void> _handleEditAction(ToolbarAction action) async {
    switch (action.actionType) {
      case ToolbarActionType.add:
        await _handleAddImages();
        break;
      case ToolbarActionType.delete:
        final confirmed = await _showDeleteConfirmation();
        if (confirmed) {
          await _handleDeleteImage();
        }
        break;
      case ToolbarActionType.save:
        await _handleSaveChanges();
        break;
    }
  }

  Future<void> _handleExtractAction(ToolbarAction action) async {
    switch (action.actionType) {
      case ToolbarActionType.boxSelect:
        _toggleBoxSelectionMode();
        break;
      case ToolbarActionType.multiSelect:
        _toggleMultiSelectMode();
        break;
      case ToolbarActionType.delete:
        await _handleDeleteSelectedRegions();
        break;
    }
  }
}
```

## Behavior Implementation

```dart
class PreviewBehaviors {
  final bool allowMultipleImages;
  final bool allowDeletion;
  final bool allowReordering;
  final bool showThumbnails;
  final bool enableZoom;
  final bool enableRegionSelection;
  final bool showSidePanel;
  final bool persistChanges;
  final bool showProcessingIndicator;
  final bool confirmLastImageDeletion;
  final bool exitOnEmpty;
  final bool enableMouseWheelZoom;
  final bool showZoomControls;
}

mixin BehaviorManager on State<EnhancedWorkPreview> {
  PreviewBehaviors get currentBehaviors => 
      _getModeConfig().behaviors;

  bool _isOperationAllowed(PreviewOperation operation) {
    switch (operation) {
      case PreviewOperation.delete:
        return currentBehaviors.allowDeletion;
      case PreviewOperation.reorder:
        return currentBehaviors.allowReordering;
      case PreviewOperation.zoom:
        return currentBehaviors.enableZoom;
      // ... other operations
    }
  }

  void _applyBehaviors() {
    final behaviors = currentBehaviors;
    
    // Configure thumbnail strip
    if (_thumbnailStrip != null) {
      _thumbnailStrip!.isEnabled = behaviors.showThumbnails;
      _thumbnailStrip!.allowReordering = behaviors.allowReordering;
    }

    // Configure zoom
    if (_zoomableView != null) {
      _zoomableView!.enabled = behaviors.enableZoom;
      _zoomableView!.enableMouseWheel = behaviors.enableMouseWheelZoom;
      _zoomableView!.showControls = behaviors.showZoomControls;
    }

    // Configure side panel
    _sidePanel?.visible = behaviors.showSidePanel;

    // Configure processing indicator
    _processingIndicator?.visible = behaviors.showProcessingIndicator;
  }
}
