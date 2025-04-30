import '../../../infrastructure/logging/logger.dart';

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
    AppLogger.debug('DatabaseQuery.fromJson', tag: 'DatabaseQuery', data: {
      'json': json,
      'whereType': json['where']?.runtimeType.toString(),
      'where': json['where'],
    });

    final conditions = <DatabaseQueryCondition>[];
    final groups = <DatabaseQueryGroup>[];

    try {
      if (json.containsKey('where')) {
        if (json['where'] is List) {
          final list = json['where'] as List;
          AppLogger.debug('处理List类型的where条件', tag: 'DatabaseQuery', data: {
            'count': list.length,
            'firstItem': list.isNotEmpty ? list.first : null,
          });

          for (var item in list) {
            if (item is Map) {
              final condition = DatabaseQueryCondition.fromJson(
                  Map<String, dynamic>.from(item));
              conditions.add(condition);

              AppLogger.debug('添加查询条件', tag: 'DatabaseQuery', data: {
                'field': condition.field,
                'op': condition.operator,
                'val': condition.value,
              });
            } else {
              AppLogger.error('无效的查询条件',
                  tag: 'DatabaseQuery',
                  error: 'Item is not a Map',
                  data: {
                    'item': item,
                    'type': item.runtimeType.toString(),
                  });
            }
          }
        } else if (json['where'] is Map) {
          final where = Map<String, dynamic>.from(json['where'] as Map);
          AppLogger.debug('处理Map类型的where条件', tag: 'DatabaseQuery', data: {
            'fields': where.keys.toList(),
          });

          conditions.addAll(
            where.entries.map((e) => DatabaseQueryCondition(
                  field: e.key,
                  operator: '=',
                  value: e.value,
                )),
          );
        } else {
          AppLogger.warning('不支持的where类型', tag: 'DatabaseQuery', data: {
            'type': json['where']?.runtimeType.toString(),
          });
        }
      }

      if (json.containsKey('conditions')) {
        final list = json['conditions'] as List;
        conditions.addAll(
          list.map((e) => DatabaseQueryCondition.fromJson(
              Map<String, dynamic>.from(e as Map))),
        );
      }

      if (json.containsKey('groups')) {
        final list = json['groups'] as List;
        groups.addAll(
          list.map((e) =>
              DatabaseQueryGroup.fromJson(Map<String, dynamic>.from(e as Map))),
        );
      }

      // AppLogger.debug('查询条件构建完成', tag: 'DatabaseQuery', data: {
      //   'conditionCount': conditions.length,
      //   'groupCount': groups.length,
      //   'orderBy': json['orderBy'],
      // });

      return DatabaseQuery(
        conditions: conditions,
        groups: groups.isEmpty ? null : groups,
        orderBy: json['orderBy'] as String?,
        limit: json['limit'] as int?,
        offset: json['offset'] as int?,
      );
    } catch (e, stack) {
      AppLogger.error('构建查询条件失败',
          tag: 'DatabaseQuery',
          error: e,
          stackTrace: stack,
          data: {'json': json});
      rethrow;
    }
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
    AppLogger.debug('创建查询条件', tag: 'DatabaseQuery', data: {
      'json': json,
    });

    return DatabaseQueryCondition(
      field: json['field'] as String,
      operator: json['op'] as String? ?? '=',
      value: json['val'],
    );
  }

  Map<String, dynamic> toJson() => {
        'field': field,
        'op': operator,
        'val': value,
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
          .map((e) => DatabaseQueryCondition.fromJson(
              Map<String, dynamic>.from(e as Map)))
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
