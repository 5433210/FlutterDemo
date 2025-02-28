import 'package:equatable/equatable.dart';

import 'practice_layer.dart';

/// 页面尺寸
class PageSize extends Equatable {
  /// 尺寸单位 (例如: 'mm')
  final String unit;

  /// 分辨率单位 (例如: 'dpi')
  final String resUnit;

  /// 分辨率单位值
  final int resUnitValue;

  /// 宽度
  final double width;

  /// 高度
  final double height;

  const PageSize({
    required this.unit,
    required this.resUnit,
    required this.resUnitValue,
    required this.width,
    required this.height,
  });

  /// 创建一个A4尺寸的页面 (210mm x 297mm, 300dpi)
  factory PageSize.a4() {
    return const PageSize(
      unit: 'mm',
      resUnit: 'dpi',
      resUnitValue: 300,
      width: 210,
      height: 297,
    );
  }

  /// 从JSON数据创建页面尺寸
  factory PageSize.fromJson(Map<String, dynamic> json) {
    return PageSize(
      unit: json['unit'] as String,
      resUnit: json['resUnit'] as String,
      resUnitValue: json['resUnitValue'] as int,
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [unit, resUnit, resUnitValue, width, height];

  /// 创建一个带有更新属性的新实例
  PageSize copyWith({
    String? unit,
    String? resUnit,
    int? resUnitValue,
    double? width,
    double? height,
  }) {
    return PageSize(
      unit: unit ?? this.unit,
      resUnit: resUnit ?? this.resUnit,
      resUnitValue: resUnitValue ?? this.resUnitValue,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  /// 将页面尺寸转换为JSON数据
  Map<String, dynamic> toJson() {
    return {
      'unit': unit,
      'resUnit': resUnit,
      'resUnitValue': resUnitValue,
      'width': width,
      'height': height,
    };
  }
}

/// 字帖页面信息
class PracticePage extends Equatable {
  /// 页面序号
  final int index;

  /// 页面尺寸
  final PageSize size;

  /// 页面图层列表
  final List<PracticeLayer> layers;

  const PracticePage({
    required this.index,
    required this.size,
    this.layers = const [],
  });

  /// 从JSON数据创建页面对象
  factory PracticePage.fromJson(Map<String, dynamic> json) {
    return PracticePage(
      index: json['index'] as int,
      size: PageSize.fromJson(json['size'] as Map<String, dynamic>),
      layers: json['layers'] != null
          ? List<PracticeLayer>.from(
              (json['layers'] as List).map(
                (x) => PracticeLayer.fromJson(x as Map<String, dynamic>),
              ),
            )
          : [],
    );
  }

  @override
  List<Object?> get props => [index, size, layers];

  /// 创建一个带有更新属性的新实例
  PracticePage copyWith({
    int? index,
    PageSize? size,
    List<PracticeLayer>? layers,
  }) {
    return PracticePage(
      index: index ?? this.index,
      size: size ?? this.size,
      layers: layers ?? this.layers,
    );
  }

  /// 将页面对象转换为JSON数据
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'size': size.toJson(),
      'layers': layers.map((layer) => layer.toJson()).toList(),
    };
  }
}
