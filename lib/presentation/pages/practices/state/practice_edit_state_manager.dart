import 'dart:async';

import 'package:flutter/material.dart';

import '../../../widgets/practice/practice_edit_controller.dart';
import '../utils/practice_edit_utils.dart';

/// 字帖编辑页面状态管理器
/// 负责管理UI状态、工具状态、剪贴板状态等
class PracticeEditStateManager extends ChangeNotifier {
  // UI状态管理
  bool _isLeftPanelOpen = false;
  bool _isRightPanelOpen = true;
  bool _showThumbnails = false;
  bool _isPreviewMode = false;

  // 工具状态
  String _currentTool = '';
  bool _isFormatBrushActive = false;
  Map<String, dynamic>? _formatBrushStyles;

  // 剪贴板状态
  Map<String, dynamic>? _clipboardElement;
  bool _clipboardHasContent = false;
  Timer? _clipboardMonitoringTimer;

  // 变换控制器
  final TransformationController _transformationController =
      TransformationController();
  // Canvas焦点节点
  final FocusNode _focusNode = FocusNode();

  // Canvas键（用于截图等功能）
  final GlobalKey _canvasKey = GlobalKey();

  /// 构造函数
  PracticeEditStateManager() {
    _startClipboardMonitoring();
  }

  // === Getters ===

  /// Canvas键
  GlobalKey get canvasKey => _canvasKey;

  /// 剪贴板元素
  Map<String, dynamic>? get clipboardElement => _clipboardElement;

  /// 剪贴板是否有内容
  bool get clipboardHasContent => _clipboardHasContent;

  /// 当前工具
  String get currentTool => _currentTool;

  /// 焦点节点
  FocusNode get focusNode => _focusNode;

  /// 格式刷样式
  Map<String, dynamic>? get formatBrushStyles => _formatBrushStyles;

  /// 格式刷是否激活
  bool get isFormatBrushActive => _isFormatBrushActive;

  /// 左侧面板是否打开
  bool get isLeftPanelOpen => _isLeftPanelOpen;

  /// 是否为预览模式
  bool get isPreviewMode => _isPreviewMode;

  /// 右侧面板是否打开
  bool get isRightPanelOpen => _isRightPanelOpen;

  /// 缩略图是否显示
  bool get showThumbnails => _showThumbnails;

  /// 变换控制器
  TransformationController get transformationController =>
      _transformationController;

  // === UI状态操作 ===

  /// 激活格式刷
  void activateFormatBrush() {
    _isFormatBrushActive = true;
    notifyListeners();
  }

  /// 应用格式刷
  void applyFormatBrush(PracticeEditController controller) {
    if (_isFormatBrushActive &&
        _formatBrushStyles != null &&
        controller.state.selectedElementIds.isNotEmpty) {
      for (final elementId in controller.state.selectedElementIds) {
        controller.updateElementProperties(elementId, _formatBrushStyles!);
      }

      // 清除格式刷状态
      clearFormatBrush();
    }
  }

  /// 将元素移到前台的包装方法
  void bringElementToFront(PracticeEditController controller) {
    PracticeEditUtils.bringElementToFront(controller);
  }

  /// 清空剪贴板
  void clearClipboard() {
    _clipboardElement = null;
    _clipboardHasContent = false;
    notifyListeners();
  }

  /// 清除格式刷状态
  void clearFormatBrush() {
    _isFormatBrushActive = false;
    _formatBrushStyles = null;
    notifyListeners();
  }

  /// 复制元素到剪贴板
  void copyElement(Map<String, dynamic> element) {
    _clipboardElement = Map<String, dynamic>.from(element);
    _clipboardHasContent = true;
    notifyListeners();
  }

  /// 复制格式刷样式
  void copyFormatBrushStyles(Map<String, dynamic> element) {
    _formatBrushStyles = Map<String, dynamic>.from(element);
    notifyListeners();
  }

  /// 复制格式刷
  void copyFormatting(PracticeEditController controller) {
    if (controller.state.selectedElementIds.isNotEmpty) {
      final selectedElement = controller.state
          .getElementById(controller.state.selectedElementIds.first);
      if (selectedElement != null) {
        // 提取格式样式
        _formatBrushStyles = _extractElementStyles(selectedElement);
        _isFormatBrushActive = true;
        notifyListeners();
      }
    }
  }

  // === 工具状态操作 ===

