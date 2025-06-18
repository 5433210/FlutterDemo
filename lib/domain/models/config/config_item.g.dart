// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConfigItemImpl _$$ConfigItemImplFromJson(Map<String, dynamic> json) =>
    _$ConfigItemImpl(
      key: json['key'] as String,
      displayName: json['displayName'] as String,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isSystem: json['isSystem'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      localizedNames: (json['localizedNames'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      createTime: json['createTime'] == null
          ? null
          : DateTime.parse(json['createTime'] as String),
      updateTime: json['updateTime'] == null
          ? null
          : DateTime.parse(json['updateTime'] as String),
    );

Map<String, dynamic> _$$ConfigItemImplToJson(_$ConfigItemImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'displayName': instance.displayName,
      'sortOrder': instance.sortOrder,
      'isSystem': instance.isSystem,
      'isActive': instance.isActive,
      'localizedNames': instance.localizedNames,
      'metadata': instance.metadata,
      'createTime': instance.createTime?.toIso8601String(),
      'updateTime': instance.updateTime?.toIso8601String(),
    };

_$ConfigCategoryImpl _$$ConfigCategoryImplFromJson(Map<String, dynamic> json) =>
    _$ConfigCategoryImpl(
      category: json['category'] as String,
      displayName: json['displayName'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ConfigItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      updateTime: json['updateTime'] == null
          ? null
          : DateTime.parse(json['updateTime'] as String),
    );

Map<String, dynamic> _$$ConfigCategoryImplToJson(
        _$ConfigCategoryImpl instance) =>
    <String, dynamic>{
      'category': instance.category,
      'displayName': instance.displayName,
      'items': instance.items,
      'updateTime': instance.updateTime?.toIso8601String(),
    };
