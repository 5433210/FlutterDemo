class WorkImageSize {
  final int width;
  final int height;

  WorkImageSize({
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

  factory WorkImageSize.fromJson(Map<String, dynamic> json) => WorkImageSize(
    width: json['width'] as int,
    height: json['height'] as int,
  );

  double get aspectRatio => width / height;

  WorkImageSize copyWith({
    int? width,
    int? height,
  }) {
    return WorkImageSize(
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}