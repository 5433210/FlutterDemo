import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../application/services/practice/practice_service.dart';
import 'canvas_capture.dart';
import 'practice_edit_state.dart';
import 'thumbnail_generator.dart';

/// 字帖持久化管理 Mixin
/// 负责字帖的保存、加载、缩略图生成等功能
mixin PracticePersistenceMixin on ChangeNotifier {
  // 抽象接口
  PracticeEditState get state;
  PracticeService get practiceService;
  GlobalKey? get canvasKey;
  Function(bool)? get previewModeCallback;
  String? get practiceTitle;
  String? get practiceId;
  
  void checkDisposed();

  // 私有字段 - 需要在使用此mixin的类中声明
  String? _practiceId;
  String? _practiceTitle;

  /// 检查字帖是否已保存过
  bool get isSaved => _practiceId != null;

  /// 获取当前字帖ID
  String? get currentPracticeId => _practiceId;

  /// 获取当前字帖标题
  String? get currentPracticeTitle => _practiceTitle;

  /// 检查标题是否已存在
  Future<bool> checkTitleExists(String title) async {
    // 如果是当前字帖的标题，不算冲突
    if (_practiceTitle == title) {
      return false;
    }

    try {
      // 查询是否有相同标题的字帖，排除当前ID
      return await practiceService.isTitleExists(title,
          excludeId: _practiceId);
    } catch (e) {
      debugPrint('检查标题是否存在时出错: $e');
      // 发生错误时假设标题不存在
      return false;
    }
  }

  /// 从 RepaintBoundary 捕获图像
  Future<Uint8List?> captureFromRepaintBoundary(GlobalKey key) async {
    try {
      // 获取 RenderObject 并安全地检查类型
      final renderObject = key.currentContext?.findRenderObject();

      // 如果渲染对象为空或不是 RenderRepaintBoundary 类型，返回空
      if (renderObject == null) {
        debugPrint('无法获取渲染对象');
        return null;
      }

      if (renderObject is! RenderRepaintBoundary) {
        debugPrint(
            '找到的渲染对象不是 RenderRepaintBoundary 类型: ${renderObject.runtimeType}');
        return null;
      }

      final boundary = renderObject;

      // 捕获图像
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }

      debugPrint('无法将图像转换为字节数据');
      return null;
    } catch (e, stack) {
      debugPrint('从 RepaintBoundary 捕获图像失败: $e');
      debugPrint('堆栈跟踪: $stack');
      return null;
    }
  }

  /// 加载字帖
  Future<bool> loadPractice(String id) async {
    try {
      final practice = await practiceService.loadPractice(id);
      if (practice == null) return false;

      // 更新字帖数据
      _practiceId = practice['id'] as String;
      _practiceTitle = practice['title'] as String;
      state.pages = List<Map<String, dynamic>>.from(practice['pages'] as List);

      // 如果有页面，选择第一个页面
      if (state.pages.isNotEmpty) {
        state.currentPageIndex = 0;
      } else {
        state.currentPageIndex = -1;
      }

      // 清除选择
      state.selectedElementIds.clear();
      state.selectedElement = null;
      state.selectedLayerId = null;

      // 标记为已保存
      state.markSaved();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('加载字帖失败: $e');
      return false;
    }
  }

  /// 另存为新字帖
  /// 始终提示用户输入标题
  /// 返回值:
  /// - true: 保存成功
  /// - false: 保存失败
  /// - 'title_exists': 标题已存在，需要确认是否覆盖
  Future<dynamic> saveAsNewPractice(String title,
      {bool forceOverwrite = false}) async {
    checkDisposed();
    // 如果没有页面，则不保存
    if (state.pages.isEmpty) return false;

    if (title.isEmpty) {
      return false;
    }

    // 如果不是强制覆盖，检查标题是否存在
    if (!forceOverwrite) {
      final exists = await checkTitleExists(title);
      if (exists) {
        // 标题已存在，返回特殊值通知调用者需要确认覆盖
        return 'title_exists';
      }
    }

    try {
      debugPrint('开始另存为新字帖: $title');

      // 生成缩略图
      final thumbnail = await _generateThumbnail();
      debugPrint(
          '缩略图生成完成: ${thumbnail != null ? '${thumbnail.length} 字节' : '无缩略图'}');

      // 确保页面数据准备好被保存
      final pagesToSave = _preparePageDataForSaving();

      // 另存为新字帖（不使用现有ID）
      final result = await practiceService.savePractice(
        id: null, // 生成新ID
        title: title,
        pages: pagesToSave,
        thumbnail: thumbnail,
      );

      // 更新ID和标题
      _practiceId = result.id;
      _practiceTitle = title;

      // 标记为已保存
      state.markSaved();
      notifyListeners();

      debugPrint('字帖另存为成功: $title, ID: $_practiceId');
      return true;
    } catch (e) {
      debugPrint('另存为字帖失败: $e');
      return false;
    }
  }

  /// 保存字帖
  /// 如果字帖未保存过，则提示用户输入标题
  /// 返回值:
  /// - true: 保存成功
  /// - false: 保存失败或需要提示用户输入标题
  /// - 'title_exists': 标题已存在，需要确认是否覆盖
  Future<dynamic> savePractice(
      {String? title, bool forceOverwrite = false}) async {
    checkDisposed();
    // 如果没有页面，则不保存
    if (state.pages.isEmpty) return false;

    // 如果未提供标题且从未保存过，返回false表示需要提示用户输入标题
    if (title == null && _practiceId == null) {
      return false;
    }

    // 使用当前标题或传入的新标题
    final saveTitle = title ?? _practiceTitle;
    if (saveTitle == null || saveTitle.isEmpty) {
      return false;
    }

    // 如果是新标题（非当前标题），检查标题是否存在
    if (!forceOverwrite && title != null && title != _practiceTitle) {
      final exists = await checkTitleExists(title);
      if (exists) {
        // 标题已存在，返回特殊值通知调用者需要确认覆盖
        return 'title_exists';
      }
    }

    try {
      debugPrint('开始保存字帖: $saveTitle, ID: $_practiceId');

      // 生成缩略图
      final thumbnail = await _generateThumbnail();
      debugPrint(
          '缩略图生成完成: ${thumbnail != null ? '${thumbnail.length} 字节' : '无缩略图'}');

      // 确保页面数据准备好被保存
      final pagesToSave = _preparePageDataForSaving();

      // 保存字帖 - 使用现有ID或创建新ID
      final result = await practiceService.savePractice(
        id: _practiceId, // 如果是null，将创建新字帖
        title: saveTitle,
        pages: pagesToSave,
        thumbnail: thumbnail,
      );

      // 更新ID和标题
      _practiceId = result.id;
      _practiceTitle = saveTitle;

      // 标记为已保存
      state.markSaved();
      notifyListeners();

      debugPrint('字帖保存成功: $saveTitle, ID: $_practiceId');
      return true;
    } catch (e) {
      debugPrint('保存字帖失败: $e');
      return false;
    }
  }

  /// 更新字帖标题
  void updatePracticeTitle(String newTitle) {
    if (_practiceTitle != newTitle) {
      _practiceTitle = newTitle;
      state.hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  /// 生成字帖缩略图
  Future<Uint8List?> _generateThumbnail() async {
    checkDisposed();

    if (state.pages.isEmpty) {
      return null;
    }

    try {
      // 获取第一页作为缩略图
      final firstPage = state.pages.first;

      // 缩略图尺寸
      const thumbWidth = 300.0;
      const thumbHeight = 400.0;

      // 临时进入预览模式
      bool wasInPreviewMode = false;
      if (previewModeCallback != null) {
        // 假设当前不在预览模式
        wasInPreviewMode = false;

        // 切换到预览模式
        previewModeCallback!(true);

        // 等待一帧，确保 RepaintBoundary 已经渲染
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 如果有画布 GlobalKey，使用 RepaintBoundary 捕获
      Uint8List? thumbnail;
      if (canvasKey != null) {
        thumbnail = await captureFromRepaintBoundary(canvasKey!);
      }

      // 恢复原来的预览模式状态
      if (previewModeCallback != null && !wasInPreviewMode) {
        previewModeCallback!(false);
      }

      // 如果成功捕获了缩略图，直接返回
      if (thumbnail != null) {
        return thumbnail;
      }

      // 使用 CanvasCapture 捕获预览模式下的页面
      thumbnail = await CanvasCapture.capturePracticePage(
        firstPage,
        width: thumbWidth,
        height: thumbHeight,
      );

      if (thumbnail != null) {
        return thumbnail;
      }

      // 如果 CanvasCapture 失败，尝试使用 ThumbnailGenerator 作为备选方案
      final fallbackThumbnail = await ThumbnailGenerator.generateThumbnail(
        firstPage,
        width: thumbWidth,
        height: thumbHeight,
        title: _practiceTitle,
      );

      return fallbackThumbnail;
    } catch (e) {
      debugPrint('生成缩略图失败: $e');
      return null;
    }
  }

  /// 准备页面数据用于保存
  List<Map<String, dynamic>> _preparePageDataForSaving() {
    return state.pages.map((page) {
      // 创建页面的深拷贝
      final pageCopy = Map<String, dynamic>.from(page);

      // 确保元素列表被正确拷贝
      if (page.containsKey('elements')) {
        final elements = page['elements'] as List<dynamic>;
        pageCopy['elements'] =
            elements.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      // 确保图层列表被正确拷贝
      if (page.containsKey('layers')) {
        final layers = page['layers'] as List<dynamic>;
        pageCopy['layers'] =
            layers.map((l) => Map<String, dynamic>.from(l)).toList();
      }

      return pageCopy;
    }).toList();
  }
} 