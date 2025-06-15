import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'intelligent_notification_mixin.dart';
import 'practice_edit_state.dart';
import 'undo_operations.dart';
import 'undo_redo_manager.dart';

/// 页面管理功能 Mixin
mixin PageManagementMixin on ChangeNotifier implements IntelligentNotificationMixin {
  // 抽象接口
  PracticeEditState get state;
  UndoRedoManager get undoRedoManager;
  Uuid get uuid;

  /// 添加新页面
  void addNewPage() {
    checkDisposed();
    final newPage = {
      'id': 'page_${uuid.v4()}',
      'name': '页面 ${state.pages.length + 1}',
      'width': 210.0,
      'height': 297.0,
      'backgroundType': 'color',
      'backgroundColor': '#FFFFFF',
      'backgroundImage': null,
      'elements': <Map<String, dynamic>>[],
      'gridSettings': {
        'enabled': false,
        'spacing': 50.0,
        'color': '#E0E0E0',
        'opacity': 0.5,
      },
      'rulers': {
        'enabled': false,
        'color': '#2196F3',
        'opacity': 0.8,
      },
    };

    final operation = AddPageOperation(
      page: newPage,
      addPage: (page) {
        state.pages.add(page);
        state.currentPageIndex = state.pages.length - 1;
      },
      removePage: (pageId) {
        final index = state.pages.indexWhere((p) => p['id'] == pageId);
        if (index >= 0) {
          state.pages.removeAt(index);
          if (state.currentPageIndex >= state.pages.length) {
            state.currentPageIndex = state.pages.length - 1;
          }
          if (state.currentPageIndex < 0 && state.pages.isNotEmpty) {
            state.currentPageIndex = 0;
          }
        }
      },
    );

    // 添加操作到撤销历史，但立即执行以确保UI更新
    undoRedoManager.addOperation(operation, executeImmediately: true);
    markUnsaved();
    
    // 🚀 使用智能状态分发器通知页面添加
    intelligentNotify(
      changeType: 'page_add',
      eventData: {
        'pageId': newPage['id'],
        'pageName': newPage['name'],
        'pageIndex': state.pages.length - 1,
        'totalPages': state.pages.length,
        'operation': 'add_new_page',
      },
      operation: 'add_new_page',
      affectedLayers: ['background', 'content'],
      affectedUIComponents: ['page_panel', 'toolbar', 'property_panel'],
    );
  }

  /// 添加页面
  void addPage(Map<String, dynamic> page) {
    checkDisposed();
    final operation = AddPageOperation(
      page: page,
      addPage: (p) {
        state.pages.add(p);
      },
      removePage: (pageId) {
        state.pages.removeWhere((p) => p['id'] == pageId);
      },
    );

    undoRedoManager.addOperation(operation);
    markUnsaved();
    
    // 🚀 使用智能状态分发器通知页面添加
    intelligentNotify(
      changeType: 'page_add',
      eventData: {
        'pageId': page['id'],
        'pageName': page['name'],
        'pageIndex': state.pages.length - 1,
        'totalPages': state.pages.length,
        'operation': 'add_page',
      },
      operation: 'add_page',
      affectedLayers: ['background', 'content'],
      affectedUIComponents: ['page_panel', 'toolbar', 'property_panel'],
    );
  }

  void checkDisposed();

  /// 删除页面
  void deletePage(int index) {
    checkDisposed();
    if (index < 0 || index >= state.pages.length || state.pages.length <= 1) {
      return; // 不能删除最后一个页面
    }

    final deletedPage = state.pages[index];
    bool wasCurrentPage = state.currentPageIndex == index;

    final operation = DeletePageOperation(
      page: deletedPage,
      pageIndex: index,
      wasCurrentPage: wasCurrentPage,
      oldCurrentPageIndex: state.currentPageIndex,
      addPage: (page, idx) {
        state.pages.insert(idx, page);
      },
      removePage: (idx) {
        state.pages.removeAt(idx);
        if (state.currentPageIndex >= state.pages.length) {
          state.currentPageIndex = state.pages.length - 1;
        }
        if (state.currentPageIndex < 0 && state.pages.isNotEmpty) {
          state.currentPageIndex = 0;
        }
      },
      setCurrentPageIndex: (idx) {
        state.currentPageIndex = idx;
      },
    );

    undoRedoManager.addOperation(operation);
    markUnsaved();
    
    // 🚀 使用智能状态分发器通知页面删除
    intelligentNotify(
      changeType: 'page_delete',
      eventData: {
        'pageId': deletedPage['id'],
        'pageName': deletedPage['name'],
        'pageIndex': index,
        'totalPages': state.pages.length,
        'wasCurrentPage': wasCurrentPage,
        'operation': 'delete_page',
      },
      operation: 'delete_page',
      affectedLayers: ['background', 'content'],
      affectedUIComponents: ['page_panel', 'toolbar', 'property_panel'],
    );
  }

  /// 复制页面
  void duplicatePage(int index) {
    checkDisposed();
    if (index < 0 || index >= state.pages.length) return;

    final originalPage = state.pages[index];
    final duplicatedPage = Map<String, dynamic>.from(originalPage);
    duplicatedPage['id'] = 'page_${uuid.v4()}';
    duplicatedPage['name'] = '${originalPage['name']} 副本';

    // 深拷贝元素列表
    final originalElements = originalPage['elements'] as List<dynamic>;
    final duplicatedElements = <Map<String, dynamic>>[];

    for (final element in originalElements) {
      final duplicatedElement =
          Map<String, dynamic>.from(element as Map<String, dynamic>);
      duplicatedElement['id'] = '${duplicatedElement['type']}_${uuid.v4()}';
      duplicatedElements.add(duplicatedElement);
    }

    duplicatedPage['elements'] = duplicatedElements;

    final operation = AddPageOperation(
      page: duplicatedPage,
      addPage: (page) {
        state.pages.insert(index + 1, page);
      },
      removePage: (pageId) {
        state.pages.removeWhere((p) => p['id'] == pageId);
      },
    );

    undoRedoManager.addOperation(operation);
    markUnsaved();
    
    // 🚀 使用智能状态分发器通知页面复制
    intelligentNotify(
      changeType: 'page_duplicate',
      eventData: {
        'originalPageId': originalPage['id'],
        'duplicatedPageId': duplicatedPage['id'],
        'originalPageName': originalPage['name'],
        'duplicatedPageName': duplicatedPage['name'],
        'pageIndex': index + 1,
        'totalPages': state.pages.length,
        'elementsCount': duplicatedElements.length,
        'operation': 'duplicate_page',
      },
      operation: 'duplicate_page',
      affectedLayers: ['background', 'content'],
      affectedUIComponents: ['page_panel', 'toolbar', 'property_panel'],
    );
  }

  void markUnsaved();

  /// 移动页面
  void movePage(int fromIndex, int toIndex) {
    checkDisposed();
    if (fromIndex == toIndex ||
        fromIndex < 0 ||
        fromIndex >= state.pages.length ||
        toIndex < 0 ||
        toIndex >= state.pages.length) {
      return;
    }

    final page = state.pages.removeAt(fromIndex);
    state.pages.insert(toIndex, page);

    // 更新当前页面索引
    if (state.currentPageIndex == fromIndex) {
      state.currentPageIndex = toIndex;
    } else if (fromIndex < state.currentPageIndex &&
        toIndex >= state.currentPageIndex) {
      state.currentPageIndex--;
    } else if (fromIndex > state.currentPageIndex &&
        toIndex <= state.currentPageIndex) {
      state.currentPageIndex++;
    }

    final operation = ReorderPageOperation(
      oldIndex: fromIndex,
      newIndex: toIndex,
      reorderPage: (from, to) {
        final page = state.pages.removeAt(from);
        state.pages.insert(to, page);

        // 更新当前页面索引
        if (state.currentPageIndex == from) {
          state.currentPageIndex = to;
        } else if (from < state.currentPageIndex &&
            to >= state.currentPageIndex) {
          state.currentPageIndex--;
        } else if (from > state.currentPageIndex &&
            to <= state.currentPageIndex) {
          state.currentPageIndex++;
        }
      },
    );

    undoRedoManager.addOperation(operation);
    markUnsaved();
    
    // 🚀 使用智能状态分发器通知页面移动
    intelligentNotify(
      changeType: 'page_reorder',
      eventData: {
        'pageId': page['id'],
        'pageName': page['name'],
        'fromIndex': fromIndex,
        'toIndex': toIndex,
        'totalPages': state.pages.length,
        'operation': 'move_page',
      },
      operation: 'move_page',
      affectedLayers: ['background', 'content'],
      affectedUIComponents: ['page_panel', 'toolbar'],
    );
  }

  /// 重命名页面
  void renamePage(int index, String newName) {
    checkDisposed();
    if (index >= 0 && index < state.pages.length) {
      final oldName = state.pages[index]['name'] as String;

      final operation = UpdatePagePropertyOperation(
        pageIndex: index,
        oldProperties: {'name': oldName},
        newProperties: {'name': newName},
        updatePage: (idx, props) {
          if (idx >= 0 && idx < state.pages.length) {
            props.forEach((key, value) {
              state.pages[idx][key] = value;
            });
          }
        },
      );

      undoRedoManager.addOperation(operation);
      markUnsaved();
      
      // 🚀 使用智能状态分发器通知页面重命名
      intelligentNotify(
        changeType: 'page_update',
        eventData: {
          'pageId': state.pages[index]['id'],
          'pageIndex': index,
          'oldName': oldName,
          'newName': newName,
          'operation': 'rename_page',
        },
        operation: 'rename_page',
        affectedUIComponents: ['page_panel', 'property_panel'],
      );
    }
  }

  /// 重新排序页面
  void reorderPages(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= state.pages.length ||
        newIndex >= state.pages.length) {
      return;
    }

    // 调整索引，处理ReorderableListView的特殊情况
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final operation = ReorderPageOperation(
      oldIndex: oldIndex,
      newIndex: newIndex,
      reorderPage: (oldIndex, newIndex) {
        final page = state.pages.removeAt(oldIndex);
        state.pages.insert(newIndex, page);

        // 更新所有页面的index属性
        for (int i = 0; i < state.pages.length; i++) {
          final page = state.pages[i];
          if (page.containsKey('index')) {
            page['index'] = i;
          }
        }

        // 更新currentPageIndex，如果当前选中页面被移动
        if (state.currentPageIndex == oldIndex) {
          state.currentPageIndex = newIndex;
        } else if (state.currentPageIndex > oldIndex &&
            state.currentPageIndex <= newIndex) {
          state.currentPageIndex--;
        } else if (state.currentPageIndex < oldIndex &&
            state.currentPageIndex >= newIndex) {
          state.currentPageIndex++;
        }

        state.hasUnsavedChanges = true;
        // 注意：这里不直接调用notifyListeners，由外层的intelligentNotify处理
      },
    );

    undoRedoManager.addOperation(operation);
    
    // 🚀 使用智能状态分发器通知页面重排序
    intelligentNotify(
      changeType: 'page_reorder',
      eventData: {
        'oldIndex': oldIndex,
        'newIndex': newIndex,
        'totalPages': state.pages.length,
        'currentPageIndex': state.currentPageIndex,
        'operation': 'reorder_pages',
      },
      operation: 'reorder_pages',
      affectedUIComponents: ['page_panel', 'toolbar'],
    );
  }

  /// 设置页面背景颜色
  void setPageBackgroundColor(String color) {
    updatePageProperties({
      'background': {
        'type': 'color',
        'value': color,
        'opacity': 1.0,
      },
      // 保持向后兼容
      'backgroundType': 'color',
      'backgroundColor': color,
      'backgroundImage': null,
    });
  }

  /// 设置页面背景图片
  void setPageBackgroundImage(String? imageUrl) {
    updatePageProperties({
      'backgroundType': imageUrl != null ? 'image' : 'color',
      'backgroundImage': imageUrl,
    });
  }

  /// 设置页面大小
  void setPageSize(double width, double height) {
    updatePageProperties({
      'width': width,
      'height': height,
    });
  }

  /// 切换到指定页面
  void switchToPage(int index) {
    checkDisposed();
    if (index >= 0 &&
        index < state.pages.length &&
        index != state.currentPageIndex) {
      final oldPageIndex = state.currentPageIndex;
      state.currentPageIndex = index;
      // 清除选择
      state.selectedElementIds.clear();
      state.selectedElement = null;
      
      // 🚀 使用智能状态分发器通知页面切换
      intelligentNotify(
        changeType: 'page_select',
        eventData: {
          'pageId': state.pages[index]['id'],
          'pageName': state.pages[index]['name'],
          'oldPageIndex': oldPageIndex,
          'newPageIndex': index,
          'totalPages': state.pages.length,
          'operation': 'switch_to_page',
        },
        operation: 'switch_to_page',
        affectedLayers: ['background', 'content', 'interaction'],
        affectedUIComponents: ['page_panel', 'toolbar', 'property_panel'],
      );
    }
  }

  /// 更新页面
  void updatePage(int index, Map<String, dynamic> updatedPage) {
    checkDisposed();
    if (index >= 0 && index < state.pages.length) {
      final oldPage = Map<String, dynamic>.from(state.pages[index]);

      final operation = UpdatePagePropertyOperation(
        pageIndex: index,
        oldProperties: oldPage,
        newProperties: updatedPage,
        updatePage: (idx, page) {
          if (idx >= 0 && idx < state.pages.length) {
            state.pages[idx] = page;
          }
        },
      );

      undoRedoManager.addOperation(operation);
      markUnsaved();
      
      // 🚀 使用智能状态分发器通知页面更新
      intelligentNotify(
        changeType: 'page_update',
        eventData: {
          'pageId': updatedPage['id'],
          'pageIndex': index,
          'updatedProperties': updatedPage.keys.toList(),
          'operation': 'update_page',
        },
        operation: 'update_page',
        affectedLayers: ['background', 'content'],
        affectedUIComponents: ['page_panel', 'property_panel'],
      );
    }
  }

  /// 更新页面属性
  void updatePageProperties(Map<String, dynamic> properties) {
    checkDisposed();
    
    EditPageLogger.controllerDebug(
      '开始更新页面属性',
      data: {
        'currentPageIndex': state.currentPageIndex,
        'totalPages': state.pages.length,
        'updateProperties': properties,
      },
    );
    
    if (state.currentPageIndex >= 0 &&
        state.currentPageIndex < state.pages.length) {
      final currentPage = state.pages[state.currentPageIndex];
      final oldProperties = <String, dynamic>{};

      // 保存旧值
      for (final key in properties.keys) {
        if (currentPage.containsKey(key)) {
          oldProperties[key] = currentPage[key];
        }
      }

      EditPageLogger.controllerDebug(
        '保存页面旧属性',
        data: {'oldProperties': oldProperties},
      );

      // 应用新值
      properties.forEach((key, value) {
        currentPage[key] = value;
      });

      EditPageLogger.controllerDebug(
        '页面属性更新完成',
        data: {
          'updatedKeys': properties.keys.toList(),
          'hasBackground': properties.containsKey('background'),
        },
      );

      final operation = UpdatePagePropertyOperation(
        pageIndex: state.currentPageIndex,
        oldProperties: oldProperties,
        newProperties: properties,
        updatePage: (idx, props) {
          if (idx >= 0 && idx < state.pages.length) {
            props.forEach((key, value) {
              state.pages[idx][key] = value;
            });
          }
        },
      );

      undoRedoManager.addOperation(operation);
      markUnsaved();
      
      EditPageLogger.controllerDebug('页面属性更新完成，触发智能通知');
      
      // 🚀 使用智能状态分发器通知页面属性更新
      intelligentNotify(
        changeType: 'page_update',
        eventData: {
          'pageId': currentPage['id'],
          'pageIndex': state.currentPageIndex,
          'updatedProperties': properties.keys.toList(),
          'hasBackground': properties.containsKey('background'),
          'hasSize': properties.containsKey('width') || properties.containsKey('height'),
          'operation': 'update_page_properties',
        },
        operation: 'update_page_properties',
        affectedLayers: properties.containsKey('background') ? ['background'] : ['content'],
        affectedUIComponents: ['property_panel', 'page_panel'],
      );
    } else {
      EditPageLogger.controllerWarning('页面索引无效，跳过更新');
    }
  }
}
