import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../application/providers/service_providers.dart';
import '../../../application/services/character/character_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/persistent_resizable_panel.dart';
import '../../widgets/common/persistent_sidebar_toggle.dart';
import '../../widgets/page_layout.dart';
// import '../../widgets/practice/edit_toolbar.dart';
// import '../../widgets/practice/file_operations.dart';
// import '../../widgets/practice/page_thumbnail_strip.dart';
import '../../widgets/practice/file_operations.dart';
import '../../widgets/practice/m3_edit_toolbar.dart';
import '../../widgets/practice/m3_page_thumbnail_strip.dart';
import '../../widgets/practice/m3_practice_layer_panel.dart';
import '../../widgets/practice/m3_top_navigation_bar.dart';
import '../../widgets/practice/practice_edit_controller.dart';
// import '../../widgets/practice/practice_layer_panel.dart';
// import '../../widgets/practice/practice_property_panel.dart';
// import '../../widgets/practice/top_navigation_bar.dart';
import '../../widgets/practice/property_panels/m3_practice_property_panels.dart';
import '../../widgets/practice/undo_redo_manager.dart';
import 'handlers/keyboard_handler.dart';
import 'utils/practice_edit_utils.dart';
// import 'widgets/m3_content_tools_panel.dart' - Removed as elements were moved to toolbar;
import 'widgets/m3_practice_edit_canvas.dart';
// import 'widgets/content_tools_panel.dart';
// import 'widgets/practice_edit_canvas.dart';
import 'widgets/practice_title_edit_dialog.dart';

/// Material 3 version of the Practice Edit page
class M3PracticeEditPage extends ConsumerStatefulWidget {
  final String? practiceId;

  const M3PracticeEditPage({super.key, this.practiceId});

  @override
  ConsumerState<M3PracticeEditPage> createState() => _M3PracticeEditPageState();
}

class _M3PracticeEditPageState extends ConsumerState<M3PracticeEditPage> {
  // Controller
  late final PracticeEditController _controller;

  // Current tool
  String _currentTool = '';

  // Clipboard monitoring timer
  Timer? _clipboardMonitoringTimer;

  // Clipboard
  Map<String, dynamic>? _clipboardElement;
  bool _clipboardHasContent = false; // Track if clipboard has valid content

  // Preview mode
  bool _isPreviewMode = false;
  // Add a GlobalKey for screenshots
  // final GlobalKey canvasKey = GlobalKey();

  // Add a GlobalKey for canvas reference (without type parameter)
  final GlobalKey _canvasKey = GlobalKey();

  // Keyboard focus node
  late FocusNode _focusNode;

  // Zoom controller
  late TransformationController _transformationController;

  // Control page thumbnails display state
  bool _showThumbnails = false;

  // Control panel visibility
  bool _isLeftPanelOpen = false; // Default to closed as requested
  bool _isRightPanelOpen = true;

  // Keyboard handler
  late KeyboardHandler _keyboardHandler;

  // 格式刷相关变量
  Map<String, dynamic>? _formatBrushStyles;
  bool _isFormatBrushActive = false;

  @override
  Widget build(BuildContext context) {
    // Remove unused l10n variable
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: PageLayout(
        toolbar: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return M3TopNavigationBar(
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

    // Remove controller listener
    _controller.removeListener(_syncToolState);

    // Release zoom controller
    _transformationController.dispose();

    _controller.dispose();

    // Cancel clipboard monitoring timer
    _clipboardMonitoringTimer?.cancel();

    super.dispose();
  }

  /// 生成随机字符串
  String getRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt((random.hashCode + _) % chars.length),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Create or get the PracticeService instance
    final practiceService = ref.read(practiceServiceProvider);
    _controller =
        PracticeEditController(practiceService); // Pass canvasKey to controller
    _controller.setCanvasKey(_canvasKey);

    // Set preview mode callback
    _controller.setPreviewModeCallback((isPreview) {
      setState(() {
        _isPreviewMode = isPreview;
      });
    });

    // Add listener to synchronize local _currentTool with controller's state.currentTool
    _controller.addListener(_syncToolState);

    // Initialize keyboard focus node
    _focusNode = FocusNode();

    // Initialize zoom controller
    _transformationController = TransformationController();
    debugPrint(
        '【平移】PracticeEditPageRefactored.initState: 初始化 transformationController=$_transformationController, 值=${_transformationController.value}');

    // Initialize keyboard handler
    _initKeyboardHandler();

    // Make sure controller state matches our initial empty tool state
    _controller.state.currentTool = _currentTool;

    // Schedule a callback to connect the canvas after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Connect canvas to controller for reset view functionality
      _setupCanvasReference();
    });

