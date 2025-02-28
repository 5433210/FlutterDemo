import 'package:equatable/equatable.dart';

class CharacterImage extends Equatable {
  final String path;
  final String thumbnail;
  final ImageSize size;

  const CharacterImage({
    required this.path,
    required this.thumbnail,
    required this.size,
  });

  factory CharacterImage.fromJson(Map<String, dynamic> json) {
    return CharacterImage(
      path: json['path'] as String,
      thumbnail: json['thumbnail'] as String,
      size: ImageSize.fromJson(json['size'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [path, thumbnail, size];

  CharacterImage copyWith({
    String? path,
    String? thumbnail,
    ImageSize? size,
  }) {
    return CharacterImage(
      path: path ?? this.path,
      thumbnail: thumbnail ?? this.thumbnail,
      size: size ?? this.size,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'thumbnail': thumbnail,
      'size': size.toJson(),
    };
  }
}

class ImageSize extends Equatable {
  final int width;
  final int height;

  const ImageSize({
    required this.width,
    required this.height,
  });

  factory ImageSize.fromJson(Map<String, dynamic> json) {
    return ImageSize(
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }

  @override
  List<Object?> get props => [width, height];

  ImageSize copyWith({
    int? width,
    int? height,
  }) {
    return ImageSize(
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
    };
  }
}
