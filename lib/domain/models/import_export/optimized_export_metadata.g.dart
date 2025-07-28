// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'optimized_export_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OptimizedExportMetadataImpl _$$OptimizedExportMetadataImplFromJson(
        Map<String, dynamic> json) =>
    _$OptimizedExportMetadataImpl(
      dataVersion: json['dataVersion'] as String,
      exportTime: DateTime.parse(json['exportTime'] as String),
      platform: json['platform'] as String? ?? 'flutter',
      appVersion: json['appVersion'] as String,
      exportType: OptimizedExportType.fromJson(
          json['exportType'] as Map<String, dynamic>),
      options: OptimizedExportOptions.fromJson(
          json['options'] as Map<String, dynamic>),
      statistics: OptimizedExportStatistics.fromJson(
          json['statistics'] as Map<String, dynamic>),
      files: (json['files'] as List<dynamic>)
          .map((e) => OptimizedFileInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      checksums: OptimizedChecksumInfo.fromJson(
          json['checksums'] as Map<String, dynamic>),
      extensions: json['extensions'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$OptimizedExportMetadataImplToJson(
        _$OptimizedExportMetadataImpl instance) =>
    <String, dynamic>{
      'dataVersion': instance.dataVersion,
      'exportTime': instance.exportTime.toIso8601String(),
      'platform': instance.platform,
      'appVersion': instance.appVersion,
      'exportType': instance.exportType,
      'options': instance.options,
      'statistics': instance.statistics,
      'files': instance.files,
      'checksums': instance.checksums,
      'extensions': instance.extensions,
    };

_$OptimizedExportTypeImpl _$$OptimizedExportTypeImplFromJson(
        Map<String, dynamic> json) =>
    _$OptimizedExportTypeImpl(
      primary: json['primary'] as String,
      secondary: json['secondary'] as String?,
      includedDataTypes: (json['includedDataTypes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      includeRelatedData: json['includeRelatedData'] as bool? ?? false,
    );

Map<String, dynamic> _$$OptimizedExportTypeImplToJson(
        _$OptimizedExportTypeImpl instance) =>
    <String, dynamic>{
      'primary': instance.primary,
      'secondary': instance.secondary,
      'includedDataTypes': instance.includedDataTypes,
      'includeRelatedData': instance.includeRelatedData,
    };

_$OptimizedExportOptionsImpl _$$OptimizedExportOptionsImplFromJson(
        Map<String, dynamic> json) =>
    _$OptimizedExportOptionsImpl(
      compressionLevel: (json['compressionLevel'] as num?)?.toInt() ?? 6,
      includeImages: json['includeImages'] as bool? ?? true,
      includeMetadata: json['includeMetadata'] as bool? ?? true,
      generateThumbnails: json['generateThumbnails'] as bool? ?? false,
      imageQuality: (json['imageQuality'] as num?)?.toInt() ?? 85,
      maxImageSize: (json['maxImageSize'] as num?)?.toInt(),
      customOptions: json['customOptions'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$OptimizedExportOptionsImplToJson(
        _$OptimizedExportOptionsImpl instance) =>
    <String, dynamic>{
      'compressionLevel': instance.compressionLevel,
      'includeImages': instance.includeImages,
      'includeMetadata': instance.includeMetadata,
      'generateThumbnails': instance.generateThumbnails,
      'imageQuality': instance.imageQuality,
      'maxImageSize': instance.maxImageSize,
      'customOptions': instance.customOptions,
    };

_$OptimizedExportStatisticsImpl _$$OptimizedExportStatisticsImplFromJson(
        Map<String, dynamic> json) =>
    _$OptimizedExportStatisticsImpl(
      workCount: (json['workCount'] as num?)?.toInt() ?? 0,
      characterCount: (json['characterCount'] as num?)?.toInt() ?? 0,
      imageCount: (json['imageCount'] as num?)?.toInt() ?? 0,
      fileCount: (json['fileCount'] as num?)?.toInt() ?? 0,
      originalSize: (json['originalSize'] as num?)?.toInt() ?? 0,
      compressedSize: (json['compressedSize'] as num?)?.toInt() ?? 0,
      processingTimeMs: (json['processingTimeMs'] as num?)?.toInt() ?? 0,
      extendedStats: (json['extendedStats'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
    );

Map<String, dynamic> _$$OptimizedExportStatisticsImplToJson(
        _$OptimizedExportStatisticsImpl instance) =>
    <String, dynamic>{
      'workCount': instance.workCount,
      'characterCount': instance.characterCount,
      'imageCount': instance.imageCount,
      'fileCount': instance.fileCount,
      'originalSize': instance.originalSize,
      'compressedSize': instance.compressedSize,
      'processingTimeMs': instance.processingTimeMs,
      'extendedStats': instance.extendedStats,
    };

_$OptimizedFileInfoImpl _$$OptimizedFileInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$OptimizedFileInfoImpl(
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileType: json['fileType'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      checksum: json['checksum'] as String,
      mimeType: json['mimeType'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      attributes: json['attributes'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$OptimizedFileInfoImplToJson(
        _$OptimizedFileInfoImpl instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'filePath': instance.filePath,
      'fileType': instance.fileType,
      'fileSize': instance.fileSize,
      'checksum': instance.checksum,
      'mimeType': instance.mimeType,
      'createdAt': instance.createdAt?.toIso8601String(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'attributes': instance.attributes,
    };

_$OptimizedChecksumInfoImpl _$$OptimizedChecksumInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$OptimizedChecksumInfoImpl(
      overall: json['overall'] as String,
      dataChecksum: json['dataChecksum'] as String,
      filesChecksum: json['filesChecksum'] as String,
      algorithm: json['algorithm'] as String? ?? 'sha256',
      checksumTime: DateTime.parse(json['checksumTime'] as String),
    );

Map<String, dynamic> _$$OptimizedChecksumInfoImplToJson(
        _$OptimizedChecksumInfoImpl instance) =>
    <String, dynamic>{
      'overall': instance.overall,
      'dataChecksum': instance.dataChecksum,
      'filesChecksum': instance.filesChecksum,
      'algorithm': instance.algorithm,
      'checksumTime': instance.checksumTime.toIso8601String(),
    };

_$OptimizedCompatibilityInfoImpl _$$OptimizedCompatibilityInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$OptimizedCompatibilityInfoImpl(
      dataVersion: json['dataVersion'] as String,
      minRequiredAppVersion: json['minRequiredAppVersion'] as String,
      recommendedAppVersion: json['recommendedAppVersion'] as String,
      isBackwardCompatible: json['isBackwardCompatible'] as bool,
      compatibilityNotes: json['compatibilityNotes'] as String?,
    );

Map<String, dynamic> _$$OptimizedCompatibilityInfoImplToJson(
        _$OptimizedCompatibilityInfoImpl instance) =>
    <String, dynamic>{
      'dataVersion': instance.dataVersion,
      'minRequiredAppVersion': instance.minRequiredAppVersion,
      'recommendedAppVersion': instance.recommendedAppVersion,
      'isBackwardCompatible': instance.isBackwardCompatible,
      'compatibilityNotes': instance.compatibilityNotes,
    };
