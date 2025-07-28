// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_export_data_version_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ImportExportDataVersionInfoImpl _$$ImportExportDataVersionInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$ImportExportDataVersionInfoImpl(
      version: json['version'] as String,
      description: json['description'] as String,
      supportedAppVersions: (json['supportedAppVersions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      databaseVersionRange: (json['databaseVersionRange'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      features:
          (json['features'] as List<dynamic>).map((e) => e as String).toList(),
      releaseDate: json['releaseDate'] == null
          ? null
          : DateTime.parse(json['releaseDate'] as String),
      deprecated: json['deprecated'] as bool? ?? false,
      deprecationNote: json['deprecationNote'] as String?,
    );

Map<String, dynamic> _$$ImportExportDataVersionInfoImplToJson(
        _$ImportExportDataVersionInfoImpl instance) =>
    <String, dynamic>{
      'version': instance.version,
      'description': instance.description,
      'supportedAppVersions': instance.supportedAppVersions,
      'databaseVersionRange': instance.databaseVersionRange,
      'features': instance.features,
      'releaseDate': instance.releaseDate?.toIso8601String(),
      'deprecated': instance.deprecated,
      'deprecationNote': instance.deprecationNote,
    };
