import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'practice_edit_state.dart';
import 'undo_operations.dart';
import 'undo_redo_manager.dart';

/// 页面管理功能 Mixin
mixin PageManagementMixin on ChangeNotifier {
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
        'spacing': 20.0,
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

    undoRedoManager.addOperation(operation);
    markUnsaved();
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
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
      notifyListeners();
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
        notifyListeners();
      },
    );

    undoRedoManager.addOperation(operation);
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
      state.currentPageIndex = index;
      // 清除选择
      state.selectedElementIds.clear();
      state.selectedElement = null;
      notifyListeners();
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
      notifyListeners();
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
      
      EditPageLogger.controllerDebug('页面属性更新完成，触发通知');
      notifyListeners();
    } else {
      EditPageLogger.controllerWarning('页面索引无效，跳过更新');
    }
  }
}