  /// 复制选中的元素
  void copySelectedElements(PracticeEditController controller) {
    final selectedIds = controller.state.selectedElementIds;
    if (selectedIds.isEmpty) return;

    final elements = selectedIds
        .map((id) => controller.state.getElementById(id))
        .where((element) => element != null)
        .cast<Map<String, dynamic>>()
        .toList();

    if (elements.isNotEmpty) {
      final clipboardData = {
        'type': elements.length == 1 ? 'single' : 'multiple',
        'elements': elements,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      copyElement(clipboardData);
    }
  }

  /// 停用格式刷
  void deactivateFormatBrush() {
    _isFormatBrushActive = false;
    _formatBrushStyles = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // 停止剪贴板监控
    _stopClipboardMonitoring();

    // 释放变换控制器
    _transformationController.dispose();

    // 释放焦点节点
    _focusNode.dispose();

    super.dispose();
  }

  /// 复制选中的元素

  /// 下移元素的包装方法
  void moveElementDown(PracticeEditController controller) {
    PracticeEditUtils.moveElementDown(controller);
  }

  /// 上移元素的包装方法
  void moveElementUp(PracticeEditController controller) {
    PracticeEditUtils.moveElementUp(controller);
  }

  // === 剪贴板操作 ===

  /// 粘贴元素
  void paste(PracticeEditController controller) {
    if (!_clipboardHasContent || _clipboardElement == null) return;

    // 使用工具函数进行粘贴操作
    PracticeEditUtils.pasteElement(controller, _clipboardElement!);
  }

  /// 将元素移到后台的包装方法
  void sendElementToBack(PracticeEditController controller) {
    PracticeEditUtils.sendElementToBack(controller);
  }

  /// 设置剪贴板状态
  void setClipboardHasContent(bool hasContent) {
    if (_clipboardHasContent != hasContent) {
      _clipboardHasContent = hasContent;
      notifyListeners();
    }
  }

  /// 设置当前工具
  void setCurrentTool(String tool) {
    if (_currentTool != tool) {
      _currentTool = tool;
      notifyListeners();
    }
  }

  /// 设置左侧面板状态
  void setLeftPanelOpen(bool isOpen) {
    if (_isLeftPanelOpen != isOpen) {
      _isLeftPanelOpen = isOpen;
      notifyListeners();
    }
  }

  /// 设置预览模式
  void setPreviewMode(bool isPreview) {
    if (_isPreviewMode != isPreview) {
      _isPreviewMode = isPreview;
      notifyListeners();
    }
  }

  /// 设置右侧面板状态
  void setRightPanelOpen(bool isOpen) {
    if (_isRightPanelOpen != isOpen) {
      _isRightPanelOpen = isOpen;
      notifyListeners();
    }
  }

  /// 设置缩略图显示状态
  void setShowThumbnails(bool show) {
    if (_showThumbnails != show) {
      _showThumbnails = show;
      notifyListeners();
    }
  }
  // === 私有方法 ===

  /// 切换格式刷状态
  void toggleFormatBrush() {
    _isFormatBrushActive = !_isFormatBrushActive;
    if (!_isFormatBrushActive) {
      _formatBrushStyles = null;
    }
    notifyListeners();
  }

  /// 切换左侧面板
  void toggleLeftPanel() {
    _isLeftPanelOpen = !_isLeftPanelOpen;
    notifyListeners();
  }

  /// 切换预览模式
  void togglePreviewMode() {
    _isPreviewMode = !_isPreviewMode;
    notifyListeners();
  }

  /// 切换右侧面板
  void toggleRightPanel() {
    _isRightPanelOpen = !_isRightPanelOpen;
    notifyListeners();
  }

  void toggleShowThumbnails() {
    _showThumbnails = !_showThumbnails;
    notifyListeners();
  }

  /// 检查剪贴板内容
  void _checkClipboardContent() {
    // 这里可以检查系统剪贴板是否有可用内容
    // 目前简单地保持当前状态
  }

  /// 提取元素样式
  Map<String, dynamic> _extractElementStyles(Map<String, dynamic> element) {
    final styles = <String, dynamic>{};

    // 提取常见样式属性
    final styleProperties = [
      'fontSize',
      'fontFamily',
      'fontWeight',
      'color',
      'backgroundColor',
      'borderColor',
      'borderWidth',
      'borderRadius',
      'opacity',
      'rotation'
    ];

    for (final property in styleProperties) {
      if (element.containsKey(property)) {
        styles[property] = element[property];
      }
    }

    return styles;
  }

  /// 开始剪贴板监控
  void _startClipboardMonitoring() {
    _clipboardMonitoringTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkClipboardContent(),
    );
  }

  /// 停止剪贴板监控
  void _stopClipboardMonitoring() {
    _clipboardMonitoringTimer?.cancel();
    _clipboardMonitoringTimer = null;
  }
}
