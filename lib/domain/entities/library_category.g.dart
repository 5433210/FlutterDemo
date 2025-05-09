// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LibraryCategoryImpl _$$LibraryCategoryImplFromJson(
        Map<String, dynamic> json) =>
    _$LibraryCategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => LibraryCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$LibraryCategoryImplToJson(
        _$LibraryCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parentId': instance.parentId,
      'sortOrder': instance.sortOrder,
      'children': instance.children,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
