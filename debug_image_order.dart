import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:charasgem/infrastructure/logging/logger.dart';

/// 调试图片顺序保存问题的脚本
void debugImageOrderSave() {
  developer.log('开始调试图片顺序保存问题', name: 'DebugImageOrder');
  
  // 添加调试日志输出
  AppLogger.debug('图片顺序调试开始', tag: 'DebugImageOrder');
  
  // 这里可以添加调试逻辑
  // 1. 检查 Provider 层的状态
  // 2. 检查 Service 层的保存逻辑
  // 3. 检查 Repository 层的数据库操作
  // 4. 检查数据库查询结果
  
  developer.log('图片顺序调试完成', name: 'DebugImageOrder');
}

/// 模拟图片顺序调整的逻辑
void simulateImageReorder() {
  developer.log('模拟图片顺序调整', name: 'ImageReorder');
  
  // 模拟原始图片列表
  final originalImages = [
    {'id': 'img1', 'index': 0, 'path': '/path/to/image1.jpg'},
    {'id': 'img2', 'index': 1, 'path': '/path/to/image2.jpg'},
    {'id': 'img3', 'index': 2, 'path': '/path/to/image3.jpg'},
  ];
  
  developer.log('原始顺序: ${originalImages.map((e) => '${e['id']}(${e['index']})').join(', ')}', name: 'ImageReorder');
  
  // 模拟拖拽调整：将第一张图片移动到第二个位置
  final reorderedImages = [
    {'id': 'img2', 'index': 0, 'path': '/path/to/image2.jpg'},
    {'id': 'img1', 'index': 1, 'path': '/path/to/image1.jpg'},
    {'id': 'img3', 'index': 2, 'path': '/path/to/image3.jpg'},
  ];
  
  developer.log('调整后顺序: ${reorderedImages.map((e) => '${e['id']}(${e['index']})').join(', ')}', name: 'ImageReorder');
  
  // 检查是否正确调整
  final isCorrect = reorderedImages[0]['id'] == 'img2' && 
                    reorderedImages[1]['id'] == 'img1' && 
                    reorderedImages[2]['id'] == 'img3';
                    
  developer.log('顺序调整是否正确: $isCorrect', name: 'ImageReorder');
}

void main() {
  debugImageOrderSave();
  simulateImageReorder();
}
