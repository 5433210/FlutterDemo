import 'package:equatable/equatable.dart';

/// 集字过滤条件，用于搜索和筛选已采集的汉字
class CharacterFilter extends Equatable {
  /// 搜索关键词（汉字/作品名）
  final String? searchQuery;

  /// 书法风格列表
  final List<String> styles;

  /// 书写工具列表
  final List<String> tools;

  /// 排序选项
  final SortOption sortOption;

  /// 是否降序排序
  final bool descending;

  /// 开始日期
  final DateTime? fromDate;

  /// 结束日期
  final DateTime? toDate;

  const CharacterFilter({
    this.searchQuery,
    this.styles = const [],
    this.tools = const [],
    this.sortOption = SortOption.createTime,
    this.descending = true,
    this.fromDate,
    this.toDate,
  });

  /// 从JSON创建过滤器
  factory CharacterFilter.fromJson(Map<String, dynamic> json) {
    return CharacterFilter(
      searchQuery: json['searchQuery'] as String?,
      styles: List<String>.from(json['styles'] as List? ?? []),
      tools: List<String>.from(json['tools'] as List? ?? []),
      sortOption: SortOption.values.firstWhere(
        (opt) => opt.name == (json['sortOption'] as String?),
        orElse: () => SortOption.createTime,
      ),
      descending: json['descending'] as bool? ?? true,
      fromDate: json['fromDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['fromDate'] as int)
          : null,
      toDate: json['toDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['toDate'] as int)
          : null,
    );
  }

  /// 检查是否包含日期范围条件
  bool get hasDateRange => fromDate != null || toDate != null;

  /// 检查过滤器是否为空（没有任何过滤条件）
  bool get isEmpty =>
      searchQuery == null &&
      styles.isEmpty &&
      tools.isEmpty &&
      fromDate == null &&
      toDate == null;

  @override
  List<Object?> get props => [
        searchQuery,
        styles,
        tools,
        sortOption,
        descending,
        fromDate,
        toDate,
      ];

  /// 重置所有过滤条件
  CharacterFilter clear() {
    return const CharacterFilter();
  }

  /// 创建过滤器副本
  CharacterFilter copyWith({
    String? searchQuery,
    List<String>? styles,
    List<String>? tools,
    SortOption? sortOption,
    bool? descending,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return CharacterFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      styles: styles ?? this.styles,
      tools: tools ?? this.tools,
      sortOption: sortOption ?? this.sortOption,
      descending: descending ?? this.descending,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }

  /// 添加或移除书法风格
  CharacterFilter toggleStyle(String style) {
    final newStyles = List<String>.from(styles);
    if (newStyles.contains(style)) {
      newStyles.remove(style);
    } else {
      newStyles.add(style);
    }
    return copyWith(styles: newStyles);
  }

  /// 添加或移除书写工具
  CharacterFilter toggleTool(String tool) {
    final newTools = List<String>.from(tools);
    if (newTools.contains(tool)) {
      newTools.remove(tool);
    } else {
      newTools.add(tool);
    }
    return copyWith(tools: newTools);
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'searchQuery': searchQuery,
      'styles': styles,
      'tools': tools,
      'sortOption': sortOption.name,
      'descending': descending,
      'fromDate': fromDate?.millisecondsSinceEpoch,
      'toDate': toDate?.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'CharacterFilter{'
        'searchQuery: $searchQuery, '
        'styles: $styles, '
        'tools: $tools, '
        'sortOption: $sortOption, '
        'descending: $descending, '
        'fromDate: $fromDate, '
        'toDate: $toDate'
        '}';
  }

  /// 更新日期范围
  CharacterFilter updateDateRange(DateTime? from, DateTime? to) {
    return copyWith(
      fromDate: from,
      toDate: to,
    );
  }

  /// 更新排序方式
  CharacterFilter updateSort(SortOption option, {bool? descending}) {
    return copyWith(
      sortOption: option,
      descending: descending,
    );
  }
}

/// 排序选项
enum SortOption {
  createTime('采集时间'),
  character('汉字'),
  workName('作品名'),
  style('书法风格');

  final String label;
  const SortOption(this.label);
}
