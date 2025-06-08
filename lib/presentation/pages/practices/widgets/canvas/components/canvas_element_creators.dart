import 'package:flutter/material.dart';

import '../../../../../../infrastructure/logging/logger.dart';
import '../../../../../widgets/practice/practice_edit_controller.dart';

/// 画布元素创建器
/// 负责处理各种类型元素的创建逻辑
mixin CanvasElementCreators {
  /// 获取控制器（由使用此mixin的类实现）
  PracticeEditController get controller;

  /// 创建集字元素
  void createCollectionElement(Offset position) {
    debugPrint('🎯[DROP] 进入createCollectionElement，位置: $position');
    
    AppLogger.info(
      '创建集字元素',
      tag: 'Canvas',
      data: {'position': '$position'},
    );

    // 调用controller创建集字元素，现在返回元素ID
    final newElementId =
        controller.addCollectionElementAt(position.dx, position.dy, '');

    debugPrint('🎯[DROP] 集字元素已创建，ID: $newElementId，位置: (${position.dx}, ${position.dy})');

    // 等待一帧后选择新创建的元素
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectElement(newElementId);
      debugPrint('🎯[DROP] 集字元素已选中: $newElementId');
      AppLogger.info(
        '创建集字元素成功',
        tag: 'Canvas',
        data: {'elementId': newElementId},
      );
    });
  }

  /// 创建图像元素
  void createImageElement(Offset position) {
    debugPrint('🎯[DROP] 进入createImageElement，位置: $position');
    
    AppLogger.info(
      '创建图像元素',
      tag: 'Canvas',
      data: {'position': '$position'},
    );

    // 调用controller创建图像元素，现在返回元素ID
    final newElementId =
        controller.addImageElementAt(position.dx, position.dy, '');

    debugPrint('🎯[DROP] 图像元素已创建，ID: $newElementId，位置: (${position.dx}, ${position.dy})');

    // 等待一帧后选择新创建的元素
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectElement(newElementId);
      debugPrint('🎯[DROP] 图像元素已选中: $newElementId');
      AppLogger.info(
        '创建图像元素成功',
        tag: 'Canvas',
        data: {'elementId': newElementId},
      );
    });
  }

  /// 创建文本元素
  void createTextElement(Offset position) {
    debugPrint('🎯[DROP] 进入createTextElement，位置: $position');
    
    AppLogger.info(
      '创建文本元素',
      tag: 'Canvas',
      data: {'position': '$position'},
    );

    // 调用controller创建文本元素，现在返回元素ID
    final newElementId = controller.addTextElementAt(position.dx, position.dy);
    
    debugPrint('🎯[DROP] 文本元素已创建，ID: $newElementId，位置: (${position.dx}, ${position.dy})');

    // 等待一帧后选择新创建的元素
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectElement(newElementId);
      debugPrint('🎯[DROP] 文本元素已选中: $newElementId');
      AppLogger.info(
        '创建文本元素成功',
        tag: 'Canvas',
        data: {'elementId': newElementId},
      );
    });
  }

  /// 创建撤销操作 - 用于Commit阶段
  void createUndoOperation(String elementId, Map<String, dynamic> oldProperties,
      Map<String, dynamic> newProperties) {
    // 检查是否有实际变化
    bool hasChanges = false;
    for (final key in newProperties.keys) {
      if (oldProperties[key] != newProperties[key]) {
        hasChanges = true;
        break;
      }
    }

    if (!hasChanges) {
      AppLogger.debug(
        '无需创建撤销操作：没有属性变化',
        tag: 'Canvas',
        data: {'elementId': elementId},
      );
      return; // 没有变化，不需要创建撤销操作
    }

    AppLogger.debug(
      '创建撤销操作',
      tag: 'Canvas',
      data: {
        'elementId': elementId,
        'changedProperties': newProperties.keys.toList(),
      },
    );

    // 根据变化类型创建对应的撤销操作
    if (newProperties.containsKey('rotation') &&
        oldProperties.containsKey('rotation')) {
      // 旋转操作
      controller.createElementRotationOperation(
        elementIds: [elementId],
        oldRotations: [(oldProperties['rotation'] as num).toDouble()],
        newRotations: [(newProperties['rotation'] as num).toDouble()],
      );
      AppLogger.debug('创建旋转撤销操作', tag: 'Canvas');
    } else if (newProperties.keys
        .any((key) => ['x', 'y', 'width', 'height'].contains(key))) {
      // 调整大小/位置操作
      final oldSize = {
        'x': (oldProperties['x'] as num).toDouble(),
        'y': (oldProperties['y'] as num).toDouble(),
        'width': (oldProperties['width'] as num).toDouble(),
        'height': (oldProperties['height'] as num).toDouble(),
      };
      final newSize = {
        'x': (newProperties['x'] as num).toDouble(),
        'y': (newProperties['y'] as num).toDouble(),
        'width': (newProperties['width'] as num).toDouble(),
        'height': (newProperties['height'] as num).toDouble(),
      };

      controller.createElementResizeOperation(
        elementIds: [elementId],
        oldSizes: [oldSize],
        newSizes: [newSize],
      );
      AppLogger.debug('创建调整大小撤销操作', tag: 'Canvas');
    }
  }

  /// 处理元素拖拽创建
  void handleElementDrop(String elementType, Offset position,
      {bool applyCenteringOffset = true}) {
    debugPrint('🎯[DROP] 进入CanvasElementCreators.handleElementDrop');
    debugPrint('🎯[DROP]   - 元素类型: $elementType');
    debugPrint('🎯[DROP]   - 接收位置: $position');
    debugPrint('🎯[DROP]   - 启用居中偏移: $applyCenteringOffset');

    Offset finalPosition = position;

    // 🔧 修复拖拽定位问题：只有在需要时才调整位置使元素居中在鼠标释放点
    // 当坐标已经在上级方法中正确转换时，不需要再次调整
    if (applyCenteringOffset) {
      debugPrint('🎯[DROP] 开始计算居中偏移:');
      // 元素默认尺寸在element_management_mixin.dart中定义
      switch (elementType) {
        case 'collection':
          // 集字元素默认 200x200，调整位置使其居中
          finalPosition = Offset(position.dx - 100, position.dy - 100);
          debugPrint('🎯[DROP]   - 集字元素 200x200: $position → $finalPosition (偏移-100,-100)');
          break;
        case 'image':
          // 图片元素默认 200x200，调整位置使其居中
          finalPosition = Offset(position.dx - 100, position.dy - 100);
          debugPrint('🎯[DROP]   - 图片元素 200x200: $position → $finalPosition (偏移-100,-100)');
          break;
        case 'text':
          // 文本元素默认 200x100，调整位置使其居中
          finalPosition = Offset(position.dx - 100, position.dy - 50);
          debugPrint('🎯[DROP]   - 文本元素 200x100: $position → $finalPosition (偏移-100,-50)');
          break;
        default:
          debugPrint('🎯[DROP]   - 未知元素类型，不应用居中偏移');
      }
    } else {
      debugPrint('🎯[DROP] 跳过居中偏移，直接使用原始位置');
    }

    debugPrint('🎯[DROP] 最终调用create方法，位置: $finalPosition');

    switch (elementType) {
      case 'collection':
        createCollectionElement(finalPosition);
        break;
      case 'image':
        createImageElement(finalPosition);
        break;
      case 'text':
        createTextElement(finalPosition);
        break;
      default:
        debugPrint('🎯[DROP] ❌ 未知的元素类型: $elementType');
        AppLogger.warning(
          '未知的元素类型',
          tag: 'Canvas',
          data: {'elementType': elementType},
        );
        break;
    }

    debugPrint('🎯[DROP] CanvasElementCreators.handleElementDrop处理完成');
    debugPrint('🎯[DROP]   - 原始位置: $position');
    debugPrint('🎯[DROP]   - 最终位置: $finalPosition');
    debugPrint('🎯[DROP]   - 居中偏移: $applyCenteringOffset');
  }
}
