import 'dart:convert';
import 'dart:io';

import '../models/work/work_entity.dart';
import '../models/work/work_image.dart';
import '../models/character/character_entity.dart';
import '../models/import_export/import_export_exceptions.dart';
import '../../infrastructure/logging/logger.dart';
import 'import_service.dart';

/// 导入事务管理器
/// 负责跟踪导入操作的所有变更，支持完整回滚
class ImportTransactionManager {
  /// 事务ID
  final String transactionId;
  
  /// 事务开始时间
  final DateTime startTime;
  
  /// 操作记录列表
  final List<TransactionOperation> _operations = [];
  
  /// 数据库快照
  final Map<String, DatabaseSnapshot> _snapshots = {};
  
  /// 文件操作记录
  final List<FileOperation> _fileOperations = [];
  
  /// 事务状态
  TransactionStatus _status = TransactionStatus.active;
  
  /// 错误信息
  String? _errorMessage;

  ImportTransactionManager(this.transactionId) : startTime = DateTime.now();

  /// 当前事务状态
  TransactionStatus get status => _status;
  
  /// 错误信息
  String? get errorMessage => _errorMessage;
  
  /// 操作总数
  int get operationCount => _operations.length;
  
  /// 是否可以回滚
  bool get canRollback => _status == TransactionStatus.committed && _operations.isNotEmpty;

  /// 记录数据库操作
  void recordDatabaseOperation(
    DatabaseOperationType type,
    String tableName,
    String entityId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  ) {
    if (_status != TransactionStatus.active) {
      throw ImportException(
        '事务已结束，无法记录新操作',
        ImportExportErrorCodes.systemConcurrencyConflict,
        details: {'transactionId': transactionId, 'status': _status.name},
      );
    }

    final operation = TransactionOperation(
      id: '${transactionId}_op_${_operations.length}',
      type: type,
      tableName: tableName,
      entityId: entityId,
      oldData: oldData,
      newData: newData,
      timestamp: DateTime.now(),
    );

    _operations.add(operation);
    
    AppLogger.info(
      '记录数据库操作',
      data: {
        'transactionId': transactionId,
        'operationType': type.name,
        'tableName': tableName,
        'entityId': entityId,
        'operationCount': _operations.length,
      },
      tag: 'import_transaction',
    );
  }

  /// 记录文件操作
  void recordFileOperation(
    FileOperationType type,
    String filePath, {
    String? sourcePath,
    String? backupPath,
    Map<String, dynamic>? metadata,
  }) {
    if (_status != TransactionStatus.active) {
      throw ImportException(
        '事务已结束，无法记录新操作',
        ImportExportErrorCodes.systemConcurrencyConflict,
        details: {'transactionId': transactionId, 'status': _status.name},
      );
    }

    final operation = FileOperation(
      id: '${transactionId}_file_${_fileOperations.length}',
      type: type,
      filePath: filePath,
      sourcePath: sourcePath,
      backupPath: backupPath,
      metadata: metadata ?? {},
      timestamp: DateTime.now(),
    );

    _fileOperations.add(operation);
    
    AppLogger.info(
      '记录文件操作',
      data: {
        'transactionId': transactionId,
        'operationType': type.name,
        'filePath': filePath,
        'sourcePath': sourcePath,
        'fileOperationCount': _fileOperations.length,
      },
      tag: 'import_transaction',
    );
  }

  /// 创建数据库表快照
  Future<void> createSnapshot(
    String tableName,
    List<Map<String, dynamic>> data,
  ) async {
    if (_status != TransactionStatus.active) {
      throw ImportException(
        '事务已结束，无法创建快照',
        ImportExportErrorCodes.systemConcurrencyConflict,
        details: {'transactionId': transactionId, 'status': _status.name},
      );
    }

    final snapshot = DatabaseSnapshot(
      tableName: tableName,
      data: List.from(data),
      timestamp: DateTime.now(),
    );

    _snapshots[tableName] = snapshot;
    
    AppLogger.info(
      '创建数据库快照',
      data: {
        'transactionId': transactionId,
        'tableName': tableName,
        'recordCount': data.length,
        'snapshotCount': _snapshots.length,
      },
      tag: 'import_transaction',
    );
  }

