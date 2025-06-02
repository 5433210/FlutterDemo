/// 属性面板性能优化 - Phase 2.2
///
/// 优化属性面板渲染性能，减少不必要的重建
library;

import 'package:flutter/material.dart';

/// 缓存型属性项构建器
/// 只在属性值实际变化时重建
class CachedPropertyItemBuilder extends StatefulWidget {
  final PropertyValue propertyValue;
  final Widget Function(BuildContext, PropertyValue) builder;
  final PropertyValueComparator comparator;

  const CachedPropertyItemBuilder({
    super.key,
    required this.propertyValue,
    required this.builder,
    this.comparator = const PropertyValueComparator(),
  });

  @override
  State<CachedPropertyItemBuilder> createState() =>
      _CachedPropertyItemBuilderState();
}

/// 延迟加载的属性面板
/// 只在需要时才构建子组件
class LazyLoadPropertyPanel extends StatefulWidget {
  final List<Widget> Function(BuildContext) childrenBuilder;
  final String title;
  final bool initiallyExpanded;

  const LazyLoadPropertyPanel({
    super.key,
    required this.childrenBuilder,
    required this.title,
    this.initiallyExpanded = true,
  });

  @override
  State<LazyLoadPropertyPanel> createState() => _LazyLoadPropertyPanelState();
}

/// 优化的属性列表
/// 使用内存高效的方式渲染大量属性
class OptimizedPropertyList extends StatefulWidget {
  final List<Widget> children;
  final bool addDividers;
  final ScrollPhysics? physics;

  const OptimizedPropertyList({
    super.key,
    required this.children,
    this.addDividers = true,
    this.physics,
  });

  @override
  State<OptimizedPropertyList> createState() => _OptimizedPropertyListState();
}

/// 优化的属性值包装器，用于减少不必要的重建
class PropertyValue<T> {
  final T _value;
  final ValueChanged<T>? _onChanged;
  final bool _enabled;

  const PropertyValue({
    required T value,
    ValueChanged<T>? onChanged,
    bool enabled = true,
  })  : _value = value,
        _onChanged = onChanged,
        _enabled = enabled;

  /// 获取启用状态
  bool get enabled => _enabled;

  /// 是否有变更回调
  bool get hasCallback => _onChanged != null;

  /// 获取值
  T get value => _value;

  /// 触发变更
  void change(T newValue) {
    if (!_enabled || _onChanged == null) return;
    _onChanged!(newValue);
  }
}

/// 属性值比较器
class PropertyValueComparator {
  const PropertyValueComparator();

  /// 比较两个属性值是否相等
  bool areEqual<T>(PropertyValue<T> a, PropertyValue<T> b) {
    return a.value == b.value && a.enabled == b.enabled;
  }
}

class _CachedPropertyItemBuilderState extends State<CachedPropertyItemBuilder> {
  late PropertyValue _lastPropertyValue;
  late Widget _cachedWidget;

  @override
  Widget build(BuildContext context) {
    if (_shouldRebuild()) {
      _lastPropertyValue = widget.propertyValue;
      _cachedWidget = widget.builder(context, widget.propertyValue);
    }
    return _cachedWidget;
  }

  @override
  void initState() {
    super.initState();
    _lastPropertyValue = widget.propertyValue;
    _cachedWidget = widget.builder(context, widget.propertyValue);
  }

  /// 检查是否需要重建
  bool _shouldRebuild() {
    return !widget.comparator
        .areEqual(_lastPropertyValue, widget.propertyValue);
  }
}

class _LazyLoadPropertyPanelState extends State<LazyLoadPropertyPanel> {
  late bool _isExpanded;
  List<Widget>? _children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.title),
            trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: _toggleExpanded,
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _getChildren(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  /// 获取子组件
  List<Widget> _getChildren() {
    _children ??= widget.childrenBuilder(context);
    return _children!;
  }

  /// 切换展开状态
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }
}

class _OptimizedPropertyListState extends State<OptimizedPropertyList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: widget.physics ?? const NeverScrollableScrollPhysics(),
      itemCount: widget.children.length * (widget.addDividers ? 2 - 1 : 1),
      itemBuilder: (context, index) {
        if (widget.addDividers && index.isOdd) {
          return const Divider();
        }
        final childIndex = widget.addDividers ? index ~/ 2 : index;
        return widget.children[childIndex];
      },
    );
  }
}
