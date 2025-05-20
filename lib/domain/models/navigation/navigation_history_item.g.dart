// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_history_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NavigationHistoryItemImpl _$$NavigationHistoryItemImplFromJson(
        Map<String, dynamic> json) =>
    _$NavigationHistoryItemImpl(
      sectionIndex: (json['sectionIndex'] as num).toInt(),
      routePath: json['routePath'] as String?,
      routeParams: json['routeParams'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$NavigationHistoryItemImplToJson(
        _$NavigationHistoryItemImpl instance) =>
    <String, dynamic>{
      'sectionIndex': instance.sectionIndex,
      'routePath': instance.routePath,
      'routeParams': instance.routeParams,
      'timestamp': instance.timestamp.toIso8601String(),
    };
