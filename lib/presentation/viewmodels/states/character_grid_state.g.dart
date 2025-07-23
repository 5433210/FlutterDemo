// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_grid_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CharacterGridStateImpl _$$CharacterGridStateImplFromJson(
        Map<String, dynamic> json) =>
    _$CharacterGridStateImpl(
      characters: (json['characters'] as List<dynamic>?)
              ?.map(
                  (e) => CharacterViewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      filteredCharacters: (json['filteredCharacters'] as List<dynamic>?)
              ?.map(
                  (e) => CharacterViewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      searchTerm: json['searchTerm'] as String? ?? '',
      filterType:
          $enumDecodeNullable(_$FilterTypeEnumMap, json['filterType']) ??
              FilterType.all,
      selectedIds: (json['selectedIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 16,
      loading: json['loading'] as bool? ?? false,
      isInitialLoad: json['isInitialLoad'] as bool? ?? true,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$CharacterGridStateImplToJson(
        _$CharacterGridStateImpl instance) =>
    <String, dynamic>{
      'characters': instance.characters,
      'filteredCharacters': instance.filteredCharacters,
      'searchTerm': instance.searchTerm,
      'filterType': _$FilterTypeEnumMap[instance.filterType]!,
      'selectedIds': instance.selectedIds.toList(),
      'currentPage': instance.currentPage,
      'totalPages': instance.totalPages,
      'pageSize': instance.pageSize,
      'loading': instance.loading,
      'isInitialLoad': instance.isInitialLoad,
      'error': instance.error,
    };

const _$FilterTypeEnumMap = {
  FilterType.all: 'all',
  FilterType.recent: 'recent',
  FilterType.favorite: 'favorite',
};

_$CharacterViewModelImpl _$$CharacterViewModelImplFromJson(
        Map<String, dynamic> json) =>
    _$CharacterViewModelImpl(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      character: json['character'] as String,
      thumbnailPath: json['thumbnailPath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      isSelected: json['isSelected'] as bool? ?? false,
      isModified: json['isModified'] as bool? ?? false,
    );

Map<String, dynamic> _$$CharacterViewModelImplToJson(
        _$CharacterViewModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pageId': instance.pageId,
      'character': instance.character,
      'thumbnailPath': instance.thumbnailPath,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isFavorite': instance.isFavorite,
      'isSelected': instance.isSelected,
      'isModified': instance.isModified,
    };
