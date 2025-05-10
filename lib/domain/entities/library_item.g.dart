// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LibraryItemImpl _$$LibraryItemImplFromJson(Map<String, dynamic> json) =>
    _$LibraryItemImpl(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      type: json['type'] as String,
      format: json['format'] as String,
      path: json['path'] as String,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      fileSize: (json['fileSize'] as num).toInt(),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      isFavorite: json['isFavorite'] as bool? ?? false,
      remarks: json['remarks'] as String? ?? '',
      thumbnail:
          const Uint8ListConverter().fromJson(json['thumbnail'] as String?),
      fileCreatedAt: DateTime.parse(json['fileCreatedAt'] as String),
      fileUpdatedAt: DateTime.parse(json['fileUpdatedAt'] as String),
    );

Map<String, dynamic> _$$LibraryItemImplToJson(_$LibraryItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'type': instance.type,
      'format': instance.format,
      'path': instance.path,
      'width': instance.width,
      'height': instance.height,
      'fileSize': instance.fileSize,
      'tags': instance.tags,
      'categories': instance.categories,
      'metadata': instance.metadata,
      'isFavorite': instance.isFavorite,
      'remarks': instance.remarks,
      'thumbnail': const Uint8ListConverter().toJson(instance.thumbnail),
      'fileCreatedAt': instance.fileCreatedAt.toIso8601String(),
      'fileUpdatedAt': instance.fileUpdatedAt.toIso8601String(),
    };
