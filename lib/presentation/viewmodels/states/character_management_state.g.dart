// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_management_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CharacterFilterConverter _$CharacterFilterConverterFromJson(
        Map<String, dynamic> json) =>
    CharacterFilterConverter();

Map<String, dynamic> _$CharacterFilterConverterToJson(
        CharacterFilterConverter instance) =>
    <String, dynamic>{};

_$CharacterManagementStateImpl _$$CharacterManagementStateImplFromJson(
        Map<String, dynamic> json) =>
    _$CharacterManagementStateImpl(
      characters: (json['characters'] as List<dynamic>?)
              ?.map((e) => CharacterView.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      allTags: (json['allTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      filter: json['filter'] == null
          ? const CharacterFilter()
          : CharacterFilter.fromJson(json['filter'] as Map<String, dynamic>),
      isLoading: json['isLoading'] as bool? ?? false,
      isBatchMode: json['isBatchMode'] as bool? ?? false,
      selectedCharacters: (json['selectedCharacters'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      isDetailOpen: json['isDetailOpen'] as bool? ?? false,
      showFilterPanel: json['showFilterPanel'] as bool? ?? true,
      errorMessage: json['errorMessage'] as String?,
      selectedCharacterId: json['selectedCharacterId'] as String?,
      viewMode: $enumDecodeNullable(_$ViewModeEnumMap, json['viewMode']) ??
          ViewMode.grid,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
    );

Map<String, dynamic> _$$CharacterManagementStateImplToJson(
        _$CharacterManagementStateImpl instance) =>
    <String, dynamic>{
      'characters': instance.characters,
      'allTags': instance.allTags,
      'filter': instance.filter,
      'isLoading': instance.isLoading,
      'isBatchMode': instance.isBatchMode,
      'selectedCharacters': instance.selectedCharacters.toList(),
      'isDetailOpen': instance.isDetailOpen,
      'showFilterPanel': instance.showFilterPanel,
      'errorMessage': instance.errorMessage,
      'selectedCharacterId': instance.selectedCharacterId,
      'viewMode': _$ViewModeEnumMap[instance.viewMode]!,
      'totalCount': instance.totalCount,
      'currentPage': instance.currentPage,
      'pageSize': instance.pageSize,
    };

const _$ViewModeEnumMap = {
  ViewMode.grid: 'grid',
  ViewMode.list: 'list',
};
