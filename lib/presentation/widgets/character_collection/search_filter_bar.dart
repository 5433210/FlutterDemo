import 'package:flutter/material.dart';

import 'filter_type.dart';

class SearchFilterBar extends StatelessWidget {
  final String searchTerm;
  final FilterType filterType;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<FilterType> onFilterChanged;

  const SearchFilterBar({
    Key? key,
    required this.searchTerm,
    required this.filterType,
    required this.onSearchChanged,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // 搜索输入框
          Expanded(
            flex: 3,
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索字符...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
              ),
              onChanged: onSearchChanged,
              controller: TextEditingController(text: searchTerm),
            ),
          ),

          const SizedBox(width: 16),

          // 筛选下拉菜单
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<FilterType>(
                  value: filterType,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  borderRadius: BorderRadius.circular(8.0),
                  items: [
                    _buildDropdownItem(FilterType.all, '全部字符', context),
                    _buildDropdownItem(FilterType.recent, '最近添加', context),
                    _buildDropdownItem(FilterType.modified, '最近修改', context),
                    _buildDropdownItem(FilterType.favorite, '已收藏', context),
                    _buildDropdownItem(FilterType.byStroke, '按笔画数', context),
                    _buildDropdownItem(FilterType.custom, '自定义排序', context),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onFilterChanged(value);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<FilterType> _buildDropdownItem(
      FilterType type, String label, BuildContext context) {
    return DropdownMenuItem<FilterType>(
      value: type,
      child: Row(
        children: [
          Icon(
            _getFilterIcon(type),
            size: 20,
            color: filterType == type
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight:
                  filterType == type ? FontWeight.bold : FontWeight.normal,
              color: filterType == type
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFilterIcon(FilterType type) {
    switch (type) {
      case FilterType.all:
        return Icons.format_list_bulleted;
      case FilterType.recent:
        return Icons.access_time;
      case FilterType.modified:
        return Icons.edit;
      case FilterType.favorite:
        return Icons.favorite;
      case FilterType.byStroke:
        return Icons.brush;
      case FilterType.custom:
        return Icons.sort;
    }
  }
}
