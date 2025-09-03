import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

import '../../../application/providers/service_providers.dart';
import '../../../application/services/character/character_service.dart';
import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../infrastructure/logging/practice_edit_logger.dart';
import '../../../infrastructure/providers/cache_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/image_path_converter.dart';
import '../../dialogs/practice_save_dialog.dart';
import '../../providers/persistent_panel_provider.dart';
import '../../widgets/common/persistent_resizable_panel.dart';
import '../../widgets/common/persistent_sidebar_toggle.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/practice/file_operations.dart';
import '../../widgets/practice/guideline_alignment/guideline_types.dart';
import '../../widgets/practice/m3_edit_toolbar.dart';
import '../../widgets/practice/m3_page_thumbnail_strip.dart';
import '../../widgets/practice/m3_practice_layer_panel.dart';
import '../../widgets/practice/m3_top_navigation_bar.dart';
import '../../widgets/practice/practice_edit_controller.dart';
import '../../widgets/practice/property_panels/m3_practice_property_panels.dart';
import '../../widgets/practice/undo_operations.dart';
import 'handlers/keyboard_handler.dart';
import 'utils/practice_edit_utils.dart';
import 'widgets/m3_practice_edit_canvas.dart';
import 'widgets/practice_title_edit_dialog.dart';

/// Material 3 version of the Practice Edit page
class M3PracticeEditPage extends ConsumerStatefulWidget {
  final String? practiceId;

  const M3PracticeEditPage({super.key, this.practiceId});

  @override
  ConsumerState<M3PracticeEditPage> createState() => _M3PracticeEditPageState();
}

