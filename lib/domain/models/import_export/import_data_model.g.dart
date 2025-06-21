// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ImportDataModelImpl _$$ImportDataModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ImportDataModelImpl(
      exportData:
          ExportDataModel.fromJson(json['exportData'] as Map<String, dynamic>),
      validation: ImportValidationResult.fromJson(
          json['validation'] as Map<String, dynamic>),
      conflicts: (json['conflicts'] as List<dynamic>?)
              ?.map(
                  (e) => ImportConflictInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      options: ImportOptions.fromJson(json['options'] as Map<String, dynamic>),
      status: $enumDecodeNullable(_$ImportStatusEnumMap, json['status']) ??
          ImportStatus.pending,
    );

Map<String, dynamic> _$$ImportDataModelImplToJson(
        _$ImportDataModelImpl instance) =>
    <String, dynamic>{
      'exportData': instance.exportData,
      'validation': instance.validation,
      'conflicts': instance.conflicts,
      'options': instance.options,
      'status': _$ImportStatusEnumMap[instance.status]!,
    };

const _$ImportStatusEnumMap = {
  ImportStatus.pending: 'pending',
  ImportStatus.validating: 'validating',
  ImportStatus.awaitingConfirmation: 'awaitingConfirmation',
  ImportStatus.importing: 'importing',
  ImportStatus.completed: 'completed',
  ImportStatus.failed: 'failed',
  ImportStatus.cancelled: 'cancelled',
};

