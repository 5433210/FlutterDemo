class CharImageInfo {
  final String path;
  final String thumbnail;
  final ImageSize size;

  const CharImageInfo({
    required this.path,
    required this.thumbnail,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'thumbnail': thumbnail,
    'size': size.toJson(),
  };

  factory CharImageInfo.fromJson(Map<String, dynamic> json) => CharImageInfo(
    path: json['path'] as String,
    thumbnail: json['thumbnail'] as String,
    size: ImageSize.fromJson(json['size'] as Map<String, dynamic>),
  );
}

class ImageSize {
  final int width;
  final int height;

  ImageSize({
    required this.width,
    required this.height,
  }) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Width and height must be positive');
    }
  }

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
  };

  factory ImageSize.fromJson(Map<String, dynamic> json) => ImageSize(
    width: json['width'] as int,
    height: json['height'] as int,
  );
}