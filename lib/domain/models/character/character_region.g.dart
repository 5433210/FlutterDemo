// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_region.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CharacterRegionImpl _$$CharacterRegionImplFromJson(
        Map<String, dynamic> json) =>
    _$CharacterRegionImpl(
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      pageIndex: (json['pageIndex'] as num).toInt(),
      isSaved: json['isSaved'] as bool? ?? false,
      label: json['label'] as String?,
      imagePath: json['imagePath'] as String,
    );

Map<String, dynamic> _$$CharacterRegionImplToJson(
        _$CharacterRegionImpl instance) =>
    <String, dynamic>{
      'left': instance.left,
      'top': instance.top,
      'width': instance.width,
      'height': instance.height,
      'rotation': instance.rotation,
      'pageIndex': instance.pageIndex,
      'isSaved': instance.isSaved,
      'label': instance.label,
      'imagePath': instance.imagePath,
    };
