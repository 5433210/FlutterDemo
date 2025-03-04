import 'dart:ui';

import 'package:uuid/uuid.dart';

class CharacterRegion {
  final String id;
  final int pageIndex;
  final String imagePath;
  Rect rect;
  double rotation;
  bool isSelected;
  bool isSaved;
  final DateTime createTime;

  CharacterRegion({
    String? id,
    required this.pageIndex,
    required this.imagePath,
    required this.rect,
    this.rotation = 0.0,
    this.isSelected = false,
    this.isSaved = false,
    DateTime? createTime,
  })  : id = id ?? const Uuid().v4(),
        createTime = createTime ?? DateTime.now();

  // 从 JSON 创建实例
  factory CharacterRegion.fromJson(Map<String, dynamic> json) {
    return CharacterRegion(
      id: json['id'] as String,
      pageIndex: json['index'] as int,
      imagePath: json['imagePath'] as String,
      rect: Rect.fromLTWH(
        json['x'] as double,
        json['y'] as double,
        json['width'] as double,
        json['height'] as double,
      ),
      rotation: json['rotation'] as double? ?? 0.0,
      createTime: DateTime.parse(json['createTime'] as String),
    );
  }

  // 用于区域调整的克隆方法
  CharacterRegion copyWith({
    String? id,
    int? pageIndex,
    String? imagePath,
    Rect? rect,
    double? rotation,
    bool? isSelected,
    bool? isSaved,
    DateTime? createTime,
  }) {
    return CharacterRegion(
      id: id ?? this.id,
      pageIndex: pageIndex ?? this.pageIndex,
      imagePath: imagePath ?? this.imagePath,
      rect: rect ?? this.rect,
      rotation: rotation ?? this.rotation,
      isSelected: isSelected ?? this.isSelected,
      isSaved: isSaved ?? this.isSaved,
      createTime: createTime ?? this.createTime,
    );
  }

  // 用于数据库存储的 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'index': pageIndex,
      'imagePath': imagePath,
      'x': rect.left,
      'y': rect.top,
      'width': rect.width,
      'height': rect.height,
      'rotation': rotation,
      'createTime': createTime.toIso8601String(),
    };
  }
}
