// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_element.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TextElementImpl _$$TextElementImplFromJson(Map<String, dynamic> json) =>
    _$TextElementImpl(
      text: json['text'] as String,
      fontFamily: json['fontFamily'] as String? ?? 'Arial',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      color: json['color'] as String? ?? '#000000',
      textAlign: $enumDecodeNullable(_$TextAlignEnumMap, json['textAlign']) ??
          TextAlign.left,
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
      underline: json['underline'] as bool? ?? false,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.2,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      customStyle: json['customStyle'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$TextElementImplToJson(_$TextElementImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'fontFamily': instance.fontFamily,
      'fontSize': instance.fontSize,
      'color': instance.color,
      'textAlign': _$TextAlignEnumMap[instance.textAlign]!,
      'bold': instance.bold,
      'italic': instance.italic,
      'underline': instance.underline,
      'lineHeight': instance.lineHeight,
      'letterSpacing': instance.letterSpacing,
      'customStyle': instance.customStyle,
    };

const _$TextAlignEnumMap = {
  TextAlign.left: 'left',
  TextAlign.right: 'right',
  TextAlign.center: 'center',
  TextAlign.justify: 'justify',
  TextAlign.start: 'start',
  TextAlign.end: 'end',
};
