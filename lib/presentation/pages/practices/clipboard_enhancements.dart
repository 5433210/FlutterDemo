import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<bool> checkClipboardContent() async => false;

/// Enhanced copy functionality for clipboard handling
void enhancedCopySelectedElement(BuildContext context) {
  debugPrint('开始复制选中元素...');
  final clipboardElement = getSelectedElements();
  debugPrint('复制结果: ${clipboardElement != null ? '成功' : '失败'}');

  if (clipboardElement != null) {
    debugPrint('复制的元素类型: ${clipboardElement['type']}');

    // Update clipboard state and paste button activation
    updateClipboardState(true);

    // Show a snackbar notification for successful copy
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('元素已复制到剪贴板')));
  } else {
    updateClipboardState(false);
  }
}

/// Enhanced inspection of clipboard contents
Future<void> enhancedInspectClipboard() async {
  debugPrint('======= 剪贴板详细检查 =======');

  final clipboardElement = getInternalClipboardElement();
  if (clipboardElement != null) {
    debugPrint('内部剪贴板内容类型: ${clipboardElement['type']}');

    final type = clipboardElement['type'];
    if (type == 'characters' || type == 'character') {
      if (clipboardElement.containsKey('characterIds')) {
        debugPrint('字符IDs: ${clipboardElement['characterIds']}');
      } else if (clipboardElement.containsKey('data') &&
          clipboardElement['data'] is Map &&
          clipboardElement['data'].containsKey('characterId')) {
        debugPrint('字符ID: ${clipboardElement['data']['characterId']}');
      }
    } else if (type == 'library_items' || type == 'image') {
      if (clipboardElement.containsKey('itemIds')) {
        debugPrint('图库项目IDs: ${clipboardElement['itemIds']}');
      } else if (clipboardElement.containsKey('imageUrl')) {
        debugPrint('图片URL: ${clipboardElement['imageUrl']}');
      }
    }

    if (kDebugMode) {
      debugPrint('内部剪贴板完整内容: $clipboardElement');
    }
  } else {
    debugPrint('内部剪贴板为空');
  }

  debugPrint('======= 剪贴板检查结束 =======');
}

/// Enhanced clipboard monitoring
void enhancedStartClipboardMonitoring() {
  // Check clipboard every 2 seconds
  Future.delayed(const Duration(seconds: 2), () async {
    // Periodically check clipboard content
    try {
      final hasContent = await checkClipboardContent();

      if (hasContentChanged(hasContent)) {
        debugPrint(
            '剪贴板状态变化: ${getCurrentClipboardState() ? "有内容" : "无内容"} -> ${hasContent ? "有内容" : "无内容"}');

        // If debugging, do a full inspection when state changes
        if (kDebugMode && hasContent) {
          await enhancedInspectClipboard();
        }

        // Update state to reflect current clipboard content
        updateClipboardState(hasContent);
      }
    } catch (e) {
      debugPrint('剪贴板监控错误: $e');
    }

    // Always schedule next check, even if there was an error
    // This ensures the monitoring is robust
    if (isWidgetMounted()) {
      enhancedStartClipboardMonitoring();
    }
  });
}

bool getCurrentClipboardState() => false;
Map<String, dynamic>? getInternalClipboardElement() => null;
// Mock functions to make the example code compile
Map<String, dynamic>? getSelectedElements() => null;
bool hasContentChanged(bool hasContent) => false;
bool isWidgetMounted() => true;
void updateClipboardState(bool hasContent) {}
