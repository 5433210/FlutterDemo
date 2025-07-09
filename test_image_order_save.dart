#!/usr/bin/env dart
// 图片顺序调整保存测试脚本

import 'dart:io';

void main() async {
  print('=== 图片顺序调整保存测试 ===');
  
  // 模拟路径标准化测试
  testPathNormalization();
  
  // 模拟文件清理逻辑测试
  testFileCleaning();
  
  // 模拟封面文件保护测试
  testCoverFileProtection();
}

void testPathNormalization() {
  print('\n--- 路径标准化测试 ---');
  
  final testPaths = [
    r'C:\Users\wailik\Documents\Code\Flutter\demo\demo\work\123\images\img1_imported.png',
    r'c:\users\wailik\documents\code\flutter\demo\demo\work\123\images\img1_imported.png',
    r'C:/Users/wailik/Documents/Code/Flutter/demo/demo/work/123/images/img1_imported.png',
    r'C:\Users\wailik\Documents\Code\Flutter\demo\demo\work\123\images\.\img1_imported.png',
  ];
  
  final normalizedPaths = testPaths.map((path) => File(path).absolute.path).toSet();
  
  print('原始路径数量: ${testPaths.length}');
  print('标准化后路径数量: ${normalizedPaths.length}');
  print('标准化是否成功: ${normalizedPaths.length == 1}');
  
  for (final path in normalizedPaths) {
    print('标准化路径: $path');
  }
}

void testFileCleaning() {
  print('\n--- 文件清理逻辑测试 ---');
  
  final allFiles = [
    r'C:\work\123\images\img1_imported.png',
    r'C:\work\123\images\img1_original.jpg',
    r'C:\work\123\images\img1_thumbnail.jpg',
    r'C:\work\123\images\img2_imported.png',
    r'C:\work\123\images\img2_original.jpg',
    r'C:\work\123\images\img2_thumbnail.jpg',
    r'C:\work\123\images\old_img_imported.png',
    r'C:\work\123\cover\imported.png',
    r'C:\work\123\cover\thumbnail.jpg',
  ];
  
  final usedPaths = [
    r'C:\work\123\images\img1_imported.png',
    r'C:\work\123\images\img1_original.jpg',
    r'C:\work\123\images\img1_thumbnail.jpg',
    r'C:\work\123\images\img2_imported.png',
    r'C:\work\123\images\img2_original.jpg',
    r'C:\work\123\images\img2_thumbnail.jpg',
    r'C:\work\123\cover\imported.png',
    r'C:\work\123\cover\thumbnail.jpg',
  ];
  
  final normalizedAllFiles = allFiles.map((path) => File(path).absolute.path).toList();
  final normalizedUsedPaths = usedPaths.map((path) => File(path).absolute.path).toSet();
  
  final unusedFiles = normalizedAllFiles.where((f) => !normalizedUsedPaths.contains(f)).toList();
  
  print('所有文件数量: ${allFiles.length}');
  print('使用的文件数量: ${usedPaths.length}');
  print('未使用的文件数量: ${unusedFiles.length}');
  
  for (final file in unusedFiles) {
    print('将被删除的文件: $file');
  }
}

void testCoverFileProtection() {
  print('\n--- 封面文件保护测试 ---');
  
  final imageFiles = [
    r'C:\work\123\images\img1_imported.png',
    r'C:\work\123\images\img1_original.jpg',
    r'C:\work\123\images\img1_thumbnail.jpg',
  ];
  
  final coverFiles = [
    r'C:\work\123\cover\imported.png',
    r'C:\work\123\cover\thumbnail.jpg',
  ];
  
  final allProtectedFiles = [...imageFiles, ...coverFiles];
  
  print('图片文件数量: ${imageFiles.length}');
  print('封面文件数量: ${coverFiles.length}');
  print('总保护文件数量: ${allProtectedFiles.length}');
  
  for (final file in allProtectedFiles) {
    print('保护的文件: $file');
  }
}
