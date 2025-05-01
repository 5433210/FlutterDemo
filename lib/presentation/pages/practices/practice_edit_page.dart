import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../widgets/common/resizable_panel.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/practice/edit_toolbar.dart';
import '../../widgets/practice/file_operations.dart';
import '../../widgets/practice/page_operations.dart';
import '../../widgets/practice/page_thumbnail_strip.dart';
import '../../widgets/practice/practice_edit_controller.dart';
import '../../widgets/practice/practice_layer_panel.dart';
import '../../widgets/practice/practice_property_panel.dart';
import '../../widgets/practice/top_navigation_bar.dart';
import 'handlers/keyboard_handler.dart';
import 'widgets/content_tools_panel.dart';
import 'widgets/practice_edit_canvas.dart';

/// Main page for practice editing
class PracticeEditPage extends ConsumerStatefulWidget {
  final String? practiceId;

  const PracticeEditPage({super.key, this.practiceId});

  @override
  ConsumerState<PracticeEditPage> createState() => _PracticeEditPageState();
}

/// Dialog for editing practice title
class PracticeTitleEditDialog extends StatefulWidget {
  final String? initialTitle;
  final Future<bool> Function(String) checkTitleExists;

  const PracticeTitleEditDialog({
    Key? key,
    required this.initialTitle,
    required this.checkTitleExists,
  }) : super(key: key);

  @override
  State<PracticeTitleEditDialog> createState() =>
      _PracticeTitleEditDialogState();
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
      // 使用 PageOperations 创建新页面
      final newPage = PageOperations.addPage(_controller.state.pages, null);

      // 添加默认图层
      if (!newPage.containsKey('layers')) {
        newPage['layers'] = [
          {
            'id': 'layer_${DateTime.now().millisecondsSinceEpoch}',
            'name': '默认图层',
            'isVisible': true,
            'isLocked': false,
          }
        ];
      }

      // 添加到页面列表
      _controller.state.pages.add(newPage);

      // 切换到新页面
      _controller.state.currentPageIndex = _controller.state.pages.length - 1;

