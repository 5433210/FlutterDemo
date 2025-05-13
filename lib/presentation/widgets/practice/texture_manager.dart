import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/providers/storage_providers.dart';
import 'global_image_cache.dart';

/// 增强版纹理管理器 - 提供更强大的纹理加载和缓存功能
class EnhancedTextureManager {
  // 单例模式
  static final EnhancedTextureManager _instance = EnhancedTextureManager._internal();
  static EnhancedTextureManager get instance => _instance;
  EnhancedTextureManager._internal();

  // 当前正在加载的纹理路径集合
  final Set<String> _loadingTextures = {};

  /// 清除纹理缓存
  void invalidateTextureCache() {
    GlobalImageCache.clear();
  }

  /// 打印缓存统计信息
  void printCacheStats() {
    debugPrint('📊 纹理缓存统计: ${GlobalImageCache.size} 个纹理图像');
  }
  
  /// 从路径中提取文件ID
  String _extractFileId(String path) {
    // 首先尝试提取文件名
    String fileName = path.split('/').last.split('\\').last;
    
    // 然后移除扩展名和参数
    fileName = fileName.split('.').first.split('?').first;
    
    return fileName;
  }

  /// 获取纹理图像 - 同步方法，用于检查缓存
  ui.Image? getTextureSync(String path) {
    final fileId = _extractFileId(path);
    return GlobalImageCache.get(fileId);
  }

  /// 加载纹理图像 - 异步方法，支持文件系统和远程加载
  Future<ui.Image?> loadTexture(String path, WidgetRef? ref, {VoidCallback? onLoaded}) async {
    if (path.isEmpty) {
      debugPrint('❌ 纹理路径为空');
      return null;
    }

    // 提取文件ID
    final fileId = _extractFileId(path);
    
    // 首先检查缓存
    if (GlobalImageCache.contains(fileId)) {
      debugPrint('✅ 从缓存加载纹理: $fileId');
      return GlobalImageCache.get(fileId);
    }

    // 防止重复加载
    if (_loadingTextures.contains(fileId)) {
      debugPrint('⏳ 纹理正在加载中: $fileId');
      return null;
    }

    // 标记为正在加载
    _loadingTextures.add(fileId);

    try {
      // 首先尝试从文件系统加载
      if (path.startsWith('/') || path.contains(':\\')) {
        try {
          final file = File(path);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final completer = Completer<ui.Image>();
            ui.decodeImageFromList(bytes, (image) {
              completer.complete(image);
            });
            final image = await completer.future;
            
            // 缓存图像
            GlobalImageCache.put(fileId, image);
            
            // 触发加载完成回调
            if (onLoaded != null) {
              onLoaded();
            }
            
            debugPrint('✅ 从文件系统加载纹理成功: $fileId (${image.width}x${image.height})');
            return image;
          }
        } catch (e) {
          debugPrint('❌ 从文件系统加载纹理失败: $e');
        }
      }

      // 然后尝试使用存储服务加载
      if (ref != null) {
        try {
          final storage = ref.read(initializedStorageProvider);
          final appDataPath = storage.getAppDataPath();
          
          // 构建完整路径
          String fullPath;
          if (path.startsWith('assets/')) {
            fullPath = '$appDataPath/${path.substring(7)}';
          } else {
            fullPath = '$appDataPath/$path';
          }
          
          final file = File(fullPath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final completer = Completer<ui.Image>();
            ui.decodeImageFromList(bytes, (image) {
              completer.complete(image);
            });
            final image = await completer.future;
            
            // 缓存图像
            GlobalImageCache.put(fileId, image);
            
            // 触发加载完成回调
            if (onLoaded != null) {
              onLoaded();
            }
            
            debugPrint('✅ 从存储服务加载纹理成功: $fileId (${image.width}x${image.height})');
            return image;
          }
          
          // 下面代码保留作为将来扩展接口支持使用
          // 当前默认不执行任何特定的纹理加载逻辑，因为这取决于具体的API支持
          
        } catch (e) {
          debugPrint('❌ 使用服务加载纹理失败: $e');
        }
      }
      
      debugPrint('❌ 无法加载纹理: $path');
      return null;
    } finally {
      // 无论成功与否，都移除加载标记
      _loadingTextures.remove(fileId);
    }
  }
}
