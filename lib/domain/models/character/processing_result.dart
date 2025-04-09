import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

class ProcessingResult {
  final Uint8List originalCrop;
  final Uint8List binaryImage;
  final Uint8List thumbnail;
  final String? svgOutline;
  final Rect boundingBox;

  const ProcessingResult({
    required this.originalCrop,
    required this.binaryImage,
    required this.thumbnail,
    this.svgOutline,
    required this.boundingBox,
  });

  // 创建空的结果
  factory ProcessingResult.empty() {
    return ProcessingResult(
      originalCrop: Uint8List(0),
      binaryImage: Uint8List(0),
      thumbnail: Uint8List(0),
      boundingBox: Rect.zero,
    );
  }

  /// 判断处理结果是否有效
  bool get isValid {
    return originalCrop.isNotEmpty &&
        binaryImage.isNotEmpty &&
        thumbnail.isNotEmpty;
  }

  /// 将 ProcessingResult 序列化并压缩为 Uint8List
  Uint8List toArchiveBytes() {
    // 创建一个新的压缩档案
    final archive = Archive();

    // 添加二进制数据
    archive.addFile(
        ArchiveFile('original_crop.bin', originalCrop.length, originalCrop));
    archive.addFile(
        ArchiveFile('binary_image.bin', binaryImage.length, binaryImage));
    archive.addFile(ArchiveFile('thumbnail.bin', thumbnail.length, thumbnail));

    // 添加元数据
    final metadata = {
      'boundingBox': {
        'x': boundingBox.left,
        'y': boundingBox.top,
        'width': boundingBox.width,
        'height': boundingBox.height,
      },
      'svgOutline': svgOutline,
    };

    final metadataBytes = utf8.encode(json.encode(metadata));
    archive.addFile(
        ArchiveFile('metadata.json', metadataBytes.length, metadataBytes));

    // 压缩整个档案
    return Uint8List.fromList(ZipEncoder().encode(archive) ?? []);
  }

  /// 从压缩的字节数据中创建 ProcessingResult
  static ProcessingResult fromArchiveBytes(Uint8List bytes) {
    try {
      // 解压缩档案
      final archive = ZipDecoder().decodeBytes(bytes);

      // 读取二进制数据
      final originalCrop = _readFileBytes(archive, 'original_crop.bin');
      final binaryImage = _readFileBytes(archive, 'binary_image.bin');
      final thumbnail = _readFileBytes(archive, 'thumbnail.bin');

      // 读取元数据
      final metadataFile = archive.findFile('metadata.json');
      if (metadataFile == null) throw Exception('缺少元数据文件');

      final metadataString = utf8.decode(metadataFile.content as List<int>);
      final metadata = json.decode(metadataString) as Map<String, dynamic>;

      // 解析边界框数据
      final boundingBoxData = metadata['boundingBox'] as Map<String, dynamic>;
      final boundingBox = Rect.fromLTWH(
        boundingBoxData['x'] as double,
        boundingBoxData['y'] as double,
        boundingBoxData['width'] as double,
        boundingBoxData['height'] as double,
      );

      return ProcessingResult(
        originalCrop: originalCrop,
        binaryImage: binaryImage,
        thumbnail: thumbnail,
        svgOutline: metadata['svgOutline'] as String?,
        boundingBox: boundingBox,
      );
    } catch (e) {
      throw Exception('无法从压缩数据中恢复处理结果: $e');
    }
  }

  /// 从压缩档案中读取文件数据
  static Uint8List _readFileBytes(Archive archive, String fileName) {
    final file = archive.findFile(fileName);
    if (file == null) {
      throw Exception('找不到文件: $fileName');
    }
    return Uint8List.fromList(file.content as List<int>);
  }
}