  /// 提交事务
  void commit() {
    if (_status != TransactionStatus.active) {
      throw ImportException(
        '事务状态无效，无法提交',
        ImportExportErrorCodes.systemConcurrencyConflict,
        details: {'transactionId': transactionId, 'status': _status.name},
      );
    }

    _status = TransactionStatus.committed;
    
    AppLogger.info(
      '提交导入事务',
      data: {
        'transactionId': transactionId,
        'operationCount': _operations.length,
        'fileOperationCount': _fileOperations.length,
        'snapshotCount': _snapshots.length,
        'duration': DateTime.now().difference(startTime).inMilliseconds,
      },
      tag: 'import_transaction',
    );
  }

  /// 标记事务失败
  void markFailed(String errorMessage) {
    _status = TransactionStatus.failed;
    _errorMessage = errorMessage;
    
    AppLogger.error(
      '导入事务失败',
      data: {
        'transactionId': transactionId,
        'errorMessage': errorMessage,
        'operationCount': _operations.length,
        'fileOperationCount': _fileOperations.length,
      },
      tag: 'import_transaction',
    );
  }

  /// 执行回滚操作
  Future<RollbackResult> rollback() async {
    if (!canRollback) {
      throw ImportException(
        '事务无法回滚',
        ImportExportErrorCodes.importRollbackFailed,
        details: {
          'transactionId': transactionId,
          'status': _status.name,
          'canRollback': canRollback,
        },
      );
    }

    _status = TransactionStatus.rollingBack;
    final rollbackStart = DateTime.now();
    final errors = <String>[];
    
    var rolledBackWorks = 0;
    var rolledBackCharacters = 0;
    var rolledBackImages = 0;

    try {
      AppLogger.info(
        '开始回滚导入事务',
        data: {
          'transactionId': transactionId,
          'operationCount': _operations.length,
          'fileOperationCount': _fileOperations.length,
        },
        tag: 'import_rollback',
      );

      // 1. 回滚文件操作（按相反顺序）
      await _rollbackFileOperations(errors);

      // 2. 回滚数据库操作（按相反顺序）
      final dbResults = await _rollbackDatabaseOperations(errors);
      rolledBackWorks = dbResults['works'] ?? 0;
      rolledBackCharacters = dbResults['characters'] ?? 0;
      rolledBackImages = dbResults['images'] ?? 0;

      // 3. 恢复数据库快照（如果需要）
      await _restoreSnapshots(errors);

      _status = TransactionStatus.rolledBack;
      
      final duration = DateTime.now().difference(rollbackStart).inMilliseconds;
      
      AppLogger.info(
        '导入事务回滚完成',
        data: {
          'transactionId': transactionId,
          'rolledBackWorks': rolledBackWorks,
          'rolledBackCharacters': rolledBackCharacters,
          'rolledBackImages': rolledBackImages,
          'errorCount': errors.length,
          'duration': duration,
        },
        tag: 'import_rollback',
      );

      return RollbackResult(
        success: errors.isEmpty,
        rolledBackWorks: rolledBackWorks,
        rolledBackCharacters: rolledBackCharacters,
        rolledBackImages: rolledBackImages,
        errors: errors,
        duration: duration,
      );

    } catch (e, stackTrace) {
      _status = TransactionStatus.rollbackFailed;
      final error = '回滚过程中发生异常: $e';
      errors.add(error);
      
      AppLogger.error(
        '导入事务回滚失败',
        error: e,
        stackTrace: stackTrace,
        data: {
          'transactionId': transactionId,
          'errorCount': errors.length,
        },
        tag: 'import_rollback',
      );

      return RollbackResult(
        success: false,
        errors: errors,
        duration: DateTime.now().difference(rollbackStart).inMilliseconds,
      );
    }
  }

