#!/usr/bin/env dart
// 验证图片顺序调整文件保护脚本

import 'dart:io';

void main() async {
  print('=== 图片顺序调整文件保护验证 ===');
  await testImageOrderSaveProtection();
}

Future<void> testImageOrderSaveProtection() async {
  print('\n--- 模拟图片顺序调整保存流程 ---');
  
  // 模拟作品ID
  final workId = 'test_work_123';
  
  // 模拟调整前的图片顺序
  final beforeOrder = [
    {'id': 'img1', 'index': 0, 'path': 'C:\\work\\$workId\\images\\img1_imported.png'},
    {'id': 'img2', 'index': 1, 'path': 'C:\\work\\$workId\\images\\img2_imported.png'},
    {'id': 'img3', 'index': 2, 'path': 'C:\\work\\$workId\\images\\img3_imported.png'},
  ];
  
  // 模拟调整后的图片顺序（img3 移到第一位）
  final afterOrder = [
    {'id': 'img3', 'index': 0, 'path': 'C:\\work\\$workId\\images\\img3_imported.png'},
    {'id': 'img1', 'index': 1, 'path': 'C:\\work\\$workId\\images\\img1_imported.png'},
    {'id': 'img2', 'index': 2, 'path': 'C:\\work\\$workId\\images\\img2_imported.png'},
  ];
  
  print('调整前顺序:');
  for (final img in beforeOrder) {
    print('  ${img['id']} (index: ${img['index']}) -> ${img['path']}');
  }
  
  print('\n调整后顺序:');
  for (final img in afterOrder) {
    print('  ${img['id']} (index: ${img['index']}) -> ${img['path']}');
  }
  
  // 模拟收集所有应该保留的文件路径
  final usedPaths = <String>[];
  
  // 添加所有图片相关文件
  for (final img in afterOrder) {
    final imageId = img['id'] as String;
    final basePath = 'C:\\work\\$workId\\images\\';
    
    usedPaths.addAll([
      '${basePath}${imageId}_imported.png',
      '${basePath}${imageId}_original.jpg',
      '${basePath}${imageId}_thumbnail.jpg',
    ]);
  }
  
  // 添加封面文件
  usedPaths.addAll([
    'C:\\work\\$workId\\cover\\imported.png',
    'C:\\work\\$workId\\cover\\thumbnail.jpg',
  ]);
  
  print('\n应该保留的文件路径:');
  for (final path in usedPaths) {
    print('  $path');
  }
  
  // 模拟文件系统中的所有文件
  final allFiles = [
    'C:\\work\\$workId\\images\\img1_imported.png',
    'C:\\work\\$workId\\images\\img1_original.jpg',
    'C:\\work\\$workId\\images\\img1_thumbnail.jpg',
    'C:\\work\\$workId\\images\\img2_imported.png',
    'C:\\work\\$workId\\images\\img2_original.jpg',
    'C:\\work\\$workId\\images\\img2_thumbnail.jpg',
    'C:\\work\\$workId\\images\\img3_imported.png',
    'C:\\work\\$workId\\images\\img3_original.jpg',
    'C:\\work\\$workId\\images\\img3_thumbnail.jpg',
    'C:\\work\\$workId\\cover\\imported.png',
    'C:\\work\\$workId\\cover\\thumbnail.jpg',
    'C:\\work\\$workId\\images\\old_deleted_image.png', // 这个应该被删除
  ];
  
  print('\n文件系统中的所有文件:');
  for (final file in allFiles) {
    print('  $file');
  }
  
  // 路径标准化
  final normalizedUsedPaths = usedPaths.map((path) => File(path).absolute.path).toSet();
  final normalizedAllFiles = allFiles.map((path) => File(path).absolute.path).toList();
  
  // 找出未使用的文件
  final unusedFiles = normalizedAllFiles.where((f) => !normalizedUsedPaths.contains(f)).toList();
  
  print('\n路径标准化结果:');
  print('  标准化后的保留文件数: ${normalizedUsedPaths.length}');
  print('  标准化后的所有文件数: ${normalizedAllFiles.length}');
  print('  未使用文件数: ${unusedFiles.length}');
  
  if (unusedFiles.isNotEmpty) {
    print('\n将被删除的文件:');
    for (final file in unusedFiles) {
      print('  $file');
    }
  } else {
    print('\n✅ 没有文件将被删除 - 所有文件都被正确保护');
  }
  
  // 验证重要文件是否被保护
  final importantFiles = [
    'img1_imported.png',
    'img2_imported.png', 
    'img3_imported.png',
    'cover/imported.png',
    'cover/thumbnail.jpg',
  ];
  
  print('\n重要文件保护检查:');
  for (final importantFile in importantFiles) {
    final isProtected = normalizedUsedPaths.any((path) => path.contains(importantFile));
    print('  $importantFile: ${isProtected ? '✅ 已保护' : '❌ 未保护'}');
  }
  
  // 检查是否有不应该被删除的文件
  bool hasProblematicDeletion = false;
  for (final file in unusedFiles) {
    if (file.contains('imported.png') || file.contains('original.jpg') || file.contains('thumbnail.jpg')) {
      if (!file.contains('old_deleted_image')) {
        hasProblematicDeletion = true;
        print('  ❌ 发现问题: $file 不应该被删除');
      }
    }
  }
  
  if (!hasProblematicDeletion) {
    print('\n✅ 文件保护验证通过 - 没有重要文件被误删');
  } else {
    print('\n❌ 文件保护验证失败 - 有重要文件可能被误删');
  }
}
