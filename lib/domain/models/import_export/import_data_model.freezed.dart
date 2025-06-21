// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'import_data_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ImportDataModel _$ImportDataModelFromJson(Map<String, dynamic> json) {
  return _ImportDataModel.fromJson(json);
}

/// @nodoc
mixin _$ImportDataModel {
  /// 解析的导出数据
  ExportDataModel get exportData => throw _privateConstructorUsedError;

  /// 验证结果
  ImportValidationResult get validation => throw _privateConstructorUsedError;

  /// 冲突信息
  List<ImportConflictInfo> get conflicts => throw _privateConstructorUsedError;

  /// 导入选项
  ImportOptions get options => throw _privateConstructorUsedError;

  /// 导入状态
  ImportStatus get status => throw _privateConstructorUsedError;

  /// Serializes this ImportDataModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ImportDataModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ImportDataModelCopyWith<ImportDataModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImportDataModelCopyWith<$Res> {
  factory $ImportDataModelCopyWith(
          ImportDataModel value, $Res Function(ImportDataModel) then) =
      _$ImportDataModelCopyWithImpl<$Res, ImportDataModel>;
  @useResult
  $Res call(
      {ExportDataModel exportData,
      ImportValidationResult validation,
      List<ImportConflictInfo> conflicts,
      ImportOptions options,
      ImportStatus status});

  $ExportDataModelCopyWith<$Res> get exportData;
  $ImportValidationResultCopyWith<$Res> get validation;
  $ImportOptionsCopyWith<$Res> get options;
}

