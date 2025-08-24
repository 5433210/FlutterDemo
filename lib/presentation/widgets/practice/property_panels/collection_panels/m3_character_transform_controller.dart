import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../common/editable_number_field.dart';

/// 单字符变换控制器组件
class M3CharacterTransformController extends StatefulWidget {
  final Map<String, dynamic> element;
  final int selectedCharIndex;
  final Function(String, dynamic) onTransformPropertyChanged;
  final Function(int, String, dynamic)? onTransformPropertyUpdateStart;
  final Function(int, String, dynamic)? onTransformPropertyUpdatePreview;
  final Function(int, String, dynamic, dynamic)?
      onTransformPropertyUpdateWithUndo;
  final Function(int, Map<String, dynamic>, Map<String, dynamic>)?
      onTransformPropertiesBatchUndo;

  const M3CharacterTransformController({
    Key? key,
    required this.element,
    required this.selectedCharIndex,
    required this.onTransformPropertyChanged,
    this.onTransformPropertyUpdateStart,
    this.onTransformPropertyUpdatePreview,
    this.onTransformPropertyUpdateWithUndo,
    this.onTransformPropertiesBatchUndo,
  }) : super(key: key);

  @override
  State<M3CharacterTransformController> createState() =>
      _M3CharacterTransformControllerState();
}

class _M3CharacterTransformControllerState
    extends State<M3CharacterTransformController> {
  // 滑块拖动时的原始值（用于Undo）
  double? _originalCharacterScale;
  double? _originalOffsetX;
  double? _originalOffsetY;

  // 长按控制相关状态
  Timer? _longPressTimer;
  bool _isLongPressing = false;
  int _longPressCount = 0;

  @override
  void dispose() {
    _stopLongPress();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';

    // 检查是否有选中的字符
    if (characters.isEmpty ||
        widget.selectedCharIndex < 0 ||
        widget.selectedCharIndex >= characters.length) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest
              .withAlpha((0.3 * 255).toInt()),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Center(
          child: Text(
            l10n.selectCharacterFirst,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    // 获取当前选中字符的变换信息
    final characterImages =
        content['characterImages'] as Map<String, dynamic>? ?? {};
    final imageInfo =
        characterImages['${widget.selectedCharIndex}'] as Map<String, dynamic>?;
    final transform = imageInfo?['transform'] as Map<String, dynamic>? ?? {};

    final characterScale =
        (transform['characterScale'] as num?)?.toDouble() ?? 1.0;
    final offsetX = (transform['offsetX'] as num?)?.toDouble() ?? 0.0;
    final offsetY = (transform['offsetY'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 字符缩放控制
        Text(
          '${l10n.characterScale} (${(characterScale * 100).round()}%)',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Slider(
                value: characterScale.clamp(0.3, 2.0), // 扩大范围：30% 到 200%
                min: 0.3,
                max: 2.0,
                // 去掉divisions参数，实现无级滑块
                label: '${(characterScale * 100).round()}%',
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceContainerHighest,
                thumbColor: colorScheme.primary,
                onChangeStart: (value) {
                  _originalCharacterScale = characterScale;
                  developer.log(
                      '滑块开始 - selectedCharIndex: ${widget.selectedCharIndex}, 当前值: $characterScale, 记录原始值: $_originalCharacterScale',
                      name: 'CharacterTransform');
                  widget.onTransformPropertyUpdateStart?.call(
                      widget.selectedCharIndex,
                      'characterScale',
                      characterScale);
                },
                onChanged: (value) {
                  // 实时预览变化，但不记录undo
                  widget.onTransformPropertyUpdatePreview
                      ?.call(widget.selectedCharIndex, 'characterScale', value);
                },
                onChangeEnd: (value) {
                  // 获取实际的当前值（因为onChanged已经更新了数据）
                  final content =
                      widget.element['content'] as Map<String, dynamic>;
                  final characterImages =
                      content['characterImages'] as Map<String, dynamic>? ?? {};
                  final imageInfo =
                      characterImages['${widget.selectedCharIndex}']
                          as Map<String, dynamic>?;
                  final transform =
                      imageInfo?['transform'] as Map<String, dynamic>? ?? {};
                  final currentCharacterScale =
                      (transform['characterScale'] as num?)?.toDouble() ?? 1.0;

                  // 只在最终释放时记录undo
                  developer.log(
                      '滑块结束 - selectedCharIndex: ${widget.selectedCharIndex}, 实际当前值: $currentCharacterScale, 原始值: $_originalCharacterScale',
                      name: 'CharacterTransform');
                  widget.onTransformPropertyUpdateWithUndo?.call(
                      widget.selectedCharIndex,
                      'characterScale',
                      currentCharacterScale,
                      _originalCharacterScale);
                  _originalCharacterScale = null;
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: EditableNumberField(
                label: l10n.scale,
                value: characterScale,
                suffix: '×',
                min: 0.3,
                max: 2.0,
                decimalPlaces: 2,
                onChanged: (value) {
                  widget.onTransformPropertyChanged('characterScale', value);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 位置偏移控制
        Text(
          '${l10n.positionOffset} (X: ${offsetX.toStringAsFixed(1)}px, Y: ${offsetY.toStringAsFixed(1)}px)',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8.0),

        // 8方向控制器
        _buildDirectionController(context, offsetX, offsetY),

        const SizedBox(height: 12.0),

        // 精确偏移值输入
        Row(
          children: [
            Expanded(
              child: EditableNumberField(
                label: l10n.xOffset,
                value: offsetX,
                suffix: 'px',
                min: -100,
                max: 100,
                decimalPlaces: 1,
                onChanged: (value) {
                  widget.onTransformPropertyChanged('offsetX', value);
                },
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: EditableNumberField(
                label: l10n.yOffset,
                value: offsetY,
                suffix: 'px',
                min: -100,
                max: 100,
                decimalPlaces: 1,
                onChanged: (value) {
                  widget.onTransformPropertyChanged('offsetY', value);
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12.0),
        
        // 重置變換按鈕 - 放在縮放和偏移控制的下方
        Center(
          child: SizedBox(
            width: 80,
            height: 36,
            child: FilledButton.tonal(
              onPressed: () => _resetTransform(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, size: 16),
                  const SizedBox(width: 4),
                  Text(l10n.reset),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建8方向控制器
  Widget _buildDirectionController(
      BuildContext context, double offsetX, double offsetY) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color:
            colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).toInt()),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          // 第一行：左上、上、右上
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDirectionButton(context, '↖', -1, -1),
              _buildDirectionButton(context, '↑', 0, -1),
              _buildDirectionButton(context, '↗', 1, -1),
            ],
          ),
          const SizedBox(height: 8.0),
          // 第二行：左、中心、右
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDirectionButton(context, '←', -1, 0),
              _buildCenterIndicator(context, offsetX, offsetY),
              _buildDirectionButton(context, '→', 1, 0),
            ],
          ),
          const SizedBox(height: 8.0),
          // 第三行：左下、下、右下
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDirectionButton(context, '↙', -1, 1),
              _buildDirectionButton(context, '↓', 0, 1),
              _buildDirectionButton(context, '↘', 1, 1),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建方向按钮 - 支持长按持续变化
  Widget _buildDirectionButton(
      BuildContext context, String icon, int deltaX, int deltaY) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 40,
      height: 40,
      child: GestureDetector(
        onTapDown: (_) => _startLongPress(deltaX.toDouble(), deltaY.toDouble()),
        onTapUp: (_) => _stopLongPress(),
        onTapCancel: () => _stopLongPress(),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: colorScheme.outline,
              width: 1.0,
            ),
          ),
          child: Center(
            child: Text(
              icon,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建中心指示器
  Widget _buildCenterIndicator(
      BuildContext context, double offsetX, double offsetY) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOffset = offsetX != 0.0 || offsetY != 0.0;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isOffset ? colorScheme.primaryContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isOffset ? colorScheme.primary : colorScheme.outline,
          width: isOffset ? 2.0 : 1.0,
        ),
      ),
      child: Icon(
        isOffset ? Icons.my_location : Icons.my_location_outlined,
        size: 20,
        color:
            isOffset ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
      ),
    );
  }

  /// 开始长按操作
  void _startLongPress(double deltaX, double deltaY) {
    if (_isLongPressing) return;

    _isLongPressing = true;
    _longPressCount = 0;

    // 保存原始值用于undo
    final content = widget.element['content'] as Map<String, dynamic>;
    final characterImages =
        content['characterImages'] as Map<String, dynamic>? ?? {};
    final imageInfo =
        characterImages['${widget.selectedCharIndex}'] as Map<String, dynamic>?;
    final transform = imageInfo?['transform'] as Map<String, dynamic>? ?? {};

    _originalOffsetX = (transform['offsetX'] as num?)?.toDouble() ?? 0.0;
    _originalOffsetY = (transform['offsetY'] as num?)?.toDouble() ?? 0.0;

    developer.log(
        '长按开始 - selectedCharIndex: ${widget.selectedCharIndex}, 记录原始偏移: X=$_originalOffsetX, Y=$_originalOffsetY',
        name: 'CharacterTransform');

    // 立即执行第一次调整
    _adjustOffsetStep(deltaX, deltaY, isFirst: true);

    // 启动定时器进行连续调整
    _longPressTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _longPressCount++;
      _adjustOffsetStep(deltaX, deltaY);
    });
  }

  /// 停止长按操作
  void _stopLongPress() {
    if (!_isLongPressing) return;

    _longPressTimer?.cancel();
    _longPressTimer = null;
    _isLongPressing = false;

    // 只在停止时记录undo操作（记录最终值）
    if (_originalOffsetX != null && _originalOffsetY != null) {
      final content = widget.element['content'] as Map<String, dynamic>;
      final characterImages =
          content['characterImages'] as Map<String, dynamic>? ?? {};
      final imageInfo = characterImages['${widget.selectedCharIndex}']
          as Map<String, dynamic>?;
      final transform = imageInfo?['transform'] as Map<String, dynamic>? ?? {};

      final finalOffsetX = (transform['offsetX'] as num?)?.toDouble() ?? 0.0;
      final finalOffsetY = (transform['offsetY'] as num?)?.toDouble() ?? 0.0;

      // 只有当偏移值真正改变时才记录undo
      if (finalOffsetX != _originalOffsetX ||
          finalOffsetY != _originalOffsetY) {
        developer.log(
            '位置偏移结束 - selectedCharIndex: ${widget.selectedCharIndex}, offsetX: $finalOffsetX <- $_originalOffsetX',
            name: 'CharacterTransform');
        developer.log(
            '位置偏移结束 - selectedCharIndex: ${widget.selectedCharIndex}, offsetY: $finalOffsetY <- $_originalOffsetY',
            name: 'CharacterTransform');

        // 使用批量undo函数，将offsetX和offsetY作为一个操作处理
        if (widget.onTransformPropertiesBatchUndo != null) {
          developer.log('使用批量undo处理位置偏移', name: 'CharacterTransform');
          widget.onTransformPropertiesBatchUndo
              ?.call(widget.selectedCharIndex, {
            'offsetX': finalOffsetX,
            'offsetY': finalOffsetY,
          }, {
            'offsetX': _originalOffsetX,
            'offsetY': _originalOffsetY,
          });
        } else {
          // 回退到原来的方式（分别调用两次）
          developer.log('使用传统方式处理位置偏移undo', name: 'CharacterTransform');
          widget.onTransformPropertyUpdateWithUndo?.call(
              widget.selectedCharIndex,
              'offsetX',
              finalOffsetX,
              _originalOffsetX);
          widget.onTransformPropertyUpdateWithUndo?.call(
              widget.selectedCharIndex,
              'offsetY',
              finalOffsetY,
              _originalOffsetY);
        }
      } else {
        developer.log(
            '位置偏移结束 - selectedCharIndex: ${widget.selectedCharIndex}, 无变化，不记录undo',
            name: 'CharacterTransform');
      }
    }

    _originalOffsetX = null;
    _originalOffsetY = null;
    _longPressCount = 0;
  }

  /// 执行单步偏移调整
  void _adjustOffsetStep(double deltaX, double deltaY, {bool isFirst = false}) {
    final content = widget.element['content'] as Map<String, dynamic>;
    final characterImages =
        content['characterImages'] as Map<String, dynamic>? ?? {};
    final imageInfo =
        characterImages['${widget.selectedCharIndex}'] as Map<String, dynamic>?;
    final transform = imageInfo?['transform'] as Map<String, dynamic>? ?? {};

    final currentOffsetX = (transform['offsetX'] as num?)?.toDouble() ?? 0.0;
    final currentOffsetY = (transform['offsetY'] as num?)?.toDouble() ?? 0.0;

    // 计算步长：初始较小，随着长按时间增加而加速
    double stepSize = 1.0;
    if (_longPressCount > 20) {
      stepSize = 3.0; // 长按2秒后加速
    } else if (_longPressCount > 10) {
      stepSize = 2.0; // 长按1秒后中等速度
    }

    final newOffsetX = currentOffsetX + (deltaX * stepSize);
    final newOffsetY = currentOffsetY + (deltaY * stepSize);

    // 限制偏移范围在合理区间内
    final clampedX = newOffsetX.clamp(-100.0, 100.0);
    final clampedY = newOffsetY.clamp(-100.0, 100.0);

    // 使用预览模式，不记录undo（只在最终停止时记录）
    if (isFirst) {
      widget.onTransformPropertyUpdateStart
          ?.call(widget.selectedCharIndex, 'offsetX', currentOffsetX);
      widget.onTransformPropertyUpdateStart
          ?.call(widget.selectedCharIndex, 'offsetY', currentOffsetY);
    }

    widget.onTransformPropertyUpdatePreview
        ?.call(widget.selectedCharIndex, 'offsetX', clampedX);
    widget.onTransformPropertyUpdatePreview
        ?.call(widget.selectedCharIndex, 'offsetY', clampedY);
  }

  /// 调整偏移量（保留原方法用于其他调用）
  void _adjustOffset(double deltaX, double deltaY) {
    final content = widget.element['content'] as Map<String, dynamic>;
    final characterImages =
        content['characterImages'] as Map<String, dynamic>? ?? {};
    final imageInfo =
        characterImages['${widget.selectedCharIndex}'] as Map<String, dynamic>?;
    final transform = imageInfo?['transform'] as Map<String, dynamic>? ?? {};

    final currentOffsetX = (transform['offsetX'] as num?)?.toDouble() ?? 0.0;
    final currentOffsetY = (transform['offsetY'] as num?)?.toDouble() ?? 0.0;

    final newOffsetX = currentOffsetX + deltaX;
    final newOffsetY = currentOffsetY + deltaY;

    // 限制偏移范围在合理区间内
    final clampedX = newOffsetX.clamp(-100.0, 100.0);
    final clampedY = newOffsetY.clamp(-100.0, 100.0);

    widget.onTransformPropertyChanged('offsetX', clampedX);
    widget.onTransformPropertyChanged('offsetY', clampedY);
  }

  /// 设置字符缩放并记录undo
  void _setCharacterScaleWithUndo(double newScale) {
    final content = widget.element['content'] as Map<String, dynamic>;
    final characterImages =
        content['characterImages'] as Map<String, dynamic>? ?? {};
    final imageInfo =
        characterImages['${widget.selectedCharIndex}'] as Map<String, dynamic>?;
    final transform = imageInfo?['transform'] as Map<String, dynamic>? ?? {};

    final currentScale =
        (transform['characterScale'] as num?)?.toDouble() ?? 1.0;

    if (currentScale != newScale) {
      developer.log(
          '设置字符缩放 - selectedCharIndex: ${widget.selectedCharIndex}, newScale: $newScale <- $currentScale',
          name: 'CharacterTransform');
      
      // 直接调用属性更新，然后使用优化的undo方法
      widget.onTransformPropertyChanged('characterScale', newScale);
      
      // 手动记录undo操作
      widget.onTransformPropertyUpdateWithUndo?.call(
          widget.selectedCharIndex, 'characterScale', newScale, currentScale);
    }
  }

  /// 重置变换并记录undo
  void _resetTransform() {
    final content = widget.element['content'] as Map<String, dynamic>;
    final characterImages =
        content['characterImages'] as Map<String, dynamic>? ?? {};
    final imageInfo =
        characterImages['${widget.selectedCharIndex}'] as Map<String, dynamic>?;
    final transform = imageInfo?['transform'] as Map<String, dynamic>? ?? {};

    final currentScale =
        (transform['characterScale'] as num?)?.toDouble() ?? 1.0;
    final currentOffsetX = (transform['offsetX'] as num?)?.toDouble() ?? 0.0;
    final currentOffsetY = (transform['offsetY'] as num?)?.toDouble() ?? 0.0;

    // 构建需要重置的属性和原始值
    Map<String, dynamic> changes = {};
    Map<String, dynamic> originalValues = {};
    
    if (currentScale != 1.0) {
      changes['characterScale'] = 1.0;
      originalValues['characterScale'] = currentScale;
    }
    if (currentOffsetX != 0.0) {
      changes['offsetX'] = 0.0;
      originalValues['offsetX'] = currentOffsetX;
    }
    if (currentOffsetY != 0.0) {
      changes['offsetY'] = 0.0;
      originalValues['offsetY'] = currentOffsetY;
    }

    // 如果有需要重置的属性，批量处理
    if (changes.isNotEmpty) {
      // 先更新UI
      for (String key in changes.keys) {
        widget.onTransformPropertyChanged(key, changes[key]);
      }
      
      // 然后使用批量undo记录操作
      if (widget.onTransformPropertiesBatchUndo != null) {
        widget.onTransformPropertiesBatchUndo!
            .call(widget.selectedCharIndex, changes, originalValues);
      } else {
        // 如果没有批量undo方法，分别记录
        for (String key in changes.keys) {
          widget.onTransformPropertyUpdateWithUndo?.call(
              widget.selectedCharIndex, key, changes[key], originalValues[key]);
        }
      }
    }
  }
}
