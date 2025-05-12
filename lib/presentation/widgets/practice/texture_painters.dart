import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/providers/storage_providers.dart';

/// A custom painter that paints a background texture
class BackgroundTexturePainter extends CustomPainter {
  final Map<String, dynamic>? textureData;
  final String fillMode;
  final double opacity;
  final WidgetRef? ref;
  ui.Image? _textureImage;
  bool _isLoading = false;
  // 添加一个重绘回调函数
  VoidCallback? _repaintCallback;

  BackgroundTexturePainter({
    required this.textureData,
    required this.fillMode,
    required this.opacity,
    this.ref,
    VoidCallback? repaintCallback,
  })  : _repaintCallback = repaintCallback,
        super(repaint: _TextureRepaintNotifier.instance) {
    // 立即尝试加载纹理图片
    if (textureData != null && textureData!['path'] != null) {
      final texturePath = textureData!['path'] as String;
      debugPrint('构造器中立即开始加载纹理: $texturePath');
      loadTextureImage(texturePath);
    }
  }

  // 设置重绘回调
  set repaintCallback(VoidCallback callback) {
    _repaintCallback = callback;
  }

  Future<void> loadTextureImage(String path) async {
    // First check if texture is already in cache
    if (_TextureCache.instance.hasTexture(path)) {
      debugPrint('⭐ 从缓存中获取纹理: $path');
      _textureImage = _TextureCache.instance.getTexture(path);

      // Trigger repaint if texture was loaded from cache
      print('🔄 从缓存加载纹理成功，准备触发重绘');
      _TextureRepaintNotifier.instance.notifyRepaint();

      // Don't directly call the callback from here as it can cause
      // "Build scheduled during frame" errors. The notifyRepaint() above
      // will trigger the CustomPainter to repaint properly
      return;
    }

    if (_isLoading) {
      debugPrint('纹理图片正在加载中，跳过重复加载');
      return;
    }

    // Enhanced texture logging
    print('🔍 TEXTURE: 开始加载纹理图片: $path');
    print('🔍 TEXTURE: 纹理数据: $textureData');
    print('🔍 TEXTURE: 填充模式: $fillMode, 不透明度: $opacity');

    // Check if the path is absolute or relative
    File textureFile = File(path);
    print('🔍 TEXTURE: 尝试作为绝对路径: ${textureFile.absolute.path}');
    print('🔍 TEXTURE: 文件是否存在: ${await textureFile.exists()}');

    _isLoading = true;

    try {
      if (ref != null) {
        final storageService = ref!.read(initializedStorageProvider);
        print('🔍 TEXTURE: 存储服务就绪');

        // 检查路径是否存在
        final fileExists = await storageService.fileExists(path);
        print('🔍 TEXTURE: 存储服务文件检查结果: $fileExists');

        if (!fileExists) {
          // 尝试不同的路径格式
          final List<String> alternativePaths = [];

          // Add slash if doesn't start with it
          if (!path.startsWith('/')) {
            alternativePaths.add('/$path');
          } else if (path.startsWith('/')) {
            // Try without slash
            alternativePaths.add(path.substring(1));
          }

          // Try with app path
          try {
            final appDataPath = storageService.getAppDataPath();
            alternativePaths.add('$appDataPath/$path');
            alternativePaths.add('$appDataPath$path');
          } catch (e) {
            print('❌ TEXTURE: 获取应用数据路径失败: $e');
          }

          print('🔍 TEXTURE: 尝试备选路径: $alternativePaths');

          String? workingPath;
          for (final altPath in alternativePaths) {
            final exists = await storageService.fileExists(altPath);
            print('🔍 TEXTURE: 检查路径 $altPath: $exists');
            if (exists) {
              workingPath = altPath;
              break;
            }
          }

          if (workingPath != null) {
            path = workingPath;
            print('✅ TEXTURE: 使用可用路径: $path');
          } else {
            print('⚠️ TEXTURE: 警告: 所有尝试的路径都不存在!');
          }
        }

        try {
          print('🔍 TEXTURE: 尝试读取文件: $path');
          final imageBytes = await storageService.readFile(path);
          print('📊 TEXTURE: 读取的图片数据大小: ${imageBytes.length} 字节');

          if (imageBytes.isNotEmpty) {
            print('🔍 TEXTURE: 解码图像数据');
            final codec =
                await ui.instantiateImageCodec(Uint8List.fromList(imageBytes));
            final frame = await codec.getNextFrame();
            _textureImage = frame.image;
            print(
                '✅ TEXTURE: 纹理图片加载成功: ${_textureImage?.width}x${_textureImage?.height}');

            // 将加载的纹理存入全局缓存
            _TextureCache.instance.putTexture(path, _textureImage!);

            // 打印缓存统计
            _TextureCache.instance.printStats();

            // 图像加载成功后触发重绘
            print('🔄 TEXTURE: 图像加载成功，准备触发重绘');

            // 通过重绘通知器强制重绘
            print('🔄 TEXTURE: 通过通知器触发重绘');
            _TextureRepaintNotifier.instance.notifyRepaint();

            // 调用重绘回调或使用markNeedsPaint如果在CustomPainter的父Widget中
            if (_repaintCallback != null) {
              print('🔄 TEXTURE: 执行重绘回调');
              _repaintCallback!();
            }
          } else {
            print('⚠️ TEXTURE: 读取的图片数据为空');
          }
        } catch (e) {
          print('❌ TEXTURE: 读取图片文件失败: $e');
          print('❌ TEXTURE: 错误堆栈: ${StackTrace.current}');
        }
      } else {
        print('⚠️ TEXTURE: 引用为空，无法获取存储服务');
      }
    } catch (e) {
      print('❌ TEXTURE: 加载纹理图片失败: $e');
      print('❌ TEXTURE: 错误堆栈: ${StackTrace.current}');
    } finally {
      _isLoading = false;
      print('📝 TEXTURE: 纹理图片加载状态重置');
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint('🎨 TEXTURE: BackgroundTexturePainter.paint:');
    debugPrint('  🔍 Canvas HashCode: ${canvas.hashCode}');
    debugPrint('  📏 Size: $size');

    if (textureData == null) {
      debugPrint('⚠️ TEXTURE: 纹理数据为空，取消绘制');
      return;
    }

    if (_textureImage == null && textureData!['path'] != null) {
      final texturePath = textureData!['path'] as String;
      debugPrint('🔍 TEXTURE: 纹理图片未加载，检查缓存: $texturePath');

      // Check cache first
      if (_TextureCache.instance.hasTexture(texturePath)) {
        debugPrint('⭐ TEXTURE: 从缓存加载纹理图片: $texturePath');
        _textureImage = _TextureCache.instance.getTexture(texturePath);
      } else {
        debugPrint('⏳ TEXTURE: 纹理不在缓存中，开始加载: $texturePath');
        loadTextureImage(texturePath);
        // Draw placeholder while loading
        _drawPlaceholderTexture(canvas, size);
        return;
      }
    }

    if (_textureImage == null) {
      debugPrint('⚠️ TEXTURE: 纹理图片未就绪，取消绘制');
      _drawPlaceholderTexture(canvas, size);
      return;
    }

    final rect = Offset.zero & size;
    debugPrint('📐 TEXTURE: 绘制区域: $rect');

    // 保存画布状态，但不使用图层混合，以避免混合模式嵌套问题
    debugPrint('🔧 TEXTURE: 保存画布状态');
    canvas.save();

    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..filterQuality = FilterQuality.high;
    // 不在这里设置混合模式，而是由调用者控制

    debugPrint('🔧 TEXTURE: 配置绘制画笔: 不透明度=$opacity');

    // 确定重复模式，根据填充模式选择
    if (fillMode == 'repeat') {
      debugPrint('🔄 TEXTURE: 使用repeat填充模式');
      _drawRepeatedTexture(canvas, rect, paint, ImageRepeat.repeat);
    } else if (fillMode == 'repeatX') {
      debugPrint('↔️ TEXTURE: 使用repeatX填充模式');
      _drawRepeatedTexture(canvas, rect, paint, ImageRepeat.repeatX);
    } else if (fillMode == 'repeatY') {
      debugPrint('↕️ TEXTURE: 使用repeatY填充模式');
      _drawRepeatedTexture(canvas, rect, paint, ImageRepeat.repeatY);
    } else if (fillMode == 'noRepeat') {
      debugPrint('1️⃣ TEXTURE: 使用noRepeat填充模式');
      _drawSingleTexture(canvas, rect, paint, BoxFit.none);
    } else if (fillMode == 'cover') {
      debugPrint('🔳 TEXTURE: 使用cover填充模式');
      _drawSingleTexture(canvas, rect, paint, BoxFit.cover);
    } else if (fillMode == 'contain') {
      debugPrint('📦 TEXTURE: 使用contain填充模式');
      _drawSingleTexture(canvas, rect, paint, BoxFit.contain);
    } else {
      // Default: repeat
      debugPrint('🔄 TEXTURE: 使用默认repeat填充模式');
      _drawRepeatedTexture(canvas, rect, paint, ImageRepeat.repeat);
    }

    // 恢复画布状态
    debugPrint('🔧 TEXTURE: 恢复画布状态');
    canvas.restore();
    debugPrint('✅ TEXTURE: 纹理绘制完成');
  }

  @override
  bool shouldRepaint(covariant BackgroundTexturePainter oldDelegate) {
    return !_areTextureDataEqual(oldDelegate.textureData, textureData) ||
        oldDelegate.fillMode != fillMode ||
        oldDelegate.opacity != opacity ||
        oldDelegate._textureImage != _textureImage;
  }

  bool _areTextureDataEqual(
      Map<String, dynamic>? map1, Map<String, dynamic>? map2) {
    if (map1 == null && map2 == null) return true;
    if (map1 == null || map2 == null) return false;
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }

  // 绘制占位纹理，确保用户能够看到有纹理存在
  void _drawPlaceholderTexture(Canvas canvas, Size size) {
    debugPrint('绘制占位纹理，尺寸: $size');
    final rect = Offset.zero & size;

    // 创建基础渐变颜色
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.grey.withOpacity(0.2),
        Colors.grey.withOpacity(0.1),
      ],
    );

