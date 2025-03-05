import 'package:equatable/equatable.dart';

class SourceRegion extends Equatable {
  final int index;
  final int x;
  final int y;
  final int width;
  final int height;

  const SourceRegion({
    required this.index,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory SourceRegion.fromJson(Map<String, dynamic> json) {
    return SourceRegion(
      index: json['index'] as int,
      x: json['x'] as int,
      y: json['y'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }

  @override
  List<Object?> get props => [index, x, y, width, height];

  SourceRegion copyWith({
    int? index,
    int? x,
    int? y,
    int? width,
    int? height,
  }) {
    return SourceRegion(
      index: index ?? this.index,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }
}
