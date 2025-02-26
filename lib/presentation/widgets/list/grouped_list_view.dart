import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

class GroupedListView<T> extends StatelessWidget {
  final List<ListGroup<T>> groups;
  final Widget Function(BuildContext, T) itemBuilder;
  final Widget Function(BuildContext, ListGroup<T>)? headerBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool showDividers;

  const GroupedListView({
    super.key,
    required this.groups,
    required this.itemBuilder,
    this.headerBuilder,
    this.padding,
    this.controller,
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: _calculateItemCount(),
      itemBuilder: (context, index) {
        final groupInfo = _getItemForIndex(index);
        if (groupInfo.isHeader) {
          return headerBuilder?.call(context, groupInfo.group!) ??
              _defaultHeaderBuilder(context, groupInfo.group!);
        }
        return itemBuilder(context, groupInfo.item as T);
      },
    );
  }

  int _calculateItemCount() {
    return groups.fold(0, (sum, group) => sum + group.items.length + 1);
  }

  Widget _defaultHeaderBuilder(BuildContext context, ListGroup<T> group) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingMedium),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        group.header,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }

  _GroupedItemInfo<T> _getItemForIndex(int index) {
    int currentIndex = 0;
    for (var group in groups) {
      if (index == currentIndex) {
        return _GroupedItemInfo(isHeader: true, group: group);
      }
      if (index <= currentIndex + group.items.length) {
        return _GroupedItemInfo(
          isHeader: false,
          item: group.items[index - currentIndex - 1],
        );
      }
      currentIndex += group.items.length + 1;
    }
    throw RangeError('Index out of range');
  }
}

class ListGroup<T> {
  final String header;
  final List<T> items;

  const ListGroup({
    required this.header,
    required this.items,
  });
}

class _GroupedItemInfo<T> {
  final bool isHeader;
  final ListGroup<T>? group;
  final T? item;

  _GroupedItemInfo({
    required this.isHeader,
    this.group,
    this.item,
  });
}