_$ImportValidationResultImpl _$$ImportValidationResultImplFromJson(
        Map<String, dynamic> json) =>
    _$ImportValidationResultImpl(
      status: $enumDecode(_$ValidationStatusEnumMap, json['status']),
      isValid: json['isValid'] as bool? ?? false,
      messages: (json['messages'] as List<dynamic>?)
              ?.map(
                  (e) => ValidationMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      statistics: ImportDataStatistics.fromJson(
          json['statistics'] as Map<String, dynamic>),
      compatibility: CompatibilityCheckResult.fromJson(
          json['compatibility'] as Map<String, dynamic>),
      fileIntegrity: FileIntegrityResult.fromJson(
          json['fileIntegrity'] as Map<String, dynamic>),
      dataIntegrity: DataIntegrityResult.fromJson(
          json['dataIntegrity'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ImportValidationResultImplToJson(
        _$ImportValidationResultImpl instance) =>
    <String, dynamic>{
      'status': _$ValidationStatusEnumMap[instance.status]!,
      'isValid': instance.isValid,
      'messages': instance.messages,
      'statistics': instance.statistics,
      'compatibility': instance.compatibility,
      'fileIntegrity': instance.fileIntegrity,
      'dataIntegrity': instance.dataIntegrity,
    };

const _$ValidationStatusEnumMap = {
  ValidationStatus.passed: 'passed',
  ValidationStatus.warning: 'warning',
  ValidationStatus.failed: 'failed',
  ValidationStatus.skipped: 'skipped',
};

_$ValidationMessageImpl _$$ValidationMessageImplFromJson(
        Map<String, dynamic> json) =>
    _$ValidationMessageImpl(
      level: $enumDecode(_$ValidationLevelEnumMap, json['level']),
      type: $enumDecode(_$ValidationTypeEnumMap, json['type']),
      message: json['message'] as String,
      details: json['details'] as Map<String, dynamic>?,
      suggestedAction: json['suggestedAction'] as String?,
      canAutoFix: json['canAutoFix'] as bool? ?? false,
    );

Map<String, dynamic> _$$ValidationMessageImplToJson(
        _$ValidationMessageImpl instance) =>
    <String, dynamic>{
      'level': _$ValidationLevelEnumMap[instance.level]!,
      'type': _$ValidationTypeEnumMap[instance.type]!,
      'message': instance.message,
      'details': instance.details,
      'suggestedAction': instance.suggestedAction,
      'canAutoFix': instance.canAutoFix,
    };

const _$ValidationLevelEnumMap = {
  ValidationLevel.info: 'info',
  ValidationLevel.warning: 'warning',
  ValidationLevel.error: 'error',
  ValidationLevel.fatal: 'fatal',
};

const _$ValidationTypeEnumMap = {
  ValidationType.format: 'format',
  ValidationType.integrity: 'integrity',
  ValidationType.compatibility: 'compatibility',
  ValidationType.relationship: 'relationship',
  ValidationType.businessRule: 'businessRule',
};

_$ImportConflictInfoImpl _$$ImportConflictInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$ImportConflictInfoImpl(
      type: $enumDecode(_$ConflictTypeEnumMap, json['type']),
      entityType: $enumDecode(_$EntityTypeEnumMap, json['entityType']),
      entityId: json['entityId'] as String,
      existingData: json['existingData'] as Map<String, dynamic>,
      importData: json['importData'] as Map<String, dynamic>,
      conflictFields: (json['conflictFields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      resolution:
          $enumDecodeNullable(_$ConflictResolutionEnumMap, json['resolution']),
      description: json['description'] as String,
    );

Map<String, dynamic> _$$ImportConflictInfoImplToJson(
        _$ImportConflictInfoImpl instance) =>
    <String, dynamic>{
      'type': _$ConflictTypeEnumMap[instance.type]!,
      'entityType': _$EntityTypeEnumMap[instance.entityType]!,
      'entityId': instance.entityId,
      'existingData': instance.existingData,
      'importData': instance.importData,
      'conflictFields': instance.conflictFields,
      'resolution': _$ConflictResolutionEnumMap[instance.resolution],
      'description': instance.description,
    };

const _$ConflictTypeEnumMap = {
  ConflictType.idConflict: 'idConflict',
  ConflictType.dataConflict: 'dataConflict',
  ConflictType.fileConflict: 'fileConflict',
  ConflictType.versionConflict: 'versionConflict',
};

const _$EntityTypeEnumMap = {
  EntityType.work: 'work',
  EntityType.workImage: 'workImage',
  EntityType.character: 'character',
  EntityType.config: 'config',
};

const _$ConflictResolutionEnumMap = {
  ConflictResolution.ask: 'ask',
  ConflictResolution.skip: 'skip',
  ConflictResolution.overwrite: 'overwrite',
  ConflictResolution.keepExisting: 'keepExisting',
  ConflictResolution.rename: 'rename',
  ConflictResolution.merge: 'merge',
};

_$ImportDataStatisticsImpl _$$ImportDataStatisticsImplFromJson(
        Map<String, dynamic> json) =>
    _$ImportDataStatisticsImpl(
      totalWorks: (json['totalWorks'] as num?)?.toInt() ?? 0,
      totalCharacters: (json['totalCharacters'] as num?)?.toInt() ?? 0,
      totalImages: (json['totalImages'] as num?)?.toInt() ?? 0,
      validWorks: (json['validWorks'] as num?)?.toInt() ?? 0,
      validCharacters: (json['validCharacters'] as num?)?.toInt() ?? 0,
      validImages: (json['validImages'] as num?)?.toInt() ?? 0,
      conflictWorks: (json['conflictWorks'] as num?)?.toInt() ?? 0,
      conflictCharacters: (json['conflictCharacters'] as num?)?.toInt() ?? 0,
      corruptedFiles: (json['corruptedFiles'] as num?)?.toInt() ?? 0,
      missingFiles: (json['missingFiles'] as num?)?.toInt() ?? 0,
      estimatedImportTime: (json['estimatedImportTime'] as num?)?.toInt() ?? 0,
      estimatedStorageSize:
          (json['estimatedStorageSize'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ImportDataStatisticsImplToJson(
        _$ImportDataStatisticsImpl instance) =>
    <String, dynamic>{
      'totalWorks': instance.totalWorks,
      'totalCharacters': instance.totalCharacters,
      'totalImages': instance.totalImages,
      'validWorks': instance.validWorks,
      'validCharacters': instance.validCharacters,
      'validImages': instance.validImages,
      'conflictWorks': instance.conflictWorks,
      'conflictCharacters': instance.conflictCharacters,
      'corruptedFiles': instance.corruptedFiles,
      'missingFiles': instance.missingFiles,
      'estimatedImportTime': instance.estimatedImportTime,
      'estimatedStorageSize': instance.estimatedStorageSize,
    };

_$CompatibilityCheckResultImpl _$$CompatibilityCheckResultImplFromJson(
        Map<String, dynamic> json) =>
    _$CompatibilityCheckResultImpl(
      isCompatible: json['isCompatible'] as bool? ?? false,
      dataFormatVersion: json['dataFormatVersion'] as String,
      appVersion: json['appVersion'] as String,
      level: $enumDecode(_$CompatibilityLevelEnumMap, json['level']),
      incompatibleFeatures: (json['incompatibleFeatures'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      requiresMigration: json['requiresMigration'] as bool? ?? false,
    );

Map<String, dynamic> _$$CompatibilityCheckResultImplToJson(
        _$CompatibilityCheckResultImpl instance) =>
    <String, dynamic>{
      'isCompatible': instance.isCompatible,
      'dataFormatVersion': instance.dataFormatVersion,
      'appVersion': instance.appVersion,
      'level': _$CompatibilityLevelEnumMap[instance.level]!,
      'incompatibleFeatures': instance.incompatibleFeatures,
      'warnings': instance.warnings,
      'requiresMigration': instance.requiresMigration,
    };

const _$CompatibilityLevelEnumMap = {
  CompatibilityLevel.fullCompatible: 'fullCompatible',
  CompatibilityLevel.partialCompatible: 'partialCompatible',
  CompatibilityLevel.incompatibleButImportable: 'incompatibleButImportable',
  CompatibilityLevel.incompatible: 'incompatible',
};

_$FileIntegrityResultImpl _$$FileIntegrityResultImplFromJson(
        Map<String, dynamic> json) =>
    _$FileIntegrityResultImpl(
      isIntact: json['isIntact'] as bool? ?? false,
      totalFiles: (json['totalFiles'] as num?)?.toInt() ?? 0,
      validFiles: (json['validFiles'] as num?)?.toInt() ?? 0,
      corruptedFiles: (json['corruptedFiles'] as List<dynamic>?)
              ?.map(
                  (e) => CorruptedFileInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      missingFiles: (json['missingFiles'] as List<dynamic>?)
              ?.map((e) => MissingFileInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      checksumResults: (json['checksumResults'] as List<dynamic>?)
              ?.map(
                  (e) => ChecksumValidation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$FileIntegrityResultImplToJson(
        _$FileIntegrityResultImpl instance) =>
    <String, dynamic>{
      'isIntact': instance.isIntact,
      'totalFiles': instance.totalFiles,
      'validFiles': instance.validFiles,
      'corruptedFiles': instance.corruptedFiles,
      'missingFiles': instance.missingFiles,
      'checksumResults': instance.checksumResults,
    };

_$DataIntegrityResultImpl _$$DataIntegrityResultImplFromJson(
        Map<String, dynamic> json) =>
    _$DataIntegrityResultImpl(
      isIntact: json['isIntact'] as bool? ?? false,
      relationships: (json['relationships'] as List<dynamic>?)
              ?.map((e) =>
                  RelationshipValidation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      formats: (json['formats'] as List<dynamic>?)
              ?.map((e) => FormatValidation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      requiredFields: (json['requiredFields'] as List<dynamic>?)
              ?.map((e) =>
                  RequiredFieldValidation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      consistency: (json['consistency'] as List<dynamic>?)
              ?.map((e) =>
                  ConsistencyValidation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$DataIntegrityResultImplToJson(
        _$DataIntegrityResultImpl instance) =>
    <String, dynamic>{
      'isIntact': instance.isIntact,
      'relationships': instance.relationships,
      'formats': instance.formats,
      'requiredFields': instance.requiredFields,
      'consistency': instance.consistency,
    };

_$CorruptedFileInfoImpl _$$CorruptedFileInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$CorruptedFileInfoImpl(
      filePath: json['filePath'] as String,
      fileType: $enumDecode(_$ExportFileTypeEnumMap, json['fileType']),
      corruptionType:
          $enumDecode(_$CorruptionTypeEnumMap, json['corruptionType']),
      errorDescription: json['errorDescription'] as String,
      canRecover: json['canRecover'] as bool? ?? false,
      recoverySuggestion: json['recoverySuggestion'] as String?,
    );

Map<String, dynamic> _$$CorruptedFileInfoImplToJson(
        _$CorruptedFileInfoImpl instance) =>
    <String, dynamic>{
      'filePath': instance.filePath,
      'fileType': _$ExportFileTypeEnumMap[instance.fileType]!,
      'corruptionType': _$CorruptionTypeEnumMap[instance.corruptionType]!,
      'errorDescription': instance.errorDescription,
      'canRecover': instance.canRecover,
      'recoverySuggestion': instance.recoverySuggestion,
    };

const _$ExportFileTypeEnumMap = {
  ExportFileType.data: 'data',
  ExportFileType.image: 'image',
  ExportFileType.thumbnail: 'thumbnail',
  ExportFileType.metadata: 'metadata',
  ExportFileType.manifest: 'manifest',
  ExportFileType.config: 'config',
};

const _$CorruptionTypeEnumMap = {
  CorruptionType.fileNotFound: 'fileNotFound',
  CorruptionType.fileCorrupted: 'fileCorrupted',
  CorruptionType.formatError: 'formatError',
  CorruptionType.checksumMismatch: 'checksumMismatch',
  CorruptionType.permissionError: 'permissionError',
};

_$MissingFileInfoImpl _$$MissingFileInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$MissingFileInfoImpl(
      filePath: json['filePath'] as String,
      fileType: $enumDecode(_$ExportFileTypeEnumMap, json['fileType']),
      isRequired: json['isRequired'] as bool? ?? true,
      affectedEntities: (json['affectedEntities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      alternative: json['alternative'] as String?,
    );

Map<String, dynamic> _$$MissingFileInfoImplToJson(
        _$MissingFileInfoImpl instance) =>
    <String, dynamic>{
      'filePath': instance.filePath,
      'fileType': _$ExportFileTypeEnumMap[instance.fileType]!,
      'isRequired': instance.isRequired,
      'affectedEntities': instance.affectedEntities,
      'alternative': instance.alternative,
    };

_$ChecksumValidationImpl _$$ChecksumValidationImplFromJson(
        Map<String, dynamic> json) =>
    _$ChecksumValidationImpl(
      filePath: json['filePath'] as String,
      expectedChecksum: json['expectedChecksum'] as String,
      actualChecksum: json['actualChecksum'] as String,
      isValid: json['isValid'] as bool? ?? false,
      algorithm: json['algorithm'] as String? ?? 'MD5',
    );

Map<String, dynamic> _$$ChecksumValidationImplToJson(
        _$ChecksumValidationImpl instance) =>
    <String, dynamic>{
      'filePath': instance.filePath,
      'expectedChecksum': instance.expectedChecksum,
      'actualChecksum': instance.actualChecksum,
      'isValid': instance.isValid,
      'algorithm': instance.algorithm,
    };

_$RelationshipValidationImpl _$$RelationshipValidationImplFromJson(
        Map<String, dynamic> json) =>
    _$RelationshipValidationImpl(
      type: $enumDecode(_$RelationshipTypeEnumMap, json['type']),
      parentId: json['parentId'] as String,
      childId: json['childId'] as String,
      isValid: json['isValid'] as bool? ?? false,
      errorDescription: json['errorDescription'] as String?,
    );

Map<String, dynamic> _$$RelationshipValidationImplToJson(
        _$RelationshipValidationImpl instance) =>
    <String, dynamic>{
      'type': _$RelationshipTypeEnumMap[instance.type]!,
      'parentId': instance.parentId,
      'childId': instance.childId,
      'isValid': instance.isValid,
      'errorDescription': instance.errorDescription,
    };

const _$RelationshipTypeEnumMap = {
  RelationshipType.workImage: 'workImage',
  RelationshipType.workCharacter: 'workCharacter',
  RelationshipType.imageFile: 'imageFile',
};

_$FormatValidationImpl _$$FormatValidationImplFromJson(
        Map<String, dynamic> json) =>
    _$FormatValidationImpl(
      entityType: $enumDecode(_$EntityTypeEnumMap, json['entityType']),
      entityId: json['entityId'] as String,
      fieldName: json['fieldName'] as String,
      isValid: json['isValid'] as bool? ?? false,
      errorDescription: json['errorDescription'] as String?,
      suggestedValue: json['suggestedValue'] as String?,
    );

Map<String, dynamic> _$$FormatValidationImplToJson(
        _$FormatValidationImpl instance) =>
    <String, dynamic>{
      'entityType': _$EntityTypeEnumMap[instance.entityType]!,
      'entityId': instance.entityId,
      'fieldName': instance.fieldName,
      'isValid': instance.isValid,
      'errorDescription': instance.errorDescription,
      'suggestedValue': instance.suggestedValue,
    };

_$RequiredFieldValidationImpl _$$RequiredFieldValidationImplFromJson(
        Map<String, dynamic> json) =>
    _$RequiredFieldValidationImpl(
      entityType: $enumDecode(_$EntityTypeEnumMap, json['entityType']),
      entityId: json['entityId'] as String,
      missingFields: (json['missingFields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isValid: json['isValid'] as bool? ?? false,
    );

Map<String, dynamic> _$$RequiredFieldValidationImplToJson(
        _$RequiredFieldValidationImpl instance) =>
    <String, dynamic>{
      'entityType': _$EntityTypeEnumMap[instance.entityType]!,
      'entityId': instance.entityId,
      'missingFields': instance.missingFields,
      'isValid': instance.isValid,
    };

_$ConsistencyValidationImpl _$$ConsistencyValidationImplFromJson(
        Map<String, dynamic> json) =>
    _$ConsistencyValidationImpl(
      type: $enumDecode(_$ConsistencyTypeEnumMap, json['type']),
      entities: (json['entities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isConsistent: json['isConsistent'] as bool? ?? false,
      inconsistencyDescription: json['inconsistencyDescription'] as String?,
      fixSuggestion: json['fixSuggestion'] as String?,
    );

Map<String, dynamic> _$$ConsistencyValidationImplToJson(
        _$ConsistencyValidationImpl instance) =>
    <String, dynamic>{
      'type': _$ConsistencyTypeEnumMap[instance.type]!,
      'entities': instance.entities,
      'isConsistent': instance.isConsistent,
      'inconsistencyDescription': instance.inconsistencyDescription,
      'fixSuggestion': instance.fixSuggestion,
    };

const _$ConsistencyTypeEnumMap = {
  ConsistencyType.dataConsistency: 'dataConsistency',
  ConsistencyType.referenceConsistency: 'referenceConsistency',
  ConsistencyType.businessLogicConsistency: 'businessLogicConsistency',
};

_$ImportOptionsImpl _$$ImportOptionsImplFromJson(Map<String, dynamic> json) =>
    _$ImportOptionsImpl(
      defaultConflictResolution: $enumDecodeNullable(
              _$ConflictResolutionEnumMap, json['defaultConflictResolution']) ??
          ConflictResolution.ask,
      overwriteExisting: json['overwriteExisting'] as bool? ?? false,
      skipCorruptedFiles: json['skipCorruptedFiles'] as bool? ?? true,
      createBackup: json['createBackup'] as bool? ?? true,
      validateFileIntegrity: json['validateFileIntegrity'] as bool? ?? true,
      autoFixErrors: json['autoFixErrors'] as bool? ?? true,
      targetDirectory: json['targetDirectory'] as String?,
      customOptions: json['customOptions'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$ImportOptionsImplToJson(_$ImportOptionsImpl instance) =>
    <String, dynamic>{
      'defaultConflictResolution':
          _$ConflictResolutionEnumMap[instance.defaultConflictResolution]!,
      'overwriteExisting': instance.overwriteExisting,
      'skipCorruptedFiles': instance.skipCorruptedFiles,
      'createBackup': instance.createBackup,
      'validateFileIntegrity': instance.validateFileIntegrity,
      'autoFixErrors': instance.autoFixErrors,
      'targetDirectory': instance.targetDirectory,
      'customOptions': instance.customOptions,
    };