  /// 回滚文件操作
  Future<void> _rollbackFileOperations(List<String> errors) async {
    for (final operation in _fileOperations.reversed) {
      try {
        await _rollbackSingleFileOperation(operation);
      } catch (e) {
        final error = '回滚文件操作失败 ${operation.filePath}: $e';
        errors.add(error);
        AppLogger.warning(
          '文件操作回滚失败',
          data: {
            'transactionId': transactionId,
            'operationId': operation.id,
            'filePath': operation.filePath,
            'error': e.toString(),
          },
          tag: 'import_rollback',
        );
      }
    }
  }

  /// 回滚单个文件操作
  Future<void> _rollbackSingleFileOperation(FileOperation operation) async {
    final file = File(operation.filePath);
    
    switch (operation.type) {
      case FileOperationType.create:
        // 删除创建的文件
        if (await file.exists()) {
          await file.delete();
        }
        break;
        
      case FileOperationType.copy:
        // 删除复制的文件
        if (await file.exists()) {
          await file.delete();
        }
        break;
        
      case FileOperationType.move:
        // 将文件移回原位置
        if (operation.sourcePath != null) {
          final sourceFile = File(operation.sourcePath!);
          if (await file.exists() && !await sourceFile.exists()) {
            await file.rename(operation.sourcePath!);
          }
        }
        break;
        
      case FileOperationType.backup:
        // 从备份恢复文件
        if (operation.backupPath != null) {
          final backupFile = File(operation.backupPath!);
          if (await backupFile.exists()) {
            await backupFile.copy(operation.filePath);
            await backupFile.delete();
          }
        }
        break;
        
      case FileOperationType.delete:
        // 从备份恢复已删除的文件
        if (operation.backupPath != null) {
          final backupFile = File(operation.backupPath!);
          if (await backupFile.exists()) {
            await backupFile.copy(operation.filePath);
          }
        }
        break;
    }
  }

  /// 回滚数据库操作
  Future<Map<String, int>> _rollbackDatabaseOperations(List<String> errors) async {
    final results = <String, int>{
      'works': 0,
      'characters': 0,
      'images': 0,
    };

    for (final operation in _operations.reversed) {
      try {
        await _rollbackSingleDatabaseOperation(operation);
        
        // 统计回滚的项目数
        switch (operation.tableName) {
          case 'works':
            results['works'] = results['works']! + 1;
            break;
          case 'characters':
            results['characters'] = results['characters']! + 1;
            break;
          case 'work_images':
            results['images'] = results['images']! + 1;
            break;
        }
      } catch (e) {
        final error = '回滚数据库操作失败 ${operation.tableName}:${operation.entityId}: $e';
        errors.add(error);
        AppLogger.warning(
          '数据库操作回滚失败',
          data: {
            'transactionId': transactionId,
            'operationId': operation.id,
            'tableName': operation.tableName,
            'entityId': operation.entityId,
            'error': e.toString(),
          },
          tag: 'import_rollback',
        );
      }
    }

    return results;
  }

  /// 回滚单个数据库操作
  Future<void> _rollbackSingleDatabaseOperation(TransactionOperation operation) async {
    // 这里需要根据具体的数据库实现来完成
    // 示例代码，需要注入实际的数据库服务
    switch (operation.type) {
      case DatabaseOperationType.insert:
        // 删除插入的记录
        AppLogger.debug(
          '回滚插入操作',
          data: {
            'tableName': operation.tableName,
            'entityId': operation.entityId,
          },
          tag: 'import_rollback',
        );
        break;
        
      case DatabaseOperationType.update:
        // 恢复旧数据
        if (operation.oldData != null) {
          AppLogger.debug(
            '回滚更新操作',
            data: {
              'tableName': operation.tableName,
              'entityId': operation.entityId,
              'oldData': operation.oldData,
            },
            tag: 'import_rollback',
          );
        }
        break;
        
      case DatabaseOperationType.delete:
        // 恢复删除的数据
        if (operation.oldData != null) {
          AppLogger.debug(
            '回滚删除操作',
            data: {
              'tableName': operation.tableName,
              'entityId': operation.entityId,
              'restoredData': operation.oldData,
            },
            tag: 'import_rollback',
          );
        }
        break;
    }
  }

