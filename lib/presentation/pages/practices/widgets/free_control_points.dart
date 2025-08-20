import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../widgets/practice/guideline_alignment/guideline_manager.dart';
import '../../../widgets/practice/guideline_alignment/guideline_types.dart';
import 'custom_cursors.dart';

/// 测试版本的控制点 - 独立移动，支持旋转操作
class FreeControlPoints extends StatefulWidget {
  final String elementId;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final double initialScale;

  // 添加回调函数，使其能够与控制器集成
  final Function(int, Offset)? onControlPointUpdate;
  final Function(int)? onControlPointDragStart;
  final Function(int)? onControlPointDragEnd;
  // 🔧 新增：传递最终状态的回调
  final Function(int, Map<String, double>)? onControlPointDragEndWithState;
  // 🔧 新增：参考线对齐回调
  final Function(List<Guideline>)? onGuidelinesUpdated;
  final AlignmentMode? alignmentMode;
  final VoidCallback? updateGuidelineManagerElements;
  const FreeControlPoints({
    Key? key,
    required this.elementId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    this.initialScale = 1.0,
    this.onControlPointUpdate,
    this.onControlPointDragStart,
    this.onControlPointDragEnd,
    this.onControlPointDragEndWithState,
    this.onGuidelinesUpdated,
    this.alignmentMode,
    this.updateGuidelineManagerElements,
  }) : super(key: key);

  @override
  State<FreeControlPoints> createState() => _FreeControlPointsState();
}

class _FreeControlPointsState extends State<FreeControlPoints> {
  // 🚀 性能优化：防止频繁日志输出的缓存
  static String? _lastUpdateLog;
  static DateTime? _lastUpdateTime;

  // 独立的控制点位置状态，不依赖元素位置
  final Map<int, Offset> _controlPointPositions = {};
  bool _isInitialized = false;
  // 独立的矩形属性 - 初始化后不再依赖widget属性
  double _currentX = 0.0;
  double _currentY = 0.0;
  double _currentWidth = 0.0;
  double _currentHeight = 0.0;
  double _currentRotation = 0.0;
  // 旋转相关状态
  Offset? _rotationCenter;
  double? _initialRotationAngle; // 🔧 新增：参考线对齐相关状态

  List<Guideline> _activeGuidelines = [];
  // 移动端手势支持
  bool _isMobile = false;
  bool _isMultiTouchActive = false;
  int _activePointerCount = 0;
  bool _platformDetected = false; // 🔧 新增：避免重复平台检测

