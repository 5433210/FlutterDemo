import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../widgets/practice/page_operations.dart';
import '../../../widgets/practice/practice_edit_controller.dart';

/// Utility methods for practice editing
class PracticeEditUtils {
  /// Add a new page
  static void addNewPage(PracticeEditController controller) {
    // 使用 PageOperations 创建新页面
    final newPage = PageOperations.addPage(controller.state.pages, null);

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
      // Remove element
      final element = elements.removeAt(index);
      // Add to end (top layer)
      elements.add(element);

      // Update current page elements
      controller.state.pages[controller.state.currentPageIndex]['elements'] =
          elements;
      controller.state.hasUnsavedChanges = true;
    }
  }

  /// Copy selected elements
  static Map<String, dynamic>? copySelectedElements(
      PracticeEditController controller, BuildContext context) {
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

        // Show notification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Element copied to clipboard'),
            duration: Duration(seconds: 2),
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

        // 显示通知
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${selectedElements.length} elements copied to clipboard'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    return clipboardElement;
  }

  /// Delete a page
  static void deletePage(
      PracticeEditController controller, int index, BuildContext context) {
    // 确保至少保留一个页面
    if (controller.state.pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the only page')),
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
      // Swap current element with element below
      final temp = elements[index];
      elements[index] = elements[index - 1];
      elements[index - 1] = temp;

      // Update current page elements
      controller.state.pages[controller.state.currentPageIndex]['elements'] =
          elements;
      controller.state.hasUnsavedChanges = true;
    }
  }

  /// Move element up one layer
  static void moveElementUp(PracticeEditController controller) {
    if (controller.state.selectedElementIds.isEmpty) return;

    final id = controller.state.selectedElementIds.first;
    final elements = controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index >= 0 && index < elements.length - 1) {
      // Swap current element with element above
      final temp = elements[index];
      elements[index] = elements[index + 1];
      elements[index + 1] = temp;

      // Update current page elements
      controller.state.pages[controller.state.currentPageIndex]['elements'] =
          elements;
      controller.state.hasUnsavedChanges = true;
    }
  }

  /// Paste element(s)
  static void pasteElement(PracticeEditController controller,
      Map<String, dynamic>? clipboardElement) {
    if (clipboardElement == null) return;

    final elements = controller.state.currentPageElements;
    final newElementIds = <String>[];

    // 检查是否是多元素集合
    if (clipboardElement['type'] == 'multi_elements') {
      // 处理多元素粘贴
      final clipboardElements = clipboardElement['elements'] as List<dynamic>;
      final newElements = <Map<String, dynamic>>[];

      // 获取当前时间戳作为基础
      final baseTimestamp = DateTime.now().millisecondsSinceEpoch;

      // 为每个元素添加索引，确保ID唯一
      int index = 0;
      for (final element in clipboardElements) {
        // 创建新元素ID，添加索引和随机数确保唯一性
        final newId =
            '${element['type']}_${baseTimestamp}_${index}_${getRandomString(4)}';
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
          '${clipboardElement['type']}_${DateTime.now().millisecondsSinceEpoch}_${getRandomString(4)}';

      // 复制元素并修改位置（稍微偏移一点）
      final newElement = {
        ...clipboardElement,
        'id': newId,
        'x': (clipboardElement['x'] as num).toDouble() + 20,
        'y': (clipboardElement['y'] as num).toDouble() + 20,
      };

      // 添加到当前页面
      elements.add(newElement);
      newElementIds.add(newId);
    }

    // 更新当前页面的元素
    controller.state.pages[controller.state.currentPageIndex]['elements'] =
        elements;

    // 选中新粘贴的元素 - 如果是多个元素，只选中第一个
    if (newElementIds.length == 1) {
      controller.state.selectedElementIds = newElementIds;
      controller.state.selectedElement =
          elements.firstWhere((e) => e['id'] == newElementIds.first);
    } else if (newElementIds.isNotEmpty) {
      // 对于多个元素，只选中第一个，这样点击时不会全部被选中
      final firstId = newElementIds.first;
      controller.state.selectedElementIds = [firstId];
      controller.state.selectedElement =
          elements.firstWhere((e) => e['id'] == firstId);
    }
    controller.state.hasUnsavedChanges = true;
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

  /// Send element to back
  static void sendElementToBack(PracticeEditController controller) {
    if (controller.state.selectedElementIds.isEmpty) return;

    final id = controller.state.selectedElementIds.first;
    final elements = controller.state.currentPageElements;
    final index = elements.indexWhere((e) => e['id'] == id);

    if (index > 0) {
      // Remove element
      final element = elements.removeAt(index);
      // Add to beginning (bottom layer)
      elements.insert(0, element);

      // Update current page elements
      controller.state.pages[controller.state.currentPageIndex]['elements'] =
          elements;
      controller.state.hasUnsavedChanges = true;
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
              const SnackBar(content: Text('Image updated')),
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
          SnackBar(content: Text('Error selecting image: $e')),
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
}
