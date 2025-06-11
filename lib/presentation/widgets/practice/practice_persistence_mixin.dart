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
  GlobalKey? get canvasKey;
  // 抽象字段 - 需要在使用此mixin的类中实现
  String? get currentPracticeId;
  set currentPracticeId(String? value);
  String? get currentPracticeTitle;
  set currentPracticeTitle(String? value);

  /// 检查字帖是否已保存过
  bool get isSaved => currentPracticeId != null;

  String? get practiceId;

  PracticeService get practiceService;
  String? get practiceTitle;
  Function(bool)? get previewModeCallback;
  // 抽象接口
  PracticeEditState get state;

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

  void checkDisposed();

  /// 检查标题是否已存在
  Future<bool> checkTitleExists(String title) async {
    // 如果是当前字帖的标题，不算冲突
    if (currentPracticeTitle == title) {
      return false;
    }

    try {
      // 查询是否有相同标题的字帖，排除当前ID
      return await practiceService.isTitleExists(title,
          excludeId: currentPracticeId);
    } catch (e) {
      debugPrint('检查标题是否存在时出错: $e');
      // 发生错误时假设标题不存在
      return false;
    }
  }

  /// 加载字帖
  Future<bool> loadPractice(String id) async {
    try {
      final practice = await practiceService.loadPractice(id);
      if (practice == null) return false;

      // 更新字帖数据
      currentPracticeId = practice['id'] as String;
      currentPracticeTitle = practice['title'] as String;
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
      currentPracticeId = result.id;
      currentPracticeTitle = title;

      // 标记为已保存
      state.markSaved();
      notifyListeners();

      debugPrint('字帖另存为成功: $title, ID: $currentPracticeId');
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
    if (title == null && currentPracticeId == null) {
      return false;
    }

    // 使用当前标题或传入的新标题
    final saveTitle = title ?? currentPracticeTitle;
    if (saveTitle == null || saveTitle.isEmpty) {
      return false;
    }

    // 如果是新标题（非当前标题），检查标题是否存在
    if (!forceOverwrite && title != null && title != currentPracticeTitle) {
      final exists = await checkTitleExists(title);
      if (exists) {
        // 标题已存在，返回特殊值通知调用者需要确认覆盖
        return 'title_exists';
      }
    }

    try {
      debugPrint('开始保存字帖: $saveTitle, ID: $currentPracticeId');

      // 生成缩略图
      final thumbnail = await _generateThumbnail();
      debugPrint(
          '缩略图生成完成: ${thumbnail != null ? '${thumbnail.length} 字节' : '无缩略图'}');

      // 确保页面数据准备好被保存
      final pagesToSave = _preparePageDataForSaving();

      // 保存字帖 - 使用现有ID或创建新ID
      final result = await practiceService.savePractice(
        id: currentPracticeId, // 如果是null，将创建新字帖
        title: saveTitle,
        pages: pagesToSave,
        thumbnail: thumbnail,
      );

      // 更新ID和标题
      currentPracticeId = result.id;
      currentPracticeTitle = saveTitle;

      // 标记为已保存
      state.markSaved();
      notifyListeners();

      debugPrint('字帖保存成功: $saveTitle, ID: $currentPracticeId');
      return true;
    } catch (e) {
      debugPrint('保存字帖失败: $e');
      return false;
    }
  }

  /// 更新字帖标题
  void updatePracticeTitle(String newTitle) {
    if (currentPracticeTitle != newTitle) {
      currentPracticeTitle = newTitle;
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

      // 智能缩略图生成：尝试在当前状态生成，失败则快速切换
      bool wasInPreviewMode = state.isPreviewMode;
      Uint8List? thumbnail;

      // 首先尝试在当前状态下捕获
      if (canvasKey != null) {
        thumbnail = await captureFromRepaintBoundary(canvasKey!);
      }

      // 如果在编辑模式下捕获失败，则快速切换到预览模式
      if (thumbnail == null &&
          !wasInPreviewMode &&
          previewModeCallback != null) {
        previewModeCallback!(true);

        // 更短的等待时间，减少用户感知
        await Future.delayed(const Duration(milliseconds: 50));

        if (canvasKey != null) {
          thumbnail = await captureFromRepaintBoundary(canvasKey!);
        }

        // 立即恢复
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
        title: currentPracticeTitle,
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