    // 绘制渐变背景
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, gradientPaint);

    // 添加点阵图案
    final patternPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    const spacing = 10.0;
    const dotRadius = 1.5;

    // 计算点的数量
    final horizontalDots = (size.width / spacing).ceil();
    final verticalDots = (size.height / spacing).ceil();

    // 绘制点阵
    for (var i = 0; i < horizontalDots; i++) {
      for (var j = 0; j < verticalDots; j++) {
        final x = i * spacing;
        final y = j * spacing;
        canvas.drawCircle(
          Offset(x, y),
          dotRadius,
          patternPaint,
        );
      }
    }

    // 添加"加载中"文本提示
    final textPainter = TextPainter(
      text: TextSpan(
        text: '纹理加载中...',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.withOpacity(0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  void _drawRepeatedTexture(
      Canvas canvas, Rect rect, Paint paint, ImageRepeat repeat) {
    if (_textureImage == null) return;

    canvas.save();
    canvas.clipRect(rect);

    final imageWidth = _textureImage!.width.toDouble();
    final imageHeight = _textureImage!.height.toDouble();

    int horizontalCount = 1;
    int verticalCount = 1;

    if (repeat == ImageRepeat.repeat || repeat == ImageRepeat.repeatX) {
      horizontalCount = (rect.width / imageWidth).ceil() + 1;
    }
    if (repeat == ImageRepeat.repeat || repeat == ImageRepeat.repeatY) {
      verticalCount = (rect.height / imageHeight).ceil() + 1;
    }

    final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);

    for (int y = 0; y < verticalCount; y++) {
      for (int x = 0; x < horizontalCount; x++) {
        final destRect = Rect.fromLTWH(
          rect.left + x * imageWidth,
          rect.top + y * imageHeight,
          imageWidth,
          imageHeight,
        );

        canvas.drawImageRect(
          _textureImage!,
          srcRect,
          destRect,
          paint,
        );
      }
    }

    canvas.restore();
  }

  void _drawSingleTexture(Canvas canvas, Rect rect, Paint paint, BoxFit fit) {
    if (_textureImage == null) return;

    canvas.save();
    canvas.clipRect(rect);

    final imageWidth = _textureImage!.width.toDouble();
    final imageHeight = _textureImage!.height.toDouble();
    final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);

    final double scale;
    final double dx;
    final double dy;

    switch (fit) {
      case BoxFit.cover:
        scale = max(rect.width / imageWidth, rect.height / imageHeight);
        dx = (rect.width - imageWidth * scale) / 2;
        dy = (rect.height - imageHeight * scale) / 2;
        break;
      case BoxFit.contain:
        scale = min(rect.width / imageWidth, rect.height / imageHeight);
        dx = (rect.width - imageWidth * scale) / 2;
        dy = (rect.height - imageHeight * scale) / 2;
        break;
      default: // none
        scale = 1.0;
        dx = (rect.width - imageWidth) / 2;
        dy = (rect.height - imageHeight) / 2;
    }

    final destRect = Rect.fromLTWH(
      rect.left + dx,
      rect.top + dy,
      imageWidth * scale,
      imageHeight * scale,
    );

    canvas.drawImageRect(_textureImage!, srcRect, destRect, paint);
    canvas.restore();
  }
}

