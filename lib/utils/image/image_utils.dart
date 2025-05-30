import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:charasgem/infrastructure/logging/logger.dart';

/// 图像处理工具类
class ImageUtils {
  /// 将字节数组转换为Flutter的Image对象
  static Future<ui.Image?> bytesToImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      AppLogger.error('字节数组转换为图像失败', error: e);
      return null;
    }
  }

  /// 裁剪图像
  static Future<ui.Image?> cropImage(ui.Image image, ui.Rect rect) async {
    try {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = ui.Canvas(pictureRecorder);

      canvas.drawImageRect(
        image,
        rect,
        rect.shift(ui.Offset(-rect.left, -rect.top)),
        ui.Paint(),
      );

      final picture = pictureRecorder.endRecording();
      return picture.toImage(
        rect.width.toInt(),
        rect.height.toInt(),
      );
    } catch (e) {
      AppLogger.error('图像裁剪失败', error: e);
      return null;
    }
  }

  /// 计算图像的实际边界（去除透明部分）
  static ui.Rect getImageBounds(ui.Image image) {
    // TODO: 实现此方法以计算图像的实际边界
    // 暂时返回整个图像的边界
    return ui.Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
  }

  /// 将Flutter的Image对象转换为字节数组
  static Future<Uint8List?> imageToBytes(ui.Image image) async {
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      AppLogger.error('图像转换失败', error: e);
      return null;
    }
  }
}
