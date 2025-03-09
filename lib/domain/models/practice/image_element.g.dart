// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_element.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ImageElementImpl _$$ImageElementImplFromJson(Map<String, dynamic> json) =>
    _$ImageElementImpl(
      imageId: json['imageId'] as String,
      url: json['url'] as String,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      mimeType: json['mimeType'] as String? ?? 'image/jpeg',
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      customProps: json['customProps'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$ImageElementImplToJson(_$ImageElementImpl instance) =>
    <String, dynamic>{
      'imageId': instance.imageId,
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
      'mimeType': instance.mimeType,
      'opacity': instance.opacity,
      'customProps': instance.customProps,
    };