/// A custom painter for handling character textures
class CharacterTexturePainter extends CustomPainter {
  final Map<String, dynamic>? textureData;
  final String fillMode;
  final double opacity;
  final WidgetRef? ref;

  ui.Image? _textureImage;
  bool _isLoading = false;
  // 添加重绘回调函数
  VoidCallback? _repaintCallback;

  CharacterTexturePainter({
    required this.textureData,
    required this.fillMode,
    required this.opacity,
    this.ref,
    VoidCallback? repaintCallback,
  })  : _repaintCallback = repaintCallback,
        super(repaint: _TextureRepaintNotifier.instance) {
    // 立即尝试加载纹理图片
    if (textureData != null && textureData!['path'] != null) {
      final texturePath = textureData!['path'] as String;
      debugPrint('字符纹理构造器中立即开始加载纹理: $texturePath');
      loadTextureImage(texturePath);
    }
  }

  // 设置重绘回调
  set repaintCallback(VoidCallback callback) {
    _repaintCallback = callback;
  }

  Future<void> loadTextureImage(String path) async {
    // First check if texture is already in cache
    if (_TextureCache.instance.hasTexture(path)) {
      debugPrint('⭐ 从缓存中获取字符纹理: $path');
      _textureImage = _TextureCache.instance.getTexture(path);

      // Trigger repaint if texture was loaded from cache
      debugPrint('🔄 从缓存加载字符纹理成功，准备触发重绘');
      _TextureRepaintNotifier.instance.notifyRepaint();

      // Do not call the callback directly when loaded from cache
      // This prevents the "Build scheduled during frame" error
      // The notifyRepaint above will properly mark for repaint without causing build errors
      return;
    }

    if (_isLoading) {
      debugPrint('字符纹理正在加载中，跳过重复加载');
      return;
    }
    debugPrint('开始加载字符纹理: $path');
    _isLoading = true;

    try {
      if (ref != null) {
        final storageService = ref!.read(initializedStorageProvider);

        // 检查路径是否存在
        final fileExists = await storageService.fileExists(path);
        if (!fileExists) {
          // 尝试不同的路径格式
          String alternativePath = path;
          if (!path.startsWith('/')) {
            alternativePath = '/$path';
          }

          final alternativeExists =
              await storageService.fileExists(alternativePath);
          if (alternativeExists) {
            path = alternativePath;
            debugPrint('使用替代路径: $path');
          } else {
            debugPrint('警告: 原始路径和替代路径都不存在');
          }
        }

        try {
          final imageBytes = await storageService.readFile(path);
          if (imageBytes.isNotEmpty) {
            final codec =
                await ui.instantiateImageCodec(Uint8List.fromList(imageBytes));
            final frame = await codec.getNextFrame();
            _textureImage = frame.image;
            debugPrint(
                '字符纹理加载成功: ${_textureImage?.width}x${_textureImage?.height}');

            // 将加载的纹理存入全局缓存
            _TextureCache.instance.putTexture(path, _textureImage!);

            // 图像加载成功后触发重绘
            debugPrint('字符纹理加载成功，准备触发重绘');

            // 通过通知器强制重绘
            debugPrint('通过通知器触发字符纹理重绘');
            _TextureRepaintNotifier.instance.notifyRepaint();

            // 调用重绘回调
            if (_repaintCallback != null) {
              debugPrint('执行字符纹理重绘回调');
              _repaintCallback!();
            }
          } else {
            debugPrint('读取的图片数据为空');
          }
        } catch (e) {
          debugPrint('读取图片文件失败: $e');
        }
      }
    } catch (e) {
      debugPrint('加载字符纹理失败: $e');
    } finally {
      _isLoading = false;
      debugPrint('字符纹理加载状态重置');
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint('🎨 开始绘制字符纹理:');
    debugPrint('  🔍 Canvas HashCode: ${canvas.hashCode}');
    debugPrint('  📏 Size: $size');

    if (textureData == null) {
      debugPrint('⚠️ 字符纹理数据为空，取消绘制');
      return;
    }

    if (_textureImage == null && textureData!['path'] != null) {
      final texturePath = textureData!['path'] as String;
      debugPrint('🔍 字符纹理未加载，检查缓存: $texturePath');

      // Check cache first
      if (_TextureCache.instance.hasTexture(texturePath)) {
        debugPrint('⭐ 从缓存加载字符纹理图片: $texturePath');
        _textureImage = _TextureCache.instance.getTexture(texturePath);
      } else {
        debugPrint('⏳ 字符纹理不在缓存中，开始加载: $texturePath');
        loadTextureImage(texturePath);
        // Draw placeholder while loading
        _drawPlaceholderTexture(canvas, size);
        return;
      }
    }

    if (_textureImage == null) {
      debugPrint('⚠️ 字符纹理未就绪，取消绘制');
      _drawPlaceholderTexture(canvas, size);
      return;
    }

    final rect = Offset.zero & size;

    // 保存画布状态但不创建图层，避免混合模式嵌套
    canvas.save();

    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..filterQuality = FilterQuality.high;
    // 不在这里设置混合模式，而是由调用者控制

    if (fillMode == 'repeat') {
      _drawRepeatedTexture(canvas, rect, paint, ImageRepeat.repeat);
    } else if (fillMode == 'repeatX') {
      _drawRepeatedTexture(canvas, rect, paint, ImageRepeat.repeatX);
    } else if (fillMode == 'repeatY') {
      _drawRepeatedTexture(canvas, rect, paint, ImageRepeat.repeatY);
    } else if (fillMode == 'noRepeat') {
      _drawSingleTexture(canvas, rect, paint, BoxFit.none);
    } else if (fillMode == 'cover') {
      _drawSingleTexture(canvas, rect, paint, BoxFit.cover);
    } else if (fillMode == 'contain') {
      _drawSingleTexture(canvas, rect, paint, BoxFit.contain);
    } else {
      // Default: repeat
      _drawRepeatedTexture(canvas, rect, paint, ImageRepeat.repeat);
    }

    // Restore canvas state
    canvas.restore();
    debugPrint('✅ 字符纹理绘制完成');
  }

  @override
  bool shouldRepaint(covariant CharacterTexturePainter oldDelegate) {
    return !_areTextureDataEqual(oldDelegate.textureData, textureData) ||
        oldDelegate.fillMode != fillMode ||
        oldDelegate.opacity != opacity ||
        oldDelegate._textureImage != _textureImage;
  }

  bool _areTextureDataEqual(
      Map<String, dynamic>? map1, Map<String, dynamic>? map2) {
    if (map1 == null && map2 == null) return true;
    if (map1 == null || map2 == null) return false;
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }

  // 绘制占位纹理，确保用户能够看到有纹理存在
  void _drawPlaceholderTexture(Canvas canvas, Size size) {
    debugPrint('字符纹理：绘制占位纹理，尺寸: $size');
    final rect = Offset.zero & size;

    // 创建基础渐变颜色
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.grey.withOpacity(0.2),
        Colors.grey.withOpacity(0.1),
      ],
    );

