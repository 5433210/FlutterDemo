import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/practice/page_operations.dart';
import '../../../widgets/practice/practice_edit_controller.dart';
import '../../../widgets/practice/undo_operations.dart';
import '../../../widgets/practice/undo_redo_manager.dart';

/// Utility methods for practice editing
class PracticeEditUtils {
  /// Add a new page
  static void addNewPage(
      PracticeEditController controller, BuildContext context) {
    // 使用 PageOperations 创建新页面
    final newPage = PageOperations.addPage(controller.state.pages, null);

    // 添加默认图层
    if (!newPage.containsKey('layers')) {
      newPage['layers'] = [
        {
          'id': 'layer_${DateTime.now().millisecondsSinceEpoch}',
          'name': AppLocalizations.of(context).practiceEditDefaultLayer,
          'isVisible': true,
          'isLocked': false,
        }
      ];
    }

    // 添加到页面列表
    controller.state.pages.add(newPage);

    // 切换到新页面
    controller.state.currentPageIndex = controller.state.pages.length - 1;

    // 标记有未保存的更改
    controller.state.hasUnsavedChanges = true;
  }

  /// Bring element to front
  static void bringElementToFront(PracticeEditController controller) {
    if (controller.state.selectedElementIds.isEmpty) return;

    final id = controller.state.selectedElementIds.first;
    final elements = controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index >= 0 && index < elements.length - 1) {
      final newIndex = elements.length - 1; // Move to end (top layer)

      // Create undo/redo operation
      final operation = BringElementToFrontOperation(
        elementId: id,
        oldIndex: index,
        newIndex: newIndex,
        reorderElement: controller.reorderElement,
      );

      controller.undoRedoManager.addOperation(operation);
    }
  }

  /// Copy selected elements with image preloading optimization
  static Map<String, dynamic>? copySelectedElements(
      PracticeEditController controller, BuildContext context,
      {dynamic characterImageService}) {
    // 检查是否有选中的元素
    if (controller.state.selectedElementIds.isEmpty) {
      return null;
    }

    final elements = controller.state.currentPageElements;
    final selectedIds = controller.state.selectedElementIds;
    Map<String, dynamic>? clipboardElement;

    // 如果只选中了一个元素，使用原来的逻辑
    if (selectedIds.length == 1) {
      final id = selectedIds.first;
      final element = elements.firstWhere((e) => e['id'] == id,
          orElse: () => <String, dynamic>{});

      if (element.isNotEmpty) {
        // Deep copy element
        clipboardElement = Map<String, dynamic>.from(element);

        // Preload images for the copied element
        if (characterImageService != null) {
          _preloadElementImages([element], characterImageService);
        }

        // Show notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).elementCopied),
            duration: const Duration(seconds: 2),
          ),
        );
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
        clipboardElement = {
          'type': 'multi_elements',
          'elements': selectedElements,
        };

        // Preload images for all copied elements
        if (characterImageService != null) {
          _preloadElementImages(selectedElements, characterImageService);
        }

        // 显示通知
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .elementsCopied(selectedElements.length)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    return clipboardElement;
  }

  /// Enhanced copy selected elements with comprehensive image preloading
  static Future<Map<String, dynamic>?> copySelectedElementsWithPreloading(
      PracticeEditController controller, BuildContext context,
      {dynamic characterImageService, dynamic imageCacheService}) async {
    // Use the regular copy method first
    final clipboardElement = copySelectedElements(controller, context,
        characterImageService: characterImageService);

    if (clipboardElement == null) return null;

    // Perform comprehensive image preloading
    await _performComprehensiveImagePreloading(
        clipboardElement, characterImageService, imageCacheService);

    return clipboardElement;
  }

  /// Creates a complete deep copy of an element and all its nested structures
  static Map<String, dynamic> deepCopyElement(Map<String, dynamic> element) {
    final result = <String, dynamic>{};

    // Copy all top-level properties
    element.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        // Deep copy for nested maps
        result[key] = deepCopyMap(value);
      } else if (value is List) {
        // Deep copy for lists
        result[key] = deepCopyList(value);
      } else {
        // Direct copy for primitive values
        result[key] = value;
      }
    });

    return result;
  }

  /// Helper method to deep copy a list
  static List<dynamic> deepCopyList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return deepCopyMap(item);
      } else if (item is List) {
        return deepCopyList(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// Helper method to deep copy a map
  static Map<String, dynamic> deepCopyMap(Map<String, dynamic> map) {
    final result = <String, dynamic>{};

    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = deepCopyMap(value);
      } else if (value is List) {
        result[key] = deepCopyList(value);
      } else {
        result[key] = value;
      }
    });

    return result;
  }

  /// Delete a page
  static void deletePage(
      PracticeEditController controller, int index, BuildContext context) {
    // 确保至少保留一个页面
    if (controller.state.pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).cannotDeleteOnlyPage)),
      );
      return;
    }

    // 删除页面
    PageOperations.deletePage(controller.state.pages, index);

    // 如果删除的是当前页面，则切换到前一个页面
    if (controller.state.currentPageIndex >= controller.state.pages.length) {
      controller.state.currentPageIndex = controller.state.pages.length - 1;
    }

    // 标记有未保存的更改
    controller.state.hasUnsavedChanges = true;
  }

  /// Generate a random string of specified length
  static String getRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  /// Move element down one layer
  static void moveElementDown(PracticeEditController controller) {
    if (controller.state.selectedElementIds.isEmpty) return;

    final id = controller.state.selectedElementIds.first;
    final elements = controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index > 0) {
      final newIndex = index - 1; // Move down one layer

      // Create undo/redo operation
      final operation = MoveElementDownOperation(
        elementId: id,
        oldIndex: index,
        newIndex: newIndex,
        reorderElement: controller.reorderElement,
      );

      controller.undoRedoManager.addOperation(operation);
    }
  }

  /// Move element up one layer
  static void moveElementUp(PracticeEditController controller) {
    if (controller.state.selectedElementIds.isEmpty) return;

    final id = controller.state.selectedElementIds.first;
    final elements = controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index >= 0 && index < elements.length - 1) {
      final newIndex = index + 1; // Move up one layer

      // Create undo/redo operation
      final operation = MoveElementUpOperation(
        elementId: id,
        oldIndex: index,
        newIndex: newIndex,
        reorderElement: controller.reorderElement,
      );

      controller.undoRedoManager.addOperation(operation);
    }
  }

  /// Paste element(s)
  static void pasteElement(PracticeEditController controller,
      Map<String, dynamic>? clipboardElement) {
    if (clipboardElement == null) return;

    final newElementIds = <String>[];
    final newElements = <Map<String, dynamic>>[];

    // 检查是否是多元素集合
    if (clipboardElement['type'] == 'multi_elements') {
      // 处理多元素粘贴
      final clipboardElements = clipboardElement['elements'] as List<dynamic>;

      // 获取当前时间戳作为基础
      final baseTimestamp = DateTime.now().millisecondsSinceEpoch;

      // 为每个元素添加索引，确保ID唯一性
      int index = 0;
      for (final element in clipboardElements) {
        // 创建新元素ID，添加索引和随机数确保唯一性
        final newId =
            '${element['type']}_${baseTimestamp}_${index}_${getRandomString(4)}';
        index++; // Create a true deep copy of the element with all nested structures
        final elementCopy = deepCopyElement(element as Map<String, dynamic>);

        // 复制元素并修改位置（稍微偏移一点）
        final newElement = {
          ...elementCopy,
          'id': newId,
          'x': (element['x'] as num).toDouble() + 20,
          'y': (element['y'] as num).toDouble() + 20,
        };

        // 特殊处理组元素，需要递归更新所有子元素的ID
        if (newElement['type'] == 'group' &&
            newElement['content'] is Map<String, dynamic> &&
            newElement['content']['children'] is List) {
          // 获取子元素列表
          final children = newElement['content']['children'] as List;
          // 为每个子元素生成新ID
          final updatedChildren = updateChildrenIds(children);
          // 更新组元素的子元素
          newElement['content']['children'] = updatedChildren;
        }

        // 添加到新元素列表
        newElements.add(newElement);
        newElementIds.add(newId);
      }
    } else {
      // 处理单个元素粘贴（原有逻辑）      // 创建新元素ID，添加随机字符串确保唯一性
      final newId =
          '${clipboardElement['type']}_${DateTime.now().millisecondsSinceEpoch}_${getRandomString(4)}'; // Create a true deep copy of the element with all nested structures
      final elementCopy = deepCopyElement(clipboardElement);

      // 复制元素并修改位置（稍微偏移一点）
      final newElement = {
        ...elementCopy,
        'id': newId,
        'x': (clipboardElement['x'] as num).toDouble() + 20,
        'y': (clipboardElement['y'] as num).toDouble() + 20,
      };

      // 特殊处理组元素，需要递归更新所有子元素的ID
      if (newElement['type'] == 'group' &&
          newElement['content'] is Map<String, dynamic> &&
          newElement['content']['children'] is List) {
        // 获取子元素列表
        final children = newElement['content']['children'] as List;
        // 为每个子元素生成新ID
        final updatedChildren = updateChildrenIds(children);
        // 更新组元素的子元素
        newElement['content']['children'] = updatedChildren;
      }

      // 添加到新元素列表
      newElements.add(newElement);
      newElementIds.add(newId);
    }

    // 使用撤销/重做管理器记录粘贴操作
    controller.undoRedoManager.addOperation(
      PasteElementOperation(
        newElements: newElements,
        addElements: (elements) {
          if (controller.state.currentPageIndex >= 0 &&
              controller.state.currentPageIndex <
                  controller.state.pages.length) {
            final page =
                controller.state.pages[controller.state.currentPageIndex];
            final pageElements = page['elements'] as List<dynamic>;
            pageElements.addAll(elements);

            // 选中所有粘贴的元素，而不仅仅是第一个
            controller.state.selectedElementIds =
                List<String>.from(elements.map((e) => e['id'] as String));

            // 如果只有一个元素，设置selectedElement属性
            if (elements.length == 1) {
              controller.state.selectedElement = elements.first;
            } else {
              controller.state.selectedElement = null; // 多选时不显示单个元素的属性
            }

            controller.state.hasUnsavedChanges = true;
            controller.notifyListeners();
          }
        },
        removeElements: (ids) {
          if (controller.state.currentPageIndex >= 0 &&
              controller.state.currentPageIndex <
                  controller.state.pages.length) {
            final page =
                controller.state.pages[controller.state.currentPageIndex];
            final elements = page['elements'] as List<dynamic>;
            elements.removeWhere((e) => ids.contains(e['id']));

            controller.state.selectedElementIds.clear();
            controller.state.selectedElement = null;

            controller.state.hasUnsavedChanges = true;
            controller.notifyListeners();
          }
        },
      ),
    );
  }

  /// Enhanced paste with cache warming
  /// This method performs cache warming before pasting to improve rendering performance
  static Future<void> pasteElementWithCacheWarming(
      PracticeEditController controller, Map<String, dynamic>? clipboardElement,
      {dynamic characterImageService, dynamic imageCacheService}) async {
    if (clipboardElement == null) return;

    try {
      EditPageLogger.editPageDebug('开始粘贴操作并预热缓存');

      // First, warm up caches by preloading images for elements that will be pasted
      await _warmCacheForPasteOperation(
          clipboardElement, characterImageService, imageCacheService);

      // Then proceed with the normal paste operation
      pasteElement(controller, clipboardElement);

      EditPageLogger.editPageDebug('粘贴操作和缓存预热完成');
    } catch (e) {
      EditPageLogger.editPageError('粘贴操作缓存预热错误', error: e);
      // Fallback to regular paste if cache warming fails
      pasteElement(controller, clipboardElement);
    }
  }

  /// Preload all collection element images
  static void preloadAllCollectionImages(
      PracticeEditController controller, dynamic characterImageService) {
    // Get current page elements
    final elements = controller.state.currentPageElements;

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
  static void reorderPages(
      PracticeEditController controller, int oldIndex, int newIndex) {
    // 处理 ReorderableListView 的特殊情况
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // 移动页面
    final page = controller.state.pages.removeAt(oldIndex);
    controller.state.pages.insert(newIndex, page);

    // 更新页面索引和名称
    for (int i = 0; i < controller.state.pages.length; i++) {
      controller.state.pages[i]['index'] = i;
      controller.state.pages[i]['name'] = '页面 ${i + 1}';
    }

    // 如果重新排序的是当前页面，更新当前页面索引
    if (oldIndex == controller.state.currentPageIndex) {
      controller.state.currentPageIndex = newIndex;
    } else if (oldIndex < controller.state.currentPageIndex &&
        newIndex >= controller.state.currentPageIndex) {
      controller.state.currentPageIndex--;
    } else if (oldIndex > controller.state.currentPageIndex &&
        newIndex <= controller.state.currentPageIndex) {
      controller.state.currentPageIndex++;
    }

    // 标记有未保存的更改
    controller.state.hasUnsavedChanges = true;
  }

  /// Ungroup the selected group element safely, ensuring all IDs are unique
  static void safeUngroupSelectedElement(PracticeEditController controller) {
    if (controller.state.selectedElementIds.length != 1) {
      return;
    }

    // Check if the selected element is a group
    if (controller.state.selectedElement == null ||
        controller.state.selectedElement!['type'] != 'group') {
      return;
    }

    final groupElement =
        Map<String, dynamic>.from(controller.state.selectedElement!);
    final content = groupElement['content'] as Map<String, dynamic>;
    final children = content['children'] as List<dynamic>;

    if (children.isEmpty) return;

    // Generate unique IDs for all children to prevent conflicts
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // 转换子元素的坐标为全局坐标
    final groupX = (groupElement['x'] as num).toDouble();
    final groupY = (groupElement['y'] as num).toDouble();

    final childElements = <Map<String, dynamic>>[];
    int index = 0;
    for (final child in children) {
      // Create a full deep copy of the child element
      final childMap = deepCopyElement(child as Map<String, dynamic>);
      final x = (childMap['x'] as num).toDouble() + groupX;
      final y = (childMap['y'] as num).toDouble() + groupY;

      // Generate a completely new ID with timestamp and index
      final type = (childMap['type'] as String).split('_').first;
      final newId = '${type}_${timestamp}_${index}_${getRandomString(4)}';
      index++;

      final newElement = {
        ...childMap,
        'id': newId,
        'x': x,
        'y': y,
      };

      // Recursively update IDs for nested groups
      if (newElement['type'] == 'group' &&
          newElement['content'] is Map<String, dynamic> &&
          newElement['content']['children'] is List) {
        final grandchildren = newElement['content']['children'] as List;
        newElement['content']['children'] = updateChildrenIds(grandchildren);
      }

      childElements.add(newElement);
    }

    // Create operation for undo/redo support
    controller.undoRedoManager.addOperation(
      UngroupElementOperation(
        groupElement: groupElement,
        childElements: childElements,
        addElement: (e) {
          if (controller.state.currentPageIndex >= 0 &&
              controller.state.currentPageIndex <
                  controller.state.pages.length) {
            final page =
                controller.state.pages[controller.state.currentPageIndex];
            final elements = page['elements'] as List<dynamic>;
            elements.add(e);

            // 选中组合元素
            controller.state.selectedElementIds = [e['id'] as String];
            controller.state.selectedElement = e;

            controller.state.hasUnsavedChanges = true;
            controller.notifyListeners();
          }
        },
        removeElement: (id) {
          if (controller.state.currentPageIndex >= 0 &&
              controller.state.currentPageIndex <
                  controller.state.pages.length) {
            final page =
                controller.state.pages[controller.state.currentPageIndex];
            final elements = page['elements'] as List<dynamic>;
            elements.removeWhere((e) => e['id'] == id);

            // 如果是当前选中的元素，清除选择
            if (controller.state.selectedElementIds.contains(id)) {
              controller.state.selectedElementIds.clear();
              controller.state.selectedElement = null;
            }

            controller.state.hasUnsavedChanges = true;
            controller.notifyListeners();
          }
        },
        addElements: (elements) {
          if (controller.state.currentPageIndex >= 0 &&
              controller.state.currentPageIndex <
                  controller.state.pages.length) {
            final page =
                controller.state.pages[controller.state.currentPageIndex];
            final pageElements = page['elements'] as List<dynamic>;
            pageElements.addAll(elements);

            // 选中所有子元素
            controller.state.selectedElementIds =
                elements.map((e) => e['id'] as String).toList();
            controller.state.selectedElement = null; // 多选时不显示单个元素的属性

            controller.state.hasUnsavedChanges = true;
            controller.notifyListeners();
          }
        },
      ),
    );
  }

  /// Send element to back
  static void sendElementToBack(PracticeEditController controller) {
    if (controller.state.selectedElementIds.isEmpty) return;

    final id = controller.state.selectedElementIds.first;
    final elements = controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index > 0) {
      const newIndex = 0; // Move to beginning (bottom layer)

      // Create undo/redo operation
      final operation = SendElementToBackOperation(
        elementId: id,
        oldIndex: index,
        newIndex: newIndex,
        reorderElement: controller.reorderElement,
      );

      controller.undoRedoManager.addOperation(operation);
    }
  }

  /// Display image selector dialog
  static Future<void> showImageUrlDialog(
      BuildContext context, PracticeEditController controller) async {
    try {
      // Use file_picker to open file selection dialog
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        dialogTitle: AppLocalizations.of(context).selectImage,
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
            SnackBar(
                content:
                    Text(AppLocalizations.of(context).couldNotGetFilePath)),
          );
        }
        return;
      } // Convert file path to usable URL format - replacing backslashes with forward slashes for Windows paths
      final fileUrl = 'file://${filePath.replaceAll("\\", "/")}';

      // Update or add image element
      if (controller.state.selectedElementIds.isNotEmpty) {
        // If there are selected elements, update its image URL
        final elementId = controller.state.selectedElementIds.first;
        final element = controller.state.currentPageElements.firstWhere(
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
          controller.updateElementProperties(elementId, {'content': content});

          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(AppLocalizations.of(context).imageUpdated)),
            );
          }
        } else {
          // Add new image element
          controller.addImageElement(fileUrl);
        }
      } else {
        // Add new image element
        controller.addImageElement(fileUrl);
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .errorSelectingImage(e.toString()))),
        );
      }
    }
  }

  /// Toggle selected elements lock state
  static void toggleSelectedElementsLock(PracticeEditController controller) {
    if (controller.state.selectedElementIds.isEmpty) return;

    for (final id in controller.state.selectedElementIds) {
      // Get current element
      final elements =
          controller.state.currentPage?['elements'] as List<dynamic>?;
      if (elements == null) continue;

      final elementIndex = elements.indexWhere((e) => e['id'] == id);
      if (elementIndex == -1) continue;

      final element = elements[elementIndex] as Map<String, dynamic>;

      // Toggle lock state
      final isLocked = element['locked'] ?? false;
      controller.updateElementProperty(id, 'locked', !isLocked);
    }
  }

  /// Toggle selected elements visibility
  static void toggleSelectedElementsVisibility(
      PracticeEditController controller) {
    if (controller.state.selectedElementIds.isEmpty) return;

    for (final id in controller.state.selectedElementIds) {
      // Get current element
      final elements =
          controller.state.currentPage?['elements'] as List<dynamic>?;
      if (elements == null) continue;

      final elementIndex = elements.indexWhere((e) => e['id'] == id);
      if (elementIndex == -1) continue;

      final element = elements[elementIndex] as Map<String, dynamic>;

      // Toggle hidden state
      final isHidden = element['hidden'] ?? false;
      controller.updateElementProperty(id, 'hidden', !isHidden);
    }
  }

  /// 递归更新子元素ID

  /// 递归更新子元素ID
  /// Creates completely new child elements with unique IDs
  static List<Map<String, dynamic>> updateChildrenIds(List<dynamic> children) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final updatedChildren = <Map<String, dynamic>>[];

    for (int i = 0; i < children.length; i++) {
      if (children[i] is! Map<String, dynamic>) {
        continue; // Skip non-map items
      }

      // Make a proper deep copy of the child element
      final originalChild = children[i] as Map<String, dynamic>;
      final child = deepCopyElement(originalChild);

      // 生成新ID
      final originalId = child['id'] as String? ?? '';
      final type = originalId.isEmpty ? 'element' : originalId.split('_').first;
      final newId = '${type}_${timestamp}_${i}_${getRandomString(4)}';
      child['id'] = newId;

      // 如果是组元素，递归更新子元素
      if (child['type'] == 'group') {
        final content = child['content'];
        if (content is Map<String, dynamic>) {
          final children = content['children'];
          if (children is List) {
            child['content']['children'] = updateChildrenIds(children);
          }
        }
      }

      updatedChildren.add(child);
    }

    return updatedChildren;
  }

  /// Asynchronously preload a character image
  static void _asyncPreloadCharacterImage(dynamic characterImageService,
      String characterId, String type, String format) {
    Future.microtask(() async {
      try {
        debugPrint('Preloading character image: $characterId ($type, $format)');
        await characterImageService.getCharacterImage(
            characterId, type, format);
        debugPrint('Successfully preloaded character image: $characterId');
      } catch (e) {
        debugPrint('Failed to preload character image $characterId: $e');
      }
    });
  }

  /// Asynchronously preload a local image
  static void _asyncPreloadLocalImage(
      dynamic characterImageService, String imagePath) {
    Future.microtask(() async {
      try {
        debugPrint('Preloading local image: $imagePath');
        // Use image cache service if available
        if (characterImageService != null &&
            characterImageService.toString().contains('ImageCacheService')) {
          final cacheKey = 'file:$imagePath';
          await characterImageService.getBinaryImage(cacheKey);
        }
        debugPrint('Successfully preloaded local image: $imagePath');
      } catch (e) {
        debugPrint('Failed to preload local image $imagePath: $e');
      }
    });
  }

  /// Asynchronously preload a network image
  static void _asyncPreloadNetworkImage(
      dynamic characterImageService, String imageUrl) {
    Future.microtask(() async {
      try {
        debugPrint('Preloading network image: $imageUrl');
        // For network images, we might need different handling
        // This is a placeholder for future network image caching
        debugPrint('Network image preloading not yet implemented: $imageUrl');
      } catch (e) {
        debugPrint('Failed to preload network image $imageUrl: $e');
      }
    });
  }

  /// Perform comprehensive image preloading for copied elements
  static Future<void> _performComprehensiveImagePreloading(
      Map<String, dynamic> clipboardElement,
      dynamic characterImageService,
      dynamic imageCacheService) async {
    try {
      debugPrint(
          'Starting comprehensive image preloading for clipboard content');

      final type = clipboardElement['type'] as String?;

      if (type == 'multi_elements') {
        final elements = clipboardElement['elements'] as List<dynamic>?;
        if (elements != null) {
          for (final element in elements) {
            if (element is Map<String, dynamic>) {
              await _preloadElementImagesAsync(
                  element, characterImageService, imageCacheService);
            }
          }
        }
      } else {
        // Single element
        await _preloadElementImagesAsync(
            clipboardElement, characterImageService, imageCacheService);
      }

      debugPrint('Comprehensive image preloading completed');
    } catch (e) {
      debugPrint('Error in comprehensive image preloading: $e');
    }
  }

  /// Preload character image with both character and UI cache
  static Future<void> _preloadCharacterImageWithCache(
      dynamic characterImageService,
      dynamic imageCacheService,
      String characterId,
      String type,
      String format,
      double fontSize) async {
    try {
      // First, preload the binary image data
      final binaryImage = await characterImageService.getCharacterImage(
          characterId, type, format);

      if (binaryImage != null && imageCacheService != null) {
        // Generate cache key for UI image
        final cacheKey = 'char_$characterId';

        // Try to decode and cache as UI image
        final uiImage =
            await imageCacheService.decodeImageFromBytes(binaryImage);
        if (uiImage != null) {
          await imageCacheService.cacheUiImage(cacheKey, uiImage);
          debugPrint(
              'Cached UI image for character $characterId with key $cacheKey');
        }
      }
    } catch (e) {
      debugPrint('Error preloading character image $characterId: $e');
    }
  }

  /// Preload images for collection elements
  static void _preloadCollectionElementImages(
      Map<String, dynamic> element, dynamic characterImageService) {
    try {
      final content = element['content'] as Map<String, dynamic>?;
      if (content == null) return;

      final characterImages =
          content['characterImages'] as Map<String, dynamic>?;
      if (characterImages == null) return;

      final characters = content['characters'] as String?;
      if (characters == null || characters.isEmpty) return;

      debugPrint(
          'Preloading images for collection element with ${characters.length} characters');

      // Preload each character's image
      for (int i = 0; i < characters.length; i++) {
        final char = characters[i];
        Map<String, dynamic>? charImage;

        // Try multiple lookup strategies
        if (characterImages.containsKey(char)) {
          charImage = characterImages[char] as Map<String, dynamic>?;
        } else if (characterImages.containsKey('$i')) {
          charImage = characterImages['$i'] as Map<String, dynamic>?;
        } else {
          // Search by character match
          for (final key in characterImages.keys) {
            final value = characterImages[key];
            if (value is Map<String, dynamic> &&
                value.containsKey('characterId') &&
                value.containsKey('character') &&
                value['character'] == char) {
              charImage = value;
              break;
            }
          }
        }

        if (charImage != null && charImage.containsKey('characterId')) {
          final characterId = charImage['characterId'].toString();
          final type = charImage['type'] as String? ?? 'square-binary';
          final format = charImage['format'] as String? ?? 'png-binary';

          // Asynchronously preload the image
          _asyncPreloadCharacterImage(
              characterImageService, characterId, type, format);
        }
      }
    } catch (e) {
      debugPrint('Error preloading collection element images: $e');
    }
  }

  /// Asynchronously preload collection element images with comprehensive caching
  static Future<void> _preloadCollectionElementImagesAsync(
      Map<String, dynamic> element,
      dynamic characterImageService,
      dynamic imageCacheService) async {
    try {
      final content = element['content'] as Map<String, dynamic>?;
      if (content == null) return;

      final characterImages =
          content['characterImages'] as Map<String, dynamic>?;
      if (characterImages == null) return;

      final characters = content['characters'] as String?;
      if (characters == null || characters.isEmpty) return;

      final fontSize = content['fontSize'] as double? ?? 24.0;

      debugPrint(
          'Async preloading images for collection element with ${characters.length} characters');

      final preloadTasks = <Future<void>>[];

      for (int i = 0; i < characters.length; i++) {
        final char = characters[i];
        Map<String, dynamic>? charImage;

        // Try multiple lookup strategies
        if (characterImages.containsKey(char)) {
          charImage = characterImages[char] as Map<String, dynamic>?;
        } else if (characterImages.containsKey('$i')) {
          charImage = characterImages['$i'] as Map<String, dynamic>?;
        } else {
          for (final key in characterImages.keys) {
            final value = characterImages[key];
            if (value is Map<String, dynamic> &&
                value.containsKey('characterId') &&
                value.containsKey('character') &&
                value['character'] == char) {
              charImage = value;
              break;
            }
          }
        }

        if (charImage != null && charImage.containsKey('characterId')) {
          final characterId = charImage['characterId'].toString();
          final type = charImage['type'] as String? ?? 'square-binary';
          final format = charImage['format'] as String? ?? 'png-binary';

          // Create preload task
          preloadTasks.add(_preloadCharacterImageWithCache(
              characterImageService,
              imageCacheService,
              characterId,
              type,
              format,
              fontSize));
        }
      }

      // Wait for all preload tasks to complete
      await Future.wait(preloadTasks);
      debugPrint('All collection element images preloaded successfully');
    } catch (e) {
      debugPrint('Error in async collection element preloading: $e');
    }
  }

  /// Preload images for a list of elements
  static void _preloadElementImages(
      List<Map<String, dynamic>> elements, dynamic characterImageService) {
    for (final element in elements) {
      _preloadSingleElementImages(element, characterImageService);
    }
  }

  /// Asynchronously preload images for a single element with comprehensive caching
  static Future<void> _preloadElementImagesAsync(Map<String, dynamic> element,
      dynamic characterImageService, dynamic imageCacheService) async {
    final elementType = element['type'] as String?;

    switch (elementType) {
      case 'collection':
        await _preloadCollectionElementImagesAsync(
            element, characterImageService, imageCacheService);
        break;
      case 'image':
        await _preloadImageElementImagesAsync(
            element, characterImageService, imageCacheService);
        break;
      case 'group':
        await _preloadGroupElementImagesAsync(
            element, characterImageService, imageCacheService);
        break;
      default:
        // For other element types, no specific image preloading needed
        break;
    }
  }

  /// Preload images for group elements (recursively process children)
  static void _preloadGroupElementImages(
      Map<String, dynamic> element, dynamic characterImageService) {
    try {
      final content = element['content'] as Map<String, dynamic>?;
      if (content == null) return;

      final children = content['children'] as List<dynamic>?;
      if (children == null) return;

      for (final child in children) {
        if (child is Map<String, dynamic>) {
          _preloadSingleElementImages(child, characterImageService);
        }
      }
    } catch (e) {
      debugPrint('Error preloading group element images: $e');
    }
  }

  /// Asynchronously preload group element images
  static Future<void> _preloadGroupElementImagesAsync(
      Map<String, dynamic> element,
      dynamic characterImageService,
      dynamic imageCacheService) async {
    try {
      final content = element['content'] as Map<String, dynamic>?;
      if (content == null) return;

      final children = content['children'] as List<dynamic>?;
      if (children == null) return;

      final preloadTasks = <Future<void>>[];

      for (final child in children) {
        if (child is Map<String, dynamic>) {
          preloadTasks.add(_preloadElementImagesAsync(
              child, characterImageService, imageCacheService));
        }
      }
      await Future.wait(preloadTasks);
      debugPrint('All group element children images preloaded successfully');
    } catch (e) {
      debugPrint('Error preloading group element images: $e');
    }
  }

  /// Preload images for image elements
  static void _preloadImageElementImages(
      Map<String, dynamic> element, dynamic characterImageService) {
    try {
      final content = element['content'] as Map<String, dynamic>?;
      if (content == null) return;

      final imagePath = content['imagePath'] as String?;
      final imageUrl = content['imageUrl'] as String?;

      if (imagePath != null) {
        // Preload local image file
        _asyncPreloadLocalImage(characterImageService, imagePath);
      } else if (imageUrl != null) {
        // Preload network image
        _asyncPreloadNetworkImage(characterImageService, imageUrl);
      }
    } catch (e) {
      debugPrint('Error preloading image element: $e');
    }
  }

  /// Asynchronously preload image element images
  static Future<void> _preloadImageElementImagesAsync(
      Map<String, dynamic> element,
      dynamic characterImageService,
      dynamic imageCacheService) async {
    try {
      final content = element['content'] as Map<String, dynamic>?;
      if (content == null) return;

      final imagePath = content['imagePath'] as String?;
      final imageUrl = content['imageUrl'] as String?;

      if (imagePath != null && imageCacheService != null) {
        final cacheKey = 'file:$imagePath';
        await imageCacheService.getBinaryImage(cacheKey);
        debugPrint('Preloaded local image: $imagePath');
      } else if (imageUrl != null) {
        debugPrint('Network image preloading not yet implemented: $imageUrl');
      }
    } catch (e) {
      debugPrint('Error preloading image element: $e');
    }
  }

  /// Preload images for a single element
  static void _preloadSingleElementImages(
      Map<String, dynamic> element, dynamic characterImageService) {
    final elementType = element['type'] as String?;

    switch (elementType) {
      case 'collection':
        _preloadCollectionElementImages(element, characterImageService);
        break;
      case 'image':
        _preloadImageElementImages(element, characterImageService);
        break;
      case 'group':
        _preloadGroupElementImages(element, characterImageService);
        break;
      default:
        // For other element types, no specific image preloading needed
        break;
    }
  }

  /// Warm up caches for paste operation
  static Future<void> _warmCacheForPasteOperation(
      Map<String, dynamic> clipboardElement,
      dynamic characterImageService,
      dynamic imageCacheService) async {
    try {
      debugPrint('Warming caches for paste operation');

      final type = clipboardElement['type'] as String?;

      if (type == 'multi_elements') {
        // Handle multiple elements
        final elements = clipboardElement['elements'] as List<dynamic>?;
        if (elements != null) {
          final preloadTasks = <Future<void>>[];
          for (final element in elements) {
            if (element is Map<String, dynamic>) {
              preloadTasks.add(_preloadElementImagesAsync(
                  element, characterImageService, imageCacheService));
            }
          }
          await Future.wait(preloadTasks);
        }
      } else {
        // Handle single element
        await _preloadElementImagesAsync(
            clipboardElement, characterImageService, imageCacheService);
      }

      debugPrint('Cache warming for paste operation completed');
    } catch (e) {
      debugPrint('Error warming cache for paste operation: $e');
    }
  }
}