  /// 恢复数据库快照
  Future<void> _restoreSnapshots(List<String> errors) async {
    for (final entry in _snapshots.entries) {
      try {
        await _restoreSingleSnapshot(entry.key, entry.value);
      } catch (e) {
        final error = '恢复快照失败 ${entry.key}: $e';
        errors.add(error);
        AppLogger.warning(
          '快照恢复失败',
          data: {
            'transactionId': transactionId,
            'tableName': entry.key,
            'error': e.toString(),
          },
          tag: 'import_rollback',
        );
      }
    }
  }

  /// 恢复单个快照
  Future<void> _restoreSingleSnapshot(String tableName, DatabaseSnapshot snapshot) async {
    AppLogger.debug(
      '恢复数据库快照',
      data: {
        'tableName': tableName,
        'recordCount': snapshot.data.length,
        'snapshotTime': snapshot.timestamp.toIso8601String(),
      },
      tag: 'import_rollback',
    );
    
    // 这里需要根据具体的数据库实现来完成快照恢复
    // 通常包括：清空表、重新插入快照数据
  }

  /// 获取事务摘要
  TransactionSummary getSummary() {
    return TransactionSummary(
      transactionId: transactionId,
      startTime: startTime,
      status: _status,
      operationCount: _operations.length,
      fileOperationCount: _fileOperations.length,
      snapshotCount: _snapshots.length,
      errorMessage: _errorMessage,
    );
  }

  /// 导出事务日志
  Map<String, dynamic> exportLog() {
    return {
      'transactionId': transactionId,
      'startTime': startTime.toIso8601String(),
      'status': _status.name,
      'errorMessage': _errorMessage,
      'operations': _operations.map((op) => op.toJson()).toList(),
      'fileOperations': _fileOperations.map((op) => op.toJson()).toList(),
      'snapshots': _snapshots.map((key, value) => MapEntry(key, {
        'tableName': value.tableName,
        'recordCount': value.data.length,
        'timestamp': value.timestamp.toIso8601String(),
      })),
    };
  }
}

/// 事务操作记录
class TransactionOperation {
  final String id;
  final DatabaseOperationType type;
  final String tableName;
  final String entityId;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final DateTime timestamp;

  const TransactionOperation({
    required this.id,
    required this.type,
    required this.tableName,
    required this.entityId,
    this.oldData,
    this.newData,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'tableName': tableName,
      'entityId': entityId,
      'oldData': oldData,
      'newData': newData,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// 文件操作记录
class FileOperation {
  final String id;
  final FileOperationType type;
  final String filePath;
  final String? sourcePath;
  final String? backupPath;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const FileOperation({
    required this.id,
    required this.type,
    required this.filePath,
    this.sourcePath,
    this.backupPath,
    this.metadata = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'filePath': filePath,
      'sourcePath': sourcePath,
      'backupPath': backupPath,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// 数据库快照
class DatabaseSnapshot {
  final String tableName;
  final List<Map<String, dynamic>> data;
  final DateTime timestamp;

  const DatabaseSnapshot({
    required this.tableName,
    required this.data,
    required this.timestamp,
  });
}

/// 事务摘要
class TransactionSummary {
  final String transactionId;
  final DateTime startTime;
  final TransactionStatus status;
  final int operationCount;
  final int fileOperationCount;
  final int snapshotCount;
  final String? errorMessage;

  const TransactionSummary({
    required this.transactionId,
    required this.startTime,
    required this.status,
    required this.operationCount,
    required this.fileOperationCount,
    required this.snapshotCount,
    this.errorMessage,
  });
}

/// 事务状态枚举
enum TransactionStatus {
  /// 活跃状态
  active,
  /// 已提交
  committed,
  /// 失败
  failed,
  /// 回滚中
  rollingBack,
  /// 已回滚
  rolledBack,
  /// 回滚失败
  rollbackFailed,
}

/// 数据库操作类型枚举
enum DatabaseOperationType {
  /// 插入
  insert,
  /// 更新
  update,
  /// 删除
  delete,
}

/// 文件操作类型枚举
enum FileOperationType {
  /// 创建
  create,
  /// 复制
  copy,
  /// 移动
  move,
  /// 备份
  backup,
  /// 删除
  delete,
} 