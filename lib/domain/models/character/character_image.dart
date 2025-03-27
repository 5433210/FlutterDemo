import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../infrastructure/utils/json_converters.dart';
import 'character_region.dart';
import 'processing_options.dart';

part 'character_image.freezed.dart';
part 'character_image.g.dart';

@freezed
class CharacterImage with _$CharacterImage {
  const factory CharacterImage({
    required String id,
    required String originalPath,
    required String binaryPath,
    required String thumbnailPath,
    String? svgPath, // 新增：SVG轮廓路径
    @SizeConverter() required Size originalSize,
    required ProcessingOptions options,
  }) = _CharacterImage;

  factory CharacterImage.fromJson(Map<String, dynamic> json) =>
      _$CharacterImageFromJson(json);

  factory CharacterImage.fromRegion(CharacterRegion region, String originalPath,
      String binaryPath, String thumbnailPath, String? svgPath) {
    return CharacterImage(
      id: region.id,
      originalPath: originalPath,
      binaryPath: binaryPath,
      thumbnailPath: thumbnailPath,
      svgPath: svgPath,
      originalSize: Size(region.rect.width, region.rect.height),
      options: region.options,
    );
  }
}
