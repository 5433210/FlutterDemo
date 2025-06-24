import 'package:flutter/material.dart';

import '../../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../widgets/practice/practice_edit_controller.dart';

/// 画布元素创建器
/// 负责处理各种类型元素的创建逻辑
mixin CanvasElementCreators {
  /// 获取控制器（由使用此mixin的类实现）
  PracticeEditController get controller;

  /// 检查组件是否已dispose（由使用此mixin的类实现）
  bool get isDisposed;

  /// 创建集字元素
  void createCollectionElement(Offset position) {
    EditPageLogger.canvasDebug(
      '开始创建集字元素',
      data: {
        'position': '(${position.dx}, ${position.dy})',
        'operation': 'createCollectionElement',
      },
    );

    // 调用controller创建集字元素，现在返回元素ID
    final newElementId =
        controller.addCollectionElementAt(position.dx, position.dy, '');

    EditPageLogger.canvasDebug(
      '集字元素已创建',
      data: {
        'elementId': newElementId,
        'position': '(${position.dx}, ${position.dy})',
        'elementType': 'collection',
      },
    );

    // 等待一帧后选择新创建的元素
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isDisposed) {
        controller.selectElement(newElementId);
        EditPageLogger.canvasDebug(
          '集字元素创建完成并已选中',
          data: {
            'elementId': newElementId,
            'operation': 'post_frame_selection',
          },
        );
      }
    });
  }

  /// 创建图像元素
  void createImageElement(Offset position) {
    EditPageLogger.canvasDebug(
      '开始创建图像元素',
      data: {
        'position': '(${position.dx}, ${position.dy})',
        'operation': 'createImageElement',
      },
    );

    // 调用controller创建图像元素，现在返回元素ID
    final newElementId =
        controller.addImageElementAt(position.dx, position.dy, '');

    EditPageLogger.canvasDebug(
      '图像元素已创建',
      data: {
        'elementId': newElementId,
        'position': '(${position.dx}, ${position.dy})',
        'elementType': 'image',
      },
    );

    // 等待一帧后选择新创建的元素
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isDisposed) {
        controller.selectElement(newElementId);
        EditPageLogger.canvasDebug(
          '图像元素创建完成并已选中',
          data: {
            'elementId': newElementId,
            'operation': 'post_frame_selection',
          },
        );
      }
    });
  }

  /// 创建文本元素
  void createTextElement(Offset position) {
    EditPageLogger.canvasDebug(
      '开始创建文本元素',
      data: {
        'position': '(${position.dx}, ${position.dy})',
        'operation': 'createTextElement',
      },
    );

    // 调用controller创建文本元素，现在返回元素ID
    final newElementId = controller.addTextElementAt(position.dx, position.dy);

    EditPageLogger.canvasDebug(
      '文本元素已创建',
      data: {
        'elementId': newElementId,
        'position': '(${position.dx}, ${position.dy})',
        'elementType': 'text',
      },
    );

    // 等待一帧后选择新创建的元素
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isDisposed) {
        controller.selectElement(newElementId);
        EditPageLogger.canvasDebug(
          '文本元素创建完成并已选中',
          data: {
            'elementId': newElementId,
            'operation': 'post_frame_selection',
          },
        );
      }
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
      EditPageLogger.canvasDebug(
        '无需创建撤销操作：没有属性变化',
        data: {'elementId': elementId},
      );
      return; // 没有变化，不需要创建撤销操作
    }

    EditPageLogger.canvasDebug(
      '创建撤销操作',
      data: {
        'elementId': elementId,
        'changedProperties': newProperties.keys.toList(),
        'operation': 'createUndoOperation',
      },
    );

    // 注意：撤销操作由控制点处理器统一创建，这里不再重复创建
    EditPageLogger.canvasDebug(
      '元素属性更新完成',
      data: {
        'elementId': elementId,
        'changedProperties': newProperties.keys.toList(),
        'hasRotationChange': newProperties.containsKey('rotation'),
        'hasSizeChange': newProperties.keys
            .any((key) => ['x', 'y', 'width', 'height'].contains(key)),
        'note': '撤销操作由控制点处理器统一管理',
      },
    );
  }

  /// 处理元素拖拽创建
  void handleElementDrop(String elementType, Offset position,
      {bool applyCenteringOffset = true}) {
    EditPageLogger.canvasDebug(
      '开始处理元素拖拽创建',
      data: {
        'elementType': elementType,
        'originalPosition': '(${position.dx}, ${position.dy})',
        'applyCenteringOffset': applyCenteringOffset,
        'operation': 'handleElementDrop',
      },
    );

    Offset finalPosition = position;

    // 🔧 修复拖拽定位问题：只有在需要时才调整位置使元素居中在鼠标释放点
    // 当坐标已经在上级方法中正确转换时，不需要再次调整
    if (applyCenteringOffset) {
      EditPageLogger.canvasDebug(
        '开始计算居中偏移',
        data: {'elementType': elementType},
      ); // 元素默认尺寸在element_management_mixin.dart中定义
      switch (elementType) {
        case 'collection':
          // 集字元素默认 400x200，调整位置使其居中
          finalPosition = Offset(position.dx - 200, position.dy - 100);
          EditPageLogger.canvasDebug(
            '计算集字元素居中偏移',
            data: {
              'defaultSize': '400x200',
              'original': '(${position.dx}, ${position.dy})',
              'adjusted': '(${finalPosition.dx}, ${finalPosition.dy})',
              'offset': '(-200, -100)',
            },
          );
          break;
        case 'image':
          // 图片元素默认 400x200，调整位置使其居中
          finalPosition = Offset(position.dx - 200, position.dy - 100);
          EditPageLogger.canvasDebug(
            '计算图像元素居中偏移',
            data: {
              'defaultSize': '400x200',
              'original': '(${position.dx}, ${position.dy})',
              'adjusted': '(${finalPosition.dx}, ${finalPosition.dy})',
              'offset': '(-200, -100)',
            },
          );
          break;
        case 'text':
          // 文本元素默认 400x200，调整位置使其居中
          finalPosition = Offset(position.dx - 200, position.dy - 100);
          EditPageLogger.canvasDebug(
            '计算文本元素居中偏移',
            data: {
              'defaultSize': '400x200',
              'original': '(${position.dx}, ${position.dy})',
              'adjusted': '(${finalPosition.dx}, ${finalPosition.dy})',
              'offset': '(-200, -100)',
            },
          );
          break;
        default:
          EditPageLogger.canvasDebug(
            '未知元素类型，不应用居中偏移',
            data: {'elementType': elementType},
          );
      }
    } else {
      EditPageLogger.canvasDebug(
        '跳过居中偏移，直接使用原始位置',
        data: {'position': '(${position.dx}, ${position.dy})'},
      );
    }

    EditPageLogger.canvasDebug(
      '调用元素创建方法',
      data: {
        'elementType': elementType,
        'finalPosition': '(${finalPosition.dx}, ${finalPosition.dy})',
      },
    );

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
        EditPageLogger.canvasError(
          '未知的元素类型',
          data: {'elementType': elementType},
        );
        break;
    }

    EditPageLogger.canvasDebug(
      '元素拖拽创建处理完成',
      data: {
        'elementType': elementType,
        'originalPosition': '(${position.dx}, ${position.dy})',
        'finalPosition': '(${finalPosition.dx}, ${finalPosition.dy})',
        'applyCenteringOffset': applyCenteringOffset,
        'operation': 'handleElementDrop_completed',
      },
    );
  }
}
