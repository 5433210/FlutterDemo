// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pagination_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaginationSettingsImpl _$$PaginationSettingsImplFromJson(
        Map<String, dynamic> json) =>
    _$PaginationSettingsImpl(
      pageId: json['pageId'] as String,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$$PaginationSettingsImplToJson(
        _$PaginationSettingsImpl instance) =>
    <String, dynamic>{
      'pageId': instance.pageId,
      'pageSize': instance.pageSize,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };

_$AllPaginationSettingsImpl _$$AllPaginationSettingsImplFromJson(
        Map<String, dynamic> json) =>
    _$AllPaginationSettingsImpl(
      settings: (json['settings'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                k, PaginationSettings.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$$AllPaginationSettingsImplToJson(
        _$AllPaginationSettingsImpl instance) =>
    <String, dynamic>{
      'settings': instance.settings,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };
