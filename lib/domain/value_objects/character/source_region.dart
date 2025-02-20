class SourceRegion {
  final int index;
  final int x;
  final int y;
  final int width;
  final int height;

  SourceRegion({
    required this.index,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  }) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Width and height must be positive');
    }
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };

  factory SourceRegion.fromJson(Map<String, dynamic> json) => SourceRegion(
    index: json['index'] as int,
    x: json['x'] as int,
    y: json['y'] as int,
    width: json['width'] as int,
    height: json['height'] as int,
  );
}