    // 绘制渐变背景
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, gradientPaint);

    // 添加点阵图案
    final patternPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    const spacing = 10.0;
    const dotRadius = 1.5;

    // 计算点的数量
    final horizontalDots = (size.width / spacing).ceil();
    final verticalDots = (size.height / spacing).ceil();

    // 绘制点阵
    for (var i = 0; i < horizontalDots; i++) {
      for (var j = 0; j < verticalDots; j++) {
        final x = i * spacing;
        final y = j * spacing;
        canvas.drawCircle(
          Offset(x, y),
          dotRadius,
          patternPaint,
        );
      }
    }

    // 添加"加载中"文本提示
    final textPainter = TextPainter(
      text: TextSpan(
        text: '字符纹理加载中...',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.withOpacity(0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  void _drawRepeatedTexture(
      Canvas canvas, Rect rect, Paint paint, ImageRepeat repeat) {
    if (_textureImage == null) return;

    canvas.save();
    canvas.clipRect(rect);

    final imageWidth = _textureImage!.width.toDouble();
    final imageHeight = _textureImage!.height.toDouble();

    int horizontalCount = 1;
    int verticalCount = 1;

    if (repeat == ImageRepeat.repeat || repeat == ImageRepeat.repeatX) {
      horizontalCount = (rect.width / imageWidth).ceil() + 1;
    }
    if (repeat == ImageRepeat.repeat || repeat == ImageRepeat.repeatY) {
      verticalCount = (rect.height / imageHeight).ceil() + 1;
    }

    final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);

    for (int y = 0; y < verticalCount; y++) {
      for (int x = 0; x < horizontalCount; x++) {
        final destRect = Rect.fromLTWH(
          rect.left + x * imageWidth,
          rect.top + y * imageHeight,
          imageWidth,
          imageHeight,
        );

        canvas.drawImageRect(
          _textureImage!,
          srcRect,
          destRect,
          paint,
        );
      }
    }

    canvas.restore();
  }

  void _drawSingleTexture(Canvas canvas, Rect rect, Paint paint, BoxFit fit) {
    if (_textureImage == null) return;

    canvas.save();
    canvas.clipRect(rect);

    final imageWidth = _textureImage!.width.toDouble();
    final imageHeight = _textureImage!.height.toDouble();
    final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);

    final double scale;
    final double dx;
    final double dy;

    switch (fit) {
      case BoxFit.cover:
        scale = max(rect.width / imageWidth, rect.height / imageHeight);
        dx = (rect.width - imageWidth * scale) / 2;
        dy = (rect.height - imageHeight * scale) / 2;
        break;
      case BoxFit.contain:
        scale = min(rect.width / imageWidth, rect.height / imageHeight);
        dx = (rect.width - imageWidth * scale) / 2;
        dy = (rect.height - imageHeight * scale) / 2;
        break;
      default: // none
        scale = 1.0;
        dx = (rect.width - imageWidth) / 2;
        dy = (rect.height - imageHeight) / 2;
    }

    final destRect = Rect.fromLTWH(
      rect.left + dx,
      rect.top + dy,
      imageWidth * scale,
      imageHeight * scale,
    );

    canvas.drawImageRect(_textureImage!, srcRect, destRect, paint);
    canvas.restore();
  }
}

