import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../../application/services/practice/practice_service.dart';
import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'canvas_capture.dart';
import 'intelligent_notification_mixin.dart';
import 'practice_edit_state.dart';
import 'thumbnail_generator.dart';

/// 文件操作混入类 - 负责文件的保存和加载
mixin FileOperationsMixin on ChangeNotifier implements IntelligentNotificationMixin {
  PracticeEditState get state;
  PracticeService get practiceService;
  
  String? get practiceId;
  String? get practiceTitle;
  
  set practiceId(String? value);
  set practiceTitle(String? value);
  
  GlobalKey? get canvasKey;
  Function(bool)? get previewModeCallback;
  
  void checkDisposed();
  Future<Uint8List?> captureFromRepaintBoundary(GlobalKey key);

  /// 检查标题是否已存在
  Future<bool> checkTitleExists(String title) async {
    if (practiceTitle == title) {
      return false;
    }

    try {
      return await practiceService.isTitleExists(title, excludeId: practiceId);
    } catch (e) {
      debugPrint('检查标题是否存在时出错: $e');
      return false;
    }
  }

  /// 加载字帖
  Future<bool> loadPractice(String id) async {
    try {
      final practice = await practiceService.loadPractice(id);
      if (practice == null) return false;

      practiceId = practice['id'] as String;
      practiceTitle = practice['title'] as String;
      state.pages = List<Map<String, dynamic>>.from(practice['pages'] as List);

      if (state.pages.isNotEmpty) {
        state.currentPageIndex = 0;
      } else {
        state.currentPageIndex = -1;
      }

      state.selectedElementIds.clear();
      state.selectedElement = null;
      state.selectedLayerId = null;

      state.markSaved();
      
      // 🚀 使用智能通知替代 notifyListeners
      intelligentNotify(
        changeType: 'file_load',
        operation: 'loadPractice',
        eventData: {
          'practiceId': practiceId,
          'practiceTitle': practiceTitle,
          'pageCount': state.pages.length,
          'currentPageIndex': state.currentPageIndex,
          'timestamp': DateTime.now().toIso8601String(),
        },
        affectedUIComponents: ['page_list', 'canvas', 'property_panel', 'toolbar'],
        affectedLayers: ['content', 'interaction'], // 文件加载影响内容和交互层
      );

      EditPageLogger.fileOpsInfo(
        '文件加载成功',
        data: {
          'practiceId': practiceId,
          'practiceTitle': practiceTitle,
          'pageCount': state.pages.length,
        },
      );

      return true;
    } catch (e) {
      debugPrint('加载字帖失败: $e');
      return false;
    }
  }

  /// 保存字帖
  Future<dynamic> savePractice({String? title, bool forceOverwrite = false}) async {
    checkDisposed();
    if (state.pages.isEmpty) return false;

    if (title == null && practiceId == null) {
      return false;
    }

    final saveTitle = title ?? practiceTitle;
    if (saveTitle == null || saveTitle.isEmpty) {
      return false;
    }

    if (!forceOverwrite && title != null && title != practiceTitle) {
      final exists = await checkTitleExists(title);
      if (exists) {
        return 'title_exists';
      }
    }

    try {
      debugPrint('开始保存字帖: $saveTitle, ID: $practiceId');

      final thumbnail = await _generateThumbnail();
      debugPrint('缩略图生成完成: ${thumbnail != null ? '${thumbnail.length} 字节' : '无缩略图'}');

      final pagesToSave = state.pages.map((page) {
        final pageCopy = Map<String, dynamic>.from(page);

        if (page.containsKey('elements')) {
          final elements = page['elements'] as List<dynamic>;
          pageCopy['elements'] = elements.map((e) => Map<String, dynamic>.from(e)).toList();
        }

        if (page.containsKey('layers')) {
          final layers = page['layers'] as List<dynamic>;
          pageCopy['layers'] = layers.map((l) => Map<String, dynamic>.from(l)).toList();
        }

        return pageCopy;
      }).toList();

      final result = await practiceService.savePractice(
        id: practiceId,
        title: saveTitle,
        pages: pagesToSave,
        thumbnail: thumbnail,
      );

      practiceId = result.id;
      practiceTitle = saveTitle;

      state.markSaved();
      
      // 🚀 使用智能通知替代 notifyListeners
      intelligentNotify(
        changeType: 'file_save',
        operation: 'savePractice',
        eventData: {
          'practiceId': practiceId,
          'practiceTitle': saveTitle,
          'pageCount': state.pages.length,
          'hasThumbnail': thumbnail != null,
          'timestamp': DateTime.now().toIso8601String(),
        },
        affectedUIComponents: ['title_bar', 'status_bar', 'file_menu'],
        affectedLayers: ['interaction'], // 文件保存主要影响交互层
      );

      EditPageLogger.fileOpsInfo(
        '文件保存成功',
        data: {
          'practiceId': practiceId,
          'practiceTitle': saveTitle,
          'pageCount': state.pages.length,
        },
      );

      debugPrint('字帖保存成功: $saveTitle, ID: $practiceId');
      return true;
    } catch (e) {
      debugPrint('保存字帖失败: $e');
      return false;
    }
  }

  /// 另存为新字帖
  Future<dynamic> saveAsNewPractice(String title, {bool forceOverwrite = false}) async {
    checkDisposed();
    if (state.pages.isEmpty) return false;

    if (title.isEmpty) {
      return false;
    }

    if (!forceOverwrite) {
      final exists = await checkTitleExists(title);
      if (exists) {
        return 'title_exists';
      }
    }

    try {
      debugPrint('开始另存为新字帖: $title');

      final thumbnail = await _generateThumbnail();
      debugPrint('缩略图生成完成: ${thumbnail != null ? '${thumbnail.length} 字节' : '无缩略图'}');

      final pagesToSave = state.pages.map((page) {
        final pageCopy = Map<String, dynamic>.from(page);

        if (page.containsKey('elements')) {
          final elements = page['elements'] as List<dynamic>;
          pageCopy['elements'] = elements.map((e) => Map<String, dynamic>.from(e)).toList();
        }

        if (page.containsKey('layers')) {
          final layers = page['layers'] as List<dynamic>;
          pageCopy['layers'] = layers.map((l) => Map<String, dynamic>.from(l)).toList();
        }

        return pageCopy;
      }).toList();

      final result = await practiceService.savePractice(
        id: null, // 生成新ID
        title: title,
        pages: pagesToSave,
        thumbnail: thumbnail,
      );

      practiceId = result.id;
      practiceTitle = title;

      state.markSaved();
      
      // 🚀 使用智能通知替代 notifyListeners
      intelligentNotify(
        changeType: 'file_save_as',
        operation: 'saveAsNewPractice',
        eventData: {
          'practiceId': practiceId,
          'practiceTitle': title,
          'pageCount': state.pages.length,
          'hasThumbnail': thumbnail != null,
          'timestamp': DateTime.now().toIso8601String(),
        },
        affectedUIComponents: ['title_bar', 'status_bar', 'file_menu'],
        affectedLayers: ['interaction'], // 另存为主要影响交互层
      );

      EditPageLogger.fileOpsInfo(
        '文件另存为成功',
        data: {
          'practiceId': practiceId,
          'practiceTitle': title,
          'pageCount': state.pages.length,
        },
      );

      debugPrint('字帖另存为成功: $title, ID: $practiceId');
      return true;
    } catch (e) {
      debugPrint('另存为字帖失败: $e');
      return false;
    }
  }

  /// 更新字帖标题
  void updatePracticeTitle(String newTitle) {
    if (practiceTitle != newTitle) {
      final oldTitle = practiceTitle;
      practiceTitle = newTitle;
      state.markUnsaved();
      
      // 🚀 使用智能通知替代 notifyListeners
      intelligentNotify(
        changeType: 'file_title_update',
        operation: 'updatePracticeTitle',
        eventData: {
          'oldTitle': oldTitle,
          'newTitle': newTitle,
          'practiceId': practiceId,
          'timestamp': DateTime.now().toIso8601String(),
        },
        affectedUIComponents: ['title_bar', 'status_bar'],
        affectedLayers: ['interaction'], // 标题更新主要影响交互层
      );

      EditPageLogger.fileOpsInfo(
        '文件标题更新',
        data: {
          'oldTitle': oldTitle,
          'newTitle': newTitle,
          'practiceId': practiceId,
        },
      );
    }
  }

  /// 生成字帖缩略图
  Future<Uint8List?> _generateThumbnail() async {
    checkDisposed();

    if (state.pages.isEmpty) {
      return null;
    }

    try {
      final firstPage = state.pages.first;

      const thumbWidth = 300.0;
      const thumbHeight = 400.0;

      bool wasInPreviewMode = false;
      if (previewModeCallback != null) {
        wasInPreviewMode = false;
        previewModeCallback!(true);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      Uint8List? thumbnail;
      if (canvasKey != null) {
        thumbnail = await captureFromRepaintBoundary(canvasKey!);
      }

      if (previewModeCallback != null && !wasInPreviewMode) {
        previewModeCallback!(false);
      }

      if (thumbnail != null) {
        return thumbnail;
      }

      thumbnail = await CanvasCapture.capturePracticePage(
        firstPage,
        width: thumbWidth,
        height: thumbHeight,
      );

      if (thumbnail != null) {
        return thumbnail;
      }

      final fallbackThumbnail = await ThumbnailGenerator.generateThumbnail(
        firstPage,
        width: thumbWidth,
        height: thumbHeight,
        title: practiceTitle,
      );

      return fallbackThumbnail;
    } catch (e) {
      debugPrint('生成缩略图失败: $e');
      return null;
    }
  }
} 