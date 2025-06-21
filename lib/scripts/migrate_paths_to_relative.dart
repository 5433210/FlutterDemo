import 'dart:io';

import '../infrastructure/logging/logger.dart';
import '../infrastructure/persistence/database_interface.dart';
import '../utils/path_privacy_helper.dart';

/// 数据库路径迁移脚本
/// 
/// 将现有数据库中的绝对路径转换为相对路径，保护用户隐私
class PathMigrationScript {
  final DatabaseInterface _db;
  
  PathMigrationScript(this._db);
  
  /// 执行路径迁移
  Future<void> migrate() async {
    AppLogger.info('开始路径隐私迁移', tag: 'PathMigration');
    
    try {
      // 迁移作品图片路径
      await _migrateWorkImagePaths();
      
      // 迁移集字图片路径（如果有的话）
      await _migrateCharacterPaths();
      
      // 迁移图库路径（如果有的话）
      await _migrateLibraryPaths();
      
      AppLogger.info('路径隐私迁移完成', tag: 'PathMigration');
      
    } catch (e, stack) {
      AppLogger.error(
        '路径隐私迁移失败',
        error: e,
        stackTrace: stack,
        tag: 'PathMigration',
      );
      rethrow;
    }
  }
  
  /// 迁移作品图片路径
  Future<void> _migrateWorkImagePaths() async {
    AppLogger.info('开始迁移作品图片路径', tag: 'PathMigration');
    
    // 获取所有作品图片记录
    final workImages = await _db.query('work_images', {});
    
    int migratedCount = 0;
    int skippedCount = 0;
    
    for (final record in workImages) {
      try {
        final id = record['id'] as String;
        bool needsUpdate = false;
        final updatedRecord = Map<String, dynamic>.from(record);
        
        // 检查并转换路径字段
        final pathFields = ['path', 'original_path', 'thumbnail_path'];
        
        for (final field in pathFields) {
          if (record.containsKey(field)) {
            final currentPath = record[field] as String;
            
            // 检查是否包含隐私信息
            if (PathPrivacyHelper.containsPrivacyInfo(currentPath)) {
              final relativePath = PathPrivacyHelper.toRelativePath(currentPath);
              updatedRecord[field] = relativePath;
              needsUpdate = true;
              
              AppLogger.debug(
                '转换路径',
                data: {
                  'imageId': id,
                  'field': field,
                  'original': currentPath.sanitizedForLogging,
                  'converted': relativePath,
                },
                tag: 'PathMigration',
              );
            }
          }
        }
        
        // 如果需要更新，保存记录
        if (needsUpdate) {
          await _db.set('work_images', id, updatedRecord);
          migratedCount++;
        } else {
          skippedCount++;
        }
        
      } catch (e) {
        AppLogger.warning(
          '迁移单个作品图片失败',
          data: {
            'recordId': record['id'],
            'error': e.toString(),
          },
          tag: 'PathMigration',
        );
        skippedCount++;
      }
    }
    
    AppLogger.info(
      '作品图片路径迁移完成',
      data: {
        'totalRecords': workImages.length,
        'migratedCount': migratedCount,
        'skippedCount': skippedCount,
      },
      tag: 'PathMigration',
    );
  }
  
  /// 迁移集字路径
  Future<void> _migrateCharacterPaths() async {
    AppLogger.info('开始迁移集字路径', tag: 'PathMigration');
    
    try {
      // 获取所有集字记录
      final characters = await _db.query('characters', {});
      
      int migratedCount = 0;
      int skippedCount = 0;
      
      for (final record in characters) {
        try {
          final id = record['id'] as String;
          bool needsUpdate = false;
          final updatedRecord = Map<String, dynamic>.from(record);
          
          // 检查可能包含路径的字段
          final pathFields = ['imagePath', 'thumbnailPath', 'originalPath'];
          
          for (final field in pathFields) {
            if (record.containsKey(field) && record[field] != null) {
              final currentPath = record[field] as String;
              
              // 检查是否包含隐私信息
              if (PathPrivacyHelper.containsPrivacyInfo(currentPath)) {
                final relativePath = PathPrivacyHelper.toRelativePath(currentPath);
                updatedRecord[field] = relativePath;
                needsUpdate = true;
                
                AppLogger.debug(
                  '转换集字路径',
                  data: {
                    'characterId': id,
                    'field': field,
                    'original': currentPath.sanitizedForLogging,
                    'converted': relativePath,
                  },
                  tag: 'PathMigration',
                );
              }
            }
          }
          
          // 如果需要更新，保存记录
          if (needsUpdate) {
            await _db.set('characters', id, updatedRecord);
            migratedCount++;
          } else {
            skippedCount++;
          }
          
        } catch (e) {
          AppLogger.warning(
            '迁移单个集字失败',
            data: {
              'recordId': record['id'],
              'error': e.toString(),
            },
            tag: 'PathMigration',
          );
          skippedCount++;
        }
      }
      
      AppLogger.info(
        '集字路径迁移完成',
        data: {
          'totalRecords': characters.length,
          'migratedCount': migratedCount,
          'skippedCount': skippedCount,
        },
        tag: 'PathMigration',
      );
      
    } catch (e) {
      AppLogger.warning(
        '集字路径迁移跳过（可能表不存在）',
        data: {'error': e.toString()},
        tag: 'PathMigration',
      );
    }
  }
  