    // Start clipboard monitoring
    _checkClipboardContent().then((hasContent) {
      setState(() {
        _clipboardHasContent = hasContent;
      });
      _startClipboardMonitoring();
    });
  }

  /// Add a new page
  void _addNewPage() {
    setState(() {
      PracticeEditUtils.addNewPage(_controller, context);
    });
  }

  /// 应用格式刷样式到选中元素
  void _applyFormatBrush() {
    if (!_isFormatBrushActive || _formatBrushStyles == null) return;

    final selectedElements = _controller.state.getSelectedElements();
    if (selectedElements.isEmpty) return;

    // 准备格式刷操作所需的数据
    final List<String> targetElementIds = [];
    final List<Map<String, dynamic>> oldPropertiesList = [];
    final List<Map<String, dynamic>> newPropertiesList = []; // 对每个选中的元素计算新旧属性
    for (final element in selectedElements) {
      final elementId = element['id'] as String;
      final elementType = element['type'];

      // 深拷贝原始元素作为旧属性
      final oldProperties = _deepCopyElement(element);

      // 深拷贝原始元素并应用格式刷样式作为新属性
      final newProperties = _deepCopyElement(element);

      // 应用通用样式 - 外层属性
      if (_formatBrushStyles!.containsKey('rotation')) {
        newProperties['rotation'] = _formatBrushStyles!['rotation'];
      }
      if (_formatBrushStyles!.containsKey('opacity')) {
        newProperties['opacity'] = _formatBrushStyles!['opacity'];
      }
      if (_formatBrushStyles!.containsKey('width')) {
        newProperties['width'] = _formatBrushStyles!['width'];
      }
      if (_formatBrushStyles!.containsKey('height')) {
        newProperties['height'] = _formatBrushStyles!['height'];
      }

      // 应用特定类型的样式
      if (elementType == 'text') {
        // 兼容旧版本的文本元素结构
        if (_formatBrushStyles!.containsKey('fontSize')) {
          newProperties['fontSize'] = _formatBrushStyles!['fontSize'];
        }
        if (_formatBrushStyles!.containsKey('fontWeight')) {
          newProperties['fontWeight'] = _formatBrushStyles!['fontWeight'];
        }
        if (_formatBrushStyles!.containsKey('fontStyle')) {
          newProperties['fontStyle'] = _formatBrushStyles!['fontStyle'];
        }
        if (_formatBrushStyles!.containsKey('textColor')) {
          newProperties['textColor'] = _formatBrushStyles!['textColor'];
        }
        if (_formatBrushStyles!.containsKey('textAlign')) {
          newProperties['textAlign'] = _formatBrushStyles!['textAlign'];
        }

        // 新版本文本元素结构处理 - content属性
        if (newProperties.containsKey('content') &&
            newProperties['content'] is Map) {
          Map<String, dynamic> content =
              Map<String, dynamic>.from(newProperties['content'] as Map);

          // 应用文本元素的content属性
          final propertiesToApply = [
            'backgroundColor',
            'fontColor',
            'fontFamily',
            'fontSize',
            'fontStyle',
            'fontWeight',
            'letterSpacing',
            'lineHeight',
            'padding',
            'textAlign',
            'verticalAlign',
            'writingMode'
          ];

          // 应用所有指定的样式属性
          for (final property in propertiesToApply) {
            final brushKey = 'content_$property';
            if (_formatBrushStyles!.containsKey(brushKey)) {
              content[property] = _formatBrushStyles![brushKey];
            }
          }

          // 更新元素的content属性
          newProperties['content'] = content;
        }
      } else if (elementType == 'image') {
        // 图像元素的content属性处理
        if (newProperties.containsKey('content') &&
            newProperties['content'] is Map) {
          Map<String, dynamic> content =
              Map<String, dynamic>.from(newProperties['content'] as Map);

          // 应用图像元素的content属性
          final propertiesToApply = [
            'backgroundColor',
            'fit',
            'isFlippedHorizontally',
            'isFlippedVertically',
            'rotation'
          ];

          // 应用所有指定的样式属性
          for (final property in propertiesToApply) {
            final brushKey = 'content_$property';
            if (_formatBrushStyles!.containsKey(brushKey)) {
              content[property] = _formatBrushStyles![brushKey];
            }
          }

          // 更新元素的content属性
          newProperties['content'] = content;
        }
      } else if (elementType == 'collection') {
        // 集字元素特有样式处理

        // 应用content中的所有样式属性（除了characters）
        if (newProperties.containsKey('content') &&
            newProperties['content'] is Map) {
          Map<String, dynamic> content =
              Map<String, dynamic>.from(newProperties['content'] as Map);

          // 保存原有的characters
          final originalCharacters =
              content.containsKey('characters') ? content['characters'] : null;

          // 根据需求中的属性列表应用所有需要支持的属性
          final propertiesToApply = [
            'fontSize',
            'fontColor',
            'backgroundColor',
            'backgroundTexture',
            'charSpacing',
            'direction',
            'gridLines',
            'letterSpacing',
            'lineSpacing',
            'padding',
            'showBackground',
            'textureApplicationRange',
            'textureFillMode',
            'textureOpacity',
            'enableSoftLineBreak', // 添加自动换行属性
          ];

          // 应用所有指定的样式属性
          for (final property in propertiesToApply) {
            final brushKey = 'content_$property';
            if (_formatBrushStyles!.containsKey(brushKey)) {
              content[property] = _formatBrushStyles![brushKey];
            }
          }

          // 如果存在characters，恢复原来的值
          if (originalCharacters != null) {
            content['characters'] = originalCharacters;
          }

          // 更新元素的content属性，但保留原有的characters
          newProperties['content'] = content;
        }
      }

      // 添加到操作列表
      targetElementIds.add(elementId);
      oldPropertiesList.add(oldProperties);
      newPropertiesList.add(newProperties);
    }

    // 使用FormatPainterOperation与撤销/重做系统集成
    final formatPainterOperation = FormatPainterOperation(
      targetElementIds: targetElementIds,
      oldPropertiesList: oldPropertiesList,
      newPropertiesList: newPropertiesList,
      updateElement: (elementId, properties) {
        // 更新指定元素的属性
        if (_controller.state.currentPageIndex >= 0 &&
            _controller.state.currentPageIndex <
                _controller.state.pages.length) {
          final page =
              _controller.state.pages[_controller.state.currentPageIndex];
          final elements = page['elements'] as List<dynamic>;
          final elementIndex = elements.indexWhere((e) => e['id'] == elementId);

          if (elementIndex >= 0) {
            // 更新元素属性
            elements[elementIndex] = properties;

            // 如果是当前选中的元素，同时更新selectedElement
            if (_controller.state.selectedElementIds.contains(elementId)) {
              _controller.state.selectedElement = properties;
            }

            // 标记有未保存的更改
            _controller.state.hasUnsavedChanges = true;

            // 通知监听器
            _controller.notifyListeners();
          }
        }
      },
    );

    // 添加到撤销/重做管理器
    _controller.undoRedoManager.addOperation(formatPainterOperation);

    // 重置格式刷状态
    setState(() {
      _isFormatBrushActive = false;
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
            if (!_isPreviewMode && _isLeftPanelOpen)
              _buildLeftPanel(), // Left panel toggle
            if (!_isPreviewMode)
              PersistentSidebarToggle(
                sidebarId: 'practice_edit_left_panel',
                defaultIsOpen: _isLeftPanelOpen,
                onToggle: (isOpen) => setState(() {
                  _isLeftPanelOpen = isOpen;
                }),
                alignRight: false,
              ),

            // Central edit area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Toolbar
                  if (!_isPreviewMode)
                    _buildEditToolbar(), // Edit canvas - 使用ProviderScope包装，确保可以访问ref
                  Expanded(
                    // Use a SizedBox with fixed height instead of unconstrained SingleChildScrollView
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height -
                          150, // Fixed height
                      child: ProviderScope(
                        child: M3PracticeEditCanvas(
                          key: _canvasKey,
                          controller: _controller,
                          isPreviewMode: _isPreviewMode,
                          transformationController: _transformationController,
                        ),
                      ),
                    ),
                  ),

                  // Page thumbnails
                  if (_showThumbnails && !_isPreviewMode)
                    _buildPageThumbnails(),
                ],
              ),
            ), // Right panel toggle
            if (!_isPreviewMode)
              PersistentSidebarToggle(
                sidebarId: 'practice_edit_right_panel',
                defaultIsOpen: _isRightPanelOpen,
                onToggle: (isOpen) => setState(() {
                  _isRightPanelOpen = isOpen;
                }),
                alignRight: true,
              ),

            // Right properties panel
            if (!_isPreviewMode && _isRightPanelOpen) _buildRightPanel(),
          ],
        );
      },
    );
  }

  /// Build the edit toolbar
  Widget _buildEditToolbar() {
    return Column(
      children: [
        M3EditToolbar(
          controller: _controller,
          gridVisible: _controller.state.gridVisible,
          snapEnabled: _controller.state.snapEnabled,
          onToggleGrid: _toggleGrid,
          onToggleSnap: _toggleSnap,
          onCopy: _copySelectedElement,
          onPaste: _pasteElement,
          canPaste: _clipboardHasContent,
          onGroupElements: _groupSelectedElements,
          onUngroupElements: _ungroupElements,
          onBringToFront: _bringElementToFront,
          onSendToBack: _sendElementToBack,
          onMoveUp: _moveElementUp,
          onMoveDown: _moveElementDown,
          onDelete: _deleteSelectedElements,
          onCopyFormatting: _copyElementFormatting,
          onApplyFormatBrush: _applyFormatBrush,
          // 选择操作相关回调
          onSelectAll: _selectAllElements,
          onDeselectAll: _deselectAllElements,
          // 添加元素工具按钮相关参数
          currentTool: _currentTool,
          onSelectTool: (tool) {
            setState(() {
              // 如果当前已经是select模式，再次点击select按钮则退出select模式
              if (_currentTool == 'select' && tool == 'select') {
                _currentTool = '';
                _controller.exitSelectMode();
              } else {
                _currentTool = tool;
                // 同步到controller的状态
                _controller.state.currentTool = tool;
                _controller.notifyListeners(); // 通知监听器更新
                debugPrint('工具切换为: $tool');
              }
            });
          },
          onDragElementStart: (context, elementType) {
            // 拖拽开始时的处理逻辑可以为空，因为Draggable内部已经处理了拖拽功能
          },
        ),
        // // Debug button
        // if (kDebugMode) // Only show in debug mode
        //   ElevatedButton(
        //     onPressed: () async {
        //       // 手动检查剪贴板状态
        //       await _inspectClipboard();
        //       // 强制刷新剪贴板状态
        //       final hasContent = await _checkClipboardContent();
        //       setState(() {
        //         _clipboardHasContent = hasContent;
        //         ScaffoldMessenger.of(context).showSnackBar(
        //           SnackBar(
        //               content: Text('剪贴板状态: ${hasContent ? '有内容' : '无内容'}')),
        //         );
        //       });
        //     },
        //     child: const Text('调试：检查剪贴板'),
        //   ),
      ],
    );
  }

  /// Build the left panel
  Widget _buildLeftPanel() {
    return PersistentResizablePanel(
      panelId: 'practice_edit_left_panel',
      initialWidth: 250,
      minWidth: 250,
      maxWidth: 400,
      isLeftPanel: true,
      child: Column(
        children: [
          // Removed content tools area as requested - it's now in the toolbar

          // Layer management area - now takes full height
          Expanded(
            child: M3PracticeLayerPanel(
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
    return M3PageThumbnailStrip(
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
            panel = M3PracticePropertyPanel.forLayer(
              controller: _controller,
              layer: layer,
              onLayerPropertiesChanged: (properties) {
                // Update layer properties
                _controller.updateLayerProperties(layerId, properties);
              },
            ); // Return resizable panel
            return PersistentResizablePanel(
              panelId: 'practice_edit_right_panel_character',
              initialWidth: 400,
              minWidth: 300,
              maxWidth: 800,
              isLeftPanel: false,
              child: panel,
            );
          }
        }

        // Show different property panels based on selected element type
        if (_controller.state.selectedElementIds.isEmpty) {
          // Show page properties when no element is selected
          panel = M3PracticePropertyPanel.forPage(
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
                panel = M3PracticePropertyPanel.forText(
                  controller: _controller,
                  element: element,
                  onElementPropertiesChanged: (properties) {
                    _controller.updateElementProperties(id, properties);
                  },
                );
                break;
              case 'image':
                panel = M3PracticePropertyPanel.forImage(
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
                panel = M3PracticePropertyPanel.forCollection(
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
                panel = M3PracticePropertyPanel.forGroup(
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
          panel = M3PracticePropertyPanel.forMultiSelection(
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
        return PersistentResizablePanel(
          panelId: 'practice_edit_right_panel_properties',
          initialWidth: 400,
          minWidth: 300,
          maxWidth: 800,
          isLeftPanel: false,
          child: panel,
        );
      },
    );
  }

  /// Check if clipboard has valid content for pasting
  /// Returns true if clipboard has content that can be pasted
  Future<bool> _checkClipboardContent() async {
    // Check internal clipboard first (handled by app)
    if (_clipboardElement != null) {
      final type = _clipboardElement?['type'];
      debugPrint('检查剪贴板: 内部剪贴板有内容 - 类型: $type');

      // Additional validation for specific types if needed
      if (type == 'characters' || type == 'character') {
        final hasIds = _clipboardElement!.containsKey('characterIds') ||
            (_clipboardElement!.containsKey('data') &&
                _clipboardElement!['data'] is Map &&
                _clipboardElement!['data'].containsKey('characterId'));
        debugPrint('检查剪贴板: 字符内容有效性: $hasIds');
        return hasIds;
      } else if (type == 'library_items' || type == 'image') {
        final hasIds = _clipboardElement!.containsKey('itemIds') ||
            (_clipboardElement!.containsKey('imageUrl') &&
                _clipboardElement!['imageUrl'] != null);
        debugPrint('检查剪贴板: 图库内容有效性: $hasIds');
        return hasIds;
      }

      // For other types, just check if it exists
      return true;
    }

    // Then check system clipboard
    try {
      // Check for text data
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final hasText = clipboardData != null &&
          clipboardData.text != null &&
          clipboardData.text!.isNotEmpty;

      // debugPrint('检查剪贴板: 系统剪贴板${hasText ? '有' : '没有'}文本内容');

      if (hasText) {
        // Try to identify if it's a JSON and what type
        try {
          final text = clipboardData.text!;
          final json = jsonDecode(text);

          if (json is Map<String, dynamic> && json.containsKey('type')) {
            final type = json['type'];
            debugPrint('检查剪贴板: 识别到JSON内容, 类型: $type');

            // 特定类型的检查
            if (type == 'characters') {
              final characterIds = json['characterIds'];
              final hasIds = characterIds != null &&
                  characterIds is List &&
                  characterIds.isNotEmpty;
              debugPrint('检查剪贴板: 字符IDs: $characterIds, 有效: $hasIds');
              return hasIds;
            } else if (type == 'library_items') {
              final itemIds = json['itemIds'];
              final hasIds =
                  itemIds != null && itemIds is List && itemIds.isNotEmpty;
              debugPrint('检查剪贴板: 图库项目IDs: $itemIds, 有效: $hasIds');
              return hasIds;
            } else if (json.containsKey('id') &&
                (type == 'text' || type == 'image' || type == 'collection')) {
              // This appears to be a direct element that can be pasted
              debugPrint('检查剪贴板: 识别到可粘贴的元素类型: $type');
              return true;
            }
          }
        } catch (e) {
          // Not valid JSON, that's fine for plain text
          // debugPrint('检查剪贴板: 不是有效的JSON，按纯文本处理: $e');
        }

        // Plain text can always be pasted
        return true;
      }

      // Check for image data in clipboard (different formats)
      try {
        // Check for common image formats
        for (final format in ['image/png', 'image/jpeg', 'image/gif']) {
          final imageClipboardData = await Clipboard.getData(format);
          if (imageClipboardData != null) {
            debugPrint('检查剪贴板: 系统剪贴板有 $format 图片数据');
            return true;
          }
        }
      } catch (e) {
        debugPrint('检查系统剪贴板图片数据错误: $e');
      }

      return hasText;
    } catch (e) {
      debugPrint('检查剪贴板错误: $e');
      return false;
    }
  }

  // _buildElementButton 方法已移除，相关功能移至 M3EditToolbar

  /// 复制选中元素的样式（格式刷功能）
  void _copyElementFormatting() {
    final selectedElements = _controller.state.getSelectedElements();
    if (selectedElements.isEmpty) return;

    // 从第一个选中元素获取样式
    final element = selectedElements.first;
    _formatBrushStyles = {};

    // 根据元素类型获取不同的样式属性
    if (element['type'] == 'text') {
      // 文本元素样式 - 外层属性
      _formatBrushStyles!['opacity'] = element['opacity'];
      _formatBrushStyles!['rotation'] = element['rotation'];
      _formatBrushStyles!['width'] = element['width'];
      _formatBrushStyles!['height'] = element['height'];

      // 复制content中的所有样式属性
      if (element.containsKey('content') &&
          element['content'] is Map<String, dynamic>) {
        final content = element['content'] as Map<String, dynamic>;

        // 文本元素的content属性
        final propertiesToCopy = [
          'backgroundColor',
          'fontColor',
          'fontFamily',
          'fontSize',
          'fontStyle',
          'fontWeight',
          'letterSpacing',
          'lineHeight',
          'padding',
          'textAlign',
          'verticalAlign',
          'writingMode'
        ];

        // 复制所有指定的样式属性
        for (final property in propertiesToCopy) {
          if (content.containsKey(property)) {
            _formatBrushStyles!['content_$property'] = content[property];
          }
        }
      } else {
        // 兼容旧版本文本元素结构
        if (element.containsKey('fontSize')) {
          _formatBrushStyles!['fontSize'] = element['fontSize'];
        }
        if (element.containsKey('fontWeight')) {
          _formatBrushStyles!['fontWeight'] = element['fontWeight'];
        }
        if (element.containsKey('fontStyle')) {
          _formatBrushStyles!['fontStyle'] = element['fontStyle'];
        }
        if (element.containsKey('textColor')) {
          _formatBrushStyles!['textColor'] = element['textColor'];
        }
        if (element.containsKey('textAlign')) {
          _formatBrushStyles!['textAlign'] = element['textAlign'];
        }
      }
    } else if (element['type'] == 'image') {
      // 图片元素样式 - 外层属性
      _formatBrushStyles!['opacity'] = element['opacity'];
      _formatBrushStyles!['rotation'] = element['rotation'];
      _formatBrushStyles!['width'] = element['width'];
      _formatBrushStyles!['height'] = element['height'];

      // 复制content中的所有样式属性
      if (element.containsKey('content') &&
          element['content'] is Map<String, dynamic>) {
        final content = element['content'] as Map<String, dynamic>;

        // 图像元素的content属性
        final propertiesToCopy = [
          'backgroundColor',
          'fit',
          'isFlippedHorizontally',
          'isFlippedVertically',
          'rotation'
        ];

        // 复制所有指定的样式属性
        for (final property in propertiesToCopy) {
          if (content.containsKey(property)) {
            _formatBrushStyles!['content_$property'] = content[property];
          }
        }
      }
    } else if (element['type'] == 'collection') {
      // 集字元素样式 - 包含除了Character和Position以外的所有属性
      _formatBrushStyles!['opacity'] = element['opacity'];
      _formatBrushStyles!['width'] = element['width'];
      _formatBrushStyles!['height'] = element['height'];
      _formatBrushStyles!['rotation'] = element['rotation'];

      // 复制content中的所有样式属性
      if (element.containsKey('content') &&
          element['content'] is Map<String, dynamic>) {
        final content = element['content'] as Map<String, dynamic>;

        // 根据需求中的属性列表添加所有需要支持的属性
        final propertiesToCopy = [
          'fontSize',
          'fontColor',
          'backgroundColor',
          'backgroundTexture',
          'charSpacing',
          'direction',
          'gridLines',
          'letterSpacing',
          'lineSpacing',
          'padding',
          'showBackground',
          'textureApplicationRange',
          'textureFillMode',
          'textureOpacity',
          'enableSoftLineBreak', // 添加自动换行属性
        ];

        // 复制所有指定的样式属性
        for (final property in propertiesToCopy) {
          if (content.containsKey(property)) {
            _formatBrushStyles!['content_$property'] = content[property];
          }
        }

        // 不复制characters属性，因为这是内容而非样式
      }
    }

    // 如果是从字符管理页面复制的字符元素，设置字体大小为200px
    if (element['type'] == 'collection' &&
        element.containsKey('isFromCharacterManagement') &&
        element['isFromCharacterManagement'] == true) {
      _formatBrushStyles!['content_fontSize'] = 200.0;
    }

    // 激活格式刷
    setState(() {
      _isFormatBrushActive = true;
      // 显示提示信息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('格式刷已激活，点击目标元素应用样式')),
      );
    });
  }

  /// Copy selected elements
  void _copySelectedElement() {
    debugPrint('开始复制选中元素...');
    _clipboardElement =
        PracticeEditUtils.copySelectedElements(_controller, context);
    debugPrint('复制结果: ${_clipboardElement != null ? '成功' : '失败'}');
    if (_clipboardElement != null) {
      debugPrint('复制的元素类型: ${_clipboardElement!['type']}');
    }

    // Update clipboard state and paste button activation
    setState(() {
      _clipboardHasContent = _clipboardElement != null;
      debugPrint('设置粘贴按钮状态: ${_clipboardHasContent ? '激活' : '禁用'}');
    });

    // Show a snackbar notification if copy was successful
    if (_clipboardElement != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('元素已复制到剪贴板')));
    }
  }

  /// 创建文本元素
  void _createTextElement(String text) {
    if (text.isEmpty) return; // 创建新元素ID
    final newId = const Uuid().v4();

    // 创建文本元素
    final newElement = {
      'id': newId,
      'type': 'text',
      'x': 100.0,
      'y': 100.0,
      'width': 200.0,
      'height': 100.0,
      'rotation': 0.0,
      'opacity': 1.0,
      'visible': true,
      'locked': false,
      'text': text,
      'fontSize': 24.0,
      'fontWeight': 'normal',
      'fontStyle': 'normal',
      'textColor': '#000000',
      'textAlign': 'left',
      // 其他必要的文本元素属性
    };

    // 添加到当前页面
    setState(() {
      _controller.state.currentPageElements.add(newElement);
      _controller.selectElement(newId);
    });
  }

  /// 深拷贝元素，确保嵌套的Map也被正确拷贝
  Map<String, dynamic> _deepCopyElement(Map<String, dynamic> element) {
    final copy = Map<String, dynamic>.from(element);

    // 特别处理content属性，确保它也被深拷贝
    if (copy.containsKey('content') && copy['content'] is Map) {
      copy['content'] = Map<String, dynamic>.from(copy['content'] as Map);
    }

    return copy;
  }

  /// Delete a page
  void _deletePage(int index) {
    setState(() {
      PracticeEditUtils.deletePage(_controller, index, context);
    });
  }

  /// Delete selected elements
  void _deleteSelectedElements() {
    final l10n = AppLocalizations.of(context);

    if (_controller.state.selectedElementIds.isEmpty) return;

    // Show confirmation dialog
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.practiceEditConfirmDeleteTitle),
        content: Text(l10n.practiceEditConfirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        // Create a copy to avoid ConcurrentModificationError
        final idsToDelete =
            List<String>.from(_controller.state.selectedElementIds);
        for (final id in idsToDelete) {
          _controller.deleteElement(id);
        }
      }
    });
  }

  /// Deselect all elements on the current page
  void _deselectAllElements() {
    _controller.clearSelection();
  }

  /// Edit title
  Future<void> _editTitle() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);

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
          SnackBar(content: Text(l10n.practiceEditTitleUpdated(newTitle))),
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

  /// 处理从字符管理页面复制的字符
  Future<void> _handleCharacterClipboardData(Map<String, dynamic> json) async {
    debugPrint('处理字符剪贴板数据: $json');
    final characterIds = List<String>.from(json['characterIds']);
    debugPrint('字符IDs: $characterIds, 数量: ${characterIds.length}');

    if (characterIds.isEmpty) {
      debugPrint('没有字符ID，无法创建集字元素');
      return;
    }

    // 获取字符服务和图像服务
    final characterService = ref.read(characterServiceProvider);
    final characterImageService = ref.read(characterImageServiceProvider);
    debugPrint('已获取字符服务和图像服务');

    // 对于每个字符ID，创建一个集字元素
    for (int i = 0; i < characterIds.length; i++) {
      final characterId = characterIds[i];
      debugPrint('处理字符ID: $characterId');

      try {
        // 获取字符数据
        debugPrint('获取字符详情...');
        final character =
            await characterService.getCharacterDetails(characterId);
        if (character == null) {
          debugPrint('无法获取字符详情，跳过');
          continue;
        }
        debugPrint('成功获取字符详情: $character');

        // 获取字符图像 - 使用default类型和png格式
        debugPrint('获取字符图像...');
        final imageBytes = await characterImageService.getCharacterImage(
            characterId, 'default', 'png');
        if (imageBytes == null) {
          debugPrint('无法获取字符图像，跳过');
          continue;
        }
        debugPrint('成功获取字符图像，大小: ${imageBytes.length} 字节'); // 创建新元素ID
        final newId = const Uuid().v4();
        debugPrint('创建新元素ID: $newId');

        // 计算放置位置（按顺序排列）
        final x = 100.0 + (i * 20);
        final y = 100.0 + (i * 20); // 创建集字元素
        final newElement = {
          'id': newId,
          'type': 'collection',
          'x': x,
          'y': y,
          'width': 200.0, // 更大的尺寸以便于查看
          'height': 200.0,
          'rotation': 0.0,
          'layerId': _controller.state.selectedLayerId ??
              _controller.state.layers.first['id'],
          'opacity': 1.0,
          'isLocked': false,
          'isHidden': false,
          'name': '集字元素',
          'characterId': characterId,
          // 添加必要的content属性结构
          'content': {
            // 使用字符名称作为默认显示内容
            'characters': character.character as String? ?? '集',
            'fontSize': 36.0, // 更大的字体以便于查看
            'fontColor': '#000000',
            'backgroundColor': '#FFFFFF',
            'writingMode': 'horizontal-l',
            'letterSpacing': 5.0,
            'lineSpacing': 10.0,
            'padding': 10.0, 'textAlign': 'center',
            'verticalAlign': 'middle',
            'enableSoftLineBreak': false,
            // 添加与字符相关的图像数据
            'characterImages': {
              'characterId': characterId,
              // 其他可能需要的图像相关属性
            },
          },
        };

        debugPrint('创建新的集字元素: $newElement'); // 添加到当前页面

        setState(() {
          // 从element中提取文本内容用于创建集字元素
          final characters =
              (newElement['content'] as Map)['characters'] as String? ?? '集';
          final x = newElement['x'] as double;
          final y =
              newElement['y'] as double; // 使用控制器的公共方法addCollectionElementAt添加元素
          // 这个方法会正确地更新底层的数据结构，确保集字元素被保存
          // 标记该元素来自字符管理页面，字体大小将自动设置为200px
          _controller.addCollectionElementAt(x, y, characters,
              isFromCharacterManagement: true);

          // 选择新添加的元素
          // 注意：我们不知道新添加元素的ID，因为它是在controller内部生成的
          // 所以我们不能直接选择它
          debugPrint('已通过控制器方法添加集字元素到当前页面位置: ($x, $y), 内容: $characters');
        });
      } catch (e) {
        debugPrint('处理字符 $characterId 时出错: $e');
      }
    }
    debugPrint('字符处理完成');
  }

  /// 处理图库项目剪贴板数据
  Future<void> _handleLibraryItemClipboardData(
      Map<String, dynamic> json) async {
    debugPrint('处理图库项目剪贴板数据: $json');
    final itemIds = List<String>.from(json['itemIds']);
    debugPrint('图库项目IDs: $itemIds, 数量: ${itemIds.length}');

    if (itemIds.isEmpty) {
      debugPrint('没有图库项目ID，无法创建图片元素');
      return;
    }

    // 获取图库服务
    final libraryService = ref.read(libraryServiceProvider);
    debugPrint('已获取图库服务');

    // 对于每个图库项目ID，创建一个图片元素
    for (int i = 0; i < itemIds.length; i++) {
      final itemId = itemIds[i];
      debugPrint('处理图库项目ID: $itemId');

      try {
        // 获取图库项目数据
        debugPrint('获取图库项目数据...');
        final item = await libraryService.getItem(itemId);
        if (item == null) {
          debugPrint('无法获取图库项目数据，跳过');
          continue;
        }
        debugPrint('成功获取图库项目数据, 路径: ${item.path}');

        // 创建新元素ID
        final newId = const Uuid().v4();
        debugPrint('创建新元素ID: $newId');

        // 计算放置位置（按顺序排列）
        final x = 100.0 + (i * 20);
        final y = 100.0 + (i * 20);

        // 图片默认尺寸
        const defaultWidth = 200.0;
        const defaultHeight = 200.0;

        // 创建图片元素
        final newElement = {
          'id': newId,
          'type': 'image',
          'x': x,
          'y': y,
          'width': defaultWidth,
          'height': defaultHeight,
          'rotation': 0.0,
          'opacity': 1.0,
          'visible': true,
          'locked': false,
          'imagePath': item.path,
          'libraryItemId': itemId,
          // 其他必要的图片元素属性
        };
        debugPrint('创建新的图片元素: $newElement'); // 添加到当前页面

        setState(() {
          // 使用控制器的公共方法添加图片元素
          // 将文件路径转换为正确的文件URI格式
          final imageUrl = 'file://${item.path.replaceAll("\\", "/")}';
          _controller.addImageElementAt(x, y, imageUrl);
          debugPrint('已通过控制器方法添加图片元素到当前页面位置: ($x, $y), URI: $imageUrl');
        });
      } catch (e) {
        debugPrint('处理图库项目 $itemId 时出错: $e');
      }
    }
    debugPrint('图库项目处理完成');
  }

  void _initKeyboardHandler() {
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
      toggleLeftPanel: () {
        setState(() {
          _isLeftPanelOpen = !_isLeftPanelOpen;
        });
      },
      toggleRightPanel: () {
        setState(() {
          _isRightPanelOpen = !_isRightPanelOpen;
        });
      },
      moveSelectedElements: _moveSelectedElements,
      copyElementFormatting: _copyElementFormatting,
      applyFormatBrush: _applyFormatBrush,
      resetViewPosition: () => _controller.resetViewPosition(),
      // Add tool selection callback to connect keyboard shortcuts with toolbar
      onSelectTool: (tool) {
        setState(() {
          // 如果当前已经是select模式，再次点击select按钮则退出select模式
          if (_currentTool == 'select' && tool == 'select') {
            _currentTool = '';
            _controller.exitSelectMode();
          } else if (_currentTool == tool) {
            // If the same tool is selected again, deselect it
            _currentTool = '';
            _controller.exitSelectMode();
          } else {
            _currentTool = tool;
            // 同步到controller的状态
            _controller.state.currentTool = tool;
            _controller.notifyListeners(); // 通知监听器更新
            debugPrint('工具切换为: $tool');
          }
        });
      },
    );

    // 添加键盘事件处理器
    HardwareKeyboard.instance.addHandler(_keyboardHandler.handleKeyEvent);
  }

  /// 在剪贴板变化时检查并输出详细日志  /// Detailed inspection of clipboard contents for debugging
  Future<void> _inspectClipboard() async {
    debugPrint('======= 剪贴板详细检查 =======');

    // 检查内部剪贴板
    if (_clipboardElement != null) {
      debugPrint('内部剪贴板内容类型: ${_clipboardElement?['type']}');

      // 根据类型显示不同的信息
      final type = _clipboardElement?['type'];
      if (type == 'characters' || type == 'character') {
        if (_clipboardElement!.containsKey('characterIds')) {
          debugPrint('字符IDs: ${_clipboardElement!['characterIds']}');
        } else if (_clipboardElement!.containsKey('data') &&
            _clipboardElement!['data'] is Map &&
            _clipboardElement!['data'].containsKey('characterId')) {
          debugPrint('字符ID: ${_clipboardElement!['data']['characterId']}');
        }
      } else if (type == 'library_items' || type == 'image') {
        if (_clipboardElement!.containsKey('itemIds')) {
          debugPrint('图库项目IDs: ${_clipboardElement!['itemIds']}');
        } else if (_clipboardElement!.containsKey('imageUrl')) {
          debugPrint('图片URL: ${_clipboardElement!['imageUrl']}');
        }
      }

      // 完整内容（可能很长，只在调试时打印）
      if (kDebugMode) {
        debugPrint('内部剪贴板完整内容: $_clipboardElement');
      }
    } else {
      debugPrint('内部剪贴板为空');
    }

    // 检查系统剪贴板文本
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null &&
          clipboardData.text != null &&
          clipboardData.text!.isNotEmpty) {
        debugPrint('系统剪贴板有文本内容，长度: ${clipboardData.text!.length}');

        // 根据长度决定显示内容
        if (clipboardData.text!.length < 300) {
          debugPrint('系统剪贴板文本内容: ${clipboardData.text}');
        } else {
          debugPrint(
              '系统剪贴板内容太长，仅显示前100个字符: ${clipboardData.text!.substring(0, 100)}...');
        }

        // 尝试解析为JSON
        try {
          final json = jsonDecode(clipboardData.text!);
          debugPrint('成功解析为JSON');

          if (json is Map && json.containsKey('type')) {
            final type = json['type'];
            debugPrint('JSON类型: $type');

            // 特定类型的检查
            if (type == 'characters') {
              final characterIds = json['characterIds'];
              debugPrint('字符IDs: $characterIds');
              debugPrint(
                  '字符数量: ${characterIds is List ? characterIds.length : 0}');
            } else if (type == 'library_items') {
              final itemIds = json['itemIds'];
              debugPrint('图库项目IDs: $itemIds');
              debugPrint('图库项目数量: ${itemIds is List ? itemIds.length : 0}');
            } else if (json.containsKey('id')) {
              debugPrint('元素ID: ${json['id']}');
              // 其他属性检查
              final props = ['width', 'height', 'x', 'y', 'text', 'imageUrl'];
              for (final prop in props) {
                if (json.containsKey(prop)) {
                  debugPrint('元素属性 $prop: ${json[prop]}');
                }
              }
            }
          }
        } catch (e) {
          // 不是有效的 JSON，作为纯文本处理
          debugPrint('不是有效的JSON，作为纯文本处理: $e');
        }
      } else {
        debugPrint('系统剪贴板为空');
      }
    } catch (e) {
      debugPrint('检查系统剪贴板时出错: $e');
    }

    // 检查系统剪贴板图片
    try {
      // 检查常见的图片格式
      for (final format in ['image/png', 'image/jpeg', 'image/gif']) {
        final imageData = await Clipboard.getData(format);
        if (imageData != null) {
          debugPrint('系统剪贴板有 $format 格式的图片数据');
          break; // 找到一种格式即可
        }
      }
    } catch (e) {
      debugPrint('检查系统剪贴板图片错误: $e');
    }

    debugPrint('当前粘贴按钮状态: ${_clipboardHasContent ? '激活' : '禁用'}');
    debugPrint('======= 剪贴板检查结束 =======');
  }

  /// Load practice
  Future<void> _loadPractice(String id) async {
    final l10n = AppLocalizations.of(context);

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
                content: Text(l10n.practiceEditPracticeLoaded(
                    _controller.practiceTitle ?? ''))),
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
            SnackBar(content: Text(l10n.practiceEditPracticeLoadFailed)),
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
          SnackBar(content: Text(l10n.practiceEditLoadFailed('$e'))),
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
    final l10n = AppLocalizations.of(context);

    // Check for unsaved changes
    if (_controller.state.hasUnsavedChanges) {
      // Show confirmation dialog
      final bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(l10n.practiceEditUnsavedChanges),
            content: Text(l10n.practiceEditUnsavedChangesExitConfirmation),
            actions: <Widget>[
              TextButton(
                child: Text(l10n.cancel),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text(l10n.practiceEditExit),
                onPressed: () {
                  Navigator.of(context).pop(true);
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
  void _pasteElement() async {
    debugPrint('开始粘贴操作...');

    // 首先尝试从内部剪贴板粘贴
    if (_clipboardElement != null) {
      debugPrint('使用内部剪贴板内容粘贴, 类型: ${_clipboardElement!['type']}');
      setState(() {
        PracticeEditUtils.pasteElement(_controller, _clipboardElement);
        // Do not clear _clipboardElement to allow multiple pastes
      });
      return;
    }

    // 如果内部剪贴板为空，则尝试从系统剪贴板读取
    try {
      debugPrint('内部剪贴板为空，尝试读取系统剪贴板...');
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);

      if (clipboardData == null || clipboardData.text == null) {
        // 剪贴板为空，无法粘贴
        debugPrint('系统剪贴板为空或没有文本内容');
        return;
      }

      final text = clipboardData.text!;
      debugPrint('系统剪贴板有文本内容，长度: ${text.length}');

      // 检查是否是JSON格式
      try {
        debugPrint('尝试解析为JSON...');
        final json = jsonDecode(text);
        debugPrint('成功解析为JSON');

        // 判断是哪种类型的数据
        final type = json['type'];
        debugPrint('JSON类型: $type');

        if (type == 'characters') {
          // 处理从字符管理页面复制的字符
          debugPrint('处理字符类型数据...');
          await _handleCharacterClipboardData(json);
          debugPrint('字符数据处理完成');
        } else if (type == 'library_items') {
          // 处理从图库管理页面复制的图片
          debugPrint('处理图库项目类型数据...');
          await _handleLibraryItemClipboardData(json);
          debugPrint('图库项目数据处理完成');
        } else {
          // 尝试作为通用 JSON 元素处理
          debugPrint('处理通用JSON元素...');
          setState(() {
            PracticeEditUtils.pasteElement(_controller, json);
          });
        }
      } catch (e) {
        // 不是有效的 JSON，作为纯文本处理
        debugPrint('不是有效的JSON，作为纯文本处理: $e');
        _createTextElement(text);
      }

      // Refresh clipboard state after pasting
      _checkClipboardContent().then((hasContent) {
        setState(() {
          _clipboardHasContent = hasContent;
          debugPrint('粘贴后更新剪贴板状态: ${_clipboardHasContent ? '有内容' : '无内容'}');
        });
      });
    } catch (e) {
      debugPrint('粘贴操作出错: $e');
    }
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
    final l10n = AppLocalizations.of(context);

    if (_controller.state.pages.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.practiceEditCannotSaveNoPages)),
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
              title: Text(l10n.practiceEditSavePractice),
              content: TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.practiceEditPracticeTitle,
                  hintText: l10n.practiceEditEnterTitle,
                ),
                onSubmitted: (value) => Navigator.of(context).pop(value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(textController.text);
                  },
                  child: Text(l10n.save),
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
        SnackBar(content: Text(l10n.practiceEditPracticeLoaded(title))),
      );
    } else if (result == 'title_exists') {
      // Title already exists, ask whether to overwrite
      final shouldOverwrite = await showDialog<bool>(
        context: context,
        barrierDismissible: true, // Allow clicking outside to close dialog
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.practiceEditTitleExists),
            content: Text(l10n.practiceEditTitleExistsMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.practiceEditOverwrite),
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
            SnackBar(content: Text(l10n.practiceEditPracticeLoaded(title))),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(l10n.practiceEditSaveFailed)),
          );
        }
      }
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.practiceEditSaveFailed)),
      );
    }
  }

  /// Save practice
  /// Returns true if save was successful, false otherwise
  Future<bool> _savePractice() async {
    final l10n = AppLocalizations.of(context);

    if (_controller.state.pages.isEmpty) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.practiceEditCannotSaveNoPages)),
      );
      return false;
    }

    // Save ScaffoldMessenger reference to avoid using context after async operation
    final scaffoldMessenger = ScaffoldMessenger.of(
        context); // If never saved before, show dialog to enter title
    if (!_controller.isSaved) {
      await _saveAsNewPractice();
      return true; // Consider save attempt successful even if canceled
    }

    // Save practice
    final result = await _controller.savePractice();

    if (!mounted) return false;
    if (result == true) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.practiceEditSaveSuccess)),
      );
      return true;
    } else if (result == 'title_exists') {
      // Title already exists, ask whether to overwrite
      final shouldOverwrite = await showDialog<bool>(
        context: context,
        barrierDismissible: true, // Allow clicking outside to close dialog
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.practiceEditTitleExists),
            content: Text(l10n.practiceEditTitleExistsMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.practiceEditOverwrite),
              ),
            ],
          );
        },
      );

      if (!mounted) return false;
      if (shouldOverwrite == true) {
        final saveResult = await _controller.savePractice(forceOverwrite: true);

        if (!mounted) return false;

        if (saveResult == true) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(l10n.practiceEditSaveSuccess)),
          );
          return true;
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(l10n.practiceEditSaveFailed)),
          );
          return false;
        }
      }
      return false;
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.practiceEditSaveFailed)),
      );
      return false;
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

  /// Set up the reference to the canvas in the controller
  void _setupCanvasReference() {
    // Canvas will register itself with the controller in its initState
    debugPrint('Canvas reference will be set up by the canvas widget itself');
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

  /// Start monitoring clipboard contents periodically
  void _startClipboardMonitoring() {
    // Cancel any existing timer
    _clipboardMonitoringTimer?.cancel();

    // Create a periodic timer that checks clipboard every 2 seconds
    _clipboardMonitoringTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        // Periodically check clipboard content
        final hasContent = await _checkClipboardContent();

        if (hasContent != _clipboardHasContent) {
          debugPrint(
              '剪贴板状态变化: ${_clipboardHasContent ? "有内容" : "无内容"} -> ${hasContent ? "有内容" : "无内容"}');

          // If debugging, do a full inspection when state changes
          if (kDebugMode && hasContent) {
            await _inspectClipboard();
          }

          // Update state to reflect current clipboard content
          setState(() {
            _clipboardHasContent = hasContent;
          });
        }
      } catch (e) {
        debugPrint('剪贴板监控错误: $e');
      }
    });
  }

  /// Synchronize local _currentTool with controller's state.currentTool
  void _syncToolState() {
    final controllerTool = _controller.state.currentTool;
    if (_currentTool != controllerTool) {
      setState(() {
        _currentTool = controllerTool;
      });
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
        // Use the safe ungroup method to prevent ID conflicts
        PracticeEditUtils.safeUngroupSelectedElement(_controller);
      }
    }
  }
}
