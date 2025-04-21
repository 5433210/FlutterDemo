import 'dart:math';

import 'package:uuid/uuid.dart';

/// 图片元素工厂函数
Map<String, dynamic> createImageElement({
  required String imageUrl,
  required double x,
  required double y,
  double width = 200,
  double height = 200,
  String? id,
  double opacity = 1.0,
  String name = '', // 添加名称属性
  bool isLocked = false, // 添加锁定标志
  bool isHidden = false, // 添加隐藏标志
}) {
  return {
    'id': id ?? const Uuid().v4(),
    'type': 'image',
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'rotation': 0,
    'opacity': opacity,
    'name': name.isNotEmpty ? name : '图片 ${Random().nextInt(1000)}', // 设置默认名称
    'isLocked': isLocked, // 锁定标志
    'isHidden': isHidden, // 隐藏标志
    'content': {
      'imageUrl': imageUrl,
      'fit': 'contain',
    },
  };
}

/// 文本元素工厂函数
Map<String, dynamic> createTextElement({
  required String text,
  required double x,
  required double y,
  double width = 200,
  double height = 100,
  String? id,
  double fontSize = 16,
  String color = '#000000',
  String fontWeight = 'normal',
  String fontStyle = 'normal',
  String textAlign = 'left',
  double opacity = 1.0,
  String name = '', // 添加名称属性
  bool isLocked = false, // 添加锁定标志
  bool isHidden = false, // 添加隐藏标志
}) {
  return {
    'id': id ?? const Uuid().v4(),
    'type': 'text',
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'rotation': 0,
    'opacity': opacity,
    'name': name.isNotEmpty ? name : '文本 ${Random().nextInt(1000)}', // 设置默认名称
    'isLocked': isLocked, // 锁定标志
    'isHidden': isHidden, // 隐藏标志
    'content': {
      'text': text,
      'fontSize': fontSize,
      'color': color,
      'fontWeight': fontWeight,
      'fontStyle': fontStyle,
      'textAlign': textAlign,
    },
  };
}

/// 集字元素工厂函数
Map<String, dynamic> createWordsElement({
  required List<Map<String, dynamic>> words,
  required double x,
  required double y,
  double width = 400,
  double height = 200,
  String? id,
  double opacity = 1.0,
  String name = '', // 添加名称属性
  bool isLocked = false, // 添加锁定标志
  bool isHidden = false, // 添加隐藏标志
}) {
  return {
    'id': id ?? const Uuid().v4(),
    'type': 'words',
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'rotation': 0,
    'opacity': opacity,
    'name': name.isNotEmpty ? name : '集字 ${Random().nextInt(1000)}', // 设置默认名称
    'isLocked': isLocked, // 锁定标志
    'isHidden': isHidden, // 隐藏标志
    'content': {
      'words': words,
      'layout': 'free',
    },
  };
}