      // 标记有未保存的更改
      _controller.state.hasUnsavedChanges = true;
    });
  }

  /// Bring element to front
  void _bringElementToFront() {
    if (_controller.state.selectedElementIds.isEmpty) return;

    final id = _controller.state.selectedElementIds.first;
    final elements = _controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index >= 0 && index < elements.length - 1) {
      // Remove element
      final element = elements.removeAt(index);
      // Add to end (top layer)
      elements.add(element);

      // Update current page elements
      _controller.state.pages[_controller.state.currentPageIndex]['elements'] =
          elements;
      _controller.state.hasUnsavedChanges = true;

      setState(() {});
    }
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
    // 检查是否有选中的元素
    if (_controller.state.selectedElementIds.isEmpty) {
      return;
    }

    final elements = _controller.state.currentPageElements;
    final selectedIds = _controller.state.selectedElementIds;

    // 如果只选中了一个元素，使用原来的逻辑
    if (selectedIds.length == 1) {
      final id = selectedIds.first;
      final element = elements.firstWhere((e) => e['id'] == id,
          orElse: () => <String, dynamic>{});

      if (element.isNotEmpty) {
        // Deep copy element
        _clipboardElement = Map<String, dynamic>.from(element);

        // Show notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Element copied to clipboard'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // 多选情况：创建一个特殊的剪贴板对象，包含多个元素
      final selectedElements = <Map<String, dynamic>>[];

      for (final id in selectedIds) {
        final element = elements.firstWhere((e) => e['id'] == id,
            orElse: () => <String, dynamic>{});

        if (element.isNotEmpty) {
          // 深拷贝元素
          selectedElements.add(Map<String, dynamic>.from(element));
        }
      }

      if (selectedElements.isNotEmpty) {
        // 创建一个特殊的剪贴板对象，标记为多元素集合
        _clipboardElement = {
          'type': 'multi_elements',
          'elements': selectedElements,
        };

        // 显示通知
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${selectedElements.length} elements copied to clipboard'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// Delete a page
  void _deletePage(int index) {
    // 确保至少保留一个页面
    if (_controller.state.pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the only page')),
      );
      return;
    }

    setState(() {
      // 删除页面
      PageOperations.deletePage(_controller.state.pages, index);

      // 如果删除的是当前页面，则切换到前一个页面
      if (_controller.state.currentPageIndex >=
          _controller.state.pages.length) {
        _controller.state.currentPageIndex = _controller.state.pages.length - 1;
      }

      // 标记有未保存的更改
      _controller.state.hasUnsavedChanges = true;
    });
  }

  //------------------------------------------------------------------------------
  // Helper methods to handle various actions
  //------------------------------------------------------------------------------

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

  // 生成随机字符串的辅助方法
  String _getRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
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
    if (_controller.state.selectedElementIds.isEmpty) return;

    final id = _controller.state.selectedElementIds.first;
    final elements = _controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index > 0) {
      // Swap current element with element below
      final temp = elements[index];
      elements[index] = elements[index - 1];
      elements[index - 1] = temp;

      // Update current page elements
      _controller.state.pages[_controller.state.currentPageIndex]['elements'] =
          elements;
      _controller.state.hasUnsavedChanges = true;

      setState(() {});
    }
  }

  /// Move element up one layer
  void _moveElementUp() {
    if (_controller.state.selectedElementIds.isEmpty) return;

    final id = _controller.state.selectedElementIds.first;
    final elements = _controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index >= 0 && index < elements.length - 1) {
      // Swap current element with element above
      final temp = elements[index];
      elements[index] = elements[index + 1];
      elements[index + 1] = temp;

      // Update current page elements
      _controller.state.pages[_controller.state.currentPageIndex]['elements'] =
          elements;
      _controller.state.hasUnsavedChanges = true;

      setState(() {});
    }
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
    if (_clipboardElement == null) return;

    final elements = _controller.state.currentPageElements;
    final newElementIds = <String>[];

    // 检查是否是多元素集合
    if (_clipboardElement!['type'] == 'multi_elements') {
      // 处理多元素粘贴
      final clipboardElements = _clipboardElement!['elements'] as List<dynamic>;
      final newElements = <Map<String, dynamic>>[];

      // 获取当前时间戳作为基础
      final baseTimestamp = DateTime.now().millisecondsSinceEpoch;

      // 为每个元素添加索引，确保ID唯一
      int index = 0;
      for (final element in clipboardElements) {
        // 创建新元素ID，添加索引和随机数确保唯一性
        final newId =
            '${element['type']}_${baseTimestamp}_${index}_${_getRandomString(4)}';
        index++;

        // 复制元素并修改位置（稍微偏移一点）
        final newElement = {
          ...Map<String, dynamic>.from(element as Map<String, dynamic>),
          'id': newId,
          'x': (element['x'] as num).toDouble() + 20,
          'y': (element['y'] as num).toDouble() + 20,
        };

        // 添加到新元素列表
        newElements.add(newElement);
        newElementIds.add(newId);
      }

      // 添加所有新元素到当前页面
      elements.addAll(newElements);
    } else {
      // 处理单个元素粘贴（原有逻辑）
      // 创建新元素ID，添加随机字符串确保唯一性
      final newId =
          '${_clipboardElement!['type']}_${DateTime.now().millisecondsSinceEpoch}_${_getRandomString(4)}';

      // 复制元素并修改位置（稍微偏移一点）
      final newElement = {
        ..._clipboardElement!,
        'id': newId,
        'x': (_clipboardElement!['x'] as num).toDouble() + 20,
        'y': (_clipboardElement!['y'] as num).toDouble() + 20,
      };

      // 添加到当前页面
      elements.add(newElement);
      newElementIds.add(newId);
    }

    // 更新当前页面的元素
    _controller.state.pages[_controller.state.currentPageIndex]['elements'] =
        elements;

    // 选中新粘贴的元素 - 如果是多个元素，只选中第一个
    if (newElementIds.length == 1) {
      _controller.state.selectedElementIds = newElementIds;
      _controller.state.selectedElement =
          elements.firstWhere((e) => e['id'] == newElementIds.first);
    } else if (newElementIds.isNotEmpty) {
      // 对于多个元素，只选中第一个，这样点击时不会全部被选中
      final firstId = newElementIds.first;
      _controller.state.selectedElementIds = [firstId];
      _controller.state.selectedElement =
          elements.firstWhere((e) => e['id'] == firstId);
    }
    _controller.state.hasUnsavedChanges = true;

    setState(() {});
  }

  /// Preload all collection element images
  void _preloadAllCollectionImages() {
    // Get current page elements
    final elements = _controller.state.currentPageElements;

    // Get character image service
    final characterImageService = ref.read(characterImageServiceProvider);

    // Iterate through all elements to find collection elements
    for (final element in elements) {
      if (element['type'] == 'collection') {
        // Get collection element content
        final content = element['content'] as Map<String, dynamic>?;
        if (content == null) continue;

        // Get character image info
        final characterImages =
            content['characterImages'] as Map<String, dynamic>?;
        if (characterImages == null) continue;

        // Get character list
        final characters = content['characters'] as String?;
        if (characters == null || characters.isEmpty) continue;

        // Preload each character's image
        for (int i = 0; i < characters.length; i++) {
          final char = characters[i];

          // Try multiple ways to find the image info for the character
          Map<String, dynamic>? charImage;

          // Try direct lookup by character
          if (characterImages.containsKey(char)) {
            charImage = characterImages[char] as Map<String, dynamic>;
          }
          // Try lookup by index
          else if (characterImages.containsKey('$i')) {
            charImage = characterImages['$i'] as Map<String, dynamic>;
          }
          // Try to find any matching character
          else {
            for (final key in characterImages.keys) {
              final value = characterImages[key];
              if (value is Map<String, dynamic> &&
                  value.containsKey('characterId') &&
                  (value.containsKey('character') &&
                      value['character'] == char)) {
                charImage = value;
                break;
              }
            }
          }

          if (charImage != null && charImage.containsKey('characterId')) {
            final characterId = charImage['characterId'].toString();
            final type = charImage['type'] as String? ?? 'square-binary';
            final format = charImage['format'] as String? ?? 'png-binary';

            // Preload image
            characterImageService.getCharacterImage(
              characterId,
              type,
              format,
            );
          }
        }
      }
    }
  }

  /// Reorder pages
  void _reorderPages(int oldIndex, int newIndex) {
    setState(() {
      // 处理 ReorderableListView 的特殊情况
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      // 移动页面
      final page = _controller.state.pages.removeAt(oldIndex);
      _controller.state.pages.insert(newIndex, page);

      // 更新页面索引和名称
      for (int i = 0; i < _controller.state.pages.length; i++) {
        _controller.state.pages[i]['index'] = i;
        _controller.state.pages[i]['name'] = '页面 ${i + 1}';
      }

      // 如果重新排序的是当前页面，更新当前页面索引
      if (oldIndex == _controller.state.currentPageIndex) {
        _controller.state.currentPageIndex = newIndex;
      } else if (oldIndex < _controller.state.currentPageIndex &&
          newIndex >= _controller.state.currentPageIndex) {
        _controller.state.currentPageIndex--;
      } else if (oldIndex > _controller.state.currentPageIndex &&
          newIndex <= _controller.state.currentPageIndex) {
        _controller.state.currentPageIndex++;
      }

      // 标记有未保存的更改
      _controller.state.hasUnsavedChanges = true;
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
    if (_controller.state.selectedElementIds.isEmpty) return;

    final id = _controller.state.selectedElementIds.first;
    final elements = _controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index > 0) {
      // Remove element
      final element = elements.removeAt(index);
      // Add to beginning (bottom layer)
      elements.insert(0, element);

      // Update current page elements
      _controller.state.pages[_controller.state.currentPageIndex]['elements'] =
          elements;
      _controller.state.hasUnsavedChanges = true;

      setState(() {});
    }
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
    try {
      // Use file_picker to open file selection dialog
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        dialogTitle: 'Select Image',
        lockParentWindow: true,
      );

      // If user cancels selection, result will be null
      if (result == null || result.files.isEmpty) {
        return;
      }

      // Get selected file path
      final file = result.files.first;
      final filePath = file.path;

      if (filePath == null || filePath.isEmpty) {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get file path')),
          );
        }
        return;
      }

      // Convert file path to usable URL format
      final fileUrl = 'file://$filePath';

      // Update or add image element
      if (_controller.state.selectedElementIds.isNotEmpty) {
        // If there are selected elements, update its image URL
        final elementId = _controller.state.selectedElementIds.first;
        final element = _controller.state.currentPageElements.firstWhere(
          (e) => e['id'] == elementId,
          orElse: () => <String, dynamic>{},
        );

        if (element.isNotEmpty && element['type'] == 'image') {
          // Update existing image element URL
          final content = Map<String, dynamic>.from(
              element['content'] as Map<String, dynamic>);
          content['imageUrl'] = fileUrl;
          // Set isTransformApplied to true to ensure image displays immediately
          content['isTransformApplied'] = true;
          _controller.updateElementProperties(elementId, {'content': content});

          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image updated')),
            );
          }
        } else {
          // Add new image element
          _controller.addImageElement(fileUrl);
        }
      } else {
        // Add new image element
        _controller.addImageElement(fileUrl);
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  /// Toggle grid visibility
  void _toggleGrid() {
    setState(() {
      _controller.state.gridVisible = !_controller.state.gridVisible;
    });
  }

  /// Toggle lock state of selected elements
  void _toggleSelectedElementsLock() {
    if (_controller.state.selectedElementIds.isEmpty) return;

    for (final id in _controller.state.selectedElementIds) {
      // Get current element
      final elements =
          _controller.state.currentPage?['elements'] as List<dynamic>?;
      if (elements == null) continue;

      final elementIndex = elements.indexWhere((e) => e['id'] == id);
      if (elementIndex == -1) continue;

      final element = elements[elementIndex] as Map<String, dynamic>;

      // Toggle lock state
      final isLocked = element['locked'] ?? false;
      _controller.updateElementProperty(id, 'locked', !isLocked);
    }
  }

  /// Toggle visibility of selected elements
  void _toggleSelectedElementsVisibility() {
    if (_controller.state.selectedElementIds.isEmpty) return;

    for (final id in _controller.state.selectedElementIds) {
      // Get current element
      final elements =
          _controller.state.currentPage?['elements'] as List<dynamic>?;
      if (elements == null) continue;

      final elementIndex = elements.indexWhere((e) => e['id'] == id);
      if (elementIndex == -1) continue;

      final element = elements[elementIndex] as Map<String, dynamic>;

      // Toggle hidden state
      final isHidden = element['hidden'] ?? false;
      _controller.updateElementProperty(id, 'hidden', !isHidden);
    }
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

class _PracticeTitleEditDialogState extends State<PracticeTitleEditDialog> {
  late TextEditingController _controller;
  String? _errorText;
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Practice Title'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: 'Title',
          errorText: _errorText,
          enabled: !_isChecking,
        ),
        autofocus: true,
        onSubmitted: _validateAndSubmit,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed:
              _isChecking ? null : () => _validateAndSubmit(_controller.text),
          child: _isChecking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  Future<void> _validateAndSubmit(String value) async {
    if (value.isEmpty) {
      setState(() {
        _errorText = 'Title cannot be empty';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorText = null;
    });

    // Check if title already exists
    if (value != widget.initialTitle) {
      final exists = await widget.checkTitleExists(value);
      if (exists) {
        setState(() {
          _errorText = 'A practice with this title already exists';
          _isChecking = false;
        });
        return;
      }
    }

    setState(() {
      _isChecking = false;
    });

    if (context.mounted) {
      Navigator.of(context).pop(value);
    }
  }
}
