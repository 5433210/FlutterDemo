import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'texture_fix.dart';

/// 改进的纹理绘制器
class ImprovedTexturePainter extends CustomPainter {
  final Map<String, dynamic>? textureData;
  final String fillMode;
  final double opacity;
  final WidgetRef? ref;
  // 纹理加载完成回调
  final VoidCallback? onTextureLoaded;
  
  // 记录是否已经触发过回调
  bool _hasCalledTextureLoadedCallback = false;
  
  ui.Image? _textureImage;
  bool _isLoading = false;
  
  ImprovedTexturePainter({
    required this.textureData,
    required this.fillMode,
    required this.opacity,
    this.ref,
    this.onTextureLoaded,
  }) {
    // 立即尝试从缓存加载纹理
    _loadTextureFromCacheSync();
    
    // 如果缓存中没有，则异步加载
    if (_textureImage == null) {
      _loadTextureIfNeeded();
    }
  }
  
  /// 同步从缓存加载纹理，避免闪烁
  void _loadTextureFromCacheSync() {
    if (textureData == null || textureData!['path'] == null) return;
    
    // 如果已经有纹理图像，直接返回
    if (_textureImage != null) return;
    
    final texturePath = textureData!['path'] as String;
    // 提取文件ID - 自定义实现而非调用私有方法
    String fileId = _extractFileId(texturePath);
    
    // 直接检查缓存
    if (TextureCache.instance.hasTexture(fileId)) {
      _textureImage = TextureCache.instance.getTexture(fileId);
      debugPrint('⚡ ImprovedTexturePainter: 同步从缓存加载纹理成功 ${_textureImage?.width}x${_textureImage?.height}');
    }
  }
  
  /// 加载纹理（如果需要）
  void _loadTextureIfNeeded() {
    if (textureData == null || textureData!['path'] == null) return;
    if (_textureImage != null) return;
    if (_isLoading) return;
    
    _isLoading = true;
    final texturePath = textureData!['path'] as String;
    
    debugPrint('🔄 ImprovedTexturePainter: 开始加载纹理 $texturePath');
    
    TextureFix.loadTexture(texturePath, ref).then((image) {
      _textureImage = image;
      _isLoading = false;
      
      if (image != null) {
        debugPrint('✅ ImprovedTexturePainter: 纹理加载成功 ${image.width}x${image.height}');
        if (onTextureLoaded != null) {
          // 使用 SchedulerBinding 确保回调在正确的时机执行
          SchedulerBinding.instance.addPostFrameCallback((_) {
            onTextureLoaded!();
          });
        }
      } else {
        debugPrint('❌ ImprovedTexturePainter: 纹理加载失败');
      }
    });
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    if (textureData == null) {
      debugPrint('⚠️ ImprovedTexturePainter: 无纹理数据');
      return;
    }
    
    final rect = Offset.zero & size;
    
    // 再次尝试从缓存加载，确保最新状态
    if (_textureImage == null) {
      _loadTextureFromCacheSync();
    }
    
    if (_textureImage == null) {
      // 绘制占位符
      TextureFix.drawPlaceholder(canvas, size);
      
      // 尝试加载纹理
      _loadTextureIfNeeded();
      return;
    }
    
    // 绘制纹理
    debugPrint('🎨 ImprovedTexturePainter: 绘制纹理 (${_textureImage!.width}x${_textureImage!.height})');
    TextureFix.drawTexture(canvas, rect, _textureImage!, fillMode, opacity);
    
    // 如果这是第一次成功绘制纹理，通知回调
    if (onTextureLoaded != null && !_hasCalledTextureLoadedCallback) {
      _hasCalledTextureLoadedCallback = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        onTextureLoaded!();
      });
    }
  }
  
  // 提取文件ID
  String _extractFileId(String path) {
    String fileName;
    
    if (path.contains('\\')) {
      final parts = path.split('\\');
      fileName = parts.last;
    } else {
      final parts = path.split('/');
      fileName = parts.last;
    }
    
    return fileName.split('.').first;
  }
  
  @override
  bool shouldRepaint(ImprovedTexturePainter oldDelegate) {
    return oldDelegate.textureData != textureData ||
           oldDelegate.fillMode != fillMode ||
           oldDelegate.opacity != opacity ||
           oldDelegate._textureImage != _textureImage;
  }
}
