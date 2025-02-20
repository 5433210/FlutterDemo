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

  double get aspectRatio => width / height;

  ImageSize copyWith({
    int? width,
    int? height,
  }) {
    return ImageSize(
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}