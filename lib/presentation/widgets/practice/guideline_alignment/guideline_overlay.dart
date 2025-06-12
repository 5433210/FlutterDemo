import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'guideline_renderer.dart';
import 'guideline_types.dart';

/// 参考线覆盖层组件
/// 用于在画布上方显示参考线
class GuidelineOverlay extends StatelessWidget {
  /// 参考线列表
  final List<Guideline> guidelines;

  /// 参考线颜色
  final Color color;

  /// 线条宽度
  final double strokeWidth;

  /// 是否显示标签
  final bool showLabels;

  /// 是否使用虚线
  final bool dashLine;

  /// 视口边界（用于裁剪）
  final Rect? viewportBounds;

  /// 子组件（通常是画布）
  final Widget? child;

  const GuidelineOverlay({
    Key? key,
    required this.guidelines,
    this.color = Colors.orange,
    this.strokeWidth = 1.0,
    this.showLabels = true,
    this.dashLine = true,
    this.viewportBounds,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 如果没有参考线，只返回子组件
    if (guidelines.isEmpty) {
      return child ?? const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 子组件（画布等）
        if (child != null) child!,

        // 参考线层
        Positioned.fill(
          child: CustomPaint(
            painter: GuidelineRenderer.createGuidelinePainter(
              guidelines: guidelines,
              color: color,
              strokeWidth: strokeWidth,
              showLabels: showLabels,
              dashLine: dashLine,
              viewportBounds: viewportBounds,
            ),
          ),
        ),
      ],
    );
  }
}

/// 响应式参考线覆盖层
/// 能够监听外部通知并自动更新
class ReactiveGuidelineOverlay extends StatefulWidget {
  /// 参考线状态监听器
  final ValueListenable<List<Guideline>> guidelinesNotifier;

  /// 参考线颜色
  final Color color;

  /// 线条宽度
  final double strokeWidth;

  /// 是否显示标签
  final bool showLabels;

  /// 是否使用虚线
  final bool dashLine;

  /// 视口边界监听器
  final ValueListenable<Rect?>? viewportBoundsNotifier;

  /// 子组件（通常是画布）
  final Widget? child;

  const ReactiveGuidelineOverlay({
    Key? key,
    required this.guidelinesNotifier,
    this.color = Colors.orange,
    this.strokeWidth = 1.0,
    this.showLabels = true,
    this.dashLine = true,
    this.viewportBoundsNotifier,
    this.child,
  }) : super(key: key);

  @override
  State<ReactiveGuidelineOverlay> createState() =>
      _ReactiveGuidelineOverlayState();
}

/// 智能参考线覆盖层
/// 能够自动响应参考线状态变化
class SmartGuidelineOverlay extends StatefulWidget {
  /// 参考线提供者函数
  final List<Guideline> Function() guidelinesProvider;

  /// 参考线颜色
  final Color color;

  /// 线条宽度
  final double strokeWidth;

  /// 是否显示标签
  final bool showLabels;

  /// 是否使用虚线
  final bool dashLine;

  /// 视口边界提供者函数
  final Rect? Function()? viewportBoundsProvider;

  /// 子组件（通常是画布）
  final Widget? child;

  const SmartGuidelineOverlay({
    Key? key,
    required this.guidelinesProvider,
    this.color = Colors.orange,
    this.strokeWidth = 1.0,
    this.showLabels = true,
    this.dashLine = true,
    this.viewportBoundsProvider,
    this.child,
  }) : super(key: key);

  @override
  State<SmartGuidelineOverlay> createState() => _SmartGuidelineOverlayState();
}

class _ReactiveGuidelineOverlayState extends State<ReactiveGuidelineOverlay> {
  @override
  Widget build(BuildContext context) {
    return GuidelineOverlay(
      guidelines: widget.guidelinesNotifier.value,
      color: widget.color,
      strokeWidth: widget.strokeWidth,
      showLabels: widget.showLabels,
      dashLine: widget.dashLine,
      viewportBounds: widget.viewportBoundsNotifier?.value,
      child: widget.child,
    );
  }

  @override
  void didUpdateWidget(ReactiveGuidelineOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.guidelinesNotifier != widget.guidelinesNotifier) {
      oldWidget.guidelinesNotifier.removeListener(_onGuidelinesChanged);
      widget.guidelinesNotifier.addListener(_onGuidelinesChanged);
    }

    if (oldWidget.viewportBoundsNotifier != widget.viewportBoundsNotifier) {
      oldWidget.viewportBoundsNotifier
          ?.removeListener(_onViewportBoundsChanged);
      widget.viewportBoundsNotifier?.addListener(_onViewportBoundsChanged);
    }
  }

  @override
  void dispose() {
    widget.guidelinesNotifier.removeListener(_onGuidelinesChanged);
    widget.viewportBoundsNotifier?.removeListener(_onViewportBoundsChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.guidelinesNotifier.addListener(_onGuidelinesChanged);
    widget.viewportBoundsNotifier?.addListener(_onViewportBoundsChanged);
  }

  void _onGuidelinesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onViewportBoundsChanged() {
    if (mounted) {
      setState(() {});
    }
  }
}

class _SmartGuidelineOverlayState extends State<SmartGuidelineOverlay> {
  List<Guideline> _cachedGuidelines = [];
  Rect? _cachedViewportBounds;

  @override
  Widget build(BuildContext context) {
    return GuidelineOverlay(
      guidelines: _cachedGuidelines,
      color: widget.color,
      strokeWidth: widget.strokeWidth,
      showLabels: widget.showLabels,
      dashLine: widget.dashLine,
      viewportBounds: _cachedViewportBounds,
      child: widget.child,
    );
  }

  @override
  void didUpdateWidget(SmartGuidelineOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateCache();
  }

  @override
  void initState() {
    super.initState();
    _updateCache();
  }

  void _updateCache() {
    final newGuidelines = widget.guidelinesProvider();
    final newViewportBounds = widget.viewportBoundsProvider?.call();

    // 检查是否有变化
    bool hasChanged = false;

    if (_cachedGuidelines.length != newGuidelines.length) {
      hasChanged = true;
    } else {
      for (int i = 0; i < _cachedGuidelines.length; i++) {
        if (!_cachedGuidelines[i].isEquivalentTo(newGuidelines[i])) {
          hasChanged = true;
          break;
        }
      }
    }

    if (_cachedViewportBounds != newViewportBounds) {
      hasChanged = true;
    }

    if (hasChanged) {
      setState(() {
        _cachedGuidelines = List.from(newGuidelines);
        _cachedViewportBounds = newViewportBounds;
      });
    }
  }
}
