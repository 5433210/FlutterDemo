/// 数据库查询
class DatabaseQuery {
  final List<DatabaseQueryCondition> conditions;
  final List<DatabaseQueryGroup>? groups;
  final String? orderBy;
  final int? limit;
  final int? offset;

  const DatabaseQuery({
    this.conditions = const [],
    this.groups,
    this.orderBy,
    this.limit,
    this.offset,
  });

  factory DatabaseQuery.fromJson(Map<String, dynamic> json) {
    final conditions = <DatabaseQueryCondition>[];
    final groups = <DatabaseQueryGroup>[];

    if (json.containsKey('where')) {
      final where = json['where'] as Map<String, dynamic>;
      conditions.addAll(
        where.entries.map((e) => DatabaseQueryCondition(
              field: e.key,
              operator: '=',
              value: e.value,
            )),
      );
    }

    if (json.containsKey('conditions')) {
      final list = json['conditions'] as List;
      conditions.addAll(
        list.map(
            (e) => DatabaseQueryCondition.fromJson(e as Map<String, dynamic>)),
      );
    }

    if (json.containsKey('groups')) {
      final list = json['groups'] as List;
      groups.addAll(
        list.map((e) => DatabaseQueryGroup.fromJson(e as Map<String, dynamic>)),
      );
    }

    return DatabaseQuery(
      conditions: conditions,
      groups: groups.isEmpty ? null : groups,
      orderBy: json['orderBy'] as String?,
      limit: json['limit'] as int?,
      offset: json['offset'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'conditions': conditions.map((e) => e.toJson()).toList(),
        if (groups != null) 'groups': groups!.map((e) => e.toJson()).toList(),
        if (orderBy != null) 'orderBy': orderBy,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      };
}

/// 数据库查询条件
class DatabaseQueryCondition {
  final String field;
  final String operator;
  final dynamic value;

  const DatabaseQueryCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  factory DatabaseQueryCondition.fromJson(Map<String, dynamic> json) {
    return DatabaseQueryCondition(
      field: json['field'] as String,
      operator: json['operator'] as String? ?? '=',
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() => {
        'field': field,
        'operator': operator,
        'value': value,
      };
}

/// 查询条件组
class DatabaseQueryGroup {
  final List<DatabaseQueryCondition> conditions;
  final String type; // 'AND' or 'OR'

  const DatabaseQueryGroup({
    required this.conditions,
    required this.type,
  });

  factory DatabaseQueryGroup.and(List<DatabaseQueryCondition> conditions) {
    return DatabaseQueryGroup(conditions: conditions, type: 'AND');
  }

  factory DatabaseQueryGroup.fromJson(Map<String, dynamic> json) {
    return DatabaseQueryGroup(
      conditions: (json['conditions'] as List)
          .map(
              (e) => DatabaseQueryCondition.fromJson(e as Map<String, dynamic>))
          .toList(),
      type: json['type'] as String,
    );
  }

  factory DatabaseQueryGroup.or(List<DatabaseQueryCondition> conditions) {
    return DatabaseQueryGroup(conditions: conditions, type: 'OR');
  }

  Map<String, dynamic> toJson() => {
        'conditions': conditions.map((e) => e.toJson()).toList(),
        'type': type,
      };
}