/// @nodoc
class _$ImportDataModelCopyWithImpl<$Res, $Val extends ImportDataModel>
    implements $ImportDataModelCopyWith<$Res> {
  _$ImportDataModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ImportDataModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exportData = null,
    Object? validation = null,
    Object? conflicts = null,
    Object? options = null,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      exportData: null == exportData
          ? _value.exportData
          : exportData // ignore: cast_nullable_to_non_nullable
              as ExportDataModel,
      validation: null == validation
          ? _value.validation
          : validation // ignore: cast_nullable_to_non_nullable
              as ImportValidationResult,
      conflicts: null == conflicts
          ? _value.conflicts
          : conflicts // ignore: cast_nullable_to_non_nullable
              as List<ImportConflictInfo>,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as ImportOptions,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ImportStatus,
    ) as $Val);
  }

  /// Create a copy of ImportDataModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExportDataModelCopyWith<$Res> get exportData {
    return $ExportDataModelCopyWith<$Res>(_value.exportData, (value) {
      return _then(_value.copyWith(exportData: value) as $Val);
    });
  }

  /// Create a copy of ImportDataModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ImportValidationResultCopyWith<$Res> get validation {
    return $ImportValidationResultCopyWith<$Res>(_value.validation, (value) {
      return _then(_value.copyWith(validation: value) as $Val);
    });
  }

  /// Create a copy of ImportDataModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ImportOptionsCopyWith<$Res> get options {
    return $ImportOptionsCopyWith<$Res>(_value.options, (value) {
      return _then(_value.copyWith(options: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ImportDataModelImplCopyWith<$Res>
    implements $ImportDataModelCopyWith<$Res> {
  factory _$$ImportDataModelImplCopyWith(_$ImportDataModelImpl value,
          $Res Function(_$ImportDataModelImpl) then) =
      __$$ImportDataModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ExportDataModel exportData,
      ImportValidationResult validation,
      List<ImportConflictInfo> conflicts,
      ImportOptions options,
      ImportStatus status});

  @override
  $ExportDataModelCopyWith<$Res> get exportData;
  @override
  $ImportValidationResultCopyWith<$Res> get validation;
  @override
  $ImportOptionsCopyWith<$Res> get options;
}

/// @nodoc
class __$$ImportDataModelImplCopyWithImpl<$Res>
    extends _$ImportDataModelCopyWithImpl<$Res, _$ImportDataModelImpl>
    implements _$$ImportDataModelImplCopyWith<$Res> {
  __$$ImportDataModelImplCopyWithImpl(
      _$ImportDataModelImpl _value, $Res Function(_$ImportDataModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ImportDataModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exportData = null,
    Object? validation = null,
    Object? conflicts = null,
    Object? options = null,
    Object? status = null,
  }) {
    return _then(_$ImportDataModelImpl(
      exportData: null == exportData
          ? _value.exportData
          : exportData // ignore: cast_nullable_to_non_nullable
              as ExportDataModel,
      validation: null == validation
          ? _value.validation
          : validation // ignore: cast_nullable_to_non_nullable
              as ImportValidationResult,
      conflicts: null == conflicts
          ? _value._conflicts
          : conflicts // ignore: cast_nullable_to_non_nullable
              as List<ImportConflictInfo>,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as ImportOptions,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ImportStatus,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ImportDataModelImpl implements _ImportDataModel {
  const _$ImportDataModelImpl(
      {required this.exportData,
      required this.validation,
      final List<ImportConflictInfo> conflicts = const [],
      required this.options,
      this.status = ImportStatus.pending})
      : _conflicts = conflicts;

  factory _$ImportDataModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImportDataModelImplFromJson(json);

  /// 解析的导出数据
  @override
  final ExportDataModel exportData;

  /// 验证结果
  @override
  final ImportValidationResult validation;

  /// 冲突信息
  final List<ImportConflictInfo> _conflicts;

  /// 冲突信息
  @override
  @JsonKey()
  List<ImportConflictInfo> get conflicts {
    if (_conflicts is EqualUnmodifiableListView) return _conflicts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_conflicts);
  }

  /// 导入选项
  @override
  final ImportOptions options;

  /// 导入状态
  @override
  @JsonKey()
  final ImportStatus status;

  @override
  String toString() {
    return 'ImportDataModel(exportData: $exportData, validation: $validation, conflicts: $conflicts, options: $options, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImportDataModelImpl &&
            (identical(other.exportData, exportData) ||
                other.exportData == exportData) &&
            (identical(other.validation, validation) ||
                other.validation == validation) &&
            const DeepCollectionEquality()
                .equals(other._conflicts, _conflicts) &&
            (identical(other.options, options) || other.options == options) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, exportData, validation,
      const DeepCollectionEquality().hash(_conflicts), options, status);

  /// Create a copy of ImportDataModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImportDataModelImplCopyWith<_$ImportDataModelImpl> get copyWith =>
      __$$ImportDataModelImplCopyWithImpl<_$ImportDataModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ImportDataModelImplToJson(
      this,
    );
  }
}

abstract class _ImportDataModel implements ImportDataModel {
  const factory _ImportDataModel(
      {required final ExportDataModel exportData,
      required final ImportValidationResult validation,
      final List<ImportConflictInfo> conflicts,
      required final ImportOptions options,
      final ImportStatus status}) = _$ImportDataModelImpl;

  factory _ImportDataModel.fromJson(Map<String, dynamic> json) =
      _$ImportDataModelImpl.fromJson;

  /// 解析的导出数据
  @override
  ExportDataModel get exportData;

  /// 验证结果
  @override
  ImportValidationResult get validation;

  /// 冲突信息
  @override
  List<ImportConflictInfo> get conflicts;

  /// 导入选项
  @override
  ImportOptions get options;

  /// 导入状态
  @override
  ImportStatus get status;

  /// Create a copy of ImportDataModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImportDataModelImplCopyWith<_$ImportDataModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ImportValidationResult _$ImportValidationResultFromJson(
    Map<String, dynamic> json) {
  return _ImportValidationResult.fromJson(json);
}

/// @nodoc
mixin _$ImportValidationResult {
  /// 验证状态
  ValidationStatus get status => throw _privateConstructorUsedError;

  /// 是否通过验证
  bool get isValid => throw _privateConstructorUsedError;

  /// 验证消息列表
  List<ValidationMessage> get messages => throw _privateConstructorUsedError;

  /// 数据统计
  ImportDataStatistics get statistics => throw _privateConstructorUsedError;

  /// 兼容性检查结果
  CompatibilityCheckResult get compatibility =>
      throw _privateConstructorUsedError;

  /// 文件完整性检查结果
  FileIntegrityResult get fileIntegrity => throw _privateConstructorUsedError;

  /// 数据完整性检查结果
  DataIntegrityResult get dataIntegrity => throw _privateConstructorUsedError;

  /// Serializes this ImportValidationResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ImportValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ImportValidationResultCopyWith<ImportValidationResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImportValidationResultCopyWith<$Res> {
  factory $ImportValidationResultCopyWith(ImportValidationResult value,
          $Res Function(ImportValidationResult) then) =
      _$ImportValidationResultCopyWithImpl<$Res, ImportValidationResult>;
  @useResult
  $Res call(
      {ValidationStatus status,
      bool isValid,
      List<ValidationMessage> messages,
      ImportDataStatistics statistics,
      CompatibilityCheckResult compatibility,
      FileIntegrityResult fileIntegrity,
      DataIntegrityResult dataIntegrity});

  $ImportDataStatisticsCopyWith<$Res> get statistics;
  $CompatibilityCheckResultCopyWith<$Res> get compatibility;
  $FileIntegrityResultCopyWith<$Res> get fileIntegrity;
  $DataIntegrityResultCopyWith<$Res> get dataIntegrity;
}

/// @nodoc
class _$ImportValidationResultCopyWithImpl<$Res,
        $Val extends ImportValidationResult>
    implements $ImportValidationResultCopyWith<$Res> {
  _$ImportValidationResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ImportValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? isValid = null,
    Object? messages = null,
    Object? statistics = null,
    Object? compatibility = null,
    Object? fileIntegrity = null,
    Object? dataIntegrity = null,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ValidationStatus,
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      messages: null == messages
          ? _value.messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<ValidationMessage>,
      statistics: null == statistics
          ? _value.statistics
          : statistics // ignore: cast_nullable_to_non_nullable
              as ImportDataStatistics,
      compatibility: null == compatibility
          ? _value.compatibility
          : compatibility // ignore: cast_nullable_to_non_nullable
              as CompatibilityCheckResult,
      fileIntegrity: null == fileIntegrity
          ? _value.fileIntegrity
          : fileIntegrity // ignore: cast_nullable_to_non_nullable
              as FileIntegrityResult,
      dataIntegrity: null == dataIntegrity
          ? _value.dataIntegrity
          : dataIntegrity // ignore: cast_nullable_to_non_nullable
              as DataIntegrityResult,
    ) as $Val);
  }

  /// Create a copy of ImportValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ImportDataStatisticsCopyWith<$Res> get statistics {
    return $ImportDataStatisticsCopyWith<$Res>(_value.statistics, (value) {
      return _then(_value.copyWith(statistics: value) as $Val);
    });
  }

  /// Create a copy of ImportValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CompatibilityCheckResultCopyWith<$Res> get compatibility {
    return $CompatibilityCheckResultCopyWith<$Res>(_value.compatibility,
        (value) {
      return _then(_value.copyWith(compatibility: value) as $Val);
    });
  }

  /// Create a copy of ImportValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FileIntegrityResultCopyWith<$Res> get fileIntegrity {
    return $FileIntegrityResultCopyWith<$Res>(_value.fileIntegrity, (value) {
      return _then(_value.copyWith(fileIntegrity: value) as $Val);
    });
  }

  /// Create a copy of ImportValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataIntegrityResultCopyWith<$Res> get dataIntegrity {
    return $DataIntegrityResultCopyWith<$Res>(_value.dataIntegrity, (value) {
      return _then(_value.copyWith(dataIntegrity: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ImportValidationResultImplCopyWith<$Res>
    implements $ImportValidationResultCopyWith<$Res> {
  factory _$$ImportValidationResultImplCopyWith(
          _$ImportValidationResultImpl value,
          $Res Function(_$ImportValidationResultImpl) then) =
      __$$ImportValidationResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ValidationStatus status,
      bool isValid,
      List<ValidationMessage> messages,
      ImportDataStatistics statistics,
      CompatibilityCheckResult compatibility,
      FileIntegrityResult fileIntegrity,
      DataIntegrityResult dataIntegrity});

  @override
  $ImportDataStatisticsCopyWith<$Res> get statistics;
  @override
  $CompatibilityCheckResultCopyWith<$Res> get compatibility;
  @override
  $FileIntegrityResultCopyWith<$Res> get fileIntegrity;
  @override
  $DataIntegrityResultCopyWith<$Res> get dataIntegrity;
}

/// @nodoc
class __$$ImportValidationResultImplCopyWithImpl<$Res>
    extends _$ImportValidationResultCopyWithImpl<$Res,
        _$ImportValidationResultImpl>
    implements _$$ImportValidationResultImplCopyWith<$Res> {
  __$$ImportValidationResultImplCopyWithImpl(
      _$ImportValidationResultImpl _value,
      $Res Function(_$ImportValidationResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of ImportValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? isValid = null,
    Object? messages = null,
    Object? statistics = null,
    Object? compatibility = null,
    Object? fileIntegrity = null,
    Object? dataIntegrity = null,
  }) {
    return _then(_$ImportValidationResultImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ValidationStatus,
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      messages: null == messages
          ? _value._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<ValidationMessage>,
      statistics: null == statistics
          ? _value.statistics
          : statistics // ignore: cast_nullable_to_non_nullable
              as ImportDataStatistics,
      compatibility: null == compatibility
          ? _value.compatibility
          : compatibility // ignore: cast_nullable_to_non_nullable
              as CompatibilityCheckResult,
      fileIntegrity: null == fileIntegrity
          ? _value.fileIntegrity
          : fileIntegrity // ignore: cast_nullable_to_non_nullable
              as FileIntegrityResult,
      dataIntegrity: null == dataIntegrity
          ? _value.dataIntegrity
          : dataIntegrity // ignore: cast_nullable_to_non_nullable
              as DataIntegrityResult,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ImportValidationResultImpl implements _ImportValidationResult {
  const _$ImportValidationResultImpl(
      {required this.status,
      this.isValid = false,
      final List<ValidationMessage> messages = const [],
      required this.statistics,
      required this.compatibility,
      required this.fileIntegrity,
      required this.dataIntegrity})
      : _messages = messages;

  factory _$ImportValidationResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImportValidationResultImplFromJson(json);

  /// 验证状态
  @override
  final ValidationStatus status;

  /// 是否通过验证
  @override
  @JsonKey()
  final bool isValid;

  /// 验证消息列表
  final List<ValidationMessage> _messages;

  /// 验证消息列表
  @override
  @JsonKey()
  List<ValidationMessage> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  /// 数据统计
  @override
  final ImportDataStatistics statistics;

  /// 兼容性检查结果
  @override
  final CompatibilityCheckResult compatibility;

  /// 文件完整性检查结果
  @override
  final FileIntegrityResult fileIntegrity;

  /// 数据完整性检查结果
  @override
  final DataIntegrityResult dataIntegrity;

  @override
  String toString() {
    return 'ImportValidationResult(status: $status, isValid: $isValid, messages: $messages, statistics: $statistics, compatibility: $compatibility, fileIntegrity: $fileIntegrity, dataIntegrity: $dataIntegrity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImportValidationResultImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isValid, isValid) || other.isValid == isValid) &&
            const DeepCollectionEquality().equals(other._messages, _messages) &&
            (identical(other.statistics, statistics) ||
                other.statistics == statistics) &&
            (identical(other.compatibility, compatibility) ||
                other.compatibility == compatibility) &&
            (identical(other.fileIntegrity, fileIntegrity) ||
                other.fileIntegrity == fileIntegrity) &&
            (identical(other.dataIntegrity, dataIntegrity) ||
                other.dataIntegrity == dataIntegrity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      status,
      isValid,
      const DeepCollectionEquality().hash(_messages),
      statistics,
      compatibility,
      fileIntegrity,
      dataIntegrity);

  /// Create a copy of ImportValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImportValidationResultImplCopyWith<_$ImportValidationResultImpl>
      get copyWith => __$$ImportValidationResultImplCopyWithImpl<
          _$ImportValidationResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ImportValidationResultImplToJson(
      this,
    );
  }
}

abstract class _ImportValidationResult implements ImportValidationResult {
  const factory _ImportValidationResult(
          {required final ValidationStatus status,
          final bool isValid,
          final List<ValidationMessage> messages,
          required final ImportDataStatistics statistics,
          required final CompatibilityCheckResult compatibility,
          required final FileIntegrityResult fileIntegrity,
          required final DataIntegrityResult dataIntegrity}) =
      _$ImportValidationResultImpl;

  factory _ImportValidationResult.fromJson(Map<String, dynamic> json) =
      _$ImportValidationResultImpl.fromJson;

  /// 验证状态
  @override
  ValidationStatus get status;

  /// 是否通过验证
  @override
  bool get isValid;

  /// 验证消息列表
  @override
  List<ValidationMessage> get messages;

  /// 数据统计
  @override
  ImportDataStatistics get statistics;

  /// 兼容性检查结果
  @override
  CompatibilityCheckResult get compatibility;

  /// 文件完整性检查结果
  @override
  FileIntegrityResult get fileIntegrity;

  /// 数据完整性检查结果
  @override
  DataIntegrityResult get dataIntegrity;

  /// Create a copy of ImportValidationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImportValidationResultImplCopyWith<_$ImportValidationResultImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ValidationMessage _$ValidationMessageFromJson(Map<String, dynamic> json) {
  return _ValidationMessage.fromJson(json);
}

/// @nodoc
mixin _$ValidationMessage {
  /// 消息级别
  ValidationLevel get level => throw _privateConstructorUsedError;

  /// 消息类型
  ValidationType get type => throw _privateConstructorUsedError;

  /// 消息内容
  String get message => throw _privateConstructorUsedError;

  /// 详细信息
  Map<String, dynamic>? get details => throw _privateConstructorUsedError;

  /// 建议的操作
  String? get suggestedAction => throw _privateConstructorUsedError;

  /// 是否可以自动修复
  bool get canAutoFix => throw _privateConstructorUsedError;

  /// Serializes this ValidationMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ValidationMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ValidationMessageCopyWith<ValidationMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ValidationMessageCopyWith<$Res> {
  factory $ValidationMessageCopyWith(
          ValidationMessage value, $Res Function(ValidationMessage) then) =
      _$ValidationMessageCopyWithImpl<$Res, ValidationMessage>;
  @useResult
  $Res call(
      {ValidationLevel level,
      ValidationType type,
      String message,
      Map<String, dynamic>? details,
      String? suggestedAction,
      bool canAutoFix});
}

/// @nodoc
class _$ValidationMessageCopyWithImpl<$Res, $Val extends ValidationMessage>
    implements $ValidationMessageCopyWith<$Res> {
  _$ValidationMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ValidationMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? type = null,
    Object? message = null,
    Object? details = freezed,
    Object? suggestedAction = freezed,
    Object? canAutoFix = null,
  }) {
    return _then(_value.copyWith(
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as ValidationLevel,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ValidationType,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      suggestedAction: freezed == suggestedAction
          ? _value.suggestedAction
          : suggestedAction // ignore: cast_nullable_to_non_nullable
              as String?,
      canAutoFix: null == canAutoFix
          ? _value.canAutoFix
          : canAutoFix // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ValidationMessageImplCopyWith<$Res>
    implements $ValidationMessageCopyWith<$Res> {
  factory _$$ValidationMessageImplCopyWith(_$ValidationMessageImpl value,
          $Res Function(_$ValidationMessageImpl) then) =
      __$$ValidationMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ValidationLevel level,
      ValidationType type,
      String message,
      Map<String, dynamic>? details,
      String? suggestedAction,
      bool canAutoFix});
}

/// @nodoc
class __$$ValidationMessageImplCopyWithImpl<$Res>
    extends _$ValidationMessageCopyWithImpl<$Res, _$ValidationMessageImpl>
    implements _$$ValidationMessageImplCopyWith<$Res> {
  __$$ValidationMessageImplCopyWithImpl(_$ValidationMessageImpl _value,
      $Res Function(_$ValidationMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ValidationMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? type = null,
    Object? message = null,
    Object? details = freezed,
    Object? suggestedAction = freezed,
    Object? canAutoFix = null,
  }) {
    return _then(_$ValidationMessageImpl(
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as ValidationLevel,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ValidationType,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      details: freezed == details
          ? _value._details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      suggestedAction: freezed == suggestedAction
          ? _value.suggestedAction
          : suggestedAction // ignore: cast_nullable_to_non_nullable
              as String?,
      canAutoFix: null == canAutoFix
          ? _value.canAutoFix
          : canAutoFix // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ValidationMessageImpl implements _ValidationMessage {
  const _$ValidationMessageImpl(
      {required this.level,
      required this.type,
      required this.message,
      final Map<String, dynamic>? details,
      this.suggestedAction,
      this.canAutoFix = false})
      : _details = details;

  factory _$ValidationMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ValidationMessageImplFromJson(json);

  /// 消息级别
  @override
  final ValidationLevel level;

  /// 消息类型
  @override
  final ValidationType type;

  /// 消息内容
  @override
  final String message;

  /// 详细信息
  final Map<String, dynamic>? _details;

  /// 详细信息
  @override
  Map<String, dynamic>? get details {
    final value = _details;
    if (value == null) return null;
    if (_details is EqualUnmodifiableMapView) return _details;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// 建议的操作
  @override
  final String? suggestedAction;

  /// 是否可以自动修复
  @override
  @JsonKey()
  final bool canAutoFix;

  @override
  String toString() {
    return 'ValidationMessage(level: $level, type: $type, message: $message, details: $details, suggestedAction: $suggestedAction, canAutoFix: $canAutoFix)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ValidationMessageImpl &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other._details, _details) &&
            (identical(other.suggestedAction, suggestedAction) ||
                other.suggestedAction == suggestedAction) &&
            (identical(other.canAutoFix, canAutoFix) ||
                other.canAutoFix == canAutoFix));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      level,
      type,
      message,
      const DeepCollectionEquality().hash(_details),
      suggestedAction,
      canAutoFix);

  /// Create a copy of ValidationMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ValidationMessageImplCopyWith<_$ValidationMessageImpl> get copyWith =>
      __$$ValidationMessageImplCopyWithImpl<_$ValidationMessageImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ValidationMessageImplToJson(
      this,
    );
  }
}

abstract class _ValidationMessage implements ValidationMessage {
  const factory _ValidationMessage(
      {required final ValidationLevel level,
      required final ValidationType type,
      required final String message,
      final Map<String, dynamic>? details,
      final String? suggestedAction,
      final bool canAutoFix}) = _$ValidationMessageImpl;

  factory _ValidationMessage.fromJson(Map<String, dynamic> json) =
      _$ValidationMessageImpl.fromJson;

  /// 消息级别
  @override
  ValidationLevel get level;

  /// 消息类型
  @override
  ValidationType get type;

  /// 消息内容
  @override
  String get message;

  /// 详细信息
  @override
  Map<String, dynamic>? get details;

  /// 建议的操作
  @override
  String? get suggestedAction;

  /// 是否可以自动修复
  @override
  bool get canAutoFix;

  /// Create a copy of ValidationMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ValidationMessageImplCopyWith<_$ValidationMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ImportConflictInfo _$ImportConflictInfoFromJson(Map<String, dynamic> json) {
  return _ImportConflictInfo.fromJson(json);
}

/// @nodoc
mixin _$ImportConflictInfo {
  /// 冲突类型
  ConflictType get type => throw _privateConstructorUsedError;

  /// 冲突的实体类型
  EntityType get entityType => throw _privateConstructorUsedError;

  /// 冲突的实体ID
  String get entityId => throw _privateConstructorUsedError;

  /// 现有数据
  Map<String, dynamic> get existingData => throw _privateConstructorUsedError;

  /// 导入数据
  Map<String, dynamic> get importData => throw _privateConstructorUsedError;

  /// 冲突字段列表
  List<String> get conflictFields => throw _privateConstructorUsedError;

  /// 解决策略
  ConflictResolution? get resolution => throw _privateConstructorUsedError;

  /// 冲突描述
  String get description => throw _privateConstructorUsedError;

  /// Serializes this ImportConflictInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ImportConflictInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ImportConflictInfoCopyWith<ImportConflictInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImportConflictInfoCopyWith<$Res> {
  factory $ImportConflictInfoCopyWith(
          ImportConflictInfo value, $Res Function(ImportConflictInfo) then) =
      _$ImportConflictInfoCopyWithImpl<$Res, ImportConflictInfo>;
  @useResult
  $Res call(
      {ConflictType type,
      EntityType entityType,
      String entityId,
      Map<String, dynamic> existingData,
      Map<String, dynamic> importData,
      List<String> conflictFields,
      ConflictResolution? resolution,
      String description});
}

/// @nodoc
class _$ImportConflictInfoCopyWithImpl<$Res, $Val extends ImportConflictInfo>
    implements $ImportConflictInfoCopyWith<$Res> {
  _$ImportConflictInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ImportConflictInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? entityType = null,
    Object? entityId = null,
    Object? existingData = null,
    Object? importData = null,
    Object? conflictFields = null,
    Object? resolution = freezed,
    Object? description = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ConflictType,
      entityType: null == entityType
          ? _value.entityType
          : entityType // ignore: cast_nullable_to_non_nullable
              as EntityType,
      entityId: null == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String,
      existingData: null == existingData
          ? _value.existingData
          : existingData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      importData: null == importData
          ? _value.importData
          : importData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      conflictFields: null == conflictFields
          ? _value.conflictFields
          : conflictFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      resolution: freezed == resolution
          ? _value.resolution
          : resolution // ignore: cast_nullable_to_non_nullable
              as ConflictResolution?,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ImportConflictInfoImplCopyWith<$Res>
    implements $ImportConflictInfoCopyWith<$Res> {
  factory _$$ImportConflictInfoImplCopyWith(_$ImportConflictInfoImpl value,
          $Res Function(_$ImportConflictInfoImpl) then) =
      __$$ImportConflictInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ConflictType type,
      EntityType entityType,
      String entityId,
      Map<String, dynamic> existingData,
      Map<String, dynamic> importData,
      List<String> conflictFields,
      ConflictResolution? resolution,
      String description});
}

/// @nodoc
class __$$ImportConflictInfoImplCopyWithImpl<$Res>
    extends _$ImportConflictInfoCopyWithImpl<$Res, _$ImportConflictInfoImpl>
    implements _$$ImportConflictInfoImplCopyWith<$Res> {
  __$$ImportConflictInfoImplCopyWithImpl(_$ImportConflictInfoImpl _value,
      $Res Function(_$ImportConflictInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of ImportConflictInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? entityType = null,
    Object? entityId = null,
    Object? existingData = null,
    Object? importData = null,
    Object? conflictFields = null,
    Object? resolution = freezed,
    Object? description = null,
  }) {
    return _then(_$ImportConflictInfoImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ConflictType,
      entityType: null == entityType
          ? _value.entityType
          : entityType // ignore: cast_nullable_to_non_nullable
              as EntityType,
      entityId: null == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String,
      existingData: null == existingData
          ? _value._existingData
          : existingData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      importData: null == importData
          ? _value._importData
          : importData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      conflictFields: null == conflictFields
          ? _value._conflictFields
          : conflictFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      resolution: freezed == resolution
          ? _value.resolution
          : resolution // ignore: cast_nullable_to_non_nullable
              as ConflictResolution?,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ImportConflictInfoImpl implements _ImportConflictInfo {
  const _$ImportConflictInfoImpl(
      {required this.type,
      required this.entityType,
      required this.entityId,
      required final Map<String, dynamic> existingData,
      required final Map<String, dynamic> importData,
      final List<String> conflictFields = const [],
      this.resolution,
      required this.description})
      : _existingData = existingData,
        _importData = importData,
        _conflictFields = conflictFields;

  factory _$ImportConflictInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImportConflictInfoImplFromJson(json);

  /// 冲突类型
  @override
  final ConflictType type;

  /// 冲突的实体类型
  @override
  final EntityType entityType;

  /// 冲突的实体ID
  @override
  final String entityId;

  /// 现有数据
  final Map<String, dynamic> _existingData;

  /// 现有数据
  @override
  Map<String, dynamic> get existingData {
    if (_existingData is EqualUnmodifiableMapView) return _existingData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_existingData);
  }

  /// 导入数据
  final Map<String, dynamic> _importData;

  /// 导入数据
  @override
  Map<String, dynamic> get importData {
    if (_importData is EqualUnmodifiableMapView) return _importData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_importData);
  }

  /// 冲突字段列表
  final List<String> _conflictFields;

  /// 冲突字段列表
  @override
  @JsonKey()
  List<String> get conflictFields {
    if (_conflictFields is EqualUnmodifiableListView) return _conflictFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_conflictFields);
  }

  /// 解决策略
  @override
  final ConflictResolution? resolution;

  /// 冲突描述
  @override
  final String description;

  @override
  String toString() {
    return 'ImportConflictInfo(type: $type, entityType: $entityType, entityId: $entityId, existingData: $existingData, importData: $importData, conflictFields: $conflictFields, resolution: $resolution, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImportConflictInfoImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.entityType, entityType) ||
                other.entityType == entityType) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            const DeepCollectionEquality()
                .equals(other._existingData, _existingData) &&
            const DeepCollectionEquality()
                .equals(other._importData, _importData) &&
            const DeepCollectionEquality()
                .equals(other._conflictFields, _conflictFields) &&
            (identical(other.resolution, resolution) ||
                other.resolution == resolution) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      type,
      entityType,
      entityId,
      const DeepCollectionEquality().hash(_existingData),
      const DeepCollectionEquality().hash(_importData),
      const DeepCollectionEquality().hash(_conflictFields),
      resolution,
      description);

  /// Create a copy of ImportConflictInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImportConflictInfoImplCopyWith<_$ImportConflictInfoImpl> get copyWith =>
      __$$ImportConflictInfoImplCopyWithImpl<_$ImportConflictInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ImportConflictInfoImplToJson(
      this,
    );
  }
}

abstract class _ImportConflictInfo implements ImportConflictInfo {
  const factory _ImportConflictInfo(
      {required final ConflictType type,
      required final EntityType entityType,
      required final String entityId,
      required final Map<String, dynamic> existingData,
      required final Map<String, dynamic> importData,
      final List<String> conflictFields,
      final ConflictResolution? resolution,
      required final String description}) = _$ImportConflictInfoImpl;

  factory _ImportConflictInfo.fromJson(Map<String, dynamic> json) =
      _$ImportConflictInfoImpl.fromJson;

  /// 冲突类型
  @override
  ConflictType get type;

  /// 冲突的实体类型
  @override
  EntityType get entityType;

  /// 冲突的实体ID
  @override
  String get entityId;

  /// 现有数据
  @override
  Map<String, dynamic> get existingData;

  /// 导入数据
  @override
  Map<String, dynamic> get importData;

  /// 冲突字段列表
  @override
  List<String> get conflictFields;

  /// 解决策略
  @override
  ConflictResolution? get resolution;

  /// 冲突描述
  @override
  String get description;

  /// Create a copy of ImportConflictInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImportConflictInfoImplCopyWith<_$ImportConflictInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ImportDataStatistics _$ImportDataStatisticsFromJson(Map<String, dynamic> json) {
  return _ImportDataStatistics.fromJson(json);
}

/// @nodoc
mixin _$ImportDataStatistics {
  /// 作品总数
  int get totalWorks => throw _privateConstructorUsedError;

  /// 集字总数
  int get totalCharacters => throw _privateConstructorUsedError;

  /// 图片总数
  int get totalImages => throw _privateConstructorUsedError;

  /// 有效作品数
  int get validWorks => throw _privateConstructorUsedError;

  /// 有效集字数
  int get validCharacters => throw _privateConstructorUsedError;

  /// 有效图片数
  int get validImages => throw _privateConstructorUsedError;

  /// 冲突作品数
  int get conflictWorks => throw _privateConstructorUsedError;

  /// 冲突集字数
  int get conflictCharacters => throw _privateConstructorUsedError;

  /// 损坏文件数
  int get corruptedFiles => throw _privateConstructorUsedError;

  /// 缺失文件数
  int get missingFiles => throw _privateConstructorUsedError;

  /// 预计导入时间（秒）
  int get estimatedImportTime => throw _privateConstructorUsedError;

  /// 预计存储空间（字节）
  int get estimatedStorageSize => throw _privateConstructorUsedError;

  /// Serializes this ImportDataStatistics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ImportDataStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ImportDataStatisticsCopyWith<ImportDataStatistics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImportDataStatisticsCopyWith<$Res> {
  factory $ImportDataStatisticsCopyWith(ImportDataStatistics value,
          $Res Function(ImportDataStatistics) then) =
      _$ImportDataStatisticsCopyWithImpl<$Res, ImportDataStatistics>;
  @useResult
  $Res call(
      {int totalWorks,
      int totalCharacters,
      int totalImages,
      int validWorks,
      int validCharacters,
      int validImages,
      int conflictWorks,
      int conflictCharacters,
      int corruptedFiles,
      int missingFiles,
      int estimatedImportTime,
      int estimatedStorageSize});
}

/// @nodoc
class _$ImportDataStatisticsCopyWithImpl<$Res,
        $Val extends ImportDataStatistics>
    implements $ImportDataStatisticsCopyWith<$Res> {
  _$ImportDataStatisticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ImportDataStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalWorks = null,
    Object? totalCharacters = null,
    Object? totalImages = null,
    Object? validWorks = null,
    Object? validCharacters = null,
    Object? validImages = null,
    Object? conflictWorks = null,
    Object? conflictCharacters = null,
    Object? corruptedFiles = null,
    Object? missingFiles = null,
    Object? estimatedImportTime = null,
    Object? estimatedStorageSize = null,
  }) {
    return _then(_value.copyWith(
      totalWorks: null == totalWorks
          ? _value.totalWorks
          : totalWorks // ignore: cast_nullable_to_non_nullable
              as int,
      totalCharacters: null == totalCharacters
          ? _value.totalCharacters
          : totalCharacters // ignore: cast_nullable_to_non_nullable
              as int,
      totalImages: null == totalImages
          ? _value.totalImages
          : totalImages // ignore: cast_nullable_to_non_nullable
              as int,
      validWorks: null == validWorks
          ? _value.validWorks
          : validWorks // ignore: cast_nullable_to_non_nullable
              as int,
      validCharacters: null == validCharacters
          ? _value.validCharacters
          : validCharacters // ignore: cast_nullable_to_non_nullable
              as int,
      validImages: null == validImages
          ? _value.validImages
          : validImages // ignore: cast_nullable_to_non_nullable
              as int,
      conflictWorks: null == conflictWorks
          ? _value.conflictWorks
          : conflictWorks // ignore: cast_nullable_to_non_nullable
              as int,
      conflictCharacters: null == conflictCharacters
          ? _value.conflictCharacters
          : conflictCharacters // ignore: cast_nullable_to_non_nullable
              as int,
      corruptedFiles: null == corruptedFiles
          ? _value.corruptedFiles
          : corruptedFiles // ignore: cast_nullable_to_non_nullable
              as int,
      missingFiles: null == missingFiles
          ? _value.missingFiles
          : missingFiles // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedImportTime: null == estimatedImportTime
          ? _value.estimatedImportTime
          : estimatedImportTime // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedStorageSize: null == estimatedStorageSize
          ? _value.estimatedStorageSize
          : estimatedStorageSize // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ImportDataStatisticsImplCopyWith<$Res>
    implements $ImportDataStatisticsCopyWith<$Res> {
  factory _$$ImportDataStatisticsImplCopyWith(_$ImportDataStatisticsImpl value,
          $Res Function(_$ImportDataStatisticsImpl) then) =
      __$$ImportDataStatisticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int totalWorks,
      int totalCharacters,
      int totalImages,
      int validWorks,
      int validCharacters,
      int validImages,
      int conflictWorks,
      int conflictCharacters,
      int corruptedFiles,
      int missingFiles,
      int estimatedImportTime,
      int estimatedStorageSize});
}

/// @nodoc
class __$$ImportDataStatisticsImplCopyWithImpl<$Res>
    extends _$ImportDataStatisticsCopyWithImpl<$Res, _$ImportDataStatisticsImpl>
    implements _$$ImportDataStatisticsImplCopyWith<$Res> {
  __$$ImportDataStatisticsImplCopyWithImpl(_$ImportDataStatisticsImpl _value,
      $Res Function(_$ImportDataStatisticsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ImportDataStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalWorks = null,
    Object? totalCharacters = null,
    Object? totalImages = null,
    Object? validWorks = null,
    Object? validCharacters = null,
    Object? validImages = null,
    Object? conflictWorks = null,
    Object? conflictCharacters = null,
    Object? corruptedFiles = null,
    Object? missingFiles = null,
    Object? estimatedImportTime = null,
    Object? estimatedStorageSize = null,
  }) {
    return _then(_$ImportDataStatisticsImpl(
      totalWorks: null == totalWorks
          ? _value.totalWorks
          : totalWorks // ignore: cast_nullable_to_non_nullable
              as int,
      totalCharacters: null == totalCharacters
          ? _value.totalCharacters
          : totalCharacters // ignore: cast_nullable_to_non_nullable
              as int,
      totalImages: null == totalImages
          ? _value.totalImages
          : totalImages // ignore: cast_nullable_to_non_nullable
              as int,
      validWorks: null == validWorks
          ? _value.validWorks
          : validWorks // ignore: cast_nullable_to_non_nullable
              as int,
      validCharacters: null == validCharacters
          ? _value.validCharacters
          : validCharacters // ignore: cast_nullable_to_non_nullable
              as int,
      validImages: null == validImages
          ? _value.validImages
          : validImages // ignore: cast_nullable_to_non_nullable
              as int,
      conflictWorks: null == conflictWorks
          ? _value.conflictWorks
          : conflictWorks // ignore: cast_nullable_to_non_nullable
              as int,
      conflictCharacters: null == conflictCharacters
          ? _value.conflictCharacters
          : conflictCharacters // ignore: cast_nullable_to_non_nullable
              as int,
      corruptedFiles: null == corruptedFiles
          ? _value.corruptedFiles
          : corruptedFiles // ignore: cast_nullable_to_non_nullable
              as int,
      missingFiles: null == missingFiles
          ? _value.missingFiles
          : missingFiles // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedImportTime: null == estimatedImportTime
          ? _value.estimatedImportTime
          : estimatedImportTime // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedStorageSize: null == estimatedStorageSize
          ? _value.estimatedStorageSize
          : estimatedStorageSize // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ImportDataStatisticsImpl implements _ImportDataStatistics {
  const _$ImportDataStatisticsImpl(
      {this.totalWorks = 0,
      this.totalCharacters = 0,
      this.totalImages = 0,
      this.validWorks = 0,
      this.validCharacters = 0,
      this.validImages = 0,
      this.conflictWorks = 0,
      this.conflictCharacters = 0,
      this.corruptedFiles = 0,
      this.missingFiles = 0,
      this.estimatedImportTime = 0,
      this.estimatedStorageSize = 0});

  factory _$ImportDataStatisticsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImportDataStatisticsImplFromJson(json);

  /// 作品总数
  @override
  @JsonKey()
  final int totalWorks;

  /// 集字总数
  @override
  @JsonKey()
  final int totalCharacters;

  /// 图片总数
  @override
  @JsonKey()
  final int totalImages;

  /// 有效作品数
  @override
  @JsonKey()
  final int validWorks;

  /// 有效集字数
  @override
  @JsonKey()
  final int validCharacters;

  /// 有效图片数
  @override
  @JsonKey()
  final int validImages;

  /// 冲突作品数
  @override
  @JsonKey()
  final int conflictWorks;

  /// 冲突集字数
  @override
  @JsonKey()
  final int conflictCharacters;

  /// 损坏文件数
  @override
  @JsonKey()
  final int corruptedFiles;

  /// 缺失文件数
  @override
  @JsonKey()
  final int missingFiles;

  /// 预计导入时间（秒）
  @override
  @JsonKey()
  final int estimatedImportTime;

  /// 预计存储空间（字节）
  @override
  @JsonKey()
  final int estimatedStorageSize;

  @override
  String toString() {
    return 'ImportDataStatistics(totalWorks: $totalWorks, totalCharacters: $totalCharacters, totalImages: $totalImages, validWorks: $validWorks, validCharacters: $validCharacters, validImages: $validImages, conflictWorks: $conflictWorks, conflictCharacters: $conflictCharacters, corruptedFiles: $corruptedFiles, missingFiles: $missingFiles, estimatedImportTime: $estimatedImportTime, estimatedStorageSize: $estimatedStorageSize)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImportDataStatisticsImpl &&
            (identical(other.totalWorks, totalWorks) ||
                other.totalWorks == totalWorks) &&
            (identical(other.totalCharacters, totalCharacters) ||
                other.totalCharacters == totalCharacters) &&
            (identical(other.totalImages, totalImages) ||
                other.totalImages == totalImages) &&
            (identical(other.validWorks, validWorks) ||
                other.validWorks == validWorks) &&
            (identical(other.validCharacters, validCharacters) ||
                other.validCharacters == validCharacters) &&
            (identical(other.validImages, validImages) ||
                other.validImages == validImages) &&
            (identical(other.conflictWorks, conflictWorks) ||
                other.conflictWorks == conflictWorks) &&
            (identical(other.conflictCharacters, conflictCharacters) ||
                other.conflictCharacters == conflictCharacters) &&
            (identical(other.corruptedFiles, corruptedFiles) ||
                other.corruptedFiles == corruptedFiles) &&
            (identical(other.missingFiles, missingFiles) ||
                other.missingFiles == missingFiles) &&
            (identical(other.estimatedImportTime, estimatedImportTime) ||
                other.estimatedImportTime == estimatedImportTime) &&
            (identical(other.estimatedStorageSize, estimatedStorageSize) ||
                other.estimatedStorageSize == estimatedStorageSize));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalWorks,
      totalCharacters,
      totalImages,
      validWorks,
      validCharacters,
      validImages,
      conflictWorks,
      conflictCharacters,
      corruptedFiles,
      missingFiles,
      estimatedImportTime,
      estimatedStorageSize);

  /// Create a copy of ImportDataStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImportDataStatisticsImplCopyWith<_$ImportDataStatisticsImpl>
      get copyWith =>
          __$$ImportDataStatisticsImplCopyWithImpl<_$ImportDataStatisticsImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ImportDataStatisticsImplToJson(
      this,
    );
  }
}

abstract class _ImportDataStatistics implements ImportDataStatistics {
  const factory _ImportDataStatistics(
      {final int totalWorks,
      final int totalCharacters,
      final int totalImages,
      final int validWorks,
      final int validCharacters,
      final int validImages,
      final int conflictWorks,
      final int conflictCharacters,
      final int corruptedFiles,
      final int missingFiles,
      final int estimatedImportTime,
      final int estimatedStorageSize}) = _$ImportDataStatisticsImpl;

  factory _ImportDataStatistics.fromJson(Map<String, dynamic> json) =
      _$ImportDataStatisticsImpl.fromJson;

  /// 作品总数
  @override
  int get totalWorks;

  /// 集字总数
  @override
  int get totalCharacters;

  /// 图片总数
  @override
  int get totalImages;

  /// 有效作品数
  @override
  int get validWorks;

  /// 有效集字数
  @override
  int get validCharacters;

  /// 有效图片数
  @override
  int get validImages;

  /// 冲突作品数
  @override
  int get conflictWorks;

  /// 冲突集字数
  @override
  int get conflictCharacters;

  /// 损坏文件数
  @override
  int get corruptedFiles;

  /// 缺失文件数
  @override
  int get missingFiles;

  /// 预计导入时间（秒）
  @override
  int get estimatedImportTime;

  /// 预计存储空间（字节）
  @override
  int get estimatedStorageSize;

  /// Create a copy of ImportDataStatistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImportDataStatisticsImplCopyWith<_$ImportDataStatisticsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

CompatibilityCheckResult _$CompatibilityCheckResultFromJson(
    Map<String, dynamic> json) {
  return _CompatibilityCheckResult.fromJson(json);
}

/// @nodoc
mixin _$CompatibilityCheckResult {
  /// 是否兼容
  bool get isCompatible => throw _privateConstructorUsedError;

  /// 数据格式版本
  String get dataFormatVersion => throw _privateConstructorUsedError;

  /// 应用版本
  String get appVersion => throw _privateConstructorUsedError;

  /// 兼容性级别
  CompatibilityLevel get level => throw _privateConstructorUsedError;

  /// 不兼容的功能列表
  List<String> get incompatibleFeatures => throw _privateConstructorUsedError;

  /// 警告信息
  List<String> get warnings => throw _privateConstructorUsedError;

  /// 是否需要数据迁移
  bool get requiresMigration => throw _privateConstructorUsedError;

  /// Serializes this CompatibilityCheckResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompatibilityCheckResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompatibilityCheckResultCopyWith<CompatibilityCheckResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompatibilityCheckResultCopyWith<$Res> {
  factory $CompatibilityCheckResultCopyWith(CompatibilityCheckResult value,
          $Res Function(CompatibilityCheckResult) then) =
      _$CompatibilityCheckResultCopyWithImpl<$Res, CompatibilityCheckResult>;
  @useResult
  $Res call(
      {bool isCompatible,
      String dataFormatVersion,
      String appVersion,
      CompatibilityLevel level,
      List<String> incompatibleFeatures,
      List<String> warnings,
      bool requiresMigration});
}

/// @nodoc
class _$CompatibilityCheckResultCopyWithImpl<$Res,
        $Val extends CompatibilityCheckResult>
    implements $CompatibilityCheckResultCopyWith<$Res> {
  _$CompatibilityCheckResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompatibilityCheckResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isCompatible = null,
    Object? dataFormatVersion = null,
    Object? appVersion = null,
    Object? level = null,
    Object? incompatibleFeatures = null,
    Object? warnings = null,
    Object? requiresMigration = null,
  }) {
    return _then(_value.copyWith(
      isCompatible: null == isCompatible
          ? _value.isCompatible
          : isCompatible // ignore: cast_nullable_to_non_nullable
              as bool,
      dataFormatVersion: null == dataFormatVersion
          ? _value.dataFormatVersion
          : dataFormatVersion // ignore: cast_nullable_to_non_nullable
              as String,
      appVersion: null == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as CompatibilityLevel,
      incompatibleFeatures: null == incompatibleFeatures
          ? _value.incompatibleFeatures
          : incompatibleFeatures // ignore: cast_nullable_to_non_nullable
              as List<String>,
      warnings: null == warnings
          ? _value.warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
      requiresMigration: null == requiresMigration
          ? _value.requiresMigration
          : requiresMigration // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CompatibilityCheckResultImplCopyWith<$Res>
    implements $CompatibilityCheckResultCopyWith<$Res> {
  factory _$$CompatibilityCheckResultImplCopyWith(
          _$CompatibilityCheckResultImpl value,
          $Res Function(_$CompatibilityCheckResultImpl) then) =
      __$$CompatibilityCheckResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isCompatible,
      String dataFormatVersion,
      String appVersion,
      CompatibilityLevel level,
      List<String> incompatibleFeatures,
      List<String> warnings,
      bool requiresMigration});
}

/// @nodoc
class __$$CompatibilityCheckResultImplCopyWithImpl<$Res>
    extends _$CompatibilityCheckResultCopyWithImpl<$Res,
        _$CompatibilityCheckResultImpl>
    implements _$$CompatibilityCheckResultImplCopyWith<$Res> {
  __$$CompatibilityCheckResultImplCopyWithImpl(
      _$CompatibilityCheckResultImpl _value,
      $Res Function(_$CompatibilityCheckResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of CompatibilityCheckResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isCompatible = null,
    Object? dataFormatVersion = null,
    Object? appVersion = null,
    Object? level = null,
    Object? incompatibleFeatures = null,
    Object? warnings = null,
    Object? requiresMigration = null,
  }) {
    return _then(_$CompatibilityCheckResultImpl(
      isCompatible: null == isCompatible
          ? _value.isCompatible
          : isCompatible // ignore: cast_nullable_to_non_nullable
              as bool,
      dataFormatVersion: null == dataFormatVersion
          ? _value.dataFormatVersion
          : dataFormatVersion // ignore: cast_nullable_to_non_nullable
              as String,
      appVersion: null == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as CompatibilityLevel,
      incompatibleFeatures: null == incompatibleFeatures
          ? _value._incompatibleFeatures
          : incompatibleFeatures // ignore: cast_nullable_to_non_nullable
              as List<String>,
      warnings: null == warnings
          ? _value._warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
      requiresMigration: null == requiresMigration
          ? _value.requiresMigration
          : requiresMigration // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CompatibilityCheckResultImpl implements _CompatibilityCheckResult {
  const _$CompatibilityCheckResultImpl(
      {this.isCompatible = false,
      required this.dataFormatVersion,
      required this.appVersion,
      required this.level,
      final List<String> incompatibleFeatures = const [],
      final List<String> warnings = const [],
      this.requiresMigration = false})
      : _incompatibleFeatures = incompatibleFeatures,
        _warnings = warnings;

  factory _$CompatibilityCheckResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompatibilityCheckResultImplFromJson(json);

  /// 是否兼容
  @override
  @JsonKey()
  final bool isCompatible;

  /// 数据格式版本
  @override
  final String dataFormatVersion;

  /// 应用版本
  @override
  final String appVersion;

  /// 兼容性级别
  @override
  final CompatibilityLevel level;

  /// 不兼容的功能列表
  final List<String> _incompatibleFeatures;

  /// 不兼容的功能列表
  @override
  @JsonKey()
  List<String> get incompatibleFeatures {
    if (_incompatibleFeatures is EqualUnmodifiableListView)
      return _incompatibleFeatures;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_incompatibleFeatures);
  }

  /// 警告信息
  final List<String> _warnings;

  /// 警告信息
  @override
  @JsonKey()
  List<String> get warnings {
    if (_warnings is EqualUnmodifiableListView) return _warnings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_warnings);
  }

  /// 是否需要数据迁移
  @override
  @JsonKey()
  final bool requiresMigration;

  @override
  String toString() {
    return 'CompatibilityCheckResult(isCompatible: $isCompatible, dataFormatVersion: $dataFormatVersion, appVersion: $appVersion, level: $level, incompatibleFeatures: $incompatibleFeatures, warnings: $warnings, requiresMigration: $requiresMigration)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompatibilityCheckResultImpl &&
            (identical(other.isCompatible, isCompatible) ||
                other.isCompatible == isCompatible) &&
            (identical(other.dataFormatVersion, dataFormatVersion) ||
                other.dataFormatVersion == dataFormatVersion) &&
            (identical(other.appVersion, appVersion) ||
                other.appVersion == appVersion) &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality()
                .equals(other._incompatibleFeatures, _incompatibleFeatures) &&
            const DeepCollectionEquality().equals(other._warnings, _warnings) &&
            (identical(other.requiresMigration, requiresMigration) ||
                other.requiresMigration == requiresMigration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      isCompatible,
      dataFormatVersion,
      appVersion,
      level,
      const DeepCollectionEquality().hash(_incompatibleFeatures),
      const DeepCollectionEquality().hash(_warnings),
      requiresMigration);

  /// Create a copy of CompatibilityCheckResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompatibilityCheckResultImplCopyWith<_$CompatibilityCheckResultImpl>
      get copyWith => __$$CompatibilityCheckResultImplCopyWithImpl<
          _$CompatibilityCheckResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompatibilityCheckResultImplToJson(
      this,
    );
  }
}

abstract class _CompatibilityCheckResult implements CompatibilityCheckResult {
  const factory _CompatibilityCheckResult(
      {final bool isCompatible,
      required final String dataFormatVersion,
      required final String appVersion,
      required final CompatibilityLevel level,
      final List<String> incompatibleFeatures,
      final List<String> warnings,
      final bool requiresMigration}) = _$CompatibilityCheckResultImpl;

  factory _CompatibilityCheckResult.fromJson(Map<String, dynamic> json) =
      _$CompatibilityCheckResultImpl.fromJson;

  /// 是否兼容
  @override
  bool get isCompatible;

  /// 数据格式版本
  @override
  String get dataFormatVersion;

  /// 应用版本
  @override
  String get appVersion;

  /// 兼容性级别
  @override
  CompatibilityLevel get level;

  /// 不兼容的功能列表
  @override
  List<String> get incompatibleFeatures;

  /// 警告信息
  @override
  List<String> get warnings;

  /// 是否需要数据迁移
  @override
  bool get requiresMigration;

  /// Create a copy of CompatibilityCheckResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompatibilityCheckResultImplCopyWith<_$CompatibilityCheckResultImpl>
      get copyWith => throw _privateConstructorUsedError;
}

FileIntegrityResult _$FileIntegrityResultFromJson(Map<String, dynamic> json) {
  return _FileIntegrityResult.fromJson(json);
}

/// @nodoc
mixin _$FileIntegrityResult {
  /// 是否完整
  bool get isIntact => throw _privateConstructorUsedError;

  /// 总文件数
  int get totalFiles => throw _privateConstructorUsedError;

  /// 有效文件数
  int get validFiles => throw _privateConstructorUsedError;

  /// 损坏文件列表
  List<CorruptedFileInfo> get corruptedFiles =>
      throw _privateConstructorUsedError;

  /// 缺失文件列表
  List<MissingFileInfo> get missingFiles => throw _privateConstructorUsedError;

  /// 校验和验证结果
  List<ChecksumValidation> get checksumResults =>
      throw _privateConstructorUsedError;

  /// Serializes this FileIntegrityResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FileIntegrityResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FileIntegrityResultCopyWith<FileIntegrityResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FileIntegrityResultCopyWith<$Res> {
  factory $FileIntegrityResultCopyWith(
          FileIntegrityResult value, $Res Function(FileIntegrityResult) then) =
      _$FileIntegrityResultCopyWithImpl<$Res, FileIntegrityResult>;
  @useResult
  $Res call(
      {bool isIntact,
      int totalFiles,
      int validFiles,
      List<CorruptedFileInfo> corruptedFiles,
      List<MissingFileInfo> missingFiles,
      List<ChecksumValidation> checksumResults});
}

/// @nodoc
class _$FileIntegrityResultCopyWithImpl<$Res, $Val extends FileIntegrityResult>
    implements $FileIntegrityResultCopyWith<$Res> {
  _$FileIntegrityResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FileIntegrityResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isIntact = null,
    Object? totalFiles = null,
    Object? validFiles = null,
    Object? corruptedFiles = null,
    Object? missingFiles = null,
    Object? checksumResults = null,
  }) {
    return _then(_value.copyWith(
      isIntact: null == isIntact
          ? _value.isIntact
          : isIntact // ignore: cast_nullable_to_non_nullable
              as bool,
      totalFiles: null == totalFiles
          ? _value.totalFiles
          : totalFiles // ignore: cast_nullable_to_non_nullable
              as int,
      validFiles: null == validFiles
          ? _value.validFiles
          : validFiles // ignore: cast_nullable_to_non_nullable
              as int,
      corruptedFiles: null == corruptedFiles
          ? _value.corruptedFiles
          : corruptedFiles // ignore: cast_nullable_to_non_nullable
              as List<CorruptedFileInfo>,
      missingFiles: null == missingFiles
          ? _value.missingFiles
          : missingFiles // ignore: cast_nullable_to_non_nullable
              as List<MissingFileInfo>,
      checksumResults: null == checksumResults
          ? _value.checksumResults
          : checksumResults // ignore: cast_nullable_to_non_nullable
              as List<ChecksumValidation>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FileIntegrityResultImplCopyWith<$Res>
    implements $FileIntegrityResultCopyWith<$Res> {
  factory _$$FileIntegrityResultImplCopyWith(_$FileIntegrityResultImpl value,
          $Res Function(_$FileIntegrityResultImpl) then) =
      __$$FileIntegrityResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isIntact,
      int totalFiles,
      int validFiles,
      List<CorruptedFileInfo> corruptedFiles,
      List<MissingFileInfo> missingFiles,
      List<ChecksumValidation> checksumResults});
}

/// @nodoc
class __$$FileIntegrityResultImplCopyWithImpl<$Res>
    extends _$FileIntegrityResultCopyWithImpl<$Res, _$FileIntegrityResultImpl>
    implements _$$FileIntegrityResultImplCopyWith<$Res> {
  __$$FileIntegrityResultImplCopyWithImpl(_$FileIntegrityResultImpl _value,
      $Res Function(_$FileIntegrityResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of FileIntegrityResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isIntact = null,
    Object? totalFiles = null,
    Object? validFiles = null,
    Object? corruptedFiles = null,
    Object? missingFiles = null,
    Object? checksumResults = null,
  }) {
    return _then(_$FileIntegrityResultImpl(
      isIntact: null == isIntact
          ? _value.isIntact
          : isIntact // ignore: cast_nullable_to_non_nullable
              as bool,
      totalFiles: null == totalFiles
          ? _value.totalFiles
          : totalFiles // ignore: cast_nullable_to_non_nullable
              as int,
      validFiles: null == validFiles
          ? _value.validFiles
          : validFiles // ignore: cast_nullable_to_non_nullable
              as int,
      corruptedFiles: null == corruptedFiles
          ? _value._corruptedFiles
          : corruptedFiles // ignore: cast_nullable_to_non_nullable
              as List<CorruptedFileInfo>,
      missingFiles: null == missingFiles
          ? _value._missingFiles
          : missingFiles // ignore: cast_nullable_to_non_nullable
              as List<MissingFileInfo>,
      checksumResults: null == checksumResults
          ? _value._checksumResults
          : checksumResults // ignore: cast_nullable_to_non_nullable
              as List<ChecksumValidation>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FileIntegrityResultImpl implements _FileIntegrityResult {
  const _$FileIntegrityResultImpl(
      {this.isIntact = false,
      this.totalFiles = 0,
      this.validFiles = 0,
      final List<CorruptedFileInfo> corruptedFiles = const [],
      final List<MissingFileInfo> missingFiles = const [],
      final List<ChecksumValidation> checksumResults = const []})
      : _corruptedFiles = corruptedFiles,
        _missingFiles = missingFiles,
        _checksumResults = checksumResults;

  factory _$FileIntegrityResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$FileIntegrityResultImplFromJson(json);

  /// 是否完整
  @override
  @JsonKey()
  final bool isIntact;

  /// 总文件数
  @override
  @JsonKey()
  final int totalFiles;

  /// 有效文件数
  @override
  @JsonKey()
  final int validFiles;

  /// 损坏文件列表
  final List<CorruptedFileInfo> _corruptedFiles;

  /// 损坏文件列表
  @override
  @JsonKey()
  List<CorruptedFileInfo> get corruptedFiles {
    if (_corruptedFiles is EqualUnmodifiableListView) return _corruptedFiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_corruptedFiles);
  }

  /// 缺失文件列表
  final List<MissingFileInfo> _missingFiles;

  /// 缺失文件列表
  @override
  @JsonKey()
  List<MissingFileInfo> get missingFiles {
    if (_missingFiles is EqualUnmodifiableListView) return _missingFiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_missingFiles);
  }

  /// 校验和验证结果
  final List<ChecksumValidation> _checksumResults;

  /// 校验和验证结果
  @override
  @JsonKey()
  List<ChecksumValidation> get checksumResults {
    if (_checksumResults is EqualUnmodifiableListView) return _checksumResults;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_checksumResults);
  }

  @override
  String toString() {
    return 'FileIntegrityResult(isIntact: $isIntact, totalFiles: $totalFiles, validFiles: $validFiles, corruptedFiles: $corruptedFiles, missingFiles: $missingFiles, checksumResults: $checksumResults)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileIntegrityResultImpl &&
            (identical(other.isIntact, isIntact) ||
                other.isIntact == isIntact) &&
            (identical(other.totalFiles, totalFiles) ||
                other.totalFiles == totalFiles) &&
            (identical(other.validFiles, validFiles) ||
                other.validFiles == validFiles) &&
            const DeepCollectionEquality()
                .equals(other._corruptedFiles, _corruptedFiles) &&
            const DeepCollectionEquality()
                .equals(other._missingFiles, _missingFiles) &&
            const DeepCollectionEquality()
                .equals(other._checksumResults, _checksumResults));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      isIntact,
      totalFiles,
      validFiles,
      const DeepCollectionEquality().hash(_corruptedFiles),
      const DeepCollectionEquality().hash(_missingFiles),
      const DeepCollectionEquality().hash(_checksumResults));

  /// Create a copy of FileIntegrityResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FileIntegrityResultImplCopyWith<_$FileIntegrityResultImpl> get copyWith =>
      __$$FileIntegrityResultImplCopyWithImpl<_$FileIntegrityResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FileIntegrityResultImplToJson(
      this,
    );
  }
}

abstract class _FileIntegrityResult implements FileIntegrityResult {
  const factory _FileIntegrityResult(
          {final bool isIntact,
          final int totalFiles,
          final int validFiles,
          final List<CorruptedFileInfo> corruptedFiles,
          final List<MissingFileInfo> missingFiles,
          final List<ChecksumValidation> checksumResults}) =
      _$FileIntegrityResultImpl;

  factory _FileIntegrityResult.fromJson(Map<String, dynamic> json) =
      _$FileIntegrityResultImpl.fromJson;

  /// 是否完整
  @override
  bool get isIntact;

  /// 总文件数
  @override
  int get totalFiles;

  /// 有效文件数
  @override
  int get validFiles;

  /// 损坏文件列表
  @override
  List<CorruptedFileInfo> get corruptedFiles;

  /// 缺失文件列表
  @override
  List<MissingFileInfo> get missingFiles;

  /// 校验和验证结果
  @override
  List<ChecksumValidation> get checksumResults;

  /// Create a copy of FileIntegrityResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FileIntegrityResultImplCopyWith<_$FileIntegrityResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DataIntegrityResult _$DataIntegrityResultFromJson(Map<String, dynamic> json) {
  return _DataIntegrityResult.fromJson(json);
}

/// @nodoc
mixin _$DataIntegrityResult {
  /// 是否完整
  bool get isIntact => throw _privateConstructorUsedError;

  /// 关联关系检查结果
  List<RelationshipValidation> get relationships =>
      throw _privateConstructorUsedError;

  /// 数据格式验证结果
  List<FormatValidation> get formats => throw _privateConstructorUsedError;

  /// 必需字段验证结果
  List<RequiredFieldValidation> get requiredFields =>
      throw _privateConstructorUsedError;

  /// 数据一致性检查结果
  List<ConsistencyValidation> get consistency =>
      throw _privateConstructorUsedError;

  /// Serializes this DataIntegrityResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DataIntegrityResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DataIntegrityResultCopyWith<DataIntegrityResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DataIntegrityResultCopyWith<$Res> {
  factory $DataIntegrityResultCopyWith(
          DataIntegrityResult value, $Res Function(DataIntegrityResult) then) =
      _$DataIntegrityResultCopyWithImpl<$Res, DataIntegrityResult>;
  @useResult
  $Res call(
      {bool isIntact,
      List<RelationshipValidation> relationships,
      List<FormatValidation> formats,
      List<RequiredFieldValidation> requiredFields,
      List<ConsistencyValidation> consistency});
}

/// @nodoc
class _$DataIntegrityResultCopyWithImpl<$Res, $Val extends DataIntegrityResult>
    implements $DataIntegrityResultCopyWith<$Res> {
  _$DataIntegrityResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DataIntegrityResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isIntact = null,
    Object? relationships = null,
    Object? formats = null,
    Object? requiredFields = null,
    Object? consistency = null,
  }) {
    return _then(_value.copyWith(
      isIntact: null == isIntact
          ? _value.isIntact
          : isIntact // ignore: cast_nullable_to_non_nullable
              as bool,
      relationships: null == relationships
          ? _value.relationships
          : relationships // ignore: cast_nullable_to_non_nullable
              as List<RelationshipValidation>,
      formats: null == formats
          ? _value.formats
          : formats // ignore: cast_nullable_to_non_nullable
              as List<FormatValidation>,
      requiredFields: null == requiredFields
          ? _value.requiredFields
          : requiredFields // ignore: cast_nullable_to_non_nullable
              as List<RequiredFieldValidation>,
      consistency: null == consistency
          ? _value.consistency
          : consistency // ignore: cast_nullable_to_non_nullable
              as List<ConsistencyValidation>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DataIntegrityResultImplCopyWith<$Res>
    implements $DataIntegrityResultCopyWith<$Res> {
  factory _$$DataIntegrityResultImplCopyWith(_$DataIntegrityResultImpl value,
          $Res Function(_$DataIntegrityResultImpl) then) =
      __$$DataIntegrityResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isIntact,
      List<RelationshipValidation> relationships,
      List<FormatValidation> formats,
      List<RequiredFieldValidation> requiredFields,
      List<ConsistencyValidation> consistency});
}

/// @nodoc
class __$$DataIntegrityResultImplCopyWithImpl<$Res>
    extends _$DataIntegrityResultCopyWithImpl<$Res, _$DataIntegrityResultImpl>
    implements _$$DataIntegrityResultImplCopyWith<$Res> {
  __$$DataIntegrityResultImplCopyWithImpl(_$DataIntegrityResultImpl _value,
      $Res Function(_$DataIntegrityResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of DataIntegrityResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isIntact = null,
    Object? relationships = null,
    Object? formats = null,
    Object? requiredFields = null,
    Object? consistency = null,
  }) {
    return _then(_$DataIntegrityResultImpl(
      isIntact: null == isIntact
          ? _value.isIntact
          : isIntact // ignore: cast_nullable_to_non_nullable
              as bool,
      relationships: null == relationships
          ? _value._relationships
          : relationships // ignore: cast_nullable_to_non_nullable
              as List<RelationshipValidation>,
      formats: null == formats
          ? _value._formats
          : formats // ignore: cast_nullable_to_non_nullable
              as List<FormatValidation>,
      requiredFields: null == requiredFields
          ? _value._requiredFields
          : requiredFields // ignore: cast_nullable_to_non_nullable
              as List<RequiredFieldValidation>,
      consistency: null == consistency
          ? _value._consistency
          : consistency // ignore: cast_nullable_to_non_nullable
              as List<ConsistencyValidation>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DataIntegrityResultImpl implements _DataIntegrityResult {
  const _$DataIntegrityResultImpl(
      {this.isIntact = false,
      final List<RelationshipValidation> relationships = const [],
      final List<FormatValidation> formats = const [],
      final List<RequiredFieldValidation> requiredFields = const [],
      final List<ConsistencyValidation> consistency = const []})
      : _relationships = relationships,
        _formats = formats,
        _requiredFields = requiredFields,
        _consistency = consistency;

  factory _$DataIntegrityResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$DataIntegrityResultImplFromJson(json);

  /// 是否完整
  @override
  @JsonKey()
  final bool isIntact;

  /// 关联关系检查结果
  final List<RelationshipValidation> _relationships;

  /// 关联关系检查结果
  @override
  @JsonKey()
  List<RelationshipValidation> get relationships {
    if (_relationships is EqualUnmodifiableListView) return _relationships;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_relationships);
  }

  /// 数据格式验证结果
  final List<FormatValidation> _formats;

  /// 数据格式验证结果
  @override
  @JsonKey()
  List<FormatValidation> get formats {
    if (_formats is EqualUnmodifiableListView) return _formats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_formats);
  }

  /// 必需字段验证结果
  final List<RequiredFieldValidation> _requiredFields;

  /// 必需字段验证结果
  @override
  @JsonKey()
  List<RequiredFieldValidation> get requiredFields {
    if (_requiredFields is EqualUnmodifiableListView) return _requiredFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requiredFields);
  }

  /// 数据一致性检查结果
  final List<ConsistencyValidation> _consistency;

  /// 数据一致性检查结果
  @override
  @JsonKey()
  List<ConsistencyValidation> get consistency {
    if (_consistency is EqualUnmodifiableListView) return _consistency;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_consistency);
  }

  @override
  String toString() {
    return 'DataIntegrityResult(isIntact: $isIntact, relationships: $relationships, formats: $formats, requiredFields: $requiredFields, consistency: $consistency)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataIntegrityResultImpl &&
            (identical(other.isIntact, isIntact) ||
                other.isIntact == isIntact) &&
            const DeepCollectionEquality()
                .equals(other._relationships, _relationships) &&
            const DeepCollectionEquality().equals(other._formats, _formats) &&
            const DeepCollectionEquality()
                .equals(other._requiredFields, _requiredFields) &&
            const DeepCollectionEquality()
                .equals(other._consistency, _consistency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      isIntact,
      const DeepCollectionEquality().hash(_relationships),
      const DeepCollectionEquality().hash(_formats),
      const DeepCollectionEquality().hash(_requiredFields),
      const DeepCollectionEquality().hash(_consistency));

  /// Create a copy of DataIntegrityResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DataIntegrityResultImplCopyWith<_$DataIntegrityResultImpl> get copyWith =>
      __$$DataIntegrityResultImplCopyWithImpl<_$DataIntegrityResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DataIntegrityResultImplToJson(
      this,
    );
  }
}

abstract class _DataIntegrityResult implements DataIntegrityResult {
  const factory _DataIntegrityResult(
          {final bool isIntact,
          final List<RelationshipValidation> relationships,
          final List<FormatValidation> formats,
          final List<RequiredFieldValidation> requiredFields,
          final List<ConsistencyValidation> consistency}) =
      _$DataIntegrityResultImpl;

  factory _DataIntegrityResult.fromJson(Map<String, dynamic> json) =
      _$DataIntegrityResultImpl.fromJson;

  /// 是否完整
  @override
  bool get isIntact;

  /// 关联关系检查结果
  @override
  List<RelationshipValidation> get relationships;

  /// 数据格式验证结果
  @override
  List<FormatValidation> get formats;

  /// 必需字段验证结果
  @override
  List<RequiredFieldValidation> get requiredFields;

  /// 数据一致性检查结果
  @override
  List<ConsistencyValidation> get consistency;

  /// Create a copy of DataIntegrityResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DataIntegrityResultImplCopyWith<_$DataIntegrityResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CorruptedFileInfo _$CorruptedFileInfoFromJson(Map<String, dynamic> json) {
  return _CorruptedFileInfo.fromJson(json);
}

/// @nodoc
mixin _$CorruptedFileInfo {
  /// 文件路径
  String get filePath => throw _privateConstructorUsedError;

  /// 文件类型
  ExportFileType get fileType => throw _privateConstructorUsedError;

  /// 损坏类型
  CorruptionType get corruptionType => throw _privateConstructorUsedError;

  /// 错误描述
  String get errorDescription => throw _privateConstructorUsedError;

  /// 是否可以修复
  bool get canRecover => throw _privateConstructorUsedError;

  /// 修复建议
  String? get recoverySuggestion => throw _privateConstructorUsedError;

  /// Serializes this CorruptedFileInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CorruptedFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CorruptedFileInfoCopyWith<CorruptedFileInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CorruptedFileInfoCopyWith<$Res> {
  factory $CorruptedFileInfoCopyWith(
          CorruptedFileInfo value, $Res Function(CorruptedFileInfo) then) =
      _$CorruptedFileInfoCopyWithImpl<$Res, CorruptedFileInfo>;
  @useResult
  $Res call(
      {String filePath,
      ExportFileType fileType,
      CorruptionType corruptionType,
      String errorDescription,
      bool canRecover,
      String? recoverySuggestion});
}

/// @nodoc
class _$CorruptedFileInfoCopyWithImpl<$Res, $Val extends CorruptedFileInfo>
    implements $CorruptedFileInfoCopyWith<$Res> {
  _$CorruptedFileInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CorruptedFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filePath = null,
    Object? fileType = null,
    Object? corruptionType = null,
    Object? errorDescription = null,
    Object? canRecover = null,
    Object? recoverySuggestion = freezed,
  }) {
    return _then(_value.copyWith(
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as ExportFileType,
      corruptionType: null == corruptionType
          ? _value.corruptionType
          : corruptionType // ignore: cast_nullable_to_non_nullable
              as CorruptionType,
      errorDescription: null == errorDescription
          ? _value.errorDescription
          : errorDescription // ignore: cast_nullable_to_non_nullable
              as String,
      canRecover: null == canRecover
          ? _value.canRecover
          : canRecover // ignore: cast_nullable_to_non_nullable
              as bool,
      recoverySuggestion: freezed == recoverySuggestion
          ? _value.recoverySuggestion
          : recoverySuggestion // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CorruptedFileInfoImplCopyWith<$Res>
    implements $CorruptedFileInfoCopyWith<$Res> {
  factory _$$CorruptedFileInfoImplCopyWith(_$CorruptedFileInfoImpl value,
          $Res Function(_$CorruptedFileInfoImpl) then) =
      __$$CorruptedFileInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String filePath,
      ExportFileType fileType,
      CorruptionType corruptionType,
      String errorDescription,
      bool canRecover,
      String? recoverySuggestion});
}

/// @nodoc
class __$$CorruptedFileInfoImplCopyWithImpl<$Res>
    extends _$CorruptedFileInfoCopyWithImpl<$Res, _$CorruptedFileInfoImpl>
    implements _$$CorruptedFileInfoImplCopyWith<$Res> {
  __$$CorruptedFileInfoImplCopyWithImpl(_$CorruptedFileInfoImpl _value,
      $Res Function(_$CorruptedFileInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of CorruptedFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filePath = null,
    Object? fileType = null,
    Object? corruptionType = null,
    Object? errorDescription = null,
    Object? canRecover = null,
    Object? recoverySuggestion = freezed,
  }) {
    return _then(_$CorruptedFileInfoImpl(
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as ExportFileType,
      corruptionType: null == corruptionType
          ? _value.corruptionType
          : corruptionType // ignore: cast_nullable_to_non_nullable
              as CorruptionType,
      errorDescription: null == errorDescription
          ? _value.errorDescription
          : errorDescription // ignore: cast_nullable_to_non_nullable
              as String,
      canRecover: null == canRecover
          ? _value.canRecover
          : canRecover // ignore: cast_nullable_to_non_nullable
              as bool,
      recoverySuggestion: freezed == recoverySuggestion
          ? _value.recoverySuggestion
          : recoverySuggestion // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CorruptedFileInfoImpl implements _CorruptedFileInfo {
  const _$CorruptedFileInfoImpl(
      {required this.filePath,
      required this.fileType,
      required this.corruptionType,
      required this.errorDescription,
      this.canRecover = false,
      this.recoverySuggestion});

  factory _$CorruptedFileInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CorruptedFileInfoImplFromJson(json);

  /// 文件路径
  @override
  final String filePath;

  /// 文件类型
  @override
  final ExportFileType fileType;

  /// 损坏类型
  @override
  final CorruptionType corruptionType;

  /// 错误描述
  @override
  final String errorDescription;

  /// 是否可以修复
  @override
  @JsonKey()
  final bool canRecover;

  /// 修复建议
  @override
  final String? recoverySuggestion;

  @override
  String toString() {
    return 'CorruptedFileInfo(filePath: $filePath, fileType: $fileType, corruptionType: $corruptionType, errorDescription: $errorDescription, canRecover: $canRecover, recoverySuggestion: $recoverySuggestion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CorruptedFileInfoImpl &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.corruptionType, corruptionType) ||
                other.corruptionType == corruptionType) &&
            (identical(other.errorDescription, errorDescription) ||
                other.errorDescription == errorDescription) &&
            (identical(other.canRecover, canRecover) ||
                other.canRecover == canRecover) &&
            (identical(other.recoverySuggestion, recoverySuggestion) ||
                other.recoverySuggestion == recoverySuggestion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, filePath, fileType,
      corruptionType, errorDescription, canRecover, recoverySuggestion);

  /// Create a copy of CorruptedFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CorruptedFileInfoImplCopyWith<_$CorruptedFileInfoImpl> get copyWith =>
      __$$CorruptedFileInfoImplCopyWithImpl<_$CorruptedFileInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CorruptedFileInfoImplToJson(
      this,
    );
  }
}

abstract class _CorruptedFileInfo implements CorruptedFileInfo {
  const factory _CorruptedFileInfo(
      {required final String filePath,
      required final ExportFileType fileType,
      required final CorruptionType corruptionType,
      required final String errorDescription,
      final bool canRecover,
      final String? recoverySuggestion}) = _$CorruptedFileInfoImpl;

  factory _CorruptedFileInfo.fromJson(Map<String, dynamic> json) =
      _$CorruptedFileInfoImpl.fromJson;

  /// 文件路径
  @override
  String get filePath;

  /// 文件类型
  @override
  ExportFileType get fileType;

  /// 损坏类型
  @override
  CorruptionType get corruptionType;

  /// 错误描述
  @override
  String get errorDescription;

  /// 是否可以修复
  @override
  bool get canRecover;

  /// 修复建议
  @override
  String? get recoverySuggestion;

  /// Create a copy of CorruptedFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CorruptedFileInfoImplCopyWith<_$CorruptedFileInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MissingFileInfo _$MissingFileInfoFromJson(Map<String, dynamic> json) {
  return _MissingFileInfo.fromJson(json);
}

/// @nodoc
mixin _$MissingFileInfo {
  /// 文件路径
  String get filePath => throw _privateConstructorUsedError;

  /// 文件类型
  ExportFileType get fileType => throw _privateConstructorUsedError;

  /// 是否必需
  bool get isRequired => throw _privateConstructorUsedError;

  /// 影响的实体
  List<String> get affectedEntities => throw _privateConstructorUsedError;

  /// 替代方案
  String? get alternative => throw _privateConstructorUsedError;

  /// Serializes this MissingFileInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MissingFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MissingFileInfoCopyWith<MissingFileInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MissingFileInfoCopyWith<$Res> {
  factory $MissingFileInfoCopyWith(
          MissingFileInfo value, $Res Function(MissingFileInfo) then) =
      _$MissingFileInfoCopyWithImpl<$Res, MissingFileInfo>;
  @useResult
  $Res call(
      {String filePath,
      ExportFileType fileType,
      bool isRequired,
      List<String> affectedEntities,
      String? alternative});
}

/// @nodoc
class _$MissingFileInfoCopyWithImpl<$Res, $Val extends MissingFileInfo>
    implements $MissingFileInfoCopyWith<$Res> {
  _$MissingFileInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MissingFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filePath = null,
    Object? fileType = null,
    Object? isRequired = null,
    Object? affectedEntities = null,
    Object? alternative = freezed,
  }) {
    return _then(_value.copyWith(
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as ExportFileType,
      isRequired: null == isRequired
          ? _value.isRequired
          : isRequired // ignore: cast_nullable_to_non_nullable
              as bool,
      affectedEntities: null == affectedEntities
          ? _value.affectedEntities
          : affectedEntities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      alternative: freezed == alternative
          ? _value.alternative
          : alternative // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MissingFileInfoImplCopyWith<$Res>
    implements $MissingFileInfoCopyWith<$Res> {
  factory _$$MissingFileInfoImplCopyWith(_$MissingFileInfoImpl value,
          $Res Function(_$MissingFileInfoImpl) then) =
      __$$MissingFileInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String filePath,
      ExportFileType fileType,
      bool isRequired,
      List<String> affectedEntities,
      String? alternative});
}

/// @nodoc
class __$$MissingFileInfoImplCopyWithImpl<$Res>
    extends _$MissingFileInfoCopyWithImpl<$Res, _$MissingFileInfoImpl>
    implements _$$MissingFileInfoImplCopyWith<$Res> {
  __$$MissingFileInfoImplCopyWithImpl(
      _$MissingFileInfoImpl _value, $Res Function(_$MissingFileInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of MissingFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filePath = null,
    Object? fileType = null,
    Object? isRequired = null,
    Object? affectedEntities = null,
    Object? alternative = freezed,
  }) {
    return _then(_$MissingFileInfoImpl(
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as ExportFileType,
      isRequired: null == isRequired
          ? _value.isRequired
          : isRequired // ignore: cast_nullable_to_non_nullable
              as bool,
      affectedEntities: null == affectedEntities
          ? _value._affectedEntities
          : affectedEntities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      alternative: freezed == alternative
          ? _value.alternative
          : alternative // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MissingFileInfoImpl implements _MissingFileInfo {
  const _$MissingFileInfoImpl(
      {required this.filePath,
      required this.fileType,
      this.isRequired = true,
      final List<String> affectedEntities = const [],
      this.alternative})
      : _affectedEntities = affectedEntities;

  factory _$MissingFileInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MissingFileInfoImplFromJson(json);

  /// 文件路径
  @override
  final String filePath;

  /// 文件类型
  @override
  final ExportFileType fileType;

  /// 是否必需
  @override
  @JsonKey()
  final bool isRequired;

  /// 影响的实体
  final List<String> _affectedEntities;

  /// 影响的实体
  @override
  @JsonKey()
  List<String> get affectedEntities {
    if (_affectedEntities is EqualUnmodifiableListView)
      return _affectedEntities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_affectedEntities);
  }

  /// 替代方案
  @override
  final String? alternative;

  @override
  String toString() {
    return 'MissingFileInfo(filePath: $filePath, fileType: $fileType, isRequired: $isRequired, affectedEntities: $affectedEntities, alternative: $alternative)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MissingFileInfoImpl &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.isRequired, isRequired) ||
                other.isRequired == isRequired) &&
            const DeepCollectionEquality()
                .equals(other._affectedEntities, _affectedEntities) &&
            (identical(other.alternative, alternative) ||
                other.alternative == alternative));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, filePath, fileType, isRequired,
      const DeepCollectionEquality().hash(_affectedEntities), alternative);

  /// Create a copy of MissingFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MissingFileInfoImplCopyWith<_$MissingFileInfoImpl> get copyWith =>
      __$$MissingFileInfoImplCopyWithImpl<_$MissingFileInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MissingFileInfoImplToJson(
      this,
    );
  }
}

abstract class _MissingFileInfo implements MissingFileInfo {
  const factory _MissingFileInfo(
      {required final String filePath,
      required final ExportFileType fileType,
      final bool isRequired,
      final List<String> affectedEntities,
      final String? alternative}) = _$MissingFileInfoImpl;

  factory _MissingFileInfo.fromJson(Map<String, dynamic> json) =
      _$MissingFileInfoImpl.fromJson;

  /// 文件路径
  @override
  String get filePath;

  /// 文件类型
  @override
  ExportFileType get fileType;

  /// 是否必需
  @override
  bool get isRequired;

  /// 影响的实体
  @override
  List<String> get affectedEntities;

  /// 替代方案
  @override
  String? get alternative;

  /// Create a copy of MissingFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MissingFileInfoImplCopyWith<_$MissingFileInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChecksumValidation _$ChecksumValidationFromJson(Map<String, dynamic> json) {
  return _ChecksumValidation.fromJson(json);
}

/// @nodoc
mixin _$ChecksumValidation {
  /// 文件路径
  String get filePath => throw _privateConstructorUsedError;

  /// 预期校验和
  String get expectedChecksum => throw _privateConstructorUsedError;

  /// 实际校验和
  String get actualChecksum => throw _privateConstructorUsedError;

  /// 是否匹配
  bool get isValid => throw _privateConstructorUsedError;

  /// 校验算法
  String get algorithm => throw _privateConstructorUsedError;

  /// Serializes this ChecksumValidation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChecksumValidation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChecksumValidationCopyWith<ChecksumValidation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChecksumValidationCopyWith<$Res> {
  factory $ChecksumValidationCopyWith(
          ChecksumValidation value, $Res Function(ChecksumValidation) then) =
      _$ChecksumValidationCopyWithImpl<$Res, ChecksumValidation>;
  @useResult
  $Res call(
      {String filePath,
      String expectedChecksum,
      String actualChecksum,
      bool isValid,
      String algorithm});
}

/// @nodoc
class _$ChecksumValidationCopyWithImpl<$Res, $Val extends ChecksumValidation>
    implements $ChecksumValidationCopyWith<$Res> {
  _$ChecksumValidationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChecksumValidation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filePath = null,
    Object? expectedChecksum = null,
    Object? actualChecksum = null,
    Object? isValid = null,
    Object? algorithm = null,
  }) {
    return _then(_value.copyWith(
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      expectedChecksum: null == expectedChecksum
          ? _value.expectedChecksum
          : expectedChecksum // ignore: cast_nullable_to_non_nullable
              as String,
      actualChecksum: null == actualChecksum
          ? _value.actualChecksum
          : actualChecksum // ignore: cast_nullable_to_non_nullable
              as String,
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      algorithm: null == algorithm
          ? _value.algorithm
          : algorithm // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChecksumValidationImplCopyWith<$Res>
    implements $ChecksumValidationCopyWith<$Res> {
  factory _$$ChecksumValidationImplCopyWith(_$ChecksumValidationImpl value,
          $Res Function(_$ChecksumValidationImpl) then) =
      __$$ChecksumValidationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String filePath,
      String expectedChecksum,
      String actualChecksum,
      bool isValid,
      String algorithm});
}

/// @nodoc
class __$$ChecksumValidationImplCopyWithImpl<$Res>
    extends _$ChecksumValidationCopyWithImpl<$Res, _$ChecksumValidationImpl>
    implements _$$ChecksumValidationImplCopyWith<$Res> {
  __$$ChecksumValidationImplCopyWithImpl(_$ChecksumValidationImpl _value,
      $Res Function(_$ChecksumValidationImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChecksumValidation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filePath = null,
    Object? expectedChecksum = null,
    Object? actualChecksum = null,
    Object? isValid = null,
    Object? algorithm = null,
  }) {
    return _then(_$ChecksumValidationImpl(
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      expectedChecksum: null == expectedChecksum
          ? _value.expectedChecksum
          : expectedChecksum // ignore: cast_nullable_to_non_nullable
              as String,
      actualChecksum: null == actualChecksum
          ? _value.actualChecksum
          : actualChecksum // ignore: cast_nullable_to_non_nullable
              as String,
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      algorithm: null == algorithm
          ? _value.algorithm
          : algorithm // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChecksumValidationImpl implements _ChecksumValidation {
  const _$ChecksumValidationImpl(
      {required this.filePath,
      required this.expectedChecksum,
      required this.actualChecksum,
      this.isValid = false,
      this.algorithm = 'MD5'});

  factory _$ChecksumValidationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChecksumValidationImplFromJson(json);

  /// 文件路径
  @override
  final String filePath;

  /// 预期校验和
  @override
  final String expectedChecksum;

  /// 实际校验和
  @override
  final String actualChecksum;

  /// 是否匹配
  @override
  @JsonKey()
  final bool isValid;

  /// 校验算法
  @override
  @JsonKey()
  final String algorithm;

  @override
  String toString() {
    return 'ChecksumValidation(filePath: $filePath, expectedChecksum: $expectedChecksum, actualChecksum: $actualChecksum, isValid: $isValid, algorithm: $algorithm)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChecksumValidationImpl &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.expectedChecksum, expectedChecksum) ||
                other.expectedChecksum == expectedChecksum) &&
            (identical(other.actualChecksum, actualChecksum) ||
                other.actualChecksum == actualChecksum) &&
            (identical(other.isValid, isValid) || other.isValid == isValid) &&
            (identical(other.algorithm, algorithm) ||
                other.algorithm == algorithm));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, filePath, expectedChecksum,
      actualChecksum, isValid, algorithm);

  /// Create a copy of ChecksumValidation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChecksumValidationImplCopyWith<_$ChecksumValidationImpl> get copyWith =>
      __$$ChecksumValidationImplCopyWithImpl<_$ChecksumValidationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChecksumValidationImplToJson(
      this,
    );
  }
}

abstract class _ChecksumValidation implements ChecksumValidation {
  const factory _ChecksumValidation(
      {required final String filePath,
      required final String expectedChecksum,
      required final String actualChecksum,
      final bool isValid,
      final String algorithm}) = _$ChecksumValidationImpl;

  factory _ChecksumValidation.fromJson(Map<String, dynamic> json) =
      _$ChecksumValidationImpl.fromJson;

  /// 文件路径
  @override
  String get filePath;

  /// 预期校验和
  @override
  String get expectedChecksum;

  /// 实际校验和
  @override
  String get actualChecksum;

  /// 是否匹配
  @override
  bool get isValid;

  /// 校验算法
  @override
  String get algorithm;

  /// Create a copy of ChecksumValidation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChecksumValidationImplCopyWith<_$ChecksumValidationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RelationshipValidation _$RelationshipValidationFromJson(
    Map<String, dynamic> json) {
  return _RelationshipValidation.fromJson(json);
}

/// @nodoc
mixin _$RelationshipValidation {
  /// 关联类型
  RelationshipType get type => throw _privateConstructorUsedError;

  /// 父实体ID
  String get parentId => throw _privateConstructorUsedError;

  /// 子实体ID
  String get childId => throw _privateConstructorUsedError;

  /// 是否有效
  bool get isValid => throw _privateConstructorUsedError;

  /// 错误描述
  String? get errorDescription => throw _privateConstructorUsedError;

  /// Serializes this RelationshipValidation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RelationshipValidation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RelationshipValidationCopyWith<RelationshipValidation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RelationshipValidationCopyWith<$Res> {
  factory $RelationshipValidationCopyWith(RelationshipValidation value,
          $Res Function(RelationshipValidation) then) =
      _$RelationshipValidationCopyWithImpl<$Res, RelationshipValidation>;
  @useResult
  $Res call(
      {RelationshipType type,
      String parentId,
      String childId,
      bool isValid,
      String? errorDescription});
}

/// @nodoc
class _$RelationshipValidationCopyWithImpl<$Res,
        $Val extends RelationshipValidation>
    implements $RelationshipValidationCopyWith<$Res> {
  _$RelationshipValidationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RelationshipValidation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? parentId = null,
    Object? childId = null,
    Object? isValid = null,
    Object? errorDescription = freezed,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as RelationshipType,
      parentId: null == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String,
      childId: null == childId
          ? _value.childId
          : childId // ignore: cast_nullable_to_non_nullable
              as String,
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      errorDescription: freezed == errorDescription
          ? _value.errorDescription
          : errorDescription // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RelationshipValidationImplCopyWith<$Res>
    implements $RelationshipValidationCopyWith<$Res> {
  factory _$$RelationshipValidationImplCopyWith(
          _$RelationshipValidationImpl value,
          $Res Function(_$RelationshipValidationImpl) then) =
      __$$RelationshipValidationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {RelationshipType type,
      String parentId,
      String childId,
      bool isValid,
      String? errorDescription});
}

/// @nodoc
class __$$RelationshipValidationImplCopyWithImpl<$Res>
    extends _$RelationshipValidationCopyWithImpl<$Res,
        _$RelationshipValidationImpl>
    implements _$$RelationshipValidationImplCopyWith<$Res> {
  __$$RelationshipValidationImplCopyWithImpl(
      _$RelationshipValidationImpl _value,
      $Res Function(_$RelationshipValidationImpl) _then)
      : super(_value, _then);

  /// Create a copy of RelationshipValidation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? parentId = null,
    Object? childId = null,
    Object? isValid = null,
    Object? errorDescription = freezed,
  }) {
    return _then(_$RelationshipValidationImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as RelationshipType,
      parentId: null == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String,
      childId: null == childId
          ? _value.childId
          : childId // ignore: cast_nullable_to_non_nullable
              as String,
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      errorDescription: freezed == errorDescription
          ? _value.errorDescription
          : errorDescription // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RelationshipValidationImpl implements _RelationshipValidation {
  const _$RelationshipValidationImpl(
      {required this.type,
      required this.parentId,
      required this.childId,
      this.isValid = false,
      this.errorDescription});

  factory _$RelationshipValidationImpl.fromJson(Map<String, dynamic> json) =>
      _$$RelationshipValidationImplFromJson(json);

  /// 关联类型
  @override
  final RelationshipType type;

  /// 父实体ID
  @override
  final String parentId;

  /// 子实体ID
  @override
  final String childId;

  /// 是否有效
  @override
  @JsonKey()
  final bool isValid;

  /// 错误描述
  @override
  final String? errorDescription;

  @override
  String toString() {
    return 'RelationshipValidation(type: $type, parentId: $parentId, childId: $childId, isValid: $isValid, errorDescription: $errorDescription)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RelationshipValidationImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.childId, childId) || other.childId == childId) &&
            (identical(other.isValid, isValid) || other.isValid == isValid) &&
            (identical(other.errorDescription, errorDescription) ||
                other.errorDescription == errorDescription));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, type, parentId, childId, isValid, errorDescription);

  /// Create a copy of RelationshipValidation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RelationshipValidationImplCopyWith<_$RelationshipValidationImpl>
      get copyWith => __$$RelationshipValidationImplCopyWithImpl<
          _$RelationshipValidationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RelationshipValidationImplToJson(
      this,
    );
  }
}

abstract class _RelationshipValidation implements RelationshipValidation {
  const factory _RelationshipValidation(
      {required final RelationshipType type,
      required final String parentId,
      required final String childId,
      final bool isValid,
      final String? errorDescription}) = _$RelationshipValidationImpl;

  factory _RelationshipValidation.fromJson(Map<String, dynamic> json) =
      _$RelationshipValidationImpl.fromJson;

  /// 关联类型
  @override
  RelationshipType get type;

  /// 父实体ID
  @override
  String get parentId;

  /// 子实体ID
  @override
  String get childId;

  /// 是否有效
  @override
  bool get isValid;

  /// 错误描述
  @override
  String? get errorDescription;

  /// Create a copy of RelationshipValidation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RelationshipValidationImplCopyWith<_$RelationshipValidationImpl>
      get copyWith => throw _privateConstructorUsedError;
}

FormatValidation _$FormatValidationFromJson(Map<String, dynamic> json) {
  return _FormatValidation.fromJson(json);
}

/// @nodoc
mixin _$FormatValidation {
  /// 实体类型
  EntityType get entityType => throw _privateConstructorUsedError;

  /// 实体ID
  String get entityId => throw _privateConstructorUsedError;

  /// 字段名
  String get fieldName => throw _privateConstructorUsedError;

  /// 是否有效
  bool get isValid => throw _privateConstructorUsedError;

  /// 错误描述
  String? get errorDescription => throw _privateConstructorUsedError;

  /// 建议值
  String? get suggestedValue => throw _privateConstructorUsedError;

  /// Serializes this FormatValidation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FormatValidation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FormatValidationCopyWith<FormatValidation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FormatValidationCopyWith<$Res> {
  factory $FormatValidationCopyWith(
          FormatValidation value, $Res Function(FormatValidation) then) =
      _$FormatValidationCopyWithImpl<$Res, FormatValidation>;
  @useResult
  $Res call(
      {EntityType entityType,
      String entityId,
      String fieldName,
      bool isValid,
      String? errorDescription,
      String? suggestedValue});
}

/// @nodoc
class _$FormatValidationCopyWithImpl<$Res, $Val extends FormatValidation>
    implements $FormatValidationCopyWith<$Res> {
  _$FormatValidationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FormatValidation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entityType = null,
    Object? entityId = null,
    Object? fieldName = null,
    Object? isValid = null,
    Object? errorDescription = freezed,
    Object? suggestedValue = freezed,
  }) {
    return _then(_value.copyWith(
      entityType: null == entityType
          ? _value.entityType
          : entityType // ignore: cast_nullable_to_non_nullable
              as EntityType,
      entityId: null == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String,
      fieldName: null == fieldName
          ? _value.fieldName
          : fieldName // ignore: cast_nullable_to_non_nullable
              as String,
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      errorDescription: freezed == errorDescription
          ? _value.errorDescription
          : errorDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      suggestedValue: freezed == suggestedValue
          ? _value.suggestedValue
          : suggestedValue // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FormatValidationImplCopyWith<$Res>
    implements $FormatValidationCopyWith<$Res> {
  factory _$$FormatValidationImplCopyWith(_$FormatValidationImpl value,
          $Res Function(_$FormatValidationImpl) then) =
      __$$FormatValidationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {EntityType entityType,
      String entityId,
      String fieldName,
      bool isValid,
      String? errorDescription,
      String? suggestedValue});
}

/// @nodoc
class __$$FormatValidationImplCopyWithImpl<$Res>
    extends _$FormatValidationCopyWithImpl<$Res, _$FormatValidationImpl>
    implements _$$FormatValidationImplCopyWith<$Res> {
  __$$FormatValidationImplCopyWithImpl(_$FormatValidationImpl _value,
      $Res Function(_$FormatValidationImpl) _then)
      : super(_value, _then);

  /// Create a copy of FormatValidation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entityType = null,
    Object? entityId = null,
    Object? fieldName = null,
    Object? isValid = null,
    Object? errorDescription = freezed,
    Object? suggestedValue = freezed,
  }) {
    return _then(_$FormatValidationImpl(
      entityType: null == entityType
          ? _value.entityType
          : entityType // ignore: cast_nullable_to_non_nullable
              as EntityType,
      entityId: null == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String,
      fieldName: null == fieldName
          ? _value.fieldName
          : fieldName // ignore: cast_nullable_to_non_nullable
              as String,
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
      errorDescription: freezed == errorDescription
          ? _value.errorDescription
          : errorDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      suggestedValue: freezed == suggestedValue
          ? _value.suggestedValue
          : suggestedValue // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FormatValidationImpl implements _FormatValidation {
  const _$FormatValidationImpl(
      {required this.entityType,
      required this.entityId,
      required this.fieldName,
      this.isValid = false,
      this.errorDescription,
      this.suggestedValue});

  factory _$FormatValidationImpl.fromJson(Map<String, dynamic> json) =>
      _$$FormatValidationImplFromJson(json);

  /// 实体类型
  @override
  final EntityType entityType;

  /// 实体ID
  @override
  final String entityId;

  /// 字段名
  @override
  final String fieldName;

  /// 是否有效
  @override
  @JsonKey()
  final bool isValid;

  /// 错误描述
  @override
  final String? errorDescription;

  /// 建议值
  @override
  final String? suggestedValue;

  @override
  String toString() {
    return 'FormatValidation(entityType: $entityType, entityId: $entityId, fieldName: $fieldName, isValid: $isValid, errorDescription: $errorDescription, suggestedValue: $suggestedValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FormatValidationImpl &&
            (identical(other.entityType, entityType) ||
                other.entityType == entityType) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.fieldName, fieldName) ||
                other.fieldName == fieldName) &&
            (identical(other.isValid, isValid) || other.isValid == isValid) &&
            (identical(other.errorDescription, errorDescription) ||
                other.errorDescription == errorDescription) &&
            (identical(other.suggestedValue, suggestedValue) ||
                other.suggestedValue == suggestedValue));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, entityType, entityId, fieldName,
      isValid, errorDescription, suggestedValue);

  /// Create a copy of FormatValidation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FormatValidationImplCopyWith<_$FormatValidationImpl> get copyWith =>
      __$$FormatValidationImplCopyWithImpl<_$FormatValidationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FormatValidationImplToJson(
      this,
    );
  }
}

abstract class _FormatValidation implements FormatValidation {
  const factory _FormatValidation(
      {required final EntityType entityType,
      required final String entityId,
      required final String fieldName,
      final bool isValid,
      final String? errorDescription,
      final String? suggestedValue}) = _$FormatValidationImpl;

  factory _FormatValidation.fromJson(Map<String, dynamic> json) =
      _$FormatValidationImpl.fromJson;

  /// 实体类型
  @override
  EntityType get entityType;

  /// 实体ID
  @override
  String get entityId;

  /// 字段名
  @override
  String get fieldName;

  /// 是否有效
  @override
  bool get isValid;

  /// 错误描述
  @override
  String? get errorDescription;

  /// 建议值
  @override
  String? get suggestedValue;

  /// Create a copy of FormatValidation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FormatValidationImplCopyWith<_$FormatValidationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RequiredFieldValidation _$RequiredFieldValidationFromJson(
    Map<String, dynamic> json) {
  return _RequiredFieldValidation.fromJson(json);
}

/// @nodoc
mixin _$RequiredFieldValidation {
  /// 实体类型
  EntityType get entityType => throw _privateConstructorUsedError;

  /// 实体ID
  String get entityId => throw _privateConstructorUsedError;

  /// 缺失字段列表
  List<String> get missingFields => throw _privateConstructorUsedError;

  /// 是否有效
  bool get isValid => throw _privateConstructorUsedError;

  /// Serializes this RequiredFieldValidation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RequiredFieldValidation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RequiredFieldValidationCopyWith<RequiredFieldValidation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RequiredFieldValidationCopyWith<$Res> {
  factory $RequiredFieldValidationCopyWith(RequiredFieldValidation value,
          $Res Function(RequiredFieldValidation) then) =
      _$RequiredFieldValidationCopyWithImpl<$Res, RequiredFieldValidation>;
  @useResult
  $Res call(
      {EntityType entityType,
      String entityId,
      List<String> missingFields,
      bool isValid});
}

/// @nodoc
class _$RequiredFieldValidationCopyWithImpl<$Res,
        $Val extends RequiredFieldValidation>
    implements $RequiredFieldValidationCopyWith<$Res> {
  _$RequiredFieldValidationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RequiredFieldValidation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entityType = null,
    Object? entityId = null,
    Object? missingFields = null,
    Object? isValid = null,
  }) {
    return _then(_value.copyWith(
      entityType: null == entityType
          ? _value.entityType
          : entityType // ignore: cast_nullable_to_non_nullable
              as EntityType,
      entityId: null == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String,
      missingFields: null == missingFields
          ? _value.missingFields
          : missingFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RequiredFieldValidationImplCopyWith<$Res>
    implements $RequiredFieldValidationCopyWith<$Res> {
  factory _$$RequiredFieldValidationImplCopyWith(
          _$RequiredFieldValidationImpl value,
          $Res Function(_$RequiredFieldValidationImpl) then) =
      __$$RequiredFieldValidationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {EntityType entityType,
      String entityId,
      List<String> missingFields,
      bool isValid});
}

/// @nodoc
class __$$RequiredFieldValidationImplCopyWithImpl<$Res>
    extends _$RequiredFieldValidationCopyWithImpl<$Res,
        _$RequiredFieldValidationImpl>
    implements _$$RequiredFieldValidationImplCopyWith<$Res> {
  __$$RequiredFieldValidationImplCopyWithImpl(
      _$RequiredFieldValidationImpl _value,
      $Res Function(_$RequiredFieldValidationImpl) _then)
      : super(_value, _then);

  /// Create a copy of RequiredFieldValidation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entityType = null,
    Object? entityId = null,
    Object? missingFields = null,
    Object? isValid = null,
  }) {
    return _then(_$RequiredFieldValidationImpl(
      entityType: null == entityType
          ? _value.entityType
          : entityType // ignore: cast_nullable_to_non_nullable
              as EntityType,
      entityId: null == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String,
      missingFields: null == missingFields
          ? _value._missingFields
          : missingFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RequiredFieldValidationImpl implements _RequiredFieldValidation {
  const _$RequiredFieldValidationImpl(
      {required this.entityType,
      required this.entityId,
      final List<String> missingFields = const [],
      this.isValid = false})
      : _missingFields = missingFields;

  factory _$RequiredFieldValidationImpl.fromJson(Map<String, dynamic> json) =>
      _$$RequiredFieldValidationImplFromJson(json);

  /// 实体类型
  @override
  final EntityType entityType;

  /// 实体ID
  @override
  final String entityId;

  /// 缺失字段列表
  final List<String> _missingFields;

  /// 缺失字段列表
  @override
  @JsonKey()
  List<String> get missingFields {
    if (_missingFields is EqualUnmodifiableListView) return _missingFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_missingFields);
  }

  /// 是否有效
  @override
  @JsonKey()
  final bool isValid;

  @override
  String toString() {
    return 'RequiredFieldValidation(entityType: $entityType, entityId: $entityId, missingFields: $missingFields, isValid: $isValid)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RequiredFieldValidationImpl &&
            (identical(other.entityType, entityType) ||
                other.entityType == entityType) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            const DeepCollectionEquality()
                .equals(other._missingFields, _missingFields) &&
            (identical(other.isValid, isValid) || other.isValid == isValid));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, entityType, entityId,
      const DeepCollectionEquality().hash(_missingFields), isValid);

  /// Create a copy of RequiredFieldValidation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RequiredFieldValidationImplCopyWith<_$RequiredFieldValidationImpl>
      get copyWith => __$$RequiredFieldValidationImplCopyWithImpl<
          _$RequiredFieldValidationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RequiredFieldValidationImplToJson(
      this,
    );
  }
}

abstract class _RequiredFieldValidation implements RequiredFieldValidation {
  const factory _RequiredFieldValidation(
      {required final EntityType entityType,
      required final String entityId,
      final List<String> missingFields,
      final bool isValid}) = _$RequiredFieldValidationImpl;

  factory _RequiredFieldValidation.fromJson(Map<String, dynamic> json) =
      _$RequiredFieldValidationImpl.fromJson;

  /// 实体类型
  @override
  EntityType get entityType;

  /// 实体ID
  @override
  String get entityId;

  /// 缺失字段列表
  @override
  List<String> get missingFields;

  /// 是否有效
  @override
  bool get isValid;

  /// Create a copy of RequiredFieldValidation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RequiredFieldValidationImplCopyWith<_$RequiredFieldValidationImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ConsistencyValidation _$ConsistencyValidationFromJson(
    Map<String, dynamic> json) {
  return _ConsistencyValidation.fromJson(json);
}

/// @nodoc
mixin _$ConsistencyValidation {
  /// 一致性类型
  ConsistencyType get type => throw _privateConstructorUsedError;

  /// 相关实体
  List<String> get entities => throw _privateConstructorUsedError;

  /// 是否一致
  bool get isConsistent => throw _privateConstructorUsedError;

  /// 不一致描述
  String? get inconsistencyDescription => throw _privateConstructorUsedError;

  /// 修复建议
  String? get fixSuggestion => throw _privateConstructorUsedError;

  /// Serializes this ConsistencyValidation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConsistencyValidation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConsistencyValidationCopyWith<ConsistencyValidation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConsistencyValidationCopyWith<$Res> {
  factory $ConsistencyValidationCopyWith(ConsistencyValidation value,
          $Res Function(ConsistencyValidation) then) =
      _$ConsistencyValidationCopyWithImpl<$Res, ConsistencyValidation>;
  @useResult
  $Res call(
      {ConsistencyType type,
      List<String> entities,
      bool isConsistent,
      String? inconsistencyDescription,
      String? fixSuggestion});
}

/// @nodoc
class _$ConsistencyValidationCopyWithImpl<$Res,
        $Val extends ConsistencyValidation>
    implements $ConsistencyValidationCopyWith<$Res> {
  _$ConsistencyValidationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConsistencyValidation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? entities = null,
    Object? isConsistent = null,
    Object? inconsistencyDescription = freezed,
    Object? fixSuggestion = freezed,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ConsistencyType,
      entities: null == entities
          ? _value.entities
          : entities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isConsistent: null == isConsistent
          ? _value.isConsistent
          : isConsistent // ignore: cast_nullable_to_non_nullable
              as bool,
      inconsistencyDescription: freezed == inconsistencyDescription
          ? _value.inconsistencyDescription
          : inconsistencyDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      fixSuggestion: freezed == fixSuggestion
          ? _value.fixSuggestion
          : fixSuggestion // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConsistencyValidationImplCopyWith<$Res>
    implements $ConsistencyValidationCopyWith<$Res> {
  factory _$$ConsistencyValidationImplCopyWith(
          _$ConsistencyValidationImpl value,
          $Res Function(_$ConsistencyValidationImpl) then) =
      __$$ConsistencyValidationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ConsistencyType type,
      List<String> entities,
      bool isConsistent,
      String? inconsistencyDescription,
      String? fixSuggestion});
}

/// @nodoc
class __$$ConsistencyValidationImplCopyWithImpl<$Res>
    extends _$ConsistencyValidationCopyWithImpl<$Res,
        _$ConsistencyValidationImpl>
    implements _$$ConsistencyValidationImplCopyWith<$Res> {
  __$$ConsistencyValidationImplCopyWithImpl(_$ConsistencyValidationImpl _value,
      $Res Function(_$ConsistencyValidationImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConsistencyValidation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? entities = null,
    Object? isConsistent = null,
    Object? inconsistencyDescription = freezed,
    Object? fixSuggestion = freezed,
  }) {
    return _then(_$ConsistencyValidationImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ConsistencyType,
      entities: null == entities
          ? _value._entities
          : entities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isConsistent: null == isConsistent
          ? _value.isConsistent
          : isConsistent // ignore: cast_nullable_to_non_nullable
              as bool,
      inconsistencyDescription: freezed == inconsistencyDescription
          ? _value.inconsistencyDescription
          : inconsistencyDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      fixSuggestion: freezed == fixSuggestion
          ? _value.fixSuggestion
          : fixSuggestion // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConsistencyValidationImpl implements _ConsistencyValidation {
  const _$ConsistencyValidationImpl(
      {required this.type,
      final List<String> entities = const [],
      this.isConsistent = false,
      this.inconsistencyDescription,
      this.fixSuggestion})
      : _entities = entities;

  factory _$ConsistencyValidationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConsistencyValidationImplFromJson(json);

  /// 一致性类型
  @override
  final ConsistencyType type;

  /// 相关实体
  final List<String> _entities;

  /// 相关实体
  @override
  @JsonKey()
  List<String> get entities {
    if (_entities is EqualUnmodifiableListView) return _entities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entities);
  }

  /// 是否一致
  @override
  @JsonKey()
  final bool isConsistent;

  /// 不一致描述
  @override
  final String? inconsistencyDescription;

  /// 修复建议
  @override
  final String? fixSuggestion;

  @override
  String toString() {
    return 'ConsistencyValidation(type: $type, entities: $entities, isConsistent: $isConsistent, inconsistencyDescription: $inconsistencyDescription, fixSuggestion: $fixSuggestion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConsistencyValidationImpl &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._entities, _entities) &&
            (identical(other.isConsistent, isConsistent) ||
                other.isConsistent == isConsistent) &&
            (identical(
                    other.inconsistencyDescription, inconsistencyDescription) ||
                other.inconsistencyDescription == inconsistencyDescription) &&
            (identical(other.fixSuggestion, fixSuggestion) ||
                other.fixSuggestion == fixSuggestion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      type,
      const DeepCollectionEquality().hash(_entities),
      isConsistent,
      inconsistencyDescription,
      fixSuggestion);

  /// Create a copy of ConsistencyValidation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConsistencyValidationImplCopyWith<_$ConsistencyValidationImpl>
      get copyWith => __$$ConsistencyValidationImplCopyWithImpl<
          _$ConsistencyValidationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConsistencyValidationImplToJson(
      this,
    );
  }
}

abstract class _ConsistencyValidation implements ConsistencyValidation {
  const factory _ConsistencyValidation(
      {required final ConsistencyType type,
      final List<String> entities,
      final bool isConsistent,
      final String? inconsistencyDescription,
      final String? fixSuggestion}) = _$ConsistencyValidationImpl;

  factory _ConsistencyValidation.fromJson(Map<String, dynamic> json) =
      _$ConsistencyValidationImpl.fromJson;

  /// 一致性类型
  @override
  ConsistencyType get type;

  /// 相关实体
  @override
  List<String> get entities;

  /// 是否一致
  @override
  bool get isConsistent;

  /// 不一致描述
  @override
  String? get inconsistencyDescription;

  /// 修复建议
  @override
  String? get fixSuggestion;

  /// Create a copy of ConsistencyValidation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConsistencyValidationImplCopyWith<_$ConsistencyValidationImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ImportOptions _$ImportOptionsFromJson(Map<String, dynamic> json) {
  return _ImportOptions.fromJson(json);
}

/// @nodoc
mixin _$ImportOptions {
  /// 冲突解决策略
  ConflictResolution get defaultConflictResolution =>
      throw _privateConstructorUsedError;

  /// 是否覆盖现有数据
  bool get overwriteExisting => throw _privateConstructorUsedError;

  /// 是否跳过损坏的文件
  bool get skipCorruptedFiles => throw _privateConstructorUsedError;

  /// 是否创建备份
  bool get createBackup => throw _privateConstructorUsedError;

  /// 是否验证文件完整性
  bool get validateFileIntegrity => throw _privateConstructorUsedError;

  /// 是否自动修复可修复的错误
  bool get autoFixErrors => throw _privateConstructorUsedError;

  /// 导入目标目录
  String? get targetDirectory => throw _privateConstructorUsedError;

  /// 自定义选项
  Map<String, dynamic> get customOptions => throw _privateConstructorUsedError;

  /// Serializes this ImportOptions to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ImportOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ImportOptionsCopyWith<ImportOptions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImportOptionsCopyWith<$Res> {
  factory $ImportOptionsCopyWith(
          ImportOptions value, $Res Function(ImportOptions) then) =
      _$ImportOptionsCopyWithImpl<$Res, ImportOptions>;
  @useResult
  $Res call(
      {ConflictResolution defaultConflictResolution,
      bool overwriteExisting,
      bool skipCorruptedFiles,
      bool createBackup,
      bool validateFileIntegrity,
      bool autoFixErrors,
      String? targetDirectory,
      Map<String, dynamic> customOptions});
}

/// @nodoc
class _$ImportOptionsCopyWithImpl<$Res, $Val extends ImportOptions>
    implements $ImportOptionsCopyWith<$Res> {
  _$ImportOptionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ImportOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? defaultConflictResolution = null,
    Object? overwriteExisting = null,
    Object? skipCorruptedFiles = null,
    Object? createBackup = null,
    Object? validateFileIntegrity = null,
    Object? autoFixErrors = null,
    Object? targetDirectory = freezed,
    Object? customOptions = null,
  }) {
    return _then(_value.copyWith(
      defaultConflictResolution: null == defaultConflictResolution
          ? _value.defaultConflictResolution
          : defaultConflictResolution // ignore: cast_nullable_to_non_nullable
              as ConflictResolution,
      overwriteExisting: null == overwriteExisting
          ? _value.overwriteExisting
          : overwriteExisting // ignore: cast_nullable_to_non_nullable
              as bool,
      skipCorruptedFiles: null == skipCorruptedFiles
          ? _value.skipCorruptedFiles
          : skipCorruptedFiles // ignore: cast_nullable_to_non_nullable
              as bool,
      createBackup: null == createBackup
          ? _value.createBackup
          : createBackup // ignore: cast_nullable_to_non_nullable
              as bool,
      validateFileIntegrity: null == validateFileIntegrity
          ? _value.validateFileIntegrity
          : validateFileIntegrity // ignore: cast_nullable_to_non_nullable
              as bool,
      autoFixErrors: null == autoFixErrors
          ? _value.autoFixErrors
          : autoFixErrors // ignore: cast_nullable_to_non_nullable
              as bool,
      targetDirectory: freezed == targetDirectory
          ? _value.targetDirectory
          : targetDirectory // ignore: cast_nullable_to_non_nullable
              as String?,
      customOptions: null == customOptions
          ? _value.customOptions
          : customOptions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ImportOptionsImplCopyWith<$Res>
    implements $ImportOptionsCopyWith<$Res> {
  factory _$$ImportOptionsImplCopyWith(
          _$ImportOptionsImpl value, $Res Function(_$ImportOptionsImpl) then) =
      __$$ImportOptionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ConflictResolution defaultConflictResolution,
      bool overwriteExisting,
      bool skipCorruptedFiles,
      bool createBackup,
      bool validateFileIntegrity,
      bool autoFixErrors,
      String? targetDirectory,
      Map<String, dynamic> customOptions});
}

/// @nodoc
class __$$ImportOptionsImplCopyWithImpl<$Res>
    extends _$ImportOptionsCopyWithImpl<$Res, _$ImportOptionsImpl>
    implements _$$ImportOptionsImplCopyWith<$Res> {
  __$$ImportOptionsImplCopyWithImpl(
      _$ImportOptionsImpl _value, $Res Function(_$ImportOptionsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ImportOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? defaultConflictResolution = null,
    Object? overwriteExisting = null,
    Object? skipCorruptedFiles = null,
    Object? createBackup = null,
    Object? validateFileIntegrity = null,
    Object? autoFixErrors = null,
    Object? targetDirectory = freezed,
    Object? customOptions = null,
  }) {
    return _then(_$ImportOptionsImpl(
      defaultConflictResolution: null == defaultConflictResolution
          ? _value.defaultConflictResolution
          : defaultConflictResolution // ignore: cast_nullable_to_non_nullable
              as ConflictResolution,
      overwriteExisting: null == overwriteExisting
          ? _value.overwriteExisting
          : overwriteExisting // ignore: cast_nullable_to_non_nullable
              as bool,
      skipCorruptedFiles: null == skipCorruptedFiles
          ? _value.skipCorruptedFiles
          : skipCorruptedFiles // ignore: cast_nullable_to_non_nullable
              as bool,
      createBackup: null == createBackup
          ? _value.createBackup
          : createBackup // ignore: cast_nullable_to_non_nullable
              as bool,
      validateFileIntegrity: null == validateFileIntegrity
          ? _value.validateFileIntegrity
          : validateFileIntegrity // ignore: cast_nullable_to_non_nullable
              as bool,
      autoFixErrors: null == autoFixErrors
          ? _value.autoFixErrors
          : autoFixErrors // ignore: cast_nullable_to_non_nullable
              as bool,
      targetDirectory: freezed == targetDirectory
          ? _value.targetDirectory
          : targetDirectory // ignore: cast_nullable_to_non_nullable
              as String?,
      customOptions: null == customOptions
          ? _value._customOptions
          : customOptions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ImportOptionsImpl implements _ImportOptions {
  const _$ImportOptionsImpl(
      {this.defaultConflictResolution = ConflictResolution.ask,
      this.overwriteExisting = false,
      this.skipCorruptedFiles = true,
      this.createBackup = true,
      this.validateFileIntegrity = true,
      this.autoFixErrors = true,
      this.targetDirectory,
      final Map<String, dynamic> customOptions = const {}})
      : _customOptions = customOptions;

  factory _$ImportOptionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImportOptionsImplFromJson(json);

  /// 冲突解决策略
  @override
  @JsonKey()
  final ConflictResolution defaultConflictResolution;

  /// 是否覆盖现有数据
  @override
  @JsonKey()
  final bool overwriteExisting;

  /// 是否跳过损坏的文件
  @override
  @JsonKey()
  final bool skipCorruptedFiles;

  /// 是否创建备份
  @override
  @JsonKey()
  final bool createBackup;

  /// 是否验证文件完整性
  @override
  @JsonKey()
  final bool validateFileIntegrity;

  /// 是否自动修复可修复的错误
  @override
  @JsonKey()
  final bool autoFixErrors;

  /// 导入目标目录
  @override
  final String? targetDirectory;

  /// 自定义选项
  final Map<String, dynamic> _customOptions;

  /// 自定义选项
  @override
  @JsonKey()
  Map<String, dynamic> get customOptions {
    if (_customOptions is EqualUnmodifiableMapView) return _customOptions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_customOptions);
  }

  @override
  String toString() {
    return 'ImportOptions(defaultConflictResolution: $defaultConflictResolution, overwriteExisting: $overwriteExisting, skipCorruptedFiles: $skipCorruptedFiles, createBackup: $createBackup, validateFileIntegrity: $validateFileIntegrity, autoFixErrors: $autoFixErrors, targetDirectory: $targetDirectory, customOptions: $customOptions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImportOptionsImpl &&
            (identical(other.defaultConflictResolution,
                    defaultConflictResolution) ||
                other.defaultConflictResolution == defaultConflictResolution) &&
            (identical(other.overwriteExisting, overwriteExisting) ||
                other.overwriteExisting == overwriteExisting) &&
            (identical(other.skipCorruptedFiles, skipCorruptedFiles) ||
                other.skipCorruptedFiles == skipCorruptedFiles) &&
            (identical(other.createBackup, createBackup) ||
                other.createBackup == createBackup) &&
            (identical(other.validateFileIntegrity, validateFileIntegrity) ||
                other.validateFileIntegrity == validateFileIntegrity) &&
            (identical(other.autoFixErrors, autoFixErrors) ||
                other.autoFixErrors == autoFixErrors) &&
            (identical(other.targetDirectory, targetDirectory) ||
                other.targetDirectory == targetDirectory) &&
            const DeepCollectionEquality()
                .equals(other._customOptions, _customOptions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      defaultConflictResolution,
      overwriteExisting,
      skipCorruptedFiles,
      createBackup,
      validateFileIntegrity,
      autoFixErrors,
      targetDirectory,
      const DeepCollectionEquality().hash(_customOptions));

  /// Create a copy of ImportOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImportOptionsImplCopyWith<_$ImportOptionsImpl> get copyWith =>
      __$$ImportOptionsImplCopyWithImpl<_$ImportOptionsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ImportOptionsImplToJson(
      this,
    );
  }
}

abstract class _ImportOptions implements ImportOptions {
  const factory _ImportOptions(
      {final ConflictResolution defaultConflictResolution,
      final bool overwriteExisting,
      final bool skipCorruptedFiles,
      final bool createBackup,
      final bool validateFileIntegrity,
      final bool autoFixErrors,
      final String? targetDirectory,
      final Map<String, dynamic> customOptions}) = _$ImportOptionsImpl;

  factory _ImportOptions.fromJson(Map<String, dynamic> json) =
      _$ImportOptionsImpl.fromJson;

  /// 冲突解决策略
  @override
  ConflictResolution get defaultConflictResolution;

  /// 是否覆盖现有数据
  @override
  bool get overwriteExisting;

  /// 是否跳过损坏的文件
  @override
  bool get skipCorruptedFiles;

  /// 是否创建备份
  @override
  bool get createBackup;

  /// 是否验证文件完整性
  @override
  bool get validateFileIntegrity;

  /// 是否自动修复可修复的错误
  @override
  bool get autoFixErrors;

  /// 导入目标目录
  @override
  String? get targetDirectory;

  /// 自定义选项
  @override
  Map<String, dynamic> get customOptions;

  /// Create a copy of ImportOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImportOptionsImplCopyWith<_$ImportOptionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
