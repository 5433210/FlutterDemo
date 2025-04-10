import 'package:json_annotation/json_annotation.dart';

import '../../domain/models/character/character_region.dart';

/// Converts between CharacterRegion objects and JSON
class CharacterRegionConverter
    implements JsonConverter<CharacterRegion, Map<String, dynamic>> {
  const CharacterRegionConverter();

  @override
  CharacterRegion fromJson(Map<String, dynamic> json) {
    return CharacterRegion.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(CharacterRegion region) {
    return region.toJson();
  }
}
