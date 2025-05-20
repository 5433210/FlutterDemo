// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_navigation_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GlobalNavigationStateImpl _$$GlobalNavigationStateImplFromJson(
        Map<String, dynamic> json) =>
    _$GlobalNavigationStateImpl(
      currentSectionIndex: (json['currentSectionIndex'] as num?)?.toInt() ?? 0,
      history: (json['history'] as List<dynamic>?)
              ?.map((e) =>
                  NavigationHistoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sectionRoutes: (json['sectionRoutes'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(int.parse(k), e as String?),
          ) ??
          const {},
      isNavigationExtended: json['isNavigationExtended'] as bool? ?? true,
      isNavigating: json['isNavigating'] as bool? ?? false,
      lastNavigationTime: json['lastNavigationTime'] == null
          ? null
          : DateTime.parse(json['lastNavigationTime'] as String),
      canPopInSection: (json['canPopInSection'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(int.parse(k), e as bool),
          ) ??
          const {},
    );

Map<String, dynamic> _$$GlobalNavigationStateImplToJson(
        _$GlobalNavigationStateImpl instance) =>
    <String, dynamic>{
      'currentSectionIndex': instance.currentSectionIndex,
      'history': instance.history,
      'sectionRoutes':
          instance.sectionRoutes.map((k, e) => MapEntry(k.toString(), e)),
      'isNavigationExtended': instance.isNavigationExtended,
      'isNavigating': instance.isNavigating,
      'lastNavigationTime': instance.lastNavigationTime?.toIso8601String(),
      'canPopInSection':
          instance.canPopInSection.map((k, e) => MapEntry(k.toString(), e)),
    };
