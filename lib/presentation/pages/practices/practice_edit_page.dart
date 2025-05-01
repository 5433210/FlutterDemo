import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../widgets/common/resizable_panel.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/practice/edit_toolbar.dart';
import '../../widgets/practice/file_operations.dart';
import '../../widgets/practice/page_thumbnail_strip.dart';
import '../../widgets/practice/practice_edit_controller.dart';
import '../../widgets/practice/practice_layer_panel.dart';
import '../../widgets/practice/practice_property_panel.dart';
import '../../widgets/practice/top_navigation_bar.dart';
import 'handlers/keyboard_handler.dart';
import 'utils/practice_edit_utils.dart';
import 'widgets/content_tools_panel.dart';
import 'widgets/practice_edit_canvas.dart';
import 'widgets/practice_title_edit_dialog.dart';

/// Main page for practice editing
class PracticeEditPage extends ConsumerStatefulWidget {
  final String? practiceId;

  const PracticeEditPage({super.key, this.practiceId});

  @override
  ConsumerState<PracticeEditPage> createState() => _PracticeEditPageState();
}

class _PracticeEditPageState extends ConsumerState<PracticeEditPage> {
  // Controller
  late final PracticeEditController _controller;

  // Current tool
  String _currentTool = 'select';

  // Clipboard
  Map<String, dynamic>? _clipboardElement;

  // Preview mode
  bool _isPreviewMode = false;

  // Add a GlobalKey for screenshots
  final GlobalKey canvasKey = GlobalKey();

  // Keyboard focus node
  late FocusNode _focusNode;

  // Zoom controller
  late TransformationController _transformationController;

  // Control page thumbnails display state
  bool _showThumbnails = false;