/// 全局纹理缓存，避免重复加载相同的纹理
class _TextureCache {
  static final _TextureCache instance = _TextureCache._();
  final Map<String, ui.Image> _cache = {};

  _TextureCache._();

  ui.Image? getTexture(String path) {
    return _cache[path];
  }

  bool hasTexture(String path) {
    return _cache.containsKey(path);
  }

  // 打印缓存统计信息
  void printStats() {
    debugPrint('📊 纹理缓存状态: ${_cache.length} 个纹理');
    _cache.forEach((key, image) {
      debugPrint('  - $key: ${image.width}x${image.height}');
    });
  }

  void putTexture(String path, ui.Image image) {
    debugPrint('⭐ 纹理缓存: 存储纹理 $path => ${image.width}x${image.height}');
    _cache[path] = image;
  }
}

/// 一个简单的可监听类，用于强制画布重绘
class _TextureRepaintNotifier extends ChangeNotifier {
  // 添加一个单例实例，方便全局访问
  static final _TextureRepaintNotifier instance = _TextureRepaintNotifier._();

  static const int _throttleMilliseconds = 16; // 约60fps
  // 防止重复通知
  DateTime? _lastNotifyTime;

  _TextureRepaintNotifier._();

  void notifyRepaint() {
    final now = DateTime.now();

    // 检查是否需要节流通知
    if (_lastNotifyTime != null) {
      final timeSinceLastNotify =
          now.difference(_lastNotifyTime!).inMilliseconds;
      if (timeSinceLastNotify < _throttleMilliseconds) {
        debugPrint('🚨 纹理重绘通知器: 通知被节流 (距上次 ${timeSinceLastNotify}ms)');
        return;
      }
    }

    _lastNotifyTime = now;
    debugPrint('🚨 纹理重绘通知器: 发送重绘通知');
    notifyListeners();
  }
}
