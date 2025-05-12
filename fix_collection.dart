// This is a fixed implementation
  void _paintTexture(Canvas canvas, Rect rect, {required String mode}) {
    // 开始性能计时
    final startTime = DateTime.now();

    // 检查纹理配置并记录详细信息
    if (!textureConfig.enabled || textureConfig.data == null) {
      debugPrint(
          '⚡ 渲染检查耗时: ${DateTime.now().difference(startTime).inMicroseconds}μs');
      debugPrint('''⚠️ 跳过纹理绘制:
  ┌─ 原因: ${!textureConfig.enabled ? "纹理未启用" : "无纹理数据"}
  ├─ 模式: $mode
  ├─ 区域: $rect
  └─ 数据: ${textureConfig.data}''');
      return;
    }

    // 创建纹理缓存键
    final String texturePath = textureConfig.data?['path'] as String? ?? '';
    final String textureCacheKey =
        '${texturePath}_${textureConfig.fillMode}_${textureConfig.opacity}';

    debugPrint('''��� 开始纹理渲染:
  ┌─ 模式: $mode (${mode == 'character' ? "字符纹理" : "背景纹理"})
  ├─ 区域: $rect
  ├─ 填充: ${textureConfig.fillMode}
  ├─ 透明度: ${textureConfig.opacity}
  ├─ 路径: $texturePath
  └─ 缓存键: $textureCacheKey''');

    try {
      // 根据模式选择适当的纹理绘制器
      final CustomPainter texturePainter;
      
      if (mode == 'character') {
        // 字符应用范围使用 CharacterTexturePainter
        texturePainter = CharacterTexturePainter(
          textureData: textureConfig.data,
          fillMode: textureConfig.fillMode,
          opacity: textureConfig.opacity,
          ref: ref,
        );
        debugPrint('��� 创建字符纹理绘制器，模式: ${textureConfig.fillMode}');
      } else {
        // 背景应用范围使用 BackgroundTexturePainter
        texturePainter = BackgroundTexturePainter(
          textureData: textureConfig.data,
          fillMode: textureConfig.fillMode,
          opacity: textureConfig.opacity,
          ref: ref,
        );
        debugPrint('��� 创建背景纹理绘制器，模式: ${textureConfig.fillMode}');
      }

      // 创建统一的绘制配置 - 为字符纹理使用 DstATop，为背景使用 SrcOver
      final paint = Paint()
        ..blendMode =
            mode == 'character' ? BlendMode.dstATop : BlendMode.srcOver;

      debugPrint('��� 使用混合模式: ${paint.blendMode}');

      // 保存画布状态并绘制
      // 注意：字符纹理使用 dstATop，让纹理适应字符形状
      canvas.saveLayer(rect, paint);
      _drawTextureWithTransform(canvas, rect, texturePainter);

      // 检查透明度并应用
      if (textureConfig.opacity < 1.0) {
        canvas.saveLayer(
            rect,
            Paint()
              ..color = Colors.white.withOpacity(textureConfig.opacity)
              ..blendMode = BlendMode.dstIn);
        canvas.restore();
      }

      canvas.restore();
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('''✅ 纹理渲染完成:
  ┌─ 模式: $mode
  ├─ 耗时: ${duration.inMilliseconds}ms
  └─ 微秒: ${duration.inMicroseconds}μs''');
    } catch (e, stack) {
      debugPrint('❌ 纹理绘制错误: $e\n$stack');
      // 确保即使出错也恢复画布状态
      canvas.restore();
      _drawFallbackTexture(canvas, rect, Colors.black.withOpacity(0.1));
    }
  }
