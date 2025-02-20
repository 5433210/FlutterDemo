import 'layer_info.dart';

class PageInfo {
  final int index;
  final PageSize size;
  final List<LayerInfo> layers;

  const PageInfo({
    required this.index,
    required this.size,
    required this.layers,
  });

  Map<String, dynamic> toJson() => {
    'index': index,
    'size': size.toJson(),
    'layers': layers.map((l) => l.toJson()).toList(),
  };

  factory PageInfo.fromJson(Map<String, dynamic> json) => PageInfo(
    index: json['index'] as int,
    size: PageSize.fromJson(json['size'] as Map<String, dynamic>),
    layers: (json['layers'] as List)
        .map((e) => LayerInfo.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class PageSize {
  final String unit;
  final String resUnit;
  final int resUnitValue;
  final double width;
  final double height;

  PageSize({
    required this.unit,
    required this.resUnit,
    required this.resUnitValue,
    required this.width,
    required this.height,
  }) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Width and height must be positive');
    }
    if (resUnitValue <= 0) {
      throw ArgumentError('Resolution unit value must be positive');
    }
  }

  Map<String, dynamic> toJson() => {
    'unit': unit,
    'resUnit': resUnit,
    'resUnitValue': resUnitValue,
    'width': width,
    'height': height,
  };

  factory PageSize.fromJson(Map<String, dynamic> json) => PageSize(
    unit: json['unit'] as String,
    resUnit: json['resUnit'] as String,
    resUnitValue: json['resUnitValue'] as int,
    width: (json['width'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
  );
}