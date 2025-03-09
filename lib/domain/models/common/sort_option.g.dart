// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sort_option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SortOptionImpl _$$SortOptionImplFromJson(Map<String, dynamic> json) =>
    _$SortOptionImpl(
      field: json['field'] == null
          ? SortField.createTime
          : _sortFieldFromJson(json['field']),
      descending: json['descending'] as bool? ?? true,
    );

Map<String, dynamic> _$$SortOptionImplToJson(_$SortOptionImpl instance) =>
    <String, dynamic>{
      'field': _sortFieldToJson(instance.field),
      'descending': instance.descending,
    };