  // Keyboard handler
  late KeyboardHandler _keyboardHandler;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: PageLayout(
        toolbar: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return TopNavigationBar(
              controller: _controller,
              practiceId: widget.practiceId,
              isPreviewMode: _isPreviewMode,
              onTogglePreviewMode: () {
                setState(() {
                  _isPreviewMode = !_isPreviewMode; // Toggle preview mode
                  _controller
                      .togglePreviewMode(_isPreviewMode); // Notify controller
                });
              },
              showThumbnails: _showThumbnails,
              onThumbnailToggle: (bool value) {
                setState(() {
                  _showThumbnails = value; // Update thumbnails display state
                });
              },
            );
          },
        ),
        body: _buildBody(context),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Load practice in didChangeDependencies instead of initState
    // This way we can safely use context
    if (widget.practiceId != null) {
      _loadPractice(widget.practiceId!);
    }
  }

  @override
  void dispose() {
    // Clear undo/redo stack
    _controller.clearUndoRedoHistory();

    // Remove keyboard listeners
    HardwareKeyboard.instance.removeHandler(_keyboardHandler.handleKeyEvent);
    _focusNode.dispose();

    // Release zoom controller
    _transformationController.dispose();

    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Create or get the PracticeService instance
    final practiceService = ref.read(practiceServiceProvider);
    _controller = PracticeEditController(practiceService);

    // Pass canvasKey to controller
    _controller.setCanvasKey(canvasKey);

    // Set preview mode callback
    _controller.setPreviewModeCallback((isPreview) {
      setState(() {
        _isPreviewMode = isPreview;
      });
    });

    // Initialize keyboard focus node
    _focusNode = FocusNode();

    // Initialize zoom controller
    _transformationController = TransformationController();
    debugPrint(
        '【平移】PracticeEditPageRefactored.initState: 初始化 transformationController=$_transformationController, 值=${_transformationController.value}');

    // Initialize keyboard handler
    _keyboardHandler = KeyboardHandler(
      controller: _controller,
      onTogglePreviewMode: () {
        setState(() {
          _isPreviewMode = !_isPreviewMode;
          _controller.togglePreviewMode(_isPreviewMode);
        });
      },
      onToggleThumbnails: () {
        setState(() {
          _showThumbnails = !_showThumbnails;
        });
      },
      editTitle: _editTitle,
      savePractice: _savePractice,
      saveAsNewPractice: _saveAsNewPractice,
      selectAllElements: _selectAllElements,
      copySelectedElement: _copySelectedElement,
      pasteElement: _pasteElement,
      deleteSelectedElements: _deleteSelectedElements,
      groupSelectedElements: _groupSelectedElements,
      ungroupElements: _ungroupElements,
      bringToFront: _bringElementToFront,
      sendToBack: _sendElementToBack,
      moveElementUp: _moveElementUp,
      moveElementDown: _moveElementDown,
      toggleGrid: _toggleGrid,
      toggleSnap: _toggleSnap,
      toggleSelectedElementsVisibility: _toggleSelectedElementsVisibility,
      toggleSelectedElementsLock: _toggleSelectedElementsLock,
      showExportDialog: _showExportDialog,
      moveSelectedElements: _moveSelectedElements,
    );

    // Add keyboard listener
    HardwareKeyboard.instance.addHandler(_keyboardHandler.handleKeyEvent);
  }

  /// Add a new page
  void _addNewPage() {
    setState(() {
      PracticeEditUtils.addNewPage(_controller);
    });
  }

  /// Bring element to front
  void _bringElementToFront() {
    setState(() {
      PracticeEditUtils.bringElementToFront(_controller);
    });
  }

  /// Build the body of the page
  Widget _buildBody(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          children: [
            // Left panel
            if (!_isPreviewMode) _buildLeftPanel(),

            // Central edit area
            Expanded(
              child: Column(
                children: [
                  // Toolbar
                  if (!_isPreviewMode) _buildEditToolbar(),

                  // Edit canvas - 使用ProviderScope包装，确保可以访问ref
                  Expanded(
                    child: ProviderScope(
                      child: PracticeEditCanvas(
                        controller: _controller,
                        isPreviewMode: _isPreviewMode,
                        canvasKey: canvasKey,
                        transformationController: _transformationController,
                      ),
                    ),
                  ),

                  // Page thumbnails
                  if (_showThumbnails && !_isPreviewMode)
                    _buildPageThumbnails(),
                ],
              ),
            ),

            // Right properties panel
            if (!_isPreviewMode) _buildRightPanel(),
          ],
        );
      },
    );
  }

  /// Build the edit toolbar
  Widget _buildEditToolbar() {
    return EditToolbar(
      controller: _controller,
      gridVisible: _controller.state.gridVisible,
      snapEnabled: _controller.state.snapEnabled,
      onToggleGrid: _toggleGrid,
      onToggleSnap: _toggleSnap,
      onCopy: _copySelectedElement,
      onPaste: _pasteElement,
      onGroupElements: _groupSelectedElements,
      onUngroupElements: _ungroupElements,
      onBringToFront: _bringElementToFront,
      onSendToBack: _sendElementToBack,
      onMoveUp: _moveElementUp,
      onMoveDown: _moveElementDown,
      onDelete: _deleteSelectedElements,
    );
  }

  /// Build the left panel
  Widget _buildLeftPanel() {
    return ResizablePanel(
      initialWidth: 250,
      minWidth: 150,
      maxWidth: 400,
      isLeftPanel: true,
      child: Column(
        children: [
          // Content tools area
          ContentToolsPanel(
            controller: _controller,
            currentTool: _currentTool,
            onToolSelected: (tool) {
              setState(() {
                _currentTool = tool;
              });
            },
          ),

          const Divider(),

          // Layer management area
          Expanded(
            child: PracticeLayerPanel(
              controller: _controller,
              onLayerSelect: (layerId) {
                // Handle layer selection
                _controller.selectLayer(layerId);
              },
              onLayerVisibilityToggle: (layerId, isVisible) {
                // Handle layer visibility toggle
                _controller.toggleLayerVisibility(layerId, isVisible);
              },
              onLayerLockToggle: (layerId, isLocked) {
                // Handle layer lock toggle
                _controller.toggleLayerLock(layerId, isLocked);
              },
              onAddLayer: _controller.addNewLayer,
              onDeleteLayer: _controller.deleteLayer,
              onReorderLayer: _controller.reorderLayer,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the page thumbnails area
  Widget _buildPageThumbnails() {
    return PageThumbnailStrip(
      pages: _controller.state.pages,
      currentPageIndex: _controller.state.currentPageIndex,
      onPageSelected: (index) {
        setState(() {
          _controller.state.currentPageIndex = index;
        });
      },
      onAddPage: _addNewPage,
      onDeletePage: _deletePage,
      onReorderPages: _reorderPages,
    );
  }

  /// Build the right properties panel
  Widget _buildRightPanel() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        Widget panel;

        // Check if a layer is selected
        if (_controller.state.selectedLayerId != null) {
          // Show layer properties when layer is selected
          final layerId = _controller.state.selectedLayerId!;
          final layer = _controller.state.getLayerById(layerId);
          if (layer != null) {
            panel = PracticePropertyPanel.forLayer(
              controller: _controller,
              layer: layer,
              onLayerPropertiesChanged: (properties) {
                // Update layer properties
                _controller.updateLayerProperties(layerId, properties);
              },
            );

            // Return resizable panel
            return ResizablePanel(
              initialWidth: 300,
              minWidth: 200,
              maxWidth: 500,
              isLeftPanel: false,
              child: panel,
            );
          }
        }

        // Show different property panels based on selected element type
        if (_controller.state.selectedElementIds.isEmpty) {
          // Show page properties when no element is selected
          panel = PracticePropertyPanel.forPage(
            controller: _controller,
            page: _controller.state.currentPage,
            onPagePropertiesChanged: (properties) {
              if (_controller.state.currentPageIndex >= 0) {
                _controller.updatePageProperties(properties);
              }
            },
          );
        } else if (_controller.state.selectedElementIds.length == 1) {
          // Show element-specific properties when one element is selected
          final id = _controller.state.selectedElementIds.first;
          final element = _controller.state.currentPageElements.firstWhere(
            (e) => e['id'] == id,
            orElse: () => <String, dynamic>{},
          );

          if (element.isNotEmpty) {
            switch (element['type']) {
              case 'text':
                panel = PracticePropertyPanel.forText(
                  controller: _controller,
                  element: element,
                  onElementPropertiesChanged: (properties) {
                    _controller.updateElementProperties(id, properties);
                  },
                );
                break;
              case 'image':
                panel = PracticePropertyPanel.forImage(
                  controller: _controller,
                  element: element,
                  onElementPropertiesChanged: (properties) {
                    _controller.updateElementProperties(id, properties);
                  },
                  onSelectImage: () async {
                    // Implement image selection logic
                    await _showImageUrlDialog(context);
                  },
                  ref: ref,
                );
                break;
              case 'collection':
                panel = PracticePropertyPanel.forCollection(
                  controller: _controller,
                  element: element,
                  onElementPropertiesChanged: (properties) {
                    _controller.updateElementProperties(id, properties);
                  },
                  onUpdateChars: (chars) {
                    // Get the current content map
                    final content = Map<String, dynamic>.from(
                        element['content'] as Map<String, dynamic>);
                    // Update the characters property
                    content['characters'] = chars;
                    // Update the element with the modified content map
                    final updatedProps = {'content': content};
                    _controller.updateElementProperties(id, updatedProps);
                  },
                  ref: ref,
                );
                break;
              case 'group':
                panel = PracticePropertyPanel.forGroup(
                  controller: _controller,
                  element: element,
                  onElementPropertiesChanged: (properties) {
                    _controller.updateElementProperties(id, properties);
                  },
                );
                break;
              default:
                panel = const Center(child: Text('Unsupported element type'));
            }
          } else {
            panel = const Center(child: Text('Selected element not found'));
          }
        } else {
          // Show multi-selection properties when multiple elements are selected
          panel = PracticePropertyPanel.forMultiSelection(
            controller: _controller,
            selectedIds: _controller.state.selectedElementIds,
            onElementPropertiesChanged: (properties) {
              // Apply properties to all selected elements
              for (final id in _controller.state.selectedElementIds) {
                _controller.updateElementProperties(id, properties);
              }
            },
          );
        }

        return ResizablePanel(
          initialWidth: 300,
          minWidth: 200,
          maxWidth: 500,
          isLeftPanel: false,
          child: panel,
        );
      },
    );
  }

  /// Copy selected elements
  void _copySelectedElement() {
    _clipboardElement =
        PracticeEditUtils.copySelectedElements(_controller, context);
  }

  /// Delete a page
  void _deletePage(int index) {
    setState(() {
      PracticeEditUtils.deletePage(_controller, index, context);
    });
  }

  /// Delete selected elements
  void _deleteSelectedElements() {
    if (_controller.state.selectedElementIds.isEmpty) return;

    // Create a copy to avoid ConcurrentModificationError
    final idsToDelete = List<String>.from(_controller.state.selectedElementIds);
    for (final id in idsToDelete) {
      _controller.deleteElement(id);
    }
  }

  /// Edit title
  Future<void> _editTitle() async {
    if (!mounted) return;

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => PracticeTitleEditDialog(
        initialTitle: _controller.practiceTitle,
        checkTitleExists: _controller.checkTitleExists,
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      _controller.updatePracticeTitle(newTitle);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Title updated to "$newTitle"')),
        );
      }
    }
  }

  /// Group selected elements
  void _groupSelectedElements() {
    if (_controller.state.selectedElementIds.length > 1) {
      _controller.groupSelectedElements();
    }
  }

  /// Load practice
  Future<void> _loadPractice(String id) async {
    // First check if we've already loaded this practice ID, avoid duplicate loading
    if (_controller.practiceId == id) {
      debugPrint('Practice already loaded, skipping duplicate load: $id');
      return;
    }

    // Save a reference before starting async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      debugPrint('Starting practice load: $id');

      // Call controller's loadPractice method
      final success = await _controller.loadPractice(id);

      if (success) {
        // Load success, update UI
        if (mounted) {
          setState(() {
            // Reset zoom and pan
            _transformationController.value = Matrix4.identity();
          });

          // Show success notification
          scaffoldMessenger.showSnackBar(
            SnackBar(
                content: Text(
                    'Practice "${_controller.practiceTitle}" loaded successfully')),
          );

          debugPrint(
              'Practice loaded successfully: ${_controller.practiceTitle}');

          // Preload all collection element images
          _preloadAllCollectionImages();
        }
      } else {
        // Load failed
        if (mounted) {
          // Show failure notification
          scaffoldMessenger.showSnackBar(
            const SnackBar(
                content: Text(
                    'Failed to load practice: Practice does not exist or has been deleted')),
          );
          debugPrint(
              'Practice load failed: Practice does not exist or has been deleted');
        }
      }
    } catch (e) {
      // Handle exceptions
      debugPrint('Failed to load practice: $e');
      if (mounted) {
        // Show exception notification
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to load practice: $e')),
        );
      }
    }
  }

  /// Move element down one layer
  void _moveElementDown() {
    setState(() {
      PracticeEditUtils.moveElementDown(_controller);
    });
  }

  /// Move element up one layer
  void _moveElementUp() {
    setState(() {
      PracticeEditUtils.moveElementUp(_controller);
    });
  }

  /// Move selected elements
  void _moveSelectedElements(double dx, double dy) {
    if (_controller.state.selectedElementIds.isEmpty) return;

    final elements = _controller.state.currentPageElements;
    bool hasChanges = false;

    for (final id in _controller.state.selectedElementIds) {
      final elementIndex = elements.indexWhere((e) => e['id'] == id);
      if (elementIndex >= 0) {
        final element = elements[elementIndex];

        // Check if element's layer is locked
        final layerId = element['layerId'] as String?;
        if (layerId != null && _controller.state.isLayerLocked(layerId)) {
          continue; // Skip elements on locked layers
        }

        // Update element position
        element['x'] = (element['x'] as num).toDouble() + dx;
        element['y'] = (element['y'] as num).toDouble() + dy;
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _controller.state.hasUnsavedChanges = true;
      setState(() {});
    }
  }

  /// Handle back button
  Future<bool> _onWillPop() async {
    // Check for unsaved changes
    if (_controller.state.hasUnsavedChanges) {
      // Show confirmation dialog
      final bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Unsaved Changes'),
            content:
                const Text('You have unsaved changes. Do you want to leave?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Leave'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
              TextButton(
                child: const Text('Save and Leave'),
                onPressed: () async {
                  // Save changes
                  await _savePractice();
                  if (context.mounted) {
                    // Return true to confirm leaving
                    Navigator.of(context).pop(true);
                  }
                },
              ),
            ],
          );
        },
      );

      // If user cancels, don't leave
      return result ?? false;
    }

    // No unsaved changes, can leave
    return true;
  }

  /// Paste element(s)
  void _pasteElement() {
    setState(() {
      PracticeEditUtils.pasteElement(_controller, _clipboardElement);
    });
  }

  /// Preload all collection element images
  void _preloadAllCollectionImages() {
    // Get character image service
    final characterImageService = ref.read(characterImageServiceProvider);
    PracticeEditUtils.preloadAllCollectionImages(
        _controller, characterImageService);
  }

  /// Reorder pages
  void _reorderPages(int oldIndex, int newIndex) {
    setState(() {
      PracticeEditUtils.reorderPages(_controller, oldIndex, newIndex);
    });
  }

  /// Save as new practice
  Future<void> _saveAsNewPractice() async {
    if (_controller.state.pages.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save: Practice has no pages')),
      );
      return;
    }

    // Save ScaffoldMessenger reference to avoid using context after async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Use StatefulBuilder to create dialog, ensuring controller is managed within dialog lifecycle
    final title = await showDialog<String>(
      context: context,
      barrierDismissible: true, // Allow clicking outside to close dialog
      builder: (context) {
        // Create controller inside dialog to ensure its lifecycle matches the dialog
        final TextEditingController textController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Save Practice'),
              content: TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Practice Title',
                  hintText: 'Please enter practice title',
                ),
                onSubmitted: (value) => Navigator.of(context).pop(value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(textController.text);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (title == null || title.isEmpty) return;

    // Save practice
    final result = await _controller.saveAsNewPractice(title);

    if (!mounted) return;

    if (result == true) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Practice "$title" saved successfully')),
      );
    } else if (result == 'title_exists') {
      // Title already exists, ask whether to overwrite
      final shouldOverwrite = await showDialog<bool>(
        context: context,
        barrierDismissible: true, // Allow clicking outside to close dialog
        builder: (context) {
          return AlertDialog(
            title: const Text('Title Already Exists'),
            content: const Text(
                'A practice with this title already exists. Overwrite?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Overwrite'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      if (shouldOverwrite == true) {
        final saveResult =
            await _controller.saveAsNewPractice(title, forceOverwrite: true);

        if (!mounted) return;

        if (saveResult == true) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Practice "$title" saved successfully')),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Save failed')),
          );
        }
      }
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Save failed')),
      );
    }
  }

  /// Save practice
  Future<void> _savePractice() async {
    if (_controller.state.pages.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save: Practice has no pages')),
      );
      return;
    }

    // Save ScaffoldMessenger reference to avoid using context after async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // If never saved before, show dialog to enter title
    if (!_controller.isSaved) {
      await _saveAsNewPractice();
      return;
    }

    // Save practice
    final result = await _controller.savePractice();

    if (!mounted) return;

    if (result == true) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Save successful')),
      );
    } else if (result == 'title_exists') {
      // Title already exists, ask whether to overwrite
      final shouldOverwrite = await showDialog<bool>(
        context: context,
        barrierDismissible: true, // Allow clicking outside to close dialog
        builder: (context) {
          return AlertDialog(
            title: const Text('Title Already Exists'),
            content: const Text(
                'A practice with this title already exists. Overwrite?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Overwrite'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      if (shouldOverwrite == true) {
        final saveResult = await _controller.savePractice(forceOverwrite: true);

        if (!mounted) return;

        if (saveResult == true) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Save successful')),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Save failed')),
          );
        }
      }
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Save failed')),
      );
    }
  }

  /// Select all elements on current page
  void _selectAllElements() {
    if (_controller.state.currentPageIndex < 0 ||
        _controller.state.currentPageIndex >= _controller.state.pages.length) {
      return;
    }

    final elements = _controller.state.currentPageElements;
    if (elements.isEmpty) return;

    // Collect IDs of all elements on unlocked layers
    final ids = <String>[];
    for (final element in elements) {
      final id = element['id'] as String;
      final layerId = element['layerId'] as String?;

      // If element's layer is not locked, add to selection list
      if (layerId == null || !_controller.state.isLayerLocked(layerId)) {
        ids.add(id);
      }
    }

    // Update selection state
    _controller.state.selectedElementIds = ids;
    _controller.state.selectedElement =
        null; // Don't set single selected element in multi-selection

    setState(() {});
  }

  /// Send element to back
  void _sendElementToBack() {
    setState(() {
      PracticeEditUtils.sendElementToBack(_controller);
    });
  }

  /// Show export dialog
  Future<void> _showExportDialog() async {
    if (!mounted) return;

    // Get default filename
    final defaultFileName = _controller.practiceTitle ?? 'Untitled Practice';

    // Call FileOperations.exportPractice method, consistent with export button behavior
    await FileOperations.exportPractice(
      context,
      _controller.state.pages,
      _controller,
      defaultFileName,
    );
  }

  /// Select local image
  Future<void> _showImageUrlDialog(BuildContext context) async {
    await PracticeEditUtils.showImageUrlDialog(context, _controller);
  }

  /// Toggle grid visibility
  void _toggleGrid() {
    setState(() {
      _controller.state.gridVisible = !_controller.state.gridVisible;
    });
  }

  /// Toggle lock state of selected elements
  void _toggleSelectedElementsLock() {
    setState(() {
      PracticeEditUtils.toggleSelectedElementsLock(_controller);
    });
  }

  /// Toggle visibility of selected elements
  void _toggleSelectedElementsVisibility() {
    setState(() {
      PracticeEditUtils.toggleSelectedElementsVisibility(_controller);
    });
  }

  /// Toggle snap to grid
  void _toggleSnap() {
    setState(() {
      _controller.state.snapEnabled = !_controller.state.snapEnabled;
    });
  }

  /// Ungroup elements
  void _ungroupElements() {
    if (_controller.state.selectedElementIds.length == 1) {
      final id = _controller.state.selectedElementIds.first;
      final element = _controller.state.currentPageElements.firstWhere(
        (e) => e['id'] == id,
        orElse: () => <String, dynamic>{},
      );

      if (element.isNotEmpty && element['type'] == 'group') {
        _controller.ungroupElements(id);
      }
    }
  }
}