class _M3PracticeEditPageState extends ConsumerState<M3PracticeEditPage>
    with WidgetsBindingObserver {
  // 🔍[TRACKING] 静态重建计数器
  static int _propertyPanelBuildCount = 0;
  static int _lastSelectedCount = -1;
  static String? _lastSelectedLayerId;
  static DateTime _lastPropertyPanelLogTime = DateTime.now();

  // Controller
  late final PracticeEditController _controller;

  // Drag optimization flag to prevent unnecessary rebuilds

  // Current tool
  String _currentTool = '';

  // Clipboard monitoring timer
  Timer? _clipboardMonitoringTimer;
  // Clipboard
  Map<String, dynamic>? _clipboardElement;
  bool _clipboardHasContent = false; // Track if clipboard has valid content
  // ValueNotifier for clipboard state to avoid setState during drag operations
  final ValueNotifier<bool> _clipboardNotifier = ValueNotifier<bool>(false);

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
  // Control toolbar visibility
  bool _showToolbar = true;
  // Control panel visibility - will be initialized from persistent state
  bool _isLeftPanelOpen = false; // Default to closed as requested
  bool _isRightPanelOpen = true;

  // Keyboard handler
  late KeyboardHandler _keyboardHandler;
  // 页面切换跟踪变量
  int _lastPageIndex = -1;
  Map<String, dynamic>? _formatBrushStyles;
  bool _isFormatBrushActive = false;
  // Track whether the practice has been loaded to prevent multiple loads
  // This prevents the "Practice loaded successfully" message from appearing
  // every time didChangeDependencies is called (e.g., on viewport size changes)
  bool _practiceLoaded = false;

  // 保存UI监听器回调引用，用于正确注销
  VoidCallback? _propertyPanelListener;

  @override
  Widget build(BuildContext context) {
    _controller.l10n = AppLocalizations.of(context); // Set l10n for controller
    // Remove unused l10n variable
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
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

                // Reset view position when toggling preview mode
                // 延迟重置视图位置，确保预览模式UI完全更新完成
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    _controller.resetViewPosition();
                  }
                });
              },
              showThumbnails: _showThumbnails,
              onThumbnailToggle: (bool value) {
                setState(() {
                  _showThumbnails = value; // Update thumbnails display state
                });
              },
              showToolbar: _showToolbar,
              onToggleToolbar: () {
                setState(() {
                  _showToolbar = !_showToolbar; // Toggle toolbar visibility
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
    // Only load once to prevent repeated loading when dependencies change (e.g., viewport size)
    if (widget.practiceId != null && !_practiceLoaded) {
      _practiceLoaded = true;
      _loadPractice(widget.practiceId!);
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // When window size changes (maximize/restore), automatically reset view position
    // Use a small delay to ensure the UI has finished updating
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.resetViewPosition();
      }
    });
  }

  @override
  void dispose() {
    // ✅ 注销属性面板的智能状态监听器
    _unregisterPropertyPanelFromIntelligentDispatcher();

    // Remove window observer
    WidgetsBinding.instance.removeObserver(this);

    // Clear undo/redo stack
    _controller.clearUndoRedoHistory();

    // Remove keyboard listeners
    HardwareKeyboard.instance.removeHandler(_keyboardHandler.handleKeyEvent);
    _focusNode.dispose();

    // Remove controller listener
    _controller.removeListener(_syncToolState);

    // Release zoom controller
    _transformationController.dispose();

    _controller.dispose(); // Cancel clipboard monitoring timer
    _clipboardMonitoringTimer?.cancel();

    // Dispose of the clipboard ValueNotifier
    _clipboardNotifier.dispose();

    super.dispose();
  }

  /// Go to previous page
  void _goToPreviousPage() {
    final currentIndex = _controller.state.currentPageIndex;
    if (currentIndex > 0) {
      _controller.switchToPage(currentIndex - 1);
    }
  }

  /// Go to next page
  void _goToNextPage() {
    final currentIndex = _controller.state.currentPageIndex;
    if (currentIndex < _controller.state.pages.length - 1) {
      _controller.switchToPage(currentIndex + 1);
    }
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

    // Add window observer to monitor window changes
    WidgetsBinding.instance.addObserver(this);

    // Create or get the PracticeService instance
    final practiceService = ref.read(practiceServiceProvider);
    _controller = PracticeEditController(practiceService);
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

    // Initialize keyboard handler
    _initKeyboardHandler();
    _controller.state.currentTool = _currentTool;

    // Initialize panel states from persistent storage
    _initializePanelStates();

    // Schedule a callback to connect the canvas after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupCanvasReference();
      _registerPropertyPanelToIntelligentDispatcher();
    });

    // Start clipboard monitoring
    _checkClipboardContent().then((hasContent) {
      _clipboardHasContent = hasContent;
      _clipboardNotifier.value = hasContent;

      if (mounted) {
        setState(() {});
      }
    });

    // Start periodic clipboard monitoring
    _startClipboardMonitoring();
  }

  /// Add a new page
  void _addNewPage() {
    EditPageLogger.editPageInfo(
      '🆕 M3PracticeEditPage._addNewPage 被调用',
      data: {
        'currentPagesCount': _controller.state.pages.length,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Use enhanced version with template inheritance from previous page
    PracticeEditUtils.addNewPage(_controller, context);

    EditPageLogger.editPageInfo(
      '✅ PracticeEditUtils.addNewPage 调用完成',
      data: {
        'finalPagesCount': _controller.state.pages.length,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // 🆕 根据页面数量自动更新缩略图显示状态
    _updateThumbnailVisibilityBasedOnPageCount();

    // The controller will notify listeners automatically through intelligent notification
  }

  /// 应用格式刷样式到选中元素
  void _applyFormatBrush() {
    if (!_isFormatBrushActive || _formatBrushStyles == null) return;
    final selectedElements = _controller.state.getSelectedElements();
    if (selectedElements.isEmpty) return;
    final stopwatch = Stopwatch()..start();
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
            'rotation',
            // 🆕 添加二值化处理参数（只应用设置，不应用数据）
            'isBinarizationEnabled',
            'binaryThreshold',
            'isNoiseReductionEnabled',
            'noiseReductionLevel',
            // 注意：不应用 binarizedImageData，因为这是处理后的数据，不是格式设置
            // 🆕 添加其他图像处理参数
            'fitMode',
            'alignment',
            'cropX',
            'cropY',
            'cropWidth',
            'cropHeight',
            'cropTop',
            'cropBottom',
            'cropLeft',
            'cropRight',
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
          } // 更新元素的content属性，但保留原有的characters
          newProperties['content'] = content;
        }
      } else if (elementType == 'group') {
        // 组合元素样式处理 - 主要是透明度和基本属性
        // 组合元素通常只应用基本的变换属性，已在通用样式部分处理

        // 应用content中的样式属性（如果存在）
        if (newProperties.containsKey('content') &&
            newProperties['content'] is Map) {
          Map<String, dynamic> content =
              Map<String, dynamic>.from(newProperties['content'] as Map);

          // 应用组合元素可能的样式属性
          final propertiesToApply = [
            'backgroundColor',
            'borderColor',
            'borderWidth',
            'cornerRadius',
            'shadowColor',
            'shadowOpacity',
            'shadowOffset',
            'shadowBlur',
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
      pageIndex: _controller.state.currentPageIndex,
      pageId: _controller.state.currentPage?['id'] ?? 'unknown',
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

            // 🆕 对图像元素触发图像处理管道
            if (properties['type'] == 'image') {
              final content = properties['content'] as Map<String, dynamic>?;
              if (content != null) {
                // 检查是否有二值化相关的参数变化
                final hasBinarizationSettings =
                    content.containsKey('isBinarizationEnabled') ||
                        content.containsKey('binaryThreshold') ||
                        content.containsKey('isNoiseReductionEnabled') ||
                        content.containsKey('noiseReductionLevel');

                // 检查是否有翻转参数变化
                final hasFlipSettings =
                    content.containsKey('isFlippedHorizontally') ||
                        content.containsKey('isFlippedVertically');

                if (hasBinarizationSettings || hasFlipSettings) {
                  // 标记需要重新处理图像
                  content['needsReprocessing'] = true;
                  content['triggerImageProcessing'] = true; // 🆕 添加特殊标记

                  // 清除现有的处理后数据，强制重新处理
                  content.remove('binarizedImageData');
                  content.remove('processedImageData');
                  content.remove('cachedProcessedImage');

                  PracticeEditLogger.debugDetail('格式刷触发图像处理', data: {
                    'elementId': elementId,
                    'hasBinarizationSettings': hasBinarizationSettings,
                    'hasFlipSettings': hasFlipSettings,
                  });

                  // 直接执行图像处理
                  // 使用微任务确保属性更新完成后再处理
                  Future.microtask(() async {
                    try {
                      // 直接执行图像二值化处理
                      if (content['isBinarizationEnabled'] == true) {
                        await _executeDirectImageBinarization(
                            elementId, content);
                      }
                    } catch (e) {
                      PracticeEditLogger.logError('格式刷图像处理失败', e,
                          context: {'elementId': elementId});
                    }
                  });
                }
              }
            }

            // 如果是当前选中的元素，同时更新selectedElement
            if (_controller.state.selectedElementIds.contains(elementId)) {
              _controller.state.selectedElement = properties;
            }

            // 标记有未保存的更改
            _controller.state.hasUnsavedChanges = true;

            // 通知监听器已由setCurrentTool处理
          }
        }
      },
    );

    // 添加到撤销/重做管理器
    _controller.undoRedoManager.addOperation(formatPainterOperation);

    // 🆕 触发智能状态分发，确保画布重新渲染
    _controller.intelligentNotify(
      changeType: 'format_brush_applied',
      eventData: {
        'targetElementIds': targetElementIds,
        'elementCount': selectedElements.length,
        'hasImageElements': targetElementIds.any((id) {
          final element = _controller.state.currentPageElements.firstWhere(
            (e) => e['id'] == id,
            orElse: () => <String, dynamic>{},
          );
          return element['type'] == 'image';
        }),
        'operation': 'apply_format_brush',
        'timestamp': DateTime.now().toIso8601String(),
      },
      operation: 'apply_format_brush',
      affectedElements: targetElementIds,
      affectedLayers: ['content', 'rendering'],
      affectedUIComponents: ['canvas', 'property_panel'],
    );

    stopwatch.stop();
    PracticeEditLogger.logPerformanceOperation(
        '批量格式刷应用', stopwatch.elapsedMilliseconds,
        data: {
          'elementCount': selectedElements.length,
          'hasImageProcessing': true,
        });
    // 重置格式刷状态
    setState(() {
      _isFormatBrushActive = false;
      _formatBrushStyles = null;
    });
  }

  /// Bring element to front
  void _bringElementToFront() {
    // Use controller directly without setState since it will notify listeners
    PracticeEditUtils.bringElementToFront(_controller);
    // Only trigger a rebuild if we're not in a drag operation
    if (_canvasKey.currentState == null ||
        !_canvasKey.currentState!.context.mounted) {
      setState(() {});
    }
  }

  /// Build the body of the page
  Widget _buildBody(BuildContext context) {
    return Row(
      children: [
        // Left panel - wrapped in AnimatedBuilder since it needs to react to controller changes
        if (!_isPreviewMode && _isLeftPanelOpen)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => _buildLeftPanel(),
          ),

        // Left panel toggle
        if (!_isPreviewMode)
          PersistentSidebarToggle(
            sidebarId: 'practice_edit_left_panel',
            defaultIsOpen: false,
            onToggle: (isOpen) => setState(() {
              _isLeftPanelOpen = isOpen;
            }),
            alignRight: false,
          ),

        // Central edit area - isolated from controller notifications to prevent canvas rebuilds
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toolbar - wrapped in AnimatedBuilder since it needs to react to controller changes
              if (!_isPreviewMode && _showToolbar)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => _buildEditToolbar(),
                ),

              // Edit canvas - NOT wrapped in AnimatedBuilder to prevent rebuilds
              Expanded(
                child: ProviderScope(
                  child: M3PracticeEditCanvas(
                    key: _canvasKey,
                    controller: _controller,
                    isPreviewMode: _isPreviewMode,
                    transformationController: _transformationController,
                  ),
                ),
              ),

              // Page thumbnails - wrapped in AnimatedBuilder since it needs to react to page changes
              if (_showThumbnails && !_isPreviewMode)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => _buildPageThumbnails(),
                ),
            ],
          ),
        ),

        // Right panel toggle
        if (!_isPreviewMode)
          PersistentSidebarToggle(
            sidebarId: 'practice_edit_right_panel',
            defaultIsOpen: true,
            onToggle: (isOpen) => setState(() {
              _isRightPanelOpen = isOpen;
            }),
            alignRight: true,
          ),

        // Right properties panel - wrapped in AnimatedBuilder since it needs to react to selection changes
        if (!_isPreviewMode && _isRightPanelOpen)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => _buildRightPanel(),
          ),
      ],
    );
  }

  /// Build the edit toolbar
  Widget _buildEditToolbar() {
    return Column(
      children: [
        // 🆕 使用AnimatedBuilder直接监听controller状态变化，确保页面切换时能及时更新剪贴板状态
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // 检查剪贴板状态，确保与当前状态一致
            final shouldHaveClipboard = _clipboardElement != null;
            if (shouldHaveClipboard != _clipboardHasContent) {
              // 异步更新剪贴板状态，避免在build期间调用setState
              Future.microtask(() async {
                final hasContent = await _checkClipboardContent();
                if (mounted && hasContent != _clipboardHasContent) {
                  _clipboardHasContent = hasContent;
                  _clipboardNotifier.value = hasContent;
                  setState(() {});

                  EditPageLogger.clipboardState(hasContent ? '有内容' : '无内容',
                      data: {
                        'correctedByToolbar': true,
                      });
                }
              });
            }

            return ValueListenableBuilder<bool>(
              valueListenable: _clipboardNotifier,
              builder: (context, canPaste, _) {
                return M3EditToolbar(
                  controller: _controller,
                  gridVisible: _controller.state.gridVisible,
                  snapEnabled: _controller.state.snapEnabled,
                  alignmentMode: _controller.state.alignmentMode,
                  onToggleGrid: _toggleGrid,
                  onToggleSnap: _toggleSnap,
                  onToggleAlignmentMode: _toggleAlignmentMode,
                  onCopy: _copySelectedElement,
                  onPaste: _pasteElement,
                  canPaste: canPaste,
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
                        _controller.setCurrentTool(tool);
                        PracticeEditLogger.logUserAction('工具切换', data: {
                          'newTool': tool,
                          'previousTool': _currentTool,
                        });
                      }
                    });
                  },
                  onDragElementStart: (context, elementType) {
                    // 拖拽开始时的处理逻辑可以为空，因为Draggable内部已经处理了拖拽功能
                  },
                  // 元素创建回调
                  onCreateTextElement: () => _createTextElement(),
                  onCreateImageElement: () => _createImageElement(),
                  onCreateCollectionElement: () => _createCollectionElement(),
                );
              },
            );
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
    EditPageLogger.editPageInfo(
      '🏗️ _buildPageThumbnails 被调用',
      data: {
        'pagesCount': _controller.state.pages.length,
        'currentPageIndex': _controller.state.currentPageIndex,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        EditPageLogger.editPageInfo(
          '🔄 M3PageThumbnailStrip AnimatedBuilder 重建',
          data: {
            'pagesCount': _controller.state.pages.length,
            'currentPageIndex': _controller.state.currentPageIndex,
            'hasUnsavedChanges': _controller.state.hasUnsavedChanges,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        return M3PageThumbnailStrip(
          pages: _controller.state.pages,
          currentPageIndex: _controller.state.currentPageIndex,
          onPageSelected: (index) {
            EditPageLogger.editPageInfo(
              '👆 页面缩略图被点击',
              data: {
                'selectedIndex': index,
                'currentIndex': _controller.state.currentPageIndex,
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
            _controller.switchToPage(index);
          },
          onAddPage: _addNewPage,
          onDeletePage: _deletePage,
          onReorderPages: _reorderPages,
        );
      },
    );
  }

  /// Build the right properties panel
  Widget _buildRightPanel() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // 🔍[TRACKING] 属性面板重建跟踪
        _propertyPanelBuildCount++;

        final selectedElementsCount =
            _controller.state.selectedElementIds.length;
        final selectedLayerId = _controller.state.selectedLayerId;

        // 🚀 优化：减少属性面板重建的重复日志
        final now = DateTime.now();
        final hasSignificantChange =
            selectedElementsCount != _lastSelectedCount ||
                selectedLayerId != _lastSelectedLayerId;
        final isTimeForLog =
            now.difference(_lastPropertyPanelLogTime).inSeconds >= 2;
        final isMilestone = _propertyPanelBuildCount % 10 == 0;

        if (hasSignificantChange || isTimeForLog || isMilestone) {
          EditPageLogger.propertyPanelDebug(
            '属性面板重建',
            data: {
              'buildNumber': _propertyPanelBuildCount,
              'selectedElementsCount': selectedElementsCount,
              'selectedLayerId': selectedLayerId,
              'changeType': hasSignificantChange
                  ? 'selection_changed'
                  : isMilestone
                      ? 'milestone'
                      : 'time_based',
              'trigger': hasSignificantChange
                  ? '选择状态变化'
                  : isMilestone
                      ? '里程碑记录'
                      : '定时记录',
              'optimization': 'property_panel_rebuild_optimized',
            },
          );

          _lastSelectedCount = selectedElementsCount;
          _lastSelectedLayerId = selectedLayerId;
          _lastPropertyPanelLogTime = now;
        }

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
                // Check if view-affecting properties are changing
                final currentPage = _controller.state.currentPage;
                final shouldResetView = currentPage != null &&
                    (properties.containsKey('orientation') ||
                        properties.containsKey('width') ||
                        properties.containsKey('height') ||
                        properties.containsKey('dpi'));

                _controller.updatePageProperties(properties);
                // Auto reset view position after page size/orientation changes
                if (shouldResetView) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _controller.resetViewPosition();
                  });
                }
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
            panel = Center(
                child:
                    Text(AppLocalizations.of(context).selectedElementNotFound));
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
      EditPageLogger.clipboardState('内部剪贴板检查', data: {'type': type});

      // 🔧 修复：正确区分不同类型的剪贴板内容
      if (type == 'text' || type == 'collection' || type == 'group') {
        // 直接复制的文本、集字、组合元素 - 检查ID
        final hasId = _clipboardElement!.containsKey('id') &&
            _clipboardElement!['id'] != null &&
            _clipboardElement!['id'].toString().isNotEmpty;
        PracticeEditLogger.debugDetail('直接复制元素验证', data: {
          'type': type,
          'hasId': hasId,
          'elementId': _clipboardElement!['id'],
        });
        return hasId;
      } else if (type == 'image') {
        // 图像元素需要特殊判断：可能是直接复制的元素，也可能是图库项目

        // 1. 检查是否是直接复制的图像元素（有完整的元素结构）
        if (_clipboardElement!.containsKey('id') &&
            _clipboardElement!.containsKey('content') &&
            _clipboardElement!.containsKey('x') &&
            _clipboardElement!.containsKey('y')) {
          final hasId = _clipboardElement!['id'] != null &&
              _clipboardElement!['id'].toString().isNotEmpty;
          PracticeEditLogger.debugDetail('直接复制图像元素验证', data: {
            'type': type,
            'hasId': hasId,
            'elementId': _clipboardElement!['id'],
            'hasContent': _clipboardElement!.containsKey('content'),
          });
          return hasId;
        }

        // 2. 检查是否是图库项目（只有imageUrl或itemIds）
        else if (_clipboardElement!.containsKey('imageUrl') ||
            _clipboardElement!.containsKey('itemIds')) {
          final hasImageUrl = _clipboardElement!.containsKey('imageUrl') &&
              _clipboardElement!['imageUrl'] != null;
          final hasItemIds = _clipboardElement!.containsKey('itemIds') &&
              _clipboardElement!['itemIds'] is List &&
              (_clipboardElement!['itemIds'] as List).isNotEmpty;

          PracticeEditLogger.debugDetail('图库项目内容验证', data: {
            'type': type,
            'hasImageUrl': hasImageUrl,
            'hasItemIds': hasItemIds,
            'imageUrl': hasImageUrl ? _clipboardElement!['imageUrl'] : null,
            'itemCount':
                hasItemIds ? (_clipboardElement!['itemIds'] as List).length : 0,
          });
          return hasImageUrl || hasItemIds;
        }

        // 3. 其他情况，可能是不完整的数据
        else {
          PracticeEditLogger.logError(
              '图像元素结构不完整', Exception('Incomplete image element structure'),
              context: {
                'type': type,
                'keys': _clipboardElement!.keys.toList(),
              });
          return false;
        }
      } else if (type == 'characters' || type == 'character') {
        // 字符类型 - 检查字符IDs
        final hasIds = _clipboardElement!.containsKey('characterIds') ||
            (_clipboardElement!.containsKey('data') &&
                _clipboardElement!['data'] is Map &&
                _clipboardElement!['data'].containsKey('characterId'));
        PracticeEditLogger.debugDetail('字符内容验证', data: {'hasIds': hasIds});
        return hasIds;
      } else if (type == 'library_items') {
        // 图库项目类型 - 检查项目IDs
        final hasIds = _clipboardElement!.containsKey('itemIds') &&
            _clipboardElement!['itemIds'] is List &&
            (_clipboardElement!['itemIds'] as List).isNotEmpty;
        PracticeEditLogger.debugDetail('图库项目验证', data: {
          'hasIds': hasIds,
          'itemCount':
              hasIds ? (_clipboardElement!['itemIds'] as List).length : 0,
        });
        return hasIds;
      } else if (type == 'multi_elements') {
        // 多元素类型 - 检查元素列表
        final elements = _clipboardElement!['elements'];
        final hasElements =
            elements != null && elements is List && elements.isNotEmpty;
        PracticeEditLogger.debugDetail('多元素内容验证', data: {
          'hasElements': hasElements,
          'elementCount': hasElements ? elements.length : 0
        });
        return hasElements;
      }

      // For other types, just check if it exists
      PracticeEditLogger.debugDetail('其他类型默认有效', data: {'type': type});
      return true;
    }

    // Then check system clipboard
    try {
      // Check for text data
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final hasText = clipboardData != null &&
          clipboardData.text != null &&
          clipboardData.text!.isNotEmpty;
      // if (hasText) ...
      if (hasText) {
        try {
          final text = clipboardData.text!.trim();

          // 检查文本是否可能是JSON格式（简单预检查）
          if (!text.startsWith('{') && !text.startsWith('[')) {
            // 不是JSON格式，按普通文本处理 - 屏蔽日志输出
            // AppLogger.debug(
            //   '检查剪贴板: 文本不是JSON格式，按普通文本处理',
            //   tag: 'PracticeEdit',
            //   data: {
            //     'textPreview':
            //         text.length > 50 ? '${text.substring(0, 50)}...' : text
            //   },
            // );
            return true;
          }

          final json = jsonDecode(text);
          if (json is Map<String, dynamic> && json.containsKey('type')) {
            final type = json['type'];
            AppLogger.debug(
              '检查剪贴板: 识别到JSON内容',
              tag: 'PracticeEdit',
              data: {'type': type},
            );
            if (type == 'characters') {
              final characterIds = json['characterIds'];
              final hasIds = characterIds != null &&
                  characterIds is List &&
                  characterIds.isNotEmpty;
              AppLogger.debug(
                '检查剪贴板: 字符IDs',
                tag: 'PracticeEdit',
                data: {'characterIds': characterIds, 'hasIds': hasIds},
              );
              return hasIds;
            } else if (type == 'library_items') {
              final itemIds = json['itemIds'];
              final hasIds =
                  itemIds != null && itemIds is List && itemIds.isNotEmpty;
              PracticeEditLogger.debugDetail('图库项目IDs验证',
                  data: {'itemIds': itemIds, 'hasIds': hasIds});
              return hasIds;
            } else if (type == 'practice_elements') {
              // 🆕 处理跨页面复制的字帖编辑元素
              final data = json['data'];
              if (data != null && data is Map<String, dynamic>) {
                PracticeEditLogger.debugDetail('跨页面字帖元素检测', data: {
                  'elementType': data['type'],
                  'source': json['source'],
                });
                return true;
              }
            } else if (json.containsKey('id') &&
                (type == 'text' || type == 'image' || type == 'collection')) {
              PracticeEditLogger.debugDetail('可粘贴元素类型检测', data: {'type': type});
              return true;
            }
          }
        } catch (e) {
          // JSON解析失败，记录详细信息但不影响功能
          AppLogger.debug(
            '检查剪贴板: JSON解析失败，按普通文本处理',
            tag: 'PracticeEdit',
            data: {
              'error': e.toString(),
              'textLength': clipboardData.text!.length,
              'textPreview': clipboardData.text!.length > 100
                  ? '${clipboardData.text!.substring(0, 100)}...'
                  : clipboardData.text!,
            },
          );
        }
        // Plain text can always be pasted
        return true;
      }
      // Check for image data in clipboard (different formats)
      try {
        for (final format in ['image/png', 'image/jpeg', 'image/gif']) {
          final imageClipboardData = await Clipboard.getData(format);
          if (imageClipboardData != null) {
            AppLogger.debug(
              '检查剪贴板: 系统剪贴板有图片数据',
              tag: 'PracticeEdit',
              data: {'format': format},
            );
            return true;
          }
        }
      } catch (e) {
        // 屏蔽警告日志
        // AppLogger.warning(
        //   '检查系统剪贴板图片数据错误',
        //   tag: 'PracticeEdit',
        //   error: e,
        // );
      }
      return hasText;
    } catch (e) {
      AppLogger.error(
        '检查剪贴板错误',
        tag: 'PracticeEdit',
        error: e,
      );
      return false;
    }
  }

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
          'rotation',
          // 🆕 添加二值化处理参数（只复制设置，不复制数据）
          'isBinarizationEnabled',
          'binaryThreshold',
          'isNoiseReductionEnabled',
          'noiseReductionLevel',
          // 注意：不复制 binarizedImageData，因为这是处理后的数据，不是格式设置
          // 🆕 添加其他图像处理参数
          'fitMode',
          'alignment',
          'cropX',
          'cropY',
          'cropWidth',
          'cropHeight',
          'cropTop',
          'cropBottom',
          'cropLeft',
          'cropRight',
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
        } // 不复制characters属性，因为这是内容而非样式
      }
    } else if (element['type'] == 'group') {
      // 组合元素样式 - 主要是透明度属性
      _formatBrushStyles!['opacity'] = element['opacity'];
      _formatBrushStyles!['rotation'] = element['rotation'];

      // 组合元素的其他可能样式属性
      if (element.containsKey('width')) {
        _formatBrushStyles!['width'] = element['width'];
      }
      if (element.containsKey('height')) {
        _formatBrushStyles!['height'] = element['height'];
      }

      // 复制content中的样式属性（如果存在）
      if (element.containsKey('content') &&
          element['content'] is Map<String, dynamic>) {
        final content = element['content'] as Map<String, dynamic>;

        // 组合元素可能的样式属性
        final propertiesToCopy = [
          'backgroundColor',
          'borderColor',
          'borderWidth',
          'cornerRadius',
          'shadowColor',
          'shadowOpacity',
          'shadowOffset',
          'shadowBlur',
        ];

        // 复制所有指定的样式属性
        for (final property in propertiesToCopy) {
          if (content.containsKey(property)) {
            _formatBrushStyles!['content_$property'] = content[property];
          }
        }
      }
    }

    // 如果是从字符管理页面复制的字符元素，设置字体大小为200px
    if (element['type'] == 'collection' &&
        element.containsKey('isFromCharacterManagement') &&
        element['isFromCharacterManagement'] == true) {
      _formatBrushStyles!['content_fontSize'] = 200.0;
    } // 激活格式刷
    setState(() {
      _isFormatBrushActive = true;
      // 显示提示信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).formatBrushActivated)),
      );
    });
  }

  /// Copy selected elements with enhanced image preloading optimization
  void _copySelectedElement() async {
    AppLogger.info(
      '开始复制选中元素（增强图像预加载）',
      tag: 'PracticeEdit',
      data: {'timestamp': DateTime.now().toIso8601String()},
    );
    // Capture context reference before async operations
    final currentContext = context;
    final scaffoldMessenger = ScaffoldMessenger.of(currentContext);
    try {
      // Get services for image preloading
      final characterImageService = ref.read(characterImageServiceProvider);
      final imageCacheService = ref.read(imageCacheServiceProvider);
      // Use enhanced copy method with comprehensive image preloading
      _clipboardElement =
          await PracticeEditUtils.copySelectedElementsWithPreloading(
        _controller,
        currentContext,
        characterImageService: characterImageService,
        imageCacheService: imageCacheService,
      );
      AppLogger.info(
        '复制结果',
        tag: 'PracticeEdit',
        data: {
          'result': _clipboardElement != null ? '成功' : '失败',
          'type': _clipboardElement != null ? _clipboardElement!['type'] : null,
        },
      );

      // 🆕 将复制的元素数据也保存到系统剪贴板，支持跨页面复制粘贴
      if (_clipboardElement != null) {
        try {
          // 为跨页面复制创建完整的数据包
          final crossPageData = {
            'type': 'practice_elements', // 标识这是字帖编辑元素
            'source': 'practice_edit_page', // 来源标识
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'data': _clipboardElement,
          };

          final jsonString = jsonEncode(crossPageData);
          await Clipboard.setData(ClipboardData(text: jsonString));

          AppLogger.info(
            '元素数据已保存到系统剪贴板，支持跨页面复制粘贴',
            tag: 'PracticeEdit',
            data: {
              'dataSize': jsonString.length,
              'elementType': _clipboardElement!['type'],
            },
          );
        } catch (e) {
          AppLogger.warning(
            '保存到系统剪贴板失败，仅支持当前页面内复制粘贴',
            tag: 'PracticeEdit',
            error: e,
          );
        }
      }

      if (mounted) {
        _clipboardHasContent = _clipboardElement != null;
        _clipboardNotifier.value = _clipboardElement != null;
        setState(() {});
        AppLogger.debug(
          '设置粘贴按钮状态',
          tag: 'PracticeEdit',
          data: {'status': _clipboardHasContent ? '激活' : '禁用'},
        );
        if (_clipboardElement != null) {
          scaffoldMessenger.showSnackBar(SnackBar(
              content:
                  Text(AppLocalizations.of(context).elementCopiedToClipboard)));
        }
      }
    } catch (e) {
      AppLogger.error(
        '复制元素时发生错误',
        tag: 'PracticeEdit',
        error: e,
      );
      if (mounted) {
        _clipboardElement =
            PracticeEditUtils.copySelectedElements(_controller, context);
        setState(() {
          _clipboardHasContent = _clipboardElement != null;
        });
        if (_clipboardElement != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(AppLocalizations.of(context).elementCopiedToClipboard)));
        }
      }
    }
  }

  // _buildElementButton 方法已移除，相关功能移至 M3EditToolbar

  /// 创建文本元素（工具栏按钮调用）
  void _createTextElement() {
    _controller.addTextElement();

    AppLogger.info(
      '通过工具栏创建文本元素',
      tag: 'PracticeEdit',
      data: {
        'action': 'create_text_element',
        'source': 'toolbar_button',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 创建图片元素（工具栏按钮调用）
  void _createImageElement() {
    // 使用默认图片URL创建图片元素，用户之后可以更换
    const defaultImageUrl = 'assets/images/transparent_bg.png';
    _controller.addImageElement(defaultImageUrl);

    AppLogger.info(
      '通过工具栏创建图片元素',
      tag: 'PracticeEdit',
      data: {
        'action': 'create_image_element',
        'source': 'toolbar_button',
        'defaultImageUrl': defaultImageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 创建采集元素（工具栏按钮调用）
  void _createCollectionElement() {
    // 使用默认字符创建采集元素，用户之后可以修改
    const defaultCharacters = '字';
    _controller.addCollectionElement(defaultCharacters);

    AppLogger.info(
      '通过工具栏创建采集元素',
      tag: 'PracticeEdit',
      data: {
        'action': 'create_collection_element',
        'source': 'toolbar_button',
        'defaultCharacters': defaultCharacters,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 创建文本元素（用于粘贴纯文本时调用）
  void _createTextElementFromText(String text) {
    if (text.isEmpty) return;

    // 创建新元素ID
    final newId = const Uuid().v4();

    // 获取本地化文本
    final l10n = AppLocalizations.of(context);

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
      'layerId': _controller.state.selectedLayerId ??
          _controller.state.layers.first['id'],
      'isLocked': false,
      'isHidden': false,
      'name': l10n.textElement, // 🌍 使用多语言支持
      'content': {
        'text': text,
        'fontSize': 24.0,
        'fontWeight': 'normal',
        'fontStyle': 'normal',
        'fontColor': '#000000',
        'textAlign': 'left',
        'verticalAlign': 'top',
        'fontFamily': 'System',
        'letterSpacing': 0.0,
        'lineHeight': 1.2,
        'padding': 8.0,
        'backgroundColor': 'transparent',
        'writingMode': 'horizontal-tb',
      },
    };

    // 添加到当前页面
    setState(() {
      _controller.state.currentPageElements.add(newElement);
      _controller.selectElement(newId);
      _controller.state.hasUnsavedChanges = true;
    });

    AppLogger.info(
      '通过粘贴文本创建文本元素',
      tag: 'PracticeEdit',
      data: {
        'action': 'create_text_element_from_paste',
        'textLength': text.length,
        'elementId': newId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
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
    // Use controller's mixin method which includes proper state management
    _controller.deletePage(index);

    // 🆕 根据页面数量自动更新缩略图显示状态
    _updateThumbnailVisibilityBasedOnPageCount();

    // The controller will notify listeners automatically through intelligent notification
  }

  /// Delete selected elements
  void _deleteSelectedElements() {
    final l10n = AppLocalizations.of(context);

    if (_controller.state.selectedElementIds.isEmpty) return;

    AppLogger.info(
      '用户请求删除选中元素',
      tag: 'PracticeEdit',
      data: {
        'selectedCount': _controller.state.selectedElementIds.length,
        'elementIds': _controller.state.selectedElementIds,
      },
    );

    // Show confirmation dialog
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.deleteElementConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        // Create a copy to avoid ConcurrentModificationError
        final idsToDelete =
            List<String>.from(_controller.state.selectedElementIds);
        AppLogger.info(
          '确认删除元素',
          tag: 'PracticeEdit',
          data: {
            'deletedCount': idsToDelete.length,
            'elementIds': idsToDelete,
          },
        );
        for (final id in idsToDelete) {
          _controller.deleteElement(id);
        }
      } else {
        AppLogger.debug(
          '用户取消删除操作',
          tag: 'PracticeEdit',
        );
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
          SnackBar(content: Text(l10n.titleUpdated(newTitle))),
        );
      }
    }
  }

  /// Group selected elements
  void _groupSelectedElements() {
    if (_controller.state.selectedElementIds.length > 1) {
      AppLogger.info(
        '分组选中元素',
        tag: 'PracticeEdit',
        data: {
          'elementCount': _controller.state.selectedElementIds.length,
          'elementIds': _controller.state.selectedElementIds,
        },
      );
      _controller.groupSelectedElements();
    }
  }

  /// 处理从字符管理页面复制的字符
  Future<void> _handleCharacterClipboardData(Map<String, dynamic> json) async {
    AppLogger.debug(
      '处理字符剪贴板数据',
      tag: 'PracticeEdit',
      data: {'json': json},
    );

    final characterIds = List<String>.from(json['characterIds']);
    AppLogger.debug(
      '字符IDs',
      tag: 'PracticeEdit',
      data: {
        'characterIds': characterIds,
        'count': characterIds.length,
      },
    );

    if (characterIds.isEmpty) {
      AppLogger.warning(
        '没有字符ID，无法创建集字元素',
        tag: 'PracticeEdit',
      );
      return;
    }

    // 获取字符服务和图像服务
    final characterService = ref.read(characterServiceProvider);
    final characterImageService = ref.read(characterImageServiceProvider);
    AppLogger.debug(
      '已获取字符服务和图像服务',
      tag: 'PracticeEdit',
    );

    // 对于每个字符ID，创建一个集字元素
    for (int i = 0; i < characterIds.length; i++) {
      final characterId = characterIds[i];
      AppLogger.debug(
        '处理字符ID',
        tag: 'PracticeEdit',
        data: {'characterId': characterId},
      );

      try {
        // 获取字符数据
        AppLogger.debug(
          '获取字符详情',
          tag: 'PracticeEdit',
          data: {'characterId': characterId},
        );
        final character =
            await characterService.getCharacterDetails(characterId);
        if (character == null) {
          AppLogger.warning(
            '无法获取字符详情，跳过',
            tag: 'PracticeEdit',
            data: {'characterId': characterId},
          );
          continue;
        }

        AppLogger.debug('成功获取字符详情', tag: 'PracticeEdit');
        // debugPrint('成功获取字符详情: $character');

        // 获取字符图像 - 使用default类型和png格式
        AppLogger.debug(
          '获取字符图像',
          tag: 'PracticeEdit',
          data: {
            'characterId': characterId,
            'type': 'default',
            'format': 'png'
          },
        );
        final imageBytes = await characterImageService.getCharacterImage(
            characterId, 'default', 'png');
        if (imageBytes == null) {
          AppLogger.warning(
            '无法获取字符图像，跳过此字符',
            tag: 'PracticeEdit',
            data: {'characterId': characterId},
          );
          continue;
        }
        AppLogger.debug(
          '成功获取字符图像',
          tag: 'PracticeEdit',
          data: {
            'characterId': characterId,
            'imageSize': imageBytes.length,
          },
        ); // 创建新元素ID
        final newId = const Uuid().v4();
        AppLogger.debug(
          '创建新元素ID',
          tag: 'PracticeEdit',
          data: {'newId': newId, 'characterId': characterId},
        );

        // 计算放置位置（按顺序排列）
        final x = 100.0 + (i * 20);
        final y = 100.0 + (i * 20); // 创建集字元素
        final newElement = {
          'id': newId,
          'type': 'collection',
          'x': x,
          'y': y,
          'width': 400.0, // 更大的尺寸以便于查看
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
            'fontSize': 50.0, // 统一字体大小
            'fontColor': '#000000',
            'backgroundColor': 'transparent',
            'writingMode': 'horizontal-l',
            'letterSpacing': 10.0,
            'lineSpacing': 10.0,
            'padding': 0.0,
            'textAlign': 'center',
            'verticalAlign': 'middle',
            'enableSoftLineBreak': false,
            // 添加与字符相关的图像数据 - 使用位置索引格式
            'characterImages': {
              '0': {
                'characterId': characterId,
                'type': 'square-binary',
                'format': 'png-binary',
                'drawingType': 'square-binary',
                'drawingFormat': 'png-binary',
                'transform': {
                  'scale': 1.0,
                  'rotation': 0.0,
                  'color': '#000000',
                  'opacity': 1.0,
                  'invert': false,
                },
              },
            },
          },
        };

        AppLogger.debug(
          '创建新的集字元素',
          tag: 'PracticeEdit',
          data: {
            'elementId': newId,
            'type': 'collection',
            'characterId': characterId,
            'x': newElement['x'],
            'y': newElement['y'],
          },
        ); // 添加到当前页面

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
              isFromCharacterManagement: true,
              elementFromCharacterManagement: newElement);

          // 选择新添加的元素
          // 注意：我们不知道新添加元素的ID，因为它是在controller内部生成的
          // 所以我们不能直接选择它
          AppLogger.info(
            '成功添加集字元素到页面',
            tag: 'PracticeEdit',
            data: {
              'position': {'x': x, 'y': y},
              'content': characters,
              'characterId': characterId,
            },
          );
        });
      } catch (e, stackTrace) {
        AppLogger.error(
          '处理字符数据失败',
          tag: 'PracticeEdit',
          error: e,
          stackTrace: stackTrace,
          data: {'characterId': characterId},
        );
      }
    }
    AppLogger.info(
      '字符剪贴板数据处理完成',
      tag: 'PracticeEdit',
      data: {'processedCount': characterIds.length},
    );
  }

  /// 处理图库项目剪贴板数据
  Future<void> _handleLibraryItemClipboardData(
      Map<String, dynamic> json) async {
    AppLogger.debug(
      '开始处理图库项目剪贴板数据',
      tag: 'PracticeEdit',
      data: {'jsonKeys': json.keys.toList()},
    );
    final itemIds = List<String>.from(json['itemIds']);
    AppLogger.debug(
      '解析图库项目IDs',
      tag: 'PracticeEdit',
      data: {'itemIds': itemIds, 'count': itemIds.length},
    );

    if (itemIds.isEmpty) {
      AppLogger.warning(
        '没有图库项目ID，无法创建图片元素',
        tag: 'PracticeEdit',
      );
      return;
    }

    // 获取图库服务
    final libraryService = ref.read(libraryServiceProvider);
    AppLogger.debug(
      '已获取图库服务',
      tag: 'PracticeEdit',
    );

    // 对于每个图库项目ID，创建一个图片元素
    for (int i = 0; i < itemIds.length; i++) {
      final itemId = itemIds[i];
      AppLogger.debug(
        '处理图库项目ID',
        tag: 'PracticeEdit',
        data: {'itemId': itemId, 'index': i},
      );

      try {
        // 获取图库项目数据
        AppLogger.debug(
          '获取图库项目数据',
          tag: 'PracticeEdit',
          data: {'itemId': itemId},
        );
        final item = await libraryService.getItem(itemId);
        if (item == null) {
          AppLogger.warning(
            '无法获取图库项目数据，跳过此项目',
            tag: 'PracticeEdit',
            data: {'itemId': itemId},
          );
          continue;
        }
        AppLogger.debug(
          '成功获取图库项目数据',
          tag: 'PracticeEdit',
          data: {'itemId': itemId, 'path': item.path},
        );

        // 创建新元素ID
        final newId = const Uuid().v4();
        AppLogger.debug(
          '创建新元素ID',
          tag: 'PracticeEdit',
          data: {'newId': newId, 'itemId': itemId},
        );

        // 计算放置位置（按顺序排列）
        final x = 100.0 + (i * 20);
        final y = 100.0 + (i * 20);

        AppLogger.debug(
          '创建新的图片元素',
          tag: 'PracticeEdit',
          data: {
            'elementId': newId,
            'type': 'image',
            'itemId': itemId,
            'x': x,
            'y': y,
          },
        ); // 添加到当前页面

        setState(() {
          // 使用控制器的公共方法添加图片元素
          // 将文件路径转换为相对路径存储
          final absoluteImageUrl = 'file://${item.path.replaceAll("\\", "/")}';
          final relativeImageUrl =
              ImagePathConverter.toRelativePath(absoluteImageUrl);
          _controller.addImageElementAt(x, y, relativeImageUrl);
          AppLogger.info(
            '成功添加图片元素到页面',
            tag: 'PracticeEdit',
            data: {
              'position': {'x': x, 'y': y},
              'imageUrl': relativeImageUrl,
              'itemId': itemId,
            },
          );
        });
      } catch (e) {
        AppLogger.error(
          '处理图库项目时出错',
          tag: 'PracticeEdit',
          error: e,
          data: {'itemId': itemId},
        );
      }
    }
    AppLogger.info(
      '图库项目剪贴板数据处理完成',
      tag: 'PracticeEdit',
      data: {'processedCount': itemIds.length},
    );
  }

  /// Initialize panel states from persistent storage
  void _initializePanelStates() {
    // Get persistent states for both panels
    final leftPanelState = ref.read(sidebarStateProvider((
      sidebarId: 'practice_edit_left_panel',
      defaultState: false, // Default to closed as requested
    )));

    final rightPanelState = ref.read(sidebarStateProvider((
      sidebarId: 'practice_edit_right_panel',
      defaultState: true, // Default to open
    )));

    // Update local state to match persistent state
    setState(() {
      _isLeftPanelOpen = leftPanelState;
      _isRightPanelOpen = rightPanelState;
    });
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
      onToggleToolbar: () {
        setState(() {
          _showToolbar = !_showToolbar;
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
      goToPreviousPage: _goToPreviousPage,
      goToNextPage: _goToNextPage,
      // Add tool selection callback to connect keyboard shortcuts with toolbar
      onSelectTool: (tool) {
        setState(() {
          // 如果当前已经是select模式，再次点击select按钮则退出select模式
          if (_currentTool == 'select' && tool == 'select') {
            _currentTool = '';
            _controller.exitSelectMode();
          } else {
            _currentTool = tool;
            // 同步到controller的状态
            _controller.setCurrentTool(tool);
            PracticeEditLogger.logUserAction('工具切换', data: {
              'newTool': tool,
              'previousTool': _currentTool,
            });
          }
        });
      },
    );

    // 添加键盘事件处理器
    HardwareKeyboard.instance.addHandler(_keyboardHandler.handleKeyEvent);
  }

  /// Load practice
  Future<void> _loadPractice(String practiceId) async {
    if (!mounted) return;

    try {
      EditPageLogger.editPageInfo(
        '开始加载字帖',
        data: {
          'practiceId': practiceId,
        },
      );

      final practice =
          await _controller.practiceService.getPractice(practiceId);
      if (!mounted) return;

      if (practice == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).practiceSheetNotExists)),
        );
        return;
      }

      // 更新控制器状态
      _controller.updatePractice(practice);

      // 🆕 根据页面数量自动决定是否显示缩略图面板
      _updateThumbnailVisibilityBasedOnPageCount();

      // 🆕 字帖加载完成后自动重置画布视图位置
      // 延迟执行以确保UI完全更新完成
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          EditPageLogger.editPageInfo(
            '字帖加载完成，自动重置视图位置',
            data: {
              'practiceId': practiceId,
              'practiceTitle': practice.title,
              'operation': 'auto_reset_view_after_load',
            },
          );
          _controller.resetViewPosition();
        }
      });
    } catch (e, stackTrace) {
      if (!mounted) return;

      EditPageLogger.editPageError(
        '加载字帖失败',
        error: e,
        stackTrace: stackTrace,
        data: {
          'practiceId': practiceId,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context).loadPracticeSheetFailed)),
      );
    }
  }

  /// Move element down one layer
  void _moveElementDown() {
    // Use controller directly without setState since it will notify listeners
    PracticeEditUtils.moveElementDown(_controller);
    // Only trigger a rebuild if we're not in a drag operation
    if (_canvasKey.currentState == null ||
        !_canvasKey.currentState!.context.mounted) {
      setState(() {});
    }
  }

  /// Move element up one layer
  void _moveElementUp() {
    // Use controller directly without setState since it will notify listeners
    PracticeEditUtils.moveElementUp(_controller);
    // Only trigger a rebuild if we're not in a drag operation
    if (_canvasKey.currentState == null ||
        !_canvasKey.currentState!.context.mounted) {
      setState(() {});
    }
  }

  /// Move selected elements
  void _moveSelectedElements(double dx, double dy) {
    if (_controller.state.selectedElementIds.isEmpty) return;

    final elements = _controller.state.currentPageElements;
    bool hasChanges = false;
    int movedCount = 0;

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
        movedCount++;
      }
    }

    if (hasChanges) {
      AppLogger.debug(
        '移动选中元素',
        tag: 'PracticeEdit',
        data: {
          'movedCount': movedCount,
          'totalSelected': _controller.state.selectedElementIds.length,
          'deltaX': dx,
          'deltaY': dy,
        },
      );
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
            title: Text(l10n.unsavedChanges),
            content: Text(l10n.unsavedChanges),
            actions: <Widget>[
              TextButton(
                child: Text(l10n.cancel),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text(l10n.exit),
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
    AppLogger.info(
      '开始粘贴操作',
      tag: 'PracticeEdit',
    );

    // 首先尝试从内部剪贴板粘贴
    if (_clipboardElement != null) {
      AppLogger.debug(
        '使用内部剪贴板内容粘贴',
        tag: 'PracticeEdit',
        data: {'type': _clipboardElement!['type']},
      );

      try {
        // Get services for cache warming
        final characterImageService = ref.read(characterImageServiceProvider);
        final imageCacheService = ref.read(imageCacheServiceProvider);

        // Use enhanced paste with cache warming
        await PracticeEditUtils.pasteElementWithCacheWarming(
          _controller,
          _clipboardElement,
          characterImageService: characterImageService,
          imageCacheService: imageCacheService,
        );

        setState(() {
          // UI state will be updated by the paste operation
        });
      } catch (e) {
        AppLogger.warning(
          '增强粘贴失败，回退到常规粘贴',
          tag: 'PracticeEdit',
          error: e,
        );
        // Fallback to regular paste
        setState(() {
          PracticeEditUtils.pasteElement(_controller, _clipboardElement);
        });
      }
      return;
    }

    // 如果内部剪贴板为空，则尝试从系统剪贴板读取
    try {
      AppLogger.debug(
        '内部剪贴板为空，尝试读取系统剪贴板',
        tag: 'PracticeEdit',
      );
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);

      if (clipboardData == null || clipboardData.text == null) {
        // 剪贴板为空，无法粘贴
        AppLogger.debug(
          '系统剪贴板为空或没有文本内容',
          tag: 'PracticeEdit',
        );
        return;
      }

      final text = clipboardData.text!;
      AppLogger.debug(
        '系统剪贴板有文本内容',
        tag: 'PracticeEdit',
        data: {'length': text.length},
      );

      // 检查是否是JSON格式
      try {
        AppLogger.debug(
          '尝试解析为JSON',
          tag: 'PracticeEdit',
        );
        final json = jsonDecode(text);
        AppLogger.debug(
          '成功解析为JSON',
          tag: 'PracticeEdit',
        );

        // 判断是哪种类型的数据
        final type = json['type'];
        AppLogger.debug(
          'JSON类型',
          tag: 'PracticeEdit',
          data: {'type': type},
        );

        if (type == 'characters') {
          // 处理从字符管理页面复制的字符
          AppLogger.debug(
            '处理字符类型数据',
            tag: 'PracticeEdit',
          );
          await _handleCharacterClipboardData(json);
          AppLogger.info(
            '字符数据处理完成',
            tag: 'PracticeEdit',
          );
        } else if (type == 'library_items') {
          // 处理从图库管理页面复制的图片
          AppLogger.debug(
            '处理图库项目类型数据',
            tag: 'PracticeEdit',
          );
          await _handleLibraryItemClipboardData(json);
          AppLogger.info(
            '图库项目数据处理完成',
            tag: 'PracticeEdit',
          );
        } else if (type == 'practice_elements') {
          // 🆕 处理从其他字帖编辑页面复制的元素（跨页面复制粘贴）
          AppLogger.debug(
            '处理字帖编辑元素类型数据（跨页面复制粘贴）',
            tag: 'PracticeEdit',
            data: {
              'source': json['source'],
              'timestamp': json['timestamp'],
            },
          );

          final elementData = json['data'];
          if (elementData != null) {
            try {
              // Get services for cache warming
              final characterImageService =
                  ref.read(characterImageServiceProvider);
              final imageCacheService = ref.read(imageCacheServiceProvider);

              // Use enhanced paste with cache warming for cross-page elements
              await PracticeEditUtils.pasteElementWithCacheWarming(
                _controller,
                elementData,
                characterImageService: characterImageService,
                imageCacheService: imageCacheService,
              );

              setState(() {
                // UI state will be updated by the paste operation
              });

              AppLogger.info(
                '跨页面字帖元素粘贴成功',
                tag: 'PracticeEdit',
                data: {
                  'elementType': elementData['type'],
                  'source': json['source'],
                },
              );

              // 显示成功提示
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        AppLocalizations.of(context).crossPagePasteSuccess),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              AppLogger.warning(
                '跨页面字帖元素粘贴失败',
                tag: 'PracticeEdit',
                error: e,
              );
              // Fallback to regular paste
              PracticeEditUtils.pasteElement(_controller, elementData);
              setState(() {});
            }
          }

          AppLogger.info(
            '跨页面字帖元素数据处理完成',
            tag: 'PracticeEdit',
          );
        } else {
          // 尝试作为通用 JSON 元素处理
          AppLogger.debug(
            '处理通用JSON元素',
            tag: 'PracticeEdit',
          );
          try {
            // Get services for cache warming
            final characterImageService =
                ref.read(characterImageServiceProvider);
            final imageCacheService = ref.read(imageCacheServiceProvider);

            // Use enhanced paste with cache warming
            await PracticeEditUtils.pasteElementWithCacheWarming(
              _controller,
              json,
              characterImageService: characterImageService,
              imageCacheService: imageCacheService,
            );
            setState(() {
              // UI state will be updated by the paste operation
            });

            // After paste operation, check and update clipboard state
            final hasContent = await _checkClipboardContent();
            _clipboardHasContent = hasContent;
            _clipboardNotifier.value = hasContent;
            AppLogger.debug(
              '粘贴后更新剪贴板状态',
              tag: 'PracticeEdit',
              data: {'hasContent': _clipboardHasContent},
            );
          } catch (e) {
            AppLogger.warning(
              '增强JSON粘贴失败，回退到常规粘贴',
              tag: 'PracticeEdit',
              error: e,
            );
            // Fallback to regular paste
            setState(() {
              PracticeEditUtils.pasteElement(_controller, json);
            });

            // After paste operation, check and update clipboard state
            final hasContent = await _checkClipboardContent();
            _clipboardHasContent = hasContent;
            _clipboardNotifier.value = hasContent;
          }
        }
      } catch (e) {
        // 不是有效的 JSON，作为纯文本处理
        AppLogger.warning(
          '不是有效的JSON，作为纯文本处理',
          tag: 'PracticeEdit',
          error: e,
        );
        _createTextElementFromText(text);
      }

      // Refresh clipboard state after pasting
      _checkClipboardContent().then((hasContent) {
        setState(() {
          _clipboardHasContent = hasContent;
          AppLogger.debug(
            '粘贴后更新剪贴板状态',
            tag: 'PracticeEdit',
            data: {'hasContent': _clipboardHasContent},
          );
        });
      });
    } catch (e) {
      AppLogger.error(
        '粘贴操作出错',
        tag: 'PracticeEdit',
        error: e,
      );
    }
  }

  /// 注册属性面板到智能状态分发器
  void _registerPropertyPanelToIntelligentDispatcher() {
    final intelligentDispatcher = _controller.intelligentDispatcher;
    if (intelligentDispatcher != null) {
      // 创建并保存回调引用
      _propertyPanelListener = () {
        if (mounted) {
          setState(() {
            // 重建属性面板
          });
        }
      };

      // 注册属性面板作为UI组件监听器
      intelligentDispatcher.registerUIListener(
          'property_panel', _propertyPanelListener!);
    }
  }

  /// Reorder pages
  void _reorderPages(int oldIndex, int newIndex) {
    // Use controller's mixin method which includes proper state management
    _controller.reorderPages(oldIndex, newIndex);
    // The controller will notify listeners automatically through intelligent notification
  }

  /// Save as new practice
  Future<void> _saveAsNewPractice() async {
    final l10n = AppLocalizations.of(context);

    if (_controller.state.pages.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cannotSaveNoPages)),
      );
      return;
    }

    // Save ScaffoldMessenger reference to avoid using context after async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 使用PracticeSaveDialog获取标题
    final title = await showDialog<String>(
      context: context,
      builder: (context) => PracticeSaveDialog(
        initialTitle: _controller.practiceTitle,
        isSaveAs: true,
        checkTitleExists: _controller.checkTitleExists,
      ),
    );

    if (title == null || title.isEmpty) return;

    // Save practice
    AppLogger.info(
      '开始保存新字帖',
      tag: 'PracticeEdit',
      data: {'title': title},
    );

    try {
      final result = await _controller.saveAsNewPractice(title);

      if (!mounted) return;

      // 根据返回值类型进行不同处理
      if (result == true) {
        AppLogger.info(
          '新字帖保存成功',
          tag: 'PracticeEdit',
          data: {'title': title},
        );
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.practiceEditPracticeLoaded(title))),
        );
      } else if (result is String && result == 'title_exists') {
        // Title already exists, ask whether to overwrite
        final shouldOverwrite = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.titleExists),
            content: Text(l10n.titleExistsMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.overwrite),
              ),
            ],
          ),
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
              SnackBar(content: Text(l10n.saveFailure)),
            );
          }
        }
      } else {
        // 处理其他失败情况
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.saveFailure)),
        );
      }
    } catch (e) {
      // 处理异常情况
      AppLogger.error(
        '保存字帖时发生异常',
        tag: 'PracticeEdit',
        error: e,
      );

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('${l10n.saveFailure}: ${e.toString()}')),
        );
      }
    }
  }

  /// Save practice
  /// Returns true if save was successful, false otherwise
  Future<bool> _savePractice() async {
    final l10n = AppLocalizations.of(context);

    if (_controller.state.pages.isEmpty) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cannotSaveNoPages)),
      );
      return false;
    }

    // Save ScaffoldMessenger reference to avoid using context after async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 如果从未保存过，显示保存对话框让用户输入标题
    if (!_controller.isSaved) {
      await _saveAsNewPractice();
      return true; // 认为保存尝试成功，即使被取消
    }

    try {
      // Save practice
      AppLogger.info(
        '开始保存字帖',
        tag: 'PracticeEdit',
        data: {'practiceId': _controller.practiceId},
      );
      final result = await _controller.savePractice();

      if (!mounted) return false;

      // 根据返回值类型进行不同处理
      if (result == true) {
        AppLogger.info(
          '字帖保存成功',
          tag: 'PracticeEdit',
          data: {'practiceId': _controller.practiceId},
        );
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.saveSuccess)),
        );
        return true;
      } else if (result is String && result == 'title_exists') {
        // 标题已存在，询问是否覆盖
        final shouldOverwrite = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.titleExists),
            content: Text(l10n.titleExistsMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.overwrite),
              ),
            ],
          ),
        );

        if (!mounted) return false;

        if (shouldOverwrite == true) {
          final saveResult =
              await _controller.savePractice(forceOverwrite: true);

          if (!mounted) return false;

          if (saveResult == true) {
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text(l10n.saveSuccess)),
            );
            return true;
          } else {
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text(l10n.saveFailure)),
            );
            return false;
          }
        }
        return false;
      } else {
        // 处理其他失败情况
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.saveFailure)),
        );
        return false;
      }
    } catch (e) {
      // 处理异常情况
      AppLogger.error(
        '保存字帖时发生异常',
        tag: 'PracticeEdit',
        error: e,
      );

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('${l10n.saveFailure}: ${e.toString()}')),
        );
      }
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

    // 🔧 修复：使用controller的selectElements方法，确保notifyListeners被调用
    _controller.selectElements(ids);
  }

  /// Send element to back
  void _sendElementToBack() {
    // Use controller directly without setState since it will notify listeners
    PracticeEditUtils.sendElementToBack(_controller);
    // Only trigger a rebuild if we're not in a drag operation
    if (_canvasKey.currentState == null ||
        !_canvasKey.currentState!.context.mounted) {
      setState(() {});
    }
  }

  /// Set up the reference to the canvas in the controller
  void _setupCanvasReference() {
    // Canvas will register itself with the controller in its initState
    AppLogger.debug(
      '画布引用将由画布组件自身设置',
      tag: 'PracticeEdit',
    );
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
          // Check if drag operation is active to avoid setState during dragging
          final isDragging = _canvasKey.currentState != null &&
              _canvasKey.currentState!.context.mounted;

          // Always update the ValueNotifier (doesn't trigger rebuild)
          _clipboardNotifier.value = hasContent;

          // Update local variable too for backward compatibility
          _clipboardHasContent = hasContent;

          // Only use setState if we're not in a drag operation
          if (!isDragging && mounted) {
            setState(() {
              // Empty setState to trigger rebuild - local variable already updated
            });
          }
        }
      } catch (e) {
        AppLogger.error(
          '剪贴板监控错误',
          tag: 'PracticeEdit',
          error: e,
        );
      }
    });
  }

  /// 🆕 根据页面数量自动决定是否显示页面缩略图栏
  /// 多页字帖显示，单页字帖隐藏
  void _updateThumbnailVisibilityBasedOnPageCount() {
    if (!mounted) return;

    final pageCount = _controller.state.pages.length;
    final shouldShowThumbnails = pageCount > 1;

    // 只有当状态真正改变时才更新UI
    if (_showThumbnails != shouldShowThumbnails) {
      setState(() {
        _showThumbnails = shouldShowThumbnails;
      });

      EditPageLogger.editPageInfo(
        '根据页面数量自动更新缩略图显示状态',
        data: {
          'pageCount': pageCount,
          'shouldShowThumbnails': shouldShowThumbnails,
          'previousState': _showThumbnails,
          'operation': 'auto_update_thumbnail_visibility',
        },
      );

      AppLogger.info(
        '缩略图显示状态已自动更新',
        tag: 'PracticeEdit',
        data: {
          'pageCount': pageCount,
          'isMultiPage': pageCount > 1,
          'thumbnailsVisible': shouldShowThumbnails,
        },
      );
    }
  }

  /// Synchronize local _currentTool with controller's state.currentTool
  void _syncToolState() {
    // 🔧 修复：确保所有状态更新都在下一帧执行，避免在构建期间修改状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // 只更新本地变量，不触发页面重建
      // 工具状态变化的UI更新应该通过智能状态分发器和局部组件处理
      final controllerTool = _controller.state.currentTool;
      if (_currentTool != controllerTool) {
        _currentTool = controllerTool;
      }

      // 🆕 检测页面切换并更新剪贴板状态
      final currentPageIndex = _controller.state.currentPageIndex;

      if (_lastPageIndex != currentPageIndex) {
        final oldPageIndex = _lastPageIndex;
        _lastPageIndex = currentPageIndex;

        AppLogger.debug(
          '检测到页面切换，立即更新剪贴板状态',
          tag: 'PracticeEdit',
          data: {
            'oldPageIndex': oldPageIndex,
            'newPageIndex': currentPageIndex,
          },
        );

        // 在下一帧异步执行剪贴板状态更新
        _updateClipboardStateAfterPageSwitch(currentPageIndex);
      }

      // 🆕 检测页面数量变化并更新缩略图显示状态
      // 这用于处理通过其他方式（如撤销/重做）改变页面数量的情况
      _updateThumbnailVisibilityBasedOnPageCount();
    });
  }

  /// 页面切换后更新剪贴板状态
  void _updateClipboardStateAfterPageSwitch(int pageIndex) async {
    if (!mounted) return;

    try {
      final hasContent = await _checkClipboardContent();

      AppLogger.debug(
        '页面切换剪贴板检查结果',
        tag: 'PracticeEdit',
        data: {
          'hasContent': hasContent,
          'oldState': _clipboardHasContent,
          'pageIndex': pageIndex,
          'clipboardElement':
              _clipboardElement != null ? _clipboardElement!['type'] : 'null',
        },
      );

      if (mounted) {
        // 强制更新状态，无论是否有变化
        _clipboardHasContent = hasContent;
        _clipboardNotifier.value = hasContent;

        AppLogger.info(
          '页面切换后强制更新剪贴板状态',
          tag: 'PracticeEdit',
          data: {
            'hasContent': hasContent,
            'pageIndex': pageIndex,
            'forceUpdate': true,
            'notifierValue': _clipboardNotifier.value,
          },
        );

        // 安全地使用setState更新UI
        setState(() {});
      }
    } catch (e) {
      AppLogger.error(
        '页面切换时检查剪贴板状态失败',
        tag: 'PracticeEdit',
        error: e,
      );
    }
  }

  /// 切换对齐模式 (三态切换)
  void _toggleAlignmentMode() {
    // 只使用controller中的方法进行三态切换，避免重复调用
    _controller.toggleAlignmentMode();

    EditPageLogger.editPageInfo('对齐模式切换', data: {
      'alignmentMode': _controller.state.alignmentMode.name,
      'snapEnabled': _controller.state.snapEnabled,
      'gridSize': _controller.state.gridSize,
      'snapThreshold': _controller.state.snapThreshold,
      'operation': 'toggle_alignment_mode',
    });

    // 强制更新UI
    setState(() {});
  }

  /// Toggle grid visibility
  void _toggleGrid() {
    final oldValue = _controller.state.gridVisible;
    _controller.state.gridVisible = !_controller.state.gridVisible;

    debugPrint('🎨 网格显示切换: $oldValue → ${_controller.state.gridVisible}');
    debugPrint('🎨 网格大小: ${_controller.state.gridSize}');
    debugPrint(
        '🎨 当前页面: ${_controller.state.currentPage != null ? "存在" : "null"}');

    // 🔧 触发网格设置变化事件，确保staticBackground层更新
    debugPrint('🎨 调用 triggerGridSettingsChange()');
    _controller.triggerGridSettingsChange();

    // 强制重建UI
    debugPrint('🎨 调用 setState() 强制重建UI');
    setState(() {});

    debugPrint('🎨 网格切换完成');
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

  /// Toggle snap to grid (兼容性方法，逐步过渡到新的对齐模式)
  void _toggleSnap() {
    final oldValue = _controller.state.snapEnabled;
    _controller.state.snapEnabled = !_controller.state.snapEnabled;

    // 同步新的对齐模式
    if (_controller.state.snapEnabled) {
      _controller.state.alignmentMode = AlignmentMode.gridSnap;
    } else {
      _controller.state.alignmentMode = AlignmentMode.none;
    }

    // 🔧 触发网格设置变化事件，确保状态同步
    _controller.triggerGridSettingsChange();

    EditPageLogger.editPageInfo(
      '网格吸附切换',
      data: {
        'oldValue': oldValue,
        'newValue': _controller.state.snapEnabled,
        'alignmentMode': _controller.state.alignmentMode.name,
        'operation': 'toggle_snap',
      },
    );

    // 强制更新UI
    setState(() {});
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
        AppLogger.info(
          '解组选中元素',
          tag: 'PracticeEdit',
          data: {
            'groupId': id,
            'groupType': element['type'],
          },
        );
        // Use the safe ungroup method to prevent ID conflicts
        PracticeEditUtils.safeUngroupSelectedElement(_controller);
      }
    }
  }

  /// ✅ 注销属性面板的智能状态监听器
  void _unregisterPropertyPanelFromIntelligentDispatcher() {
    final intelligentDispatcher = _controller.intelligentDispatcher;
    if (intelligentDispatcher != null && _propertyPanelListener != null) {
      try {
        // 使用正确的方法名及已保存的回调引用
        intelligentDispatcher.removeUIListener(
            'property_panel', _propertyPanelListener!);
        _propertyPanelListener = null;

        EditPageLogger.editPageDebug(
          '属性面板已从智能状态分发器注销',
          data: {
            'operation': 'cleanup_property_panel_listeners',
          },
        );
      } catch (e) {
        // 添加错误处理，防止应用崩溃
        EditPageLogger.editPageError(
          '属性面板注销失败',
          error: e,
          data: {
            'operation': 'cleanup_property_panel_listeners_failed',
          },
        );
      }
    }
  }

  /// 🔥 直接执行图像二值化处理
  Future<void> _executeDirectImageBinarization(
      String elementId, Map<String, dynamic> content) async {
    try {
      final imageUrl = content['imageUrl'] as String?;
      if (imageUrl == null || imageUrl.isEmpty) {
        AppLogger.warning('图像URL为空，无法执行二值化处理', tag: 'PracticeEdit');
        return;
      }

      // 获取图像处理器
      final imageProcessor = ref.read(imageProcessorProvider);

      // 获取二值化参数
      final threshold =
          (content['binaryThreshold'] as num?)?.toDouble() ?? 128.0;
      final isNoiseReductionEnabled =
          content['isNoiseReductionEnabled'] as bool? ?? false;
      final noiseReductionLevel =
          (content['noiseReductionLevel'] as num?)?.toDouble() ?? 3.0;

      AppLogger.info(
        '开始直接二值化处理',
        tag: 'PracticeEdit',
        data: {
          'elementId': elementId,
          'imageUrl': imageUrl,
          'threshold': threshold,
          'noiseReduction': isNoiseReductionEnabled,
          'noiseLevel': noiseReductionLevel,
        },
      );

      // 加载原始图像
      Uint8List? imageData;
      if (imageUrl.startsWith('file://')) {
        final filePath = imageUrl.substring(7);
        final file = File(filePath);
        if (await file.exists()) {
          imageData = await file.readAsBytes();
        }
      } else {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          imageData = response.bodyBytes;
        }
      }

      if (imageData == null) {
        AppLogger.error('无法加载图像数据', tag: 'PracticeEdit');
        return;
      }

      // 解码图像
      final img.Image? sourceImage = img.decodeImage(imageData);
      if (sourceImage == null) {
        AppLogger.error('无法解码图像', tag: 'PracticeEdit');
        return;
      }

      AppLogger.info(
        '成功加载图像，开始二值化处理',
        tag: 'PracticeEdit',
        data: {
          'imageSize': '${sourceImage.width}x${sourceImage.height}',
          'threshold': threshold,
        },
      );

      // 执行二值化处理
      img.Image processedImage = sourceImage;

      // 降噪处理（如果启用）
      if (isNoiseReductionEnabled && noiseReductionLevel > 0) {
        processedImage =
            imageProcessor.denoiseImage(processedImage, noiseReductionLevel);
      }

      // 二值化处理
      processedImage =
          imageProcessor.binarizeImage(processedImage, threshold, false);

      // 编码为PNG
      final binarizedImageData =
          Uint8List.fromList(img.encodePng(processedImage));

      AppLogger.info(
        '二值化处理完成',
        tag: 'PracticeEdit',
        data: {
          'elementId': elementId,
          'resultSize': '${processedImage.width}x${processedImage.height}',
          'dataSize': binarizedImageData.length,
        },
      );

      // 更新元素content
      setState(() {
        content['binarizedImageData'] = binarizedImageData;
        _controller.state.hasUnsavedChanges = true;
      });

      AppLogger.info('二值化数据已更新到元素', tag: 'PracticeEdit');
    } catch (e, stackTrace) {
      AppLogger.error(
        '直接二值化处理失败',
        tag: 'PracticeEdit',
        error: e,
        stackTrace: stackTrace,
        data: {'elementId': elementId},
      );
    }
  }
}