  /// 迁移图库路径
  Future<void> _migrateLibraryPaths() async {
    AppLogger.info('开始迁移图库路径', tag: 'PathMigration');
    
    try {
      // 获取所有图库记录
      final libraryItems = await _db.query('library_items', {});
      
      int migratedCount = 0;
      int skippedCount = 0;
      
      for (final record in libraryItems) {
        try {
          final id = record['id'] as String;
          bool needsUpdate = false;
          final updatedRecord = Map<String, dynamic>.from(record);
          
          // 检查可能包含路径的字段
          final pathFields = ['filePath', 'thumbnailPath', 'originalPath'];
          
          for (final field in pathFields) {
            if (record.containsKey(field) && record[field] != null) {
              final currentPath = record[field] as String;
              
              // 检查是否包含隐私信息
              if (PathPrivacyHelper.containsPrivacyInfo(currentPath)) {
                final relativePath = PathPrivacyHelper.toRelativePath(currentPath);
                updatedRecord[field] = relativePath;
                needsUpdate = true;
                
                AppLogger.debug(
                  '转换图库路径',
                  data: {
                    'libraryItemId': id,
                    'field': field,
                    'original': currentPath.sanitizedForLogging,
                    'converted': relativePath,
                  },
                  tag: 'PathMigration',
                );
              }
            }
          }
          
          // 如果需要更新，保存记录
          if (needsUpdate) {
            await _db.set('library_items', id, updatedRecord);
            migratedCount++;
          } else {
            skippedCount++;
          }
          
        } catch (e) {
          AppLogger.warning(
            '迁移单个图库项失败',
            data: {
              'recordId': record['id'],
              'error': e.toString(),
            },
            tag: 'PathMigration',
          );
          skippedCount++;
        }
      }
      
      AppLogger.info(
        '图库路径迁移完成',
        data: {
          'totalRecords': libraryItems.length,
          'migratedCount': migratedCount,
          'skippedCount': skippedCount,
        },
        tag: 'PathMigration',
      );
      
    } catch (e) {
      AppLogger.warning(
        '图库路径迁移跳过（可能表不存在）',
        data: {'error': e.toString()},
        tag: 'PathMigration',
      );
    }
  }
  
  /// 验证迁移结果
  Future<MigrationReport> validateMigration() async {
    AppLogger.info('开始验证迁移结果', tag: 'PathMigration');
    
    int totalRecords = 0;
    int recordsWithPrivacyInfo = 0;
    final problemRecords = <String>[];
    
    // 验证作品图片
    final workImages = await _db.query('work_images', {});
    for (final record in workImages) {
      totalRecords++;
      final pathFields = ['path', 'original_path', 'thumbnail_path'];
      
      for (final field in pathFields) {
        if (record.containsKey(field)) {
          final currentPath = record[field] as String;
          if (PathPrivacyHelper.containsPrivacyInfo(currentPath)) {
            recordsWithPrivacyInfo++;
            problemRecords.add('work_images:${record['id']}:$field');
          }
        }
      }
    }
    
    final report = MigrationReport(
      totalRecords: totalRecords,
      recordsWithPrivacyInfo: recordsWithPrivacyInfo,
      problemRecords: problemRecords,
    );
    
    AppLogger.info(
      '迁移验证完成',
      data: {
        'totalRecords': report.totalRecords,
        'recordsWithPrivacyInfo': report.recordsWithPrivacyInfo,
        'problemRecords': report.problemRecords.length,
      },
      tag: 'PathMigration',
    );
    
    return report;
  }
}

/// 迁移报告
class MigrationReport {
  final int totalRecords;
  final int recordsWithPrivacyInfo;
  final List<String> problemRecords;
  
  MigrationReport({
    required this.totalRecords,
    required this.recordsWithPrivacyInfo,
    required this.problemRecords,
  });
  
  bool get isClean => recordsWithPrivacyInfo == 0;
}

/// 主函数：执行迁移脚本
Future<void> main() async {
  print('开始执行路径隐私迁移...');
  
  try {
    // 这里需要根据实际情况初始化数据库
    // final db = await initializeDatabase();
    // final migrationScript = PathMigrationScript(db);
    
    // await migrationScript.migrate();
    // final report = await migrationScript.validateMigration();
    
    // if (report.isClean) {
    //   print('✅ 迁移成功完成，所有路径已转换为相对路径');
    // } else {
    //   print('⚠️ 迁移完成，但仍有 ${report.recordsWithPrivacyInfo} 条记录包含隐私信息');
    //   print('问题记录: ${report.problemRecords.join(', ')}');
    // }
    
    print('❌ 请在应用中运行此迁移脚本，此处仅为示例代码');
    
  } catch (e, stack) {
    print('❌ 迁移失败: $e');
    print('堆栈跟踪: $stack');
  }
} 