  // 🔧 新增：当前拖拽控制点追踪，用于传递操作上下文
  int? _currentDraggingControlPoint;

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      EditPageLogger.canvasDebug('🔥 FreeControlPoints未初始化，跳过构建', data: {
        'elementId': widget.elementId,
      });
      return const SizedBox.shrink();
    }

    EditPageLogger.canvasDebug('🔥 FreeControlPoints构建中', data: {
      'elementId': widget.elementId,
      'controlPointCount': _controlPointPositions.length,
      'currentPosition': '($_currentX, $_currentY)',
      'currentSize': '($_currentWidth x $_currentHeight)',
    });

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.loose,
      children: [
        // 使用角落标记式边框绘制器
        CustomPaint(
          painter: _CornerMarksBorderPainter(
            x: _currentX,
            y: _currentY,
            width: _currentWidth,
            height: _currentHeight,
            rotation: _currentRotation * 180 / pi, // 使用当前旋转角度
            color: Colors.blue.withValues(alpha: 0.8), // 使用藍色邊框，類似字符採集頁
          ),
          size: Size.infinite,
        ),

        // 透明拖拽层 - 用于平移整个控制点组
        _buildTransparentDragLayer(),

        // 渲染所有控制点
        for (int i = 0; i < _controlPointPositions.length; i++)
          _buildTestControlPoint(i),
      ],
    );
  }

  @override
  void didUpdateWidget(FreeControlPoints oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🚀 性能优化：限制日志输出频率，避免日志洪水
    if (_isInitialized) {
      final now = DateTime.now();
      final updateKey =
          '${widget.elementId}_${widget.x}_${widget.y}_${widget.width}_${widget.height}_${widget.rotation}';

      // 只有在值真正变化或超过500ms时才输出日志
      if (_lastUpdateLog != updateKey ||
          _lastUpdateTime == null ||
          now.difference(_lastUpdateTime!).inMilliseconds > 500) {
        final hasPositionChange =
            oldWidget.x != widget.x || oldWidget.y != widget.y;
        final hasSizeChange = oldWidget.width != widget.width ||
            oldWidget.height != widget.height;
        final hasRotationChange = oldWidget.rotation != widget.rotation;

        // 只有在有实际变化时才输出DEBUG日志
        if (hasPositionChange || hasSizeChange || hasRotationChange) {
          EditPageLogger.editPageDebug('🔧 FreeControlPoints属性更新检测', data: {
            'elementId': widget.elementId,
            'position_changed': {
              'old_x': oldWidget.x,
              'new_x': widget.x,
              'old_y': oldWidget.y,
              'new_y': widget.y,
              'x_changed': hasPositionChange,
              'y_changed': hasPositionChange,
            },
            'size_changed': {
              'old_width': oldWidget.width,
              'new_width': widget.width,
              'old_height': oldWidget.height,
              'new_height': widget.height,
              'width_changed': hasSizeChange,
              'height_changed': hasSizeChange,
            },
            'rotation_changed': {
              'old_rotation': oldWidget.rotation,
              'new_rotation': widget.rotation,
              'rotation_changed': hasRotationChange,
            },
            'operation': 'free_control_points_update_analysis',
          });
        } else {
          // 无变化时使用INFO级别，减少DEBUG噪音
          EditPageLogger.editPageInfo('🔧 控制点更新（无变化）', data: {
            'elementId': widget.elementId,
            'optimization': 'skip_unchanged_update',
          });
        }

        _lastUpdateLog = updateKey;
        _lastUpdateTime = now;
      }
    }

    // 🔧 修复：控制点应该跟随元素位置变化，但只在不是自己触发的变化时
    // 检查是否是外部元素拖拽导致的位置变化（而不是控制点自己的resize/rotate操作）
    if (_isInitialized &&
        (widget.x != oldWidget.x || widget.y != oldWidget.y) &&
        (widget.width == oldWidget.width &&
            widget.height == oldWidget.height &&
            widget.rotation == oldWidget.rotation)) {
      // 这是一个纯粹的位置变化（平移），不是尺寸或旋转变化
      // 更新控制点位置以跟随元素移动
      final deltaX = widget.x - oldWidget.x;
      final deltaY = widget.y - oldWidget.y;

      EditPageLogger.editPageDebug('🔧 FreeControlPoints跟随元素平移', data: {
        'delta': '($deltaX, $deltaY)',
        'from': '(${oldWidget.x}, ${oldWidget.y})',
        'to': '(${widget.x}, ${widget.y})',
        'operation': 'free_control_points_follow_translation',
      });

      setState(() {
        _syncWithElementPosition(
            widget.x, widget.y, widget.width, widget.height, widget.rotation);
      });
    }
    // 🔧 修复：旋转撤销时需要更新控制点
    else if (_isInitialized && widget.rotation != oldWidget.rotation) {
      EditPageLogger.editPageDebug('🔧 FreeControlPoints检测到旋转变化', data: {
        'oldRotation': oldWidget.rotation,
        'newRotation': widget.rotation,
        'operation': 'free_control_points_rotation_change',
      });

      setState(() {
        _syncWithElementPosition(
            widget.x, widget.y, widget.width, widget.height, widget.rotation);
      });
    }
    // 如果是尺寸或旋转变化，保持控制点的独立状态，不响应widget变化
    else if (_isInitialized) {
      EditPageLogger.editPageDebug('🔧 FreeControlPoints保持独立状态', data: {
        'reason': '忽略外部尺寸变化或未初始化',
        'isInitialized': _isInitialized,
        'operation': 'free_control_points_ignore_change',
      });
    }
  }

  /// 获取当前计算出的元素属性（用于Commit阶段）
  Map<String, double> getCurrentElementProperties() {
    final result = {
      'x': _currentX,
      'y': _currentY,
      'width': _currentWidth,
      'height': _currentHeight,
      'rotation': _currentRotation * 180 / pi, // 转换为度数
    };

    EditPageLogger.canvasDebug('FreeControlPoints最终状态', data: {
      'currentState': result,
      'deltaFromInitial': {
        'x': _currentX - widget.x,
        'y': _currentY - widget.y,
        'width': _currentWidth - widget.width,
        'height': _currentHeight - widget.height,
        'rotation': _currentRotation * 180 / pi - widget.rotation,
      }
    });

    return result;
  }

  @override
  void initState() {
    super.initState();
    // 🔧 不在initState中进行控制点初始化，移至didChangeDependencies中
    // _initializeControlPointPositions(); // 移除，移至didChangeDependencies
    // 增加GuidelineManager状态检查日志
    EditPageLogger.editPageInfo('🔍【吸附调试】FreeControlPoints初始化', data: {
      'elementId': widget.elementId,
      'guidelineManagerEnabled': GuidelineManager.instance.enabled,
      'hasStaticGuidelines':
          GuidelineManager.instance.staticGuidelines.isNotEmpty,
      'alignmentMode': widget.alignmentMode?.toString() ?? 'null',
      'operation': 'free_control_points_init',
      'note': '控制点初始化将在didChangeDependencies中进行',
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 🔧 修復：簡化初始化邏輯，確保控制點能夠正常顯示
    if (!_isInitialized) {
      EditPageLogger.canvasDebug('開始控制點初始化流程', data: {
        'platformDetected': _platformDetected,
        'isInitialized': _isInitialized,
        'timing': 'didChangeDependencies',
      });

      // 如果還沒有檢測平台，先檢測
      if (!_platformDetected) {
        _isMobile = _detectMobilePlatformByUI();
        _platformDetected = true;
        EditPageLogger.canvasDebug('控制點平台檢測完成', data: {
          'isMobile': _isMobile,
          'detectionMethod': 'ui_based_detection_only',
          'screenWidth': MediaQuery.of(context).size.width,
          'screenHeight': MediaQuery.of(context).size.height,
          'devicePixelRatio': MediaQuery.of(context).devicePixelRatio,
        });
      }

      // 使用PostFrameCallback確保在渲染完成後初始化
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isInitialized) {
          try {
            _initializeControlPointPositions();

            // 強制觸發重建以顯示控制點
            if (mounted) {
              setState(() {});
            }

            EditPageLogger.canvasDebug('控制點初始化完成並觸發重建', data: {
              'isMobile': _isMobile,
              'platformDetected': _platformDetected,
              'isInitialized': _isInitialized,
              'controlPointCount': _controlPointPositions.length,
              'timing': 'postframe_callback',
            });
          } catch (e, stackTrace) {
            EditPageLogger.canvasError('控制點初始化失敗',
                error: e,
                stackTrace: stackTrace,
                data: {
                  'elementId': widget.elementId,
                  'operation': 'initialize_control_points',
                });
          }
        }
      });
    } else {
      EditPageLogger.canvasDebug('控制點已初始化，跳過重複初始化', data: {
        'isMobile': _isMobile,
        'platformDetected': _platformDetected,
        'isInitialized': _isInitialized,
        'controlPointCount': _controlPointPositions.length,
      });
    }
  }

  /// 基于UI特征的移动平台检测（完全避免Platform API）
  bool _detectMobilePlatformByUI() {
    try {
      final mediaQuery = MediaQuery.of(context);
      final screenSize = mediaQuery.size;
      final devicePixelRatio = mediaQuery.devicePixelRatio;
      final viewPadding = mediaQuery.viewPadding;

      // 移动设备的典型特征：
      // 1. 较小的屏幕宽度（通常 < 800px）
      // 2. 较高的像素密度（通常 > 1.5）
      // 3. 有状态栏/导航栏（viewPadding.top > 0）
      // 4. 屏幕宽高比通常更接近 16:9 或更窄

      final aspectRatio = screenSize.width / screenSize.height;
      final hasStatusBar = viewPadding.top > 0;
      final hasHighDensity = devicePixelRatio > 1.5;
      final hasSmallWidth = screenSize.width < 800;
      final hasMobileAspectRatio = aspectRatio < 1.5; // 移动设备通常是竖屏或接近方形

      // 组合判断：满足多个条件的设备很可能是移动设备
      int mobileScore = 0;
      if (hasSmallWidth) mobileScore += 3; // 小屏幕权重最高
      if (hasHighDensity) mobileScore += 2; // 高像素密度
      if (hasStatusBar) mobileScore += 2; // 有状态栏
      if (hasMobileAspectRatio) mobileScore += 1; // 移动设备宽高比

      final isMobile = mobileScore >= 4; // 分数阈值

      EditPageLogger.canvasDebug('UI特征移动设备检测', data: {
        'screenSize': '${screenSize.width}x${screenSize.height}',
        'devicePixelRatio': devicePixelRatio,
        'aspectRatio': aspectRatio.toStringAsFixed(2),
        'hasStatusBar': hasStatusBar,
        'hasHighDensity': hasHighDensity,
        'hasSmallWidth': hasSmallWidth,
        'hasMobileAspectRatio': hasMobileAspectRatio,
        'mobileScore': mobileScore,
        'isMobile': isMobile,
      });

      return isMobile;
    } catch (e) {
      // 最终回退：简单的屏幕宽度检测
      EditPageLogger.canvasDebug('UI检测失败，使用简单回退方案', data: {
        'error': e.toString(),
      });
      return MediaQuery.of(context).size.width < 600;
    }
  }

  /// 处理指针按下事件
  void _handlePointerDown(PointerDownEvent event) {
    _activePointerCount++;
    _isMultiTouchActive = _activePointerCount > 1;

    EditPageLogger.canvasDebug('控制点指针按下', data: {
      'pointerId': event.pointer,
      'activePointers': _activePointerCount,
      'isMultiTouch': _isMultiTouchActive,
      'isMobile': _isMobile,
    });
  }

  /// 处理指针释放事件
  void _handlePointerUp(PointerUpEvent event) {
    _activePointerCount = max(0, _activePointerCount - 1);
    if (_activePointerCount <= 1) {
      _isMultiTouchActive = false;
    }

    EditPageLogger.canvasDebug('控制点指针释放', data: {
      'pointerId': event.pointer,
      'activePointers': _activePointerCount,
      'isMultiTouch': _isMultiTouchActive,
    });
  }

  /// 🔧 新增：对齐到最近的参考线（仅在鼠标释放时调用，只在距离很近时对齐）
  Map<String, double> _alignToClosestGuidelines(
    Map<String, double> currentProperties, {
    String operationType = 'translate',
    String? resizeDirection,
  }) {
    EditPageLogger.editPageInfo('🔍【吸附调试】开始执行参考线吸附对齐', data: {
      'alignmentMode': widget.alignmentMode?.toString() ?? 'null',
      'elementId': widget.elementId,
      'currentPosition':
          '(${currentProperties['x']}, ${currentProperties['y']})',
      'currentSize':
          '(${currentProperties['width']} x ${currentProperties['height']})',
      'operationType': operationType,
      'resizeDirection': resizeDirection,
      'operation': 'guideline_alignment_debug',
    });

    // 只在参考线对齐模式下执行对齐，如果未设置alignmentMode，默认启用参考线对齐
    if (widget.alignmentMode != null &&
        widget.alignmentMode != AlignmentMode.guideline) {
      EditPageLogger.editPageInfo('🚫【吸附调试】不在参考线对齐模式，跳过对齐', data: {
        'alignmentMode': widget.alignmentMode.toString(),
        'operation': 'guideline_alignment_skip',
      });
      return currentProperties;
    }

    // 检查GuidelineManager状态
    final isEnabled = GuidelineManager.instance.enabled;
    final hasStaticGuidelines =
        GuidelineManager.instance.staticGuidelines.isNotEmpty;

    EditPageLogger.editPageInfo('✅【吸附调试】符合参考线对齐条件，检查GuidelineManager状态', data: {
      'guidelineManagerEnabled': isEnabled,
      'hasStaticGuidelines': hasStaticGuidelines,
      'activeGuidelines': _activeGuidelines.length,
      'operation': 'guideline_manager_state_check',
    });

    if (!isEnabled) {
      EditPageLogger.editPageWarning('⚠️【吸附调试】GuidelineManager未启用，跳过对齐',
          data: {'operation': 'skip_alignment_manager_disabled'});
      return currentProperties;
    }

    // 确保GuidelineManager有必要的初始化
    if (widget.updateGuidelineManagerElements != null) {
      EditPageLogger.editPageInfo('🔄【吸附调试】强制更新GuidelineManager元素');
      widget.updateGuidelineManagerElements!();
    }

    // 如果没有静态参考线，尝试重新生成
    if (!hasStaticGuidelines) {
      EditPageLogger.editPageInfo('🔄【吸附调试】没有静态参考线，尝试重新生成');
      // 获取当前位置和大小
      final currentPos =
          Offset(currentProperties['x']!, currentProperties['y']!);
      final currentSize =
          Size(currentProperties['width']!, currentProperties['height']!);

      try {
        GuidelineManager.instance.updateGuidelinesLive(
          elementId: widget.elementId,
          draftPosition: currentPos,
          elementSize: currentSize,
          regenerateStatic: true,
          operationType: operationType,
          resizeDirection: resizeDirection,
        );

        EditPageLogger.editPageInfo('✅【吸附调试】重新生成静态参考线成功', data: {
          'staticGuidelinesCount':
              GuidelineManager.instance.staticGuidelines.length,
          'operation': 'regenerate_static_guidelines',
        });
      } catch (e) {
        EditPageLogger.editPageError('❌【吸附调试】重新生成静态参考线失败',
            data: {
              'error': e.toString(),
              'operation': 'regenerate_static_guidelines_failed',
            },
            error: e);
      }
    }

    // 🔧 使用新的 performAlignment 方法执行吸附对齐（只在鼠标释放时调用）
    Map<String, dynamic> alignmentResult;
    try {
      // 🔧 在调用对齐之前，先检查高亮参考线的状态
      final highlightedGuidelines =
          GuidelineManager.instance.highlightedGuidelines;
      final dynamicGuidelines = GuidelineManager.instance.dynamicGuidelines;
      final staticGuidelines = GuidelineManager.instance.staticGuidelines;

      EditPageLogger.editPageInfo('🔍【吸附调试】准备执行对齐，检查参考线状态', data: {
        'staticGuidelinesCount': staticGuidelines.length,
        'dynamicGuidelinesCount': dynamicGuidelines.length,
        'highlightedGuidelinesCount': highlightedGuidelines.length,
        'highlightedGuidelines': highlightedGuidelines
            .map((g) => {
                  'id': g.id,
                  'type': g.type.toString(),
                  'direction': g.direction.toString(),
                  'position': g.position,
                })
            .toList(),
        'operation': 'pre_alignment_guideline_check',
      });

      alignmentResult = GuidelineManager.instance.performAlignment(
        elementId: widget.elementId,
        currentPosition:
            Offset(currentProperties['x']!, currentProperties['y']!),
        elementSize:
            Size(currentProperties['width']!, currentProperties['height']!),
        operationType: operationType,
        resizeDirection: resizeDirection,
      );

      // 打印详细的对齐结果
      EditPageLogger.editPageInfo('📊【吸附调试】performAlignment返回结果', data: {
        'hasAlignment': alignmentResult['hasAlignment'],
        'position': alignmentResult['position'].toString(),
        'size': alignmentResult['size'].toString(),
        'alignmentInfo': alignmentResult['alignmentInfo'],
        'operation': 'guideline_alignment_result',
      });
    } catch (e) {
      EditPageLogger.editPageError('❌【吸附调试】执行吸附对齐时发生异常',
          data: {
            'error': e.toString(),
            'operation': 'perform_alignment_exception',
          },
          error: e);
      return currentProperties; // 发生异常时返回原始属性
    }

    Map<String, double> alignedProperties = Map.from(currentProperties);

    if (alignmentResult['hasAlignment'] == true) {
      final alignedPosition = alignmentResult['position'] as Offset;
      final alignedSize = alignmentResult['size'] as Size;

      alignedProperties['x'] = alignedPosition.dx;
      alignedProperties['y'] = alignedPosition.dy;
      alignedProperties['width'] = alignedSize.width;
      alignedProperties['height'] = alignedSize.height;

      EditPageLogger.editPageInfo(
        '🎯【吸附调试】参考线吸附成功，应用对齐结果',
        data: {
          'elementId': widget.elementId,
          'operationType': operationType,
          'resizeDirection': resizeDirection,
          'originalPosition':
              '(${currentProperties['x']}, ${currentProperties['y']})',
          'alignedPosition': '(${alignedPosition.dx}, ${alignedPosition.dy})',
          'originalSize':
              '(${currentProperties['width']}, ${currentProperties['height']})',
          'alignedSize': '(${alignedSize.width}, ${alignedSize.height})',
          'deltaPosition':
              '(${alignedPosition.dx - currentProperties['x']!}, ${alignedPosition.dy - currentProperties['y']!})',
          'deltaSize':
              '(${alignedSize.width - currentProperties['width']!}, ${alignedSize.height - currentProperties['height']!})',
          'operation': 'guideline_alignment_applied',
        },
      );
    } else {
      EditPageLogger.editPageInfo('🚫【吸附调试】未找到可对齐的参考线', data: {
        'elementId': widget.elementId,
        'operation': 'guideline_alignment_not_found',
      });
    }

    // 🔧 清除所有参考线（对齐完成后不再需要显示）
    // 注意：这个清除逻辑移到了调用方，避免在对齐过程中过早清除高亮参考线
    // if (_activeGuidelines.isNotEmpty) {
    //   _activeGuidelines = <Guideline>[];
    //   widget.onGuidelinesUpdated?.call([]);
    //   EditPageLogger.editPageInfo('🧹【吸附调试】清除所有参考线');
    // }

    return alignedProperties;
  }

  /// 构建测试控制点 - 独立移动，不更新元素
  Widget _buildTestControlPoint(int index) {
    final position = _controlPointPositions[index]!;

    // 🔧 分離觸摸區域和可視區域的尺寸
    // 觸摸區域根據平台優化，提高操作容錯性
    final double touchAreaSize = _isMobile ? 56.0 : 32.0; // 移動端更大的觸摸區域

    String controlPointName = _getControlPointName(index);
    MouseCursor cursor = _getControlPointCursor(index);
    bool isRotation = index == 8;

    // 如果是旋转控制点，保留可视化的旋转图标
    Widget? child;
    if (isRotation) {
      child = Container(
        width: 16.0,
        height: 16.0,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.blue,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              spreadRadius: 1.0,
              blurRadius: 2.0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(
          Icons.rotate_right,
          size: 10,
          color: Colors.blue,
        ),
      );
    }

    return Positioned(
      left: position.dx - touchAreaSize / 2,
      top: position.dy - touchAreaSize / 2,
      width: touchAreaSize,
      height: touchAreaSize,
      child: Material(
        color: Colors.transparent,
        child: Listener(
          onPointerDown: _handlePointerDown,
          onPointerUp: _handlePointerUp,
          child: MouseRegion(
            cursor: cursor,
            opaque: true,
            hitTestBehavior: HitTestBehavior.opaque,
            child: GestureDetector(
              // 移动端优化：调整手势行为
              behavior: _isMobile
                  ? HitTestBehavior.translucent
                  : HitTestBehavior.opaque,
              onTapDown: (details) {
                // 移动端：如果是多指手势，不处理tapDown
                if (_isMobile && _isMultiTouchActive) return;

                EditPageLogger.canvasDebug('🔥 控制点手势检测 - TapDown', data: {
                  'index': index,
                  'localPosition': '${details.localPosition}',
                  'globalPosition': '${details.globalPosition}',
                  'isMobile': _isMobile,
                  'isMultiTouch': _isMultiTouchActive,
                });
              },
              onPanStart: (details) {
                // 移动端：如果是多指手势，不处理单指拖拽
                if (_isMobile && _isMultiTouchActive) return;
                EditPageLogger.canvasDebug('🔥 FreeControlPoints拖拽开始', data: {
                  'index': index,
                  'controlPointName': controlPointName,
                  'localPosition': '${details.localPosition}',
                  'globalPosition': '${details.globalPosition}',
                });

                // 🔧 设置当前拖拽控制点
                _currentDraggingControlPoint = index;

                if (index == 8) {
                  // 旋转控制点 - 初始化旋转状态
                  _initializeRotationState();
                } // 触发拖拽开始回调
                widget.onControlPointDragStart?.call(index);

                // 🔹 设置GuidelineManager的拖拽状态为true
                GuidelineManager.instance.isDragging = true;

                // 🔹 初始化动态参考线显示
                _initializeDynamicGuidelines();
              },
              onPanUpdate: (details) {
                setState(() {
                  // 先更新控制点位置
                  _updateControlPointWithConstraints(index, details.delta);
                });

                // 在setState完成后立即刷新参考线
                _refreshGuidelinesImmediately();
              },
              onPanEnd: (details) {
                EditPageLogger.editPageInfo('控制点结束拖拽', data: {
                  'index': index,
                  'controlPointName': controlPointName,
                  'operation': 'control_point_drag_end',
                });

                // 🔧 在鼠标释放时进行参考线对齐（在清除参考线之前）
                var finalProperties = getCurrentElementProperties();
                EditPageLogger.editPageInfo('🔄【吸附调试】拖拽结束，获取当前属性', data: {
                  'x': finalProperties['x'],
                  'y': finalProperties['y'],
                  'width': finalProperties['width'],
                  'height': finalProperties['height'],
                  'operation': 'prepare_for_alignment',
                });

                finalProperties = _alignToClosestGuidelines(
                  finalProperties,
                  operationType:
                      _isResizeOperation(index) ? 'resize' : 'translate',
                  resizeDirection: _getResizeDirection(index),
                );

                // 🔧 拖拽结束后清除所有参考线
                _clearGuidelines();

                // 🔹 设置GuidelineManager的拖拽状态为false
                GuidelineManager.instance.isDragging = false;

                // 🔧 如果对齐后位置或尺寸有变化，需要更新控制点位置
                if (finalProperties['x'] != _currentX ||
                    finalProperties['y'] != _currentY ||
                    finalProperties['width'] != _currentWidth ||
                    finalProperties['height'] != _currentHeight) {
                  EditPageLogger.editPageInfo('🔄【吸附调试】检测到吸附修改，更新控制点位置', data: {
                    'from':
                        '($_currentX, $_currentY, $_currentWidth x $_currentHeight)',
                    'to':
                        '(${finalProperties['x']}, ${finalProperties['y']}, ${finalProperties['width']} x ${finalProperties['height']})',
                    'operation': 'update_control_points_after_alignment',
                  });

                  setState(() {
                    _currentX = finalProperties['x']!;
                    _currentY = finalProperties['y']!;
                    _currentWidth = finalProperties['width']!;
                    _currentHeight = finalProperties['height']!;
                    _recalculateControlPointPositions();
                  });

                  EditPageLogger.editPageInfo('🎯【吸附调试】FreeControlPoints应用对齐吸附',
                      data: {
                        'elementId': widget.elementId,
                        'beforeAlignment': {
                          'x': getCurrentElementProperties()['x'],
                          'y': getCurrentElementProperties()['y'],
                          'width': getCurrentElementProperties()['width'],
                          'height': getCurrentElementProperties()['height'],
                        },
                        'afterAlignment': finalProperties,
                        'operationType':
                            _isResizeOperation(index) ? 'resize' : 'translate',
                        'resizeDirection': _getResizeDirection(index),
                        'operation': 'alignment_applied',
                      });
                } else {
                  EditPageLogger.editPageInfo('⚠️【吸附调试】吸附无效果，位置和尺寸没有变化', data: {
                    'position': '($_currentX, $_currentY)',
                    'size': '($_currentWidth x $_currentHeight)',
                    'operation': 'alignment_no_effect',
                  });
                }

                // 🔧 修复时序：先传递最终计算的状态（已对齐），再触发Commit阶段
                widget.onControlPointDragEndWithState
                    ?.call(index, finalProperties);

                // 然后触发拖拽结束回调（触发Commit阶段）
                widget.onControlPointDragEnd?.call(index);

                // 🔧 清除当前拖拽控制点状态
                _currentDraggingControlPoint = null;
              },
              child: Container(
                width: touchAreaSize,
                height: touchAreaSize,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: child != null
                    ? Center(child: child) // 旋转控制点显示图标
                    : null, // 其他控制点不显示任何可视元素
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建透明拖拽层 - 用于平移整个控制点组
  /// 🔧 新架构：以控制点为主导，让DragPreviewLayer跟随控制点状态
  Widget _buildTransparentDragLayer() {
    // 使用当前独立的矩形尺寸，不受旋转影响
    const padding = 5.0;
    final dragWidth = _currentWidth + padding * 2;
    final dragHeight = _currentHeight + padding * 2;

    // 计算旋转中心位置
    final centerX = _currentX + _currentWidth / 2;
    final centerY = _currentY + _currentHeight / 2;

    // 计算拖拽层的左上角位置（相对于旋转中心）
    final dragLeft = centerX - dragWidth / 2;
    final dragTop = centerY - dragHeight / 2;

    return Positioned(
      left: dragLeft,
      top: dragTop,
      width: dragWidth,
      height: dragHeight,
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerUp: _handlePointerUp,
        child: MouseRegion(
          cursor: SystemMouseCursors.move,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (details) {
              // 移动端：如果是多指手势，不处理单指拖拽
              if (_isMobile && _isMultiTouchActive) return;

              EditPageLogger.canvasDebug('控制点主导：开始平移操作', data: {
                'isMobile': _isMobile,
                'isMultiTouch': _isMultiTouchActive,
              });
              // 清除之前的参考线
              _clearGuidelines();

              // 🔹 设置GuidelineManager的拖拽状态为true
              GuidelineManager.instance.isDragging = true;

              // 🔹 初始化动态参考线显示
              _initializeDynamicGuidelines();

              // 🔧 关键：通知Canvas开始拖拽，以控制点为主导
              widget.onControlPointDragStart?.call(-1); // -1表示平移操作
            },
            onPanUpdate: (details) {
              // 移动端：如果是多指手势，不处理单指拖拽
              if (_isMobile && _isMultiTouchActive) return;

              setState(() {
                _translateAllControlPoints(details.delta);
              });

              // 在setState完成后强制立即刷新参考线，确保每次移动都更新
              _refreshGuidelinesImmediately();
            },
            onPanEnd: (details) {
              EditPageLogger.editPageInfo('🔄【吸附调试】平移操作结束', data: {
                'operation': 'translate_end',
              });

              // 在鼠标释放时进行参考线对齐（在清除参考线之前）
              var finalProperties = getCurrentElementProperties();
              finalProperties = _alignToClosestGuidelines(
                finalProperties,
                operationType: 'translate', // 拖拽整体移动操作
                resizeDirection: null,
              );

              // 拖拽结束后清除所有参考线
              _clearGuidelines();

              // 设置GuidelineManager的拖拽状态为false
              GuidelineManager.instance.isDragging = false;

              // 🔧 如果对齐后位置或尺寸有变化，需要更新控制点位置
              if (finalProperties['x'] != _currentX ||
                  finalProperties['y'] != _currentY ||
                  finalProperties['width'] != _currentWidth ||
                  finalProperties['height'] != _currentHeight) {
                setState(() {
                  _currentX = finalProperties['x']!;
                  _currentY = finalProperties['y']!;
                  _currentWidth = finalProperties['width']!;
                  _currentHeight = finalProperties['height']!;
                  _recalculateControlPointPositions();
                });

                EditPageLogger.editPageInfo('🎯【吸附调试】FreeControlPoints应用平移对齐吸附',
                    data: {
                      'elementId': widget.elementId,
                      'beforeAlignment': {
                        'x': _currentX,
                        'y': _currentY,
                      },
                      'afterAlignment': {
                        'x': finalProperties['x'],
                        'y': finalProperties['y'],
                      },
                      'operation': 'apply_translation_alignment',
                    });
              } else {
                EditPageLogger.editPageInfo('🚫【吸附调试】平移对齐无变化', data: {
                  'currentPosition': '($_currentX, $_currentY)',
                  'alignedPosition':
                      '(${finalProperties['x']}, ${finalProperties['y']})',
                  'operation': 'no_translation_alignment_change',
                });
              }

              // 🔧 传递最终状态（已对齐）
              widget.onControlPointDragEndWithState?.call(-1, finalProperties);

              // 触发Commit阶段
              widget.onControlPointDragEnd?.call(-1);
            },
            child: Container(
              width: dragWidth,
              height: dragHeight,
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Rect? _calculateCurrentRectFromControlPoints() {
    // 简化：使用左上角和右下角控制点计算
    final topLeft = _controlPointPositions[0];
    final bottomRight = _controlPointPositions[4];

    if (topLeft == null || bottomRight == null) return null;

    // 由于控制点现在在内部，需要向外扩展8像素来获得真实的元素边界
    const offset = 8.0;
    return Rect.fromLTRB(
      topLeft.dx - offset,
      topLeft.dy - offset,
      bottomRight.dx + offset,
      bottomRight.dy + offset,
    );
  }

  /// 🔧 新增：清除参考线
  void _clearGuidelines() {
    if (_activeGuidelines.isNotEmpty) {
      setState(() {
        _activeGuidelines =
            <Guideline>[]; // Create new empty list instead of clearing
      });
      widget.onGuidelinesUpdated?.call([]);
    }
  }

  MouseCursor _getControlPointCursor(int index) {
    switch (index) {
      case 0:
        return CustomCursors.resizeTopLeft;
      case 1:
        return CustomCursors.resizeTop;
      case 2:
        return CustomCursors.resizeTopRight;
      case 3:
        return CustomCursors.resizeRight;
      case 4:
        return CustomCursors.resizeBottomRight;
      case 5:
        return CustomCursors.resizeBottom;
      case 6:
        return CustomCursors.resizeBottomLeft;
      case 7:
        return CustomCursors.resizeLeft;
      case 8:
        return CustomCursors.rotate;
      default:
        return SystemMouseCursors.basic;
    }
  }

  String _getControlPointName(int index) {
    switch (index) {
      case 0:
        return '左上角';
      case 1:
        return '上中';
      case 2:
        return '右上角';
      case 3:
        return '右中';
      case 4:
        return '右下角';
      case 5:
        return '下中';
      case 6:
        return '左下角';
      case 7:
        return '左中';
      case 8:
        return '旋转';
      default:
        return '未知';
    }
  }

  /// 获取Resize方向
  String? _getResizeDirection(int controlPointIndex) {
    if (!_isResizeOperation(controlPointIndex)) return null;

    switch (controlPointIndex) {
      case 0:
        return 'top-left'; // 左上角
      case 1:
        return 'top'; // 上中
      case 2:
        return 'top-right'; // 右上角
      case 3:
        return 'right'; // 右中
      case 4:
        return 'bottom-right'; // 右下角
      case 5:
        return 'bottom'; // 下中
      case 6:
        return 'bottom-left'; // 左下角
      case 7:
        return 'left'; // 左中
      default:
        return null;
    }
  }

  /// 初始化控制点位置 - 基于元素的初始位置和大小
  void _initializeControlPointPositions() {
    // 从widget获取初始状态，后续独立管理
    _currentX = widget.x;
    _currentY = widget.y;
    _currentWidth = widget.width;
    _currentHeight = widget.height;
    _currentRotation = widget.rotation * pi / 180;

    final centerX = _currentX + _currentWidth / 2;
    final centerY = _currentY + _currentHeight / 2;

    // 初始化旋转中心
    _rotationCenter = Offset(centerX, centerY);

    const offset = 8.0; // 控制点内偏移量 - 现在向内偏移

    // 🔧 移动端优化：旋转控制点距离调整
    final rotationOffset = _isMobile ? 120.0 : 80.0; // 移动端增加距离避免误触

    final unrotatedPositions = [
      // 索引0: 左上角 - 移动到元素内部
      Offset(_currentX + offset, _currentY + offset),
      // 索引1: 上中 - 移动到元素内部
      Offset(_currentX + _currentWidth / 2, _currentY + offset),
      // 索引2: 右上角 - 移动到元素内部
      Offset(_currentX + _currentWidth - offset, _currentY + offset),
      // 索引3: 右中 - 移动到元素内部
      Offset(
          _currentX + _currentWidth - offset, _currentY + _currentHeight / 2),
      // 索引4: 右下角 - 移动到元素内部
      Offset(_currentX + _currentWidth - offset,
          _currentY + _currentHeight - offset),
      // 索引5: 下中 - 移动到元素内部
      Offset(
          _currentX + _currentWidth / 2, _currentY + _currentHeight - offset),
      // 索引6: 左下角 - 移动到元素内部
      Offset(_currentX + offset, _currentY + _currentHeight - offset),
      // 索引7: 左中 - 移动到元素内部
      Offset(_currentX + offset, _currentY + _currentHeight / 2),
      // 索引8: 旋转控制点 - 保持在元素外部以便操作
      Offset(centerX, _currentY - rotationOffset),
    ];

    // 应用旋转并保存位置
    for (int i = 0; i < unrotatedPositions.length; i++) {
      final rotated = _rotatePoint(
        unrotatedPositions[i].dx,
        unrotatedPositions[i].dy,
        centerX,
        centerY,
        _currentRotation,
      );
      _controlPointPositions[i] = rotated;
    }

    _isInitialized = true;

    EditPageLogger.canvasDebug('控制点初始化完成', data: {
      'position': '($_currentX, $_currentY)',
      'size': '($_currentWidth, $_currentHeight)',
      'rotation': '${_currentRotation * 180 / pi}°',
    });
  }

  /// 🔹 新增：初始化动态参考线显示
  void _initializeDynamicGuidelines() {
    // 确保清空之前的任何参考线
    _clearGuidelines();

    // 只在参考线对齐模式下处理
    if (widget.alignmentMode != AlignmentMode.guideline) {
      EditPageLogger.editPageInfo('🚫【吸附调试】不在参考线对齐模式，跳过初始化参考线', data: {
        'alignmentMode': widget.alignmentMode?.toString() ?? 'null',
        'operation': 'skip_dynamic_guidelines_init',
      });
      return;
    }

    // 检查GuidelineManager的状态
    final isEnabled = GuidelineManager.instance.enabled;
    final hasStaticGuidelines =
        GuidelineManager.instance.staticGuidelines.isNotEmpty;

    EditPageLogger.editPageInfo('🔍【吸附调试】GuidelineManager状态检查', data: {
      'enabled': isEnabled,
      'hasStaticGuidelines': hasStaticGuidelines,
      'operation': 'check_guideline_manager_state',
    });

    if (!isEnabled) {
      EditPageLogger.editPageWarning('⚠️【吸附调试】GuidelineManager未启用，无法生成参考线',
          data: {'operation': 'guideline_manager_disabled'});
      return;
    }

    // 如果没有静态参考线，尝试更新元素
    if (!hasStaticGuidelines && widget.updateGuidelineManagerElements != null) {
      EditPageLogger.editPageInfo('🔄【吸附调试】GuidelineManager没有静态参考线，尝试更新元素');
      widget.updateGuidelineManagerElements!();
    }

    // 设置GuidelineManager为拖拽状态
    GuidelineManager.instance.isDragging = true;

    // 强制立即刷新参考线，确保初始状态正确（重新生成静态参考线）
    _refreshGuidelinesWithStaticRegeneration();

    EditPageLogger.editPageInfo('🔧【吸附调试】初始化动态参考线完成', data: {
      'elementId': widget.elementId,
      'guidelinesCount': _activeGuidelines.length,
      'operation': 'init_dynamic_guidelines_completed',
    });
  }

  /// 初始化旋转状态
  void _initializeRotationState() {
    // 计算矩形中心作为旋转中心
    final currentRect = _calculateCurrentRectFromControlPoints();
    if (currentRect != null) {
      _rotationCenter = currentRect.center;

      // 计算初始角度
      final rotationPoint = _controlPointPositions[8]!;
      _initialRotationAngle = atan2(
        rotationPoint.dy - _rotationCenter!.dy,
        rotationPoint.dx - _rotationCenter!.dx,
      );
    }
  }

  /// 判断是否为Resize操作
  bool _isResizeOperation(int controlPointIndex) {
    // -1 表示平移操作，8 表示旋转操作，其他为resize操作
    return controlPointIndex != -1 && controlPointIndex != 8;
  }

  /// 重新计算控制点位置
  void _recalculateControlPointPositions() {
    const offset = 8.0; // 控制点内偏移量 - 现在向内偏移

    // 🔧 移动端优化：旋转控制点距离调整
    final rotationOffset = _isMobile ? 120.0 : 80.0; // 移动端增加距离避免误触

    final centerX = _currentX + _currentWidth / 2;
    final centerY = _currentY + _currentHeight / 2;

    final unrotatedPositions = [
      // 索引0: 左上角 - 移动到元素内部
      Offset(_currentX + offset, _currentY + offset),
      // 索引1: 上中 - 移动到元素内部
      Offset(_currentX + _currentWidth / 2, _currentY + offset),
      // 索引2: 右上角 - 移动到元素内部
      Offset(_currentX + _currentWidth - offset, _currentY + offset),
      // 索引3: 右中 - 移动到元素内部
      Offset(
          _currentX + _currentWidth - offset, _currentY + _currentHeight / 2),
      // 索引4: 右下角 - 移动到元素内部
      Offset(_currentX + _currentWidth - offset,
          _currentY + _currentHeight - offset),
      // 索引5: 下中 - 移动到元素内部
      Offset(
          _currentX + _currentWidth / 2, _currentY + _currentHeight - offset),
      // 索引6: 左下角 - 移动到元素内部
      Offset(_currentX + offset, _currentY + _currentHeight - offset),
      // 索引7: 左中 - 移动到元素内部
      Offset(_currentX + offset, _currentY + _currentHeight / 2),
      // 索引8: 旋转控制点 - 保持在元素外部以便操作
      Offset(centerX, _currentY - rotationOffset),
    ];

    // 应用旋转并保存位置
    for (int i = 0; i < unrotatedPositions.length; i++) {
      final rotated = _rotatePoint(
        unrotatedPositions[i].dx,
        unrotatedPositions[i].dy,
        centerX,
        centerY,
        _currentRotation,
      );
      _controlPointPositions[i] = rotated;
    }
  }

  // 添加一个强制刷新参考线的方法
  void _refreshGuidelinesImmediately() {
    // 获取最新状态
    final currentState = getCurrentElementProperties();

    // 清除现有参考线
    _activeGuidelines = [];

    // 强制生成新参考线
    try {
      if (widget.alignmentMode == AlignmentMode.guideline &&
          GuidelineManager.instance.enabled) {
        // 直接从元素属性重新生成参考线
        final currentPos = Offset(currentState['x']!, currentState['y']!);
        final currentSize =
            Size(currentState['width']!, currentState['height']!);
        final rotation = currentState['rotation']!;

        EditPageLogger.editPageInfo('🔄【吸附调试】刷新动态参考线', data: {
          'elementId': widget.elementId,
          'currentPos': '${currentPos.dx}, ${currentPos.dy}',
          'currentSize': '${currentSize.width} x ${currentSize.height}',
          'rotation': rotation,
          'isDragging': GuidelineManager.instance.isDragging,
          'operation': 'refresh_guidelines',
        });

        // 🔧 使用实时参考线生成方法，在拖拽过程中不重新生成静态参考线
        GuidelineManager.instance.updateGuidelinesLive(
          elementId: widget.elementId,
          draftPosition: currentPos,
          elementSize: currentSize,
          regenerateStatic: false, // 🔧 拖拽过程中不重新生成静态参考线
          operationType: _currentDraggingControlPoint != null
              ? (_isResizeOperation(_currentDraggingControlPoint!)
                  ? 'resize'
                  : 'translate')
              : 'translate',
          resizeDirection: _currentDraggingControlPoint != null
              ? _getResizeDirection(_currentDraggingControlPoint!)
              : null,
        );

        // 获取生成的参考线
        final dynamicGuidelines = GuidelineManager.instance.activeGuidelines;

        EditPageLogger.editPageInfo('🔄【吸附调试】获取动态参考线', data: {
          'guidelineCount': dynamicGuidelines.length,
          'guidelineTypes': dynamicGuidelines.map((g) => g.type.name).toList(),
          'operation': 'get_dynamic_guidelines',
        });

        // 处理生成的参考线
        if (dynamicGuidelines.isNotEmpty) {
          // 直接使用生成的参考线
          _activeGuidelines = dynamicGuidelines;

          // 强制通知外部更新参考线
          if (widget.onGuidelinesUpdated != null) {
            widget.onGuidelinesUpdated!(dynamicGuidelines);

            EditPageLogger.editPageInfo('✅【吸附调试】成功刷新动态参考线UI', data: {
              'guidelinesCount': dynamicGuidelines.length,
              'elementId': widget.elementId,
              'elementPosition': '(${currentPos.dx}, ${currentPos.dy})',
              'guidelineTypes':
                  dynamicGuidelines.map((g) => g.type.name).toList(),
              'operation': 'update_guidelines_ui',
            });
          } else {
            EditPageLogger.editPageWarning('⚠️【吸附调试】无法更新参考线UI，回调为null',
                data: {'operation': 'missing_guidelines_callback'});
          }
        } else {
          // 没有找到对齐点，清除参考线
          if (_activeGuidelines.isNotEmpty) {
            _activeGuidelines = [];
            widget.onGuidelinesUpdated?.call([]);
            EditPageLogger.editPageInfo('🧹【吸附调试】清除参考线（无匹配的参考线）',
                data: {'operation': 'clear_guidelines_no_match'});
          }
        }
      } else {
        EditPageLogger.editPageInfo('⚠️【吸附调试】参考线不可用', data: {
          'alignmentMode': widget.alignmentMode?.toString() ?? 'null',
          'guidelineManagerEnabled': GuidelineManager.instance.enabled,
          'operation': 'guidelines_unavailable',
        });
      }
    } catch (e) {
      EditPageLogger.editPageError('❌【吸附调试】刷新参考线失败',
          data: {
            'error': e.toString(),
            'elementId': widget.elementId,
            'operation': 'refresh_guidelines_error',
          },
          error: e);
    }

    // 推送元素状态更新到预览层（但CanvasControlPointHandlers不会覆盖参考线）
    if (widget.onControlPointDragEndWithState != null) {
      widget.onControlPointDragEndWithState!(-2, currentState);
    }
  }

  // 添加一个强制刷新参考线的方法（在拖拽开始时调用，重新生成静态参考线）
  void _refreshGuidelinesWithStaticRegeneration() {
    // 获取最新状态
    final currentState = getCurrentElementProperties();

    // 清除现有参考线
    _activeGuidelines = [];

    // 强制生成新参考线
    try {
      if (widget.alignmentMode == AlignmentMode.guideline &&
          GuidelineManager.instance.enabled) {
        // 先检查GuidelineManager状态
        final hasStaticGuidelines =
            GuidelineManager.instance.staticGuidelines.isNotEmpty;
        if (!hasStaticGuidelines &&
            widget.updateGuidelineManagerElements != null) {
          EditPageLogger.editPageInfo('🔄【吸附调试】重新生成参考线前更新元素');
          widget.updateGuidelineManagerElements!();
        }

        // 直接从元素属性重新生成参考线
        final currentPos = Offset(currentState['x']!, currentState['y']!);
        final currentSize =
            Size(currentState['width']!, currentState['height']!);

        EditPageLogger.editPageInfo('🔄【吸附调试】开始刷新静态和动态参考线', data: {
          'elementId': widget.elementId,
          'currentPos': '${currentPos.dx}, ${currentPos.dy}',
          'currentSize': '${currentSize.width} x ${currentSize.height}',
          'hasStaticGuidelines':
              GuidelineManager.instance.staticGuidelines.isNotEmpty,
          'isDragging': GuidelineManager.instance.isDragging,
          'operation': 'refresh_all_guidelines',
        });

        // 尝试重新生成静态参考线
        try {
          // 🔧 使用实时参考线生成方法，在拖拽开始时重新生成静态参考线
          GuidelineManager.instance.updateGuidelinesLive(
            elementId: widget.elementId,
            draftPosition: currentPos,
            elementSize: currentSize,
            regenerateStatic: true, // 🔧 重新生成静态参考线
          );

          // 记录静态参考线生成过程
          EditPageLogger.editPageInfo('✅【吸附调试】静态参考线生成成功', data: {
            'staticGuidelinesCount':
                GuidelineManager.instance.staticGuidelines.length,
            'operation': 'static_guidelines_generated',
          });
        } catch (e) {
          EditPageLogger.editPageError('❌【吸附调试】静态参考线生成失败',
              data: {
                'error': e.toString(),
                'elementId': widget.elementId,
                'operation': 'static_guidelines_generation_failed',
              },
              error: e);
        }

        // 获取生成的参考线
        final dynamicGuidelines = GuidelineManager.instance.activeGuidelines;

        // 处理生成的参考线
        if (dynamicGuidelines.isNotEmpty) {
          // 直接使用生成的参考线
          _activeGuidelines = dynamicGuidelines;

          // 强制通知外部更新参考线
          if (widget.onGuidelinesUpdated != null) {
            widget.onGuidelinesUpdated!(dynamicGuidelines);

            EditPageLogger.editPageInfo('✅【吸附调试】成功更新参考线UI（含静态重生成）', data: {
              'guidelinesCount': dynamicGuidelines.length,
              'elementId': widget.elementId,
              'isFullRegeneration': true,
              'elementPosition': '(${currentPos.dx}, ${currentPos.dy})',
              'guidelineTypes':
                  dynamicGuidelines.map((g) => g.type.name).toList(),
              'operation': 'update_guidelines_ui_with_static',
            });
          }
        } else {
          EditPageLogger.editPageInfo('🚫【吸附调试】未获取到动态参考线', data: {
            'elementId': widget.elementId,
            'staticGuidelinesCount':
                GuidelineManager.instance.staticGuidelines.length,
            'operation': 'no_dynamic_guidelines',
          });

          // 没有找到对齐点，清除参考线
          if (_activeGuidelines.isNotEmpty) {
            _activeGuidelines = [];
            widget.onGuidelinesUpdated?.call([]);
          }
        }
      } else {
        EditPageLogger.editPageWarning('⚠️【吸附调试】无法刷新参考线，条件不满足', data: {
          'alignmentMode': widget.alignmentMode?.toString() ?? 'null',
          'guidelineManagerEnabled': GuidelineManager.instance.enabled,
          'operation': 'refresh_guidelines_conditions_not_met',
        });
      }
    } catch (e) {
      EditPageLogger.editPageError('❌【吸附调试】刷新参考线异常',
          data: {
            'error': e.toString(),
            'elementId': widget.elementId,
            'operation': 'refresh_guidelines_exception',
          },
          error: e);
    }

    // 推送元素状态更新到预览层
    if (widget.onControlPointDragEndWithState != null) {
      widget.onControlPointDragEndWithState!(-2, currentState);
    }
  }

  /// 旋转一个点
  Offset _rotatePoint(
      double px, double py, double cx, double cy, double angle) {
    final s = sin(angle);
    final c = cos(angle);

    final translatedX = px - cx;
    final translatedY = py - cy;

    final rotatedX = translatedX * c - translatedY * s;
    final rotatedY = translatedX * s + translatedY * c;

    return Offset(rotatedX + cx, rotatedY + cy);
  }

  /// 同步控制点位置到元素位置 - 用于跟随外部元素移动
  void _syncWithElementPosition(
      double x, double y, double width, double height, double rotation) {
    // 更新内部状态
    _currentX = x;
    _currentY = y;
    _currentWidth = width;
    _currentHeight = height;
    _currentRotation = rotation * pi / 180;

    final centerX = _currentX + _currentWidth / 2;
    final centerY = _currentY + _currentHeight / 2;

    // 更新旋转中心
    _rotationCenter = Offset(centerX, centerY);

    // 重新计算所有控制点位置
    _recalculateControlPointPositions();
  }

  /// 将屏幕坐标系的delta转换为元素本地坐标系的delta
  /// ⚠️ 注意：此方法仅用于调整大小操作（resize），不用于平移操作（translate）
  /// 平移操作应始终使用屏幕坐标系，确保鼠标移动方向与元素移动方向一致
  Offset _transformDeltaToLocalCoordinates(Offset screenDelta) {
    if (_currentRotation == 0.0) {
      return screenDelta; // 没有旋转时直接返回
    }

    // 计算旋转矩阵的逆变换
    // 如果元素旋转了角度θ，那么要将屏幕坐标转换到本地坐标，需要旋转-θ
    final cosAngle = cos(-_currentRotation);
    final sinAngle = sin(-_currentRotation);

    final localDx = screenDelta.dx * cosAngle - screenDelta.dy * sinAngle;
    final localDy = screenDelta.dx * sinAngle + screenDelta.dy * cosAngle;

    return Offset(localDx, localDy);
  }

  /// 平移所有控制点
  void _translateAllControlPoints(Offset delta) {
    // ✅✅ 完全按照屏幕坐标系平移，无任何坐标转换
    // 规则：鼠标向上移动10像素 → 控制点向上移动10像素 (delta.dy = -10)
    //      鼠标向下移动10像素 → 控制点向下移动10像素 (delta.dy = +10)
    //      鼠标向左移动10像素 → 控制点向左移动10像素 (delta.dx = -10)
    //      鼠标向右移动10像素 → 控制点向右移动10像素 (delta.dx = +10)

    // 将所有控制点位置直接加上屏幕坐标系的位移量（不转换）
    for (int i = 0; i < _controlPointPositions.length; i++) {
      final currentPos = _controlPointPositions[i];
      if (currentPos != null) {
        final newPos = currentPos + delta;
        _controlPointPositions[i] = newPos;
      }
    }

    // 同时更新独立的位置属性（直接使用屏幕delta，无转换）
    _currentX += delta.dx;
    _currentY += delta.dy;

    // 同时更新旋转中心（直接使用屏幕delta，无转换）
    if (_rotationCenter != null) {
      _rotationCenter = _rotationCenter! + delta;
    }
  }

  void _updateAllControlPointsFromRect(Rect rect) {
    const offset = 8.0; // 控制点内偏移量 - 现在向内偏移
    // 🔧 移动端优化：旋转控制点距离调整
    final rotationOffset = _isMobile ? 120.0 : 80.0; // 移动端增加距离避免误触

    final centerX = rect.center.dx;
    final centerY = rect.center.dy;

    // 更新独立的矩形属性
    _currentX = rect.left;
    _currentY = rect.top;
    _currentWidth = rect.width;
    _currentHeight = rect.height;

    // 🔧 修复：需要考虑旋转角度！
    // 不能直接基于矩形设置控制点，要先计算未旋转的位置，然后应用旋转

    // 计算未旋转的控制点位置
    final unrotatedPositions = [
      // 索引0: 左上角 - 移动到元素内部
      Offset(rect.left + offset, rect.top + offset),
      // 索引1: 上中 - 移动到元素内部
      Offset(centerX, rect.top + offset),
      // 索引2: 右上角 - 移动到元素内部
      Offset(rect.right - offset, rect.top + offset),
      // 索引3: 右中 - 移动到元素内部
      Offset(rect.right - offset, centerY),
      // 索引4: 右下角 - 移动到元素内部
      Offset(rect.right - offset, rect.bottom - offset),
      // 索引5: 下中 - 移动到元素内部
      Offset(centerX, rect.bottom - offset),
      // 索引6: 左下角 - 移动到元素内部
      Offset(rect.left + offset, rect.bottom - offset),
      // 索引7: 左中 - 移动到元素内部
      Offset(rect.left + offset, centerY),
      // 索引8: 旋转控制点 - 保持在元素外部以便操作
      Offset(centerX, rect.top - rotationOffset),
    ];

    // 应用当前旋转角度到所有控制点
    for (int i = 0; i < unrotatedPositions.length; i++) {
      final rotated = _rotatePoint(
        unrotatedPositions[i].dx,
        unrotatedPositions[i].dy,
        centerX,
        centerY,
        _currentRotation,
      );
      _controlPointPositions[i] = rotated;
    }
  }

  /// 根据新的旋转角度更新所有控制点位置
  void _updateAllControlPointsFromRotation() {
    if (_rotationCenter == null) return;

    final centerX = _rotationCenter!.dx;
    final centerY = _rotationCenter!.dy;

    // 🔧 修复：更新位置坐标，确保_currentX和_currentY是左上角位置
    _currentX = centerX - _currentWidth / 2;
    _currentY = centerY - _currentHeight / 2;

    // 使用当前独立的矩形尺寸
    const offset = 8.0; // 控制点内偏移量 - 现在向内偏移
    // 🔧 移动端优化：旋转控制点距离调整
    final rotationOffset = _isMobile ? 120.0 : 80.0; // 移动端增加距离避免误触

    // 原始控制点位置（未旋转）
    final unrotatedPositions = [
      // 索引0: 左上角 - 移动到元素内部
      Offset(centerX - _currentWidth / 2 + offset,
          centerY - _currentHeight / 2 + offset),
      // 索引1: 上中 - 移动到元素内部
      Offset(centerX, centerY - _currentHeight / 2 + offset),
      // 索引2: 右上角 - 移动到元素内部
      Offset(centerX + _currentWidth / 2 - offset,
          centerY - _currentHeight / 2 + offset),
      // 索引3: 右中 - 移动到元素内部
      Offset(centerX + _currentWidth / 2 - offset, centerY),
      // 索引4: 右下角 - 移动到元素内部
      Offset(centerX + _currentWidth / 2 - offset,
          centerY + _currentHeight / 2 - offset),
      // 索引5: 下中 - 移动到元素内部
      Offset(centerX, centerY + _currentHeight / 2 - offset),
      // 索引6: 左下角 - 移动到元素内部
      Offset(centerX - _currentWidth / 2 + offset,
          centerY + _currentHeight / 2 - offset),
      // 索引7: 左中 - 移动到元素内部
      Offset(centerX - _currentWidth / 2 + offset, centerY),
      // 索引8: 旋转控制点 - 保持在元素外部以便操作
      Offset(centerX, centerY - _currentHeight / 2 - rotationOffset),
    ];

    // 应用当前旋转角度并保存位置
    for (int i = 0; i < unrotatedPositions.length; i++) {
      final rotated = _rotatePoint(
        unrotatedPositions[i].dx,
        unrotatedPositions[i].dy,
        centerX,
        centerY,
        _currentRotation,
      );
      _controlPointPositions[i] = rotated;
    }
  }

  /// 根据约束更新控制点位置 - 保持矩形边框关系
  void _updateControlPointWithConstraints(int index, Offset delta) {
    if (index == 8) {
      // 旋转控制点 - 计算旋转角度并更新所有控制点
      _updateRotation(delta);
      return;
    }

    // ⚠️ 重要：调整大小操作需要考虑旋转角度！
    // 用户拖拽右边控制点时，应该增加元素的"宽度"（本地坐标系），
    // 而不是屏幕坐标系的X方向。所以需要坐标转换。
    final localDelta = _transformDeltaToLocalCoordinates(delta);

    // 获取当前矩形的虚拟边界（从其他控制点推算）
    final currentRect = _calculateCurrentRectFromControlPoints();
    if (currentRect == null) return;

    // 根据控制点类型应用约束移动
    switch (index) {
      case 0: // 左上角
        _updateCornerPoint(index, localDelta, currentRect, true, true);
        break;
      case 1: // 上中
        _updateEdgePoint(index, localDelta, currentRect, true, false);
        break;
      case 2: // 右上角
        _updateCornerPoint(index, localDelta, currentRect, false, true);
        break;
      case 3: // 右中
        _updateEdgePoint(index, localDelta, currentRect, false, true);
        break;
      case 4: // 右下角
        _updateCornerPoint(index, localDelta, currentRect, false, false);
        break;
      case 5: // 下中
        _updateEdgePoint(index, localDelta, currentRect, true, false);
        break;
      case 6: // 左下角
        _updateCornerPoint(index, localDelta, currentRect, true, false);
        break;
      case 7: // 左中
        _updateEdgePoint(index, localDelta, currentRect, false, true);
        break;
    }
  }

  /// 更新角点（可以同时改变宽度和高度）
  void _updateCornerPoint(
      int index, Offset localDelta, Rect rect, bool isLeft, bool isTop) {
    // 在本地坐标系中直接更新尺寸
    double deltaWidth = 0.0;
    double deltaHeight = 0.0;
    double deltaX = 0.0;
    double deltaY = 0.0;

    // 根据角点位置计算尺寸变化
    if (isLeft) {
      // 左侧角点：宽度减少，x位置增加
      deltaWidth = -localDelta.dx;
      deltaX = localDelta.dx;
    } else {
      // 右侧角点：宽度增加
      deltaWidth = localDelta.dx;
    }

    if (isTop) {
      // 上方角点：高度减少，y位置增加
      deltaHeight = -localDelta.dy;
      deltaY = localDelta.dy;
    } else {
      // 下方角点：高度增加
      deltaHeight = localDelta.dy;
    }

    // 应用尺寸变化，确保最小尺寸
    const minSize = 20.0;
    final newWidth =
        (_currentWidth + deltaWidth).clamp(minSize, double.infinity);
    final newHeight =
        (_currentHeight + deltaHeight).clamp(minSize, double.infinity);

    // 如果尺寸被限制，调整位置变化
    if (newWidth != _currentWidth + deltaWidth) {
      deltaX = isLeft ? (_currentWidth - newWidth) : 0.0;
    }
    if (newHeight != _currentHeight + deltaHeight) {
      deltaY = isTop ? (_currentHeight - newHeight) : 0.0;
    }

    // 更新独立的矩形属性
    _currentWidth = newWidth;
    _currentHeight = newHeight;
    _currentX += deltaX;
    _currentY += deltaY;

    // 重新计算所有控制点位置
    _updateAllControlPointsFromRect(
        Rect.fromLTWH(_currentX, _currentY, _currentWidth, _currentHeight));
  }

  /// 更新边点（只能改变一个方向的尺寸）
  void _updateEdgePoint(int index, Offset localDelta, Rect rect,
      bool isHorizontal, bool isVertical) {
    double deltaWidth = 0.0;
    double deltaHeight = 0.0;
    double deltaX = 0.0;
    double deltaY = 0.0;

    if (isHorizontal && (index == 1 || index == 5)) {
      // 上中或下中 - 只改变高度
      if (index == 1) {
        // 上中：高度减少，y位置增加
        deltaHeight = -localDelta.dy;
        deltaY = localDelta.dy;
      } else {
        // 下中：高度增加
        deltaHeight = localDelta.dy;
      }
    } else if (isVertical && (index == 3 || index == 7)) {
      // 右中或左中 - 只改变宽度
      if (index == 7) {
        // 左中：宽度减少，x位置增加
        deltaWidth = -localDelta.dx;
        deltaX = localDelta.dx;
      } else {
        // 右中：宽度增加
        deltaWidth = localDelta.dx;
      }
    }

    // 应用尺寸变化，确保最小尺寸
    const minSize = 20.0;
    final newWidth = deltaWidth != 0.0
        ? (_currentWidth + deltaWidth).clamp(minSize, double.infinity)
        : _currentWidth;
    final newHeight = deltaHeight != 0.0
        ? (_currentHeight + deltaHeight).clamp(minSize, double.infinity)
        : _currentHeight;

    // 如果尺寸被限制，调整位置变化
    if (deltaWidth != 0.0 && newWidth != _currentWidth + deltaWidth) {
      deltaX = index == 7 ? (_currentWidth - newWidth) : 0.0;
    }
    if (deltaHeight != 0.0 && newHeight != _currentHeight + deltaHeight) {
      deltaY = index == 1 ? (_currentHeight - newHeight) : 0.0;
    }

    // 更新独立的矩形属性
    _currentWidth = newWidth;
    _currentHeight = newHeight;
    _currentX += deltaX;
    _currentY += deltaY;

    // 重新计算所有控制点位置
    _updateAllControlPointsFromRect(
        Rect.fromLTWH(_currentX, _currentY, _currentWidth, _currentHeight));
  }

  /// 更新旋转
  void _updateRotation(Offset delta) {
    if (_rotationCenter == null || _initialRotationAngle == null) return;

    // 获取旋转控制点的新位置
    final currentRotationPoint = _controlPointPositions[8]! + delta;

    // 计算新的角度
    final newAngle = atan2(
      currentRotationPoint.dy - _rotationCenter!.dy,
      currentRotationPoint.dx - _rotationCenter!.dx,
    );

    // 🔧 修复：使用当前累积的旋转角度，而不是重新从widget.rotation开始
    final deltaAngle = newAngle - _initialRotationAngle!;
    _currentRotation += deltaAngle;

    // 🔧 修复：更新初始角度，避免累积误差
    _initialRotationAngle = newAngle; // 重新计算所有控制点的位置
    _updateAllControlPointsFromRotation();
  }
}

/// 角落标记式边框绘制器 - 在所有8个控制点位置绘制L形标记，并添加细线框
class _CornerMarksBorderPainter extends CustomPainter {
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final Color color;

  _CornerMarksBorderPainter({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = x + width / 2;
    final centerY = y + height / 2;
    final angle = rotation * pi / 180;

    // 绘制包围元素区域的细线框
    _drawElementBorder(canvas, centerX, centerY, angle);

    // 绘制控制点位置的L形标记
    _drawControlPointMarks(canvas, centerX, centerY, angle);
  }

  void _drawElementBorder(
      Canvas canvas, double centerX, double centerY, double angle) {
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 计算四个角点
    final corners = [
      Offset(x, y),
      Offset(x + width, y),
      Offset(x + width, y + height),
      Offset(x, y + height),
    ];

    // 应用旋转变换
    final rotatedCorners = corners.map((corner) {
      return _rotatePoint(corner.dx, corner.dy, centerX, centerY, angle);
    }).toList();

    // 绘制边框
    final path = Path();
    path.moveTo(rotatedCorners[0].dx, rotatedCorners[0].dy);
    for (int i = 1; i < rotatedCorners.length; i++) {
      path.lineTo(rotatedCorners[i].dx, rotatedCorners[i].dy);
    }
    path.close();

    canvas.drawPath(path, borderPaint);
  }

  void _drawControlPointMarks(
      Canvas canvas, double centerX, double centerY, double angle) {
    final markPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // 控制点标记的长度
    const double markLength = 12.0;
    const double inset = 8.0; // 控制点内偏移量

    // 计算所有8个控制点位置（在元素内部）
    final controlPoints = [
      Offset(x + inset, y + inset), // 左上角
      Offset(x + width / 2, y + inset), // 上中
      Offset(x + width - inset, y + inset), // 右上角
      Offset(x + width - inset, y + height / 2), // 右中
      Offset(x + width - inset, y + height - inset), // 右下角
      Offset(x + width / 2, y + height - inset), // 下中
      Offset(x + inset, y + height - inset), // 左下角
      Offset(x + inset, y + height / 2), // 左中
    ];

    // 为每个控制点位置绘制L形标记
    for (int i = 0; i < controlPoints.length; i++) {
      _drawControlPointMark(canvas, markPaint, controlPoints[i], i, centerX,
          centerY, angle, markLength);
    }
  }

  void _drawControlPointMark(
      Canvas canvas,
      Paint paint,
      Offset controlPoint,
      int index,
      double centerX,
      double centerY,
      double angle,
      double markLength) {
    // 应用旋转变换到控制点位置
    final rotatedControlPoint =
        _rotatePoint(controlPoint.dx, controlPoint.dy, centerX, centerY, angle);

    // 根据控制点位置确定L形标记的方向
    Offset horizontal, vertical;

    switch (index) {
      case 0: // 左上角 - L形开口向右下
        horizontal = _rotatePoint(controlPoint.dx + markLength, controlPoint.dy,
            centerX, centerY, angle);
        vertical = _rotatePoint(controlPoint.dx, controlPoint.dy + markLength,
            centerX, centerY, angle);
        break;
      case 1: // 上中 - T形向下
        horizontal = _rotatePoint(controlPoint.dx - markLength / 2,
            controlPoint.dy, centerX, centerY, angle);
        final horizontal2 = _rotatePoint(controlPoint.dx + markLength / 2,
            controlPoint.dy, centerX, centerY, angle);
        vertical = _rotatePoint(controlPoint.dx, controlPoint.dy + markLength,
            centerX, centerY, angle);
        canvas.drawLine(horizontal, horizontal2, paint);
        canvas.drawLine(rotatedControlPoint, vertical, paint);
        return;
      case 2: // 右上角 - L形开口向左下
        horizontal = _rotatePoint(controlPoint.dx - markLength, controlPoint.dy,
            centerX, centerY, angle);
        vertical = _rotatePoint(controlPoint.dx, controlPoint.dy + markLength,
            centerX, centerY, angle);
        break;
      case 3: // 右中 - T形向左
        horizontal = _rotatePoint(controlPoint.dx - markLength, controlPoint.dy,
            centerX, centerY, angle);
        vertical = _rotatePoint(controlPoint.dx,
            controlPoint.dy - markLength / 2, centerX, centerY, angle);
        final vertical2 = _rotatePoint(controlPoint.dx,
            controlPoint.dy + markLength / 2, centerX, centerY, angle);
        canvas.drawLine(rotatedControlPoint, horizontal, paint);
        canvas.drawLine(vertical, vertical2, paint);
        return;
      case 4: // 右下角 - L形开口向左上
        horizontal = _rotatePoint(controlPoint.dx - markLength, controlPoint.dy,
            centerX, centerY, angle);
        vertical = _rotatePoint(controlPoint.dx, controlPoint.dy - markLength,
            centerX, centerY, angle);
        break;
      case 5: // 下中 - T形向上
        horizontal = _rotatePoint(controlPoint.dx - markLength / 2,
            controlPoint.dy, centerX, centerY, angle);
        final horizontal2 = _rotatePoint(controlPoint.dx + markLength / 2,
            controlPoint.dy, centerX, centerY, angle);
        vertical = _rotatePoint(controlPoint.dx, controlPoint.dy - markLength,
            centerX, centerY, angle);
        canvas.drawLine(horizontal, horizontal2, paint);
        canvas.drawLine(rotatedControlPoint, vertical, paint);
        return;
      case 6: // 左下角 - L形开口向右上
        horizontal = _rotatePoint(controlPoint.dx + markLength, controlPoint.dy,
            centerX, centerY, angle);
        vertical = _rotatePoint(controlPoint.dx, controlPoint.dy - markLength,
            centerX, centerY, angle);
        break;
      case 7: // 左中 - T形向右
        horizontal = _rotatePoint(controlPoint.dx + markLength, controlPoint.dy,
            centerX, centerY, angle);
        vertical = _rotatePoint(controlPoint.dx,
            controlPoint.dy - markLength / 2, centerX, centerY, angle);
        final vertical2 = _rotatePoint(controlPoint.dx,
            controlPoint.dy + markLength / 2, centerX, centerY, angle);
        canvas.drawLine(rotatedControlPoint, horizontal, paint);
        canvas.drawLine(vertical, vertical2, paint);
        return;
      default:
        return;
    }

    // 绘制L形标记（对于角落位置）
    canvas.drawLine(rotatedControlPoint, horizontal, paint);
    canvas.drawLine(rotatedControlPoint, vertical, paint);
  }

  Offset _rotatePoint(
      double px, double py, double cx, double cy, double angle) {
    final cosAngle = cos(angle);
    final sinAngle = sin(angle);
    final dx = px - cx;
    final dy = py - cy;
    return Offset(
      cx + dx * cosAngle - dy * sinAngle,
      cy + dx * sinAngle + dy * cosAngle,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
