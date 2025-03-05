import 'package:equatable/equatable.dart';
import 'package:demo/domain/models/processing_options.dart';

class CharacterImage extends Equatable {
  final String path;
  final String binary;
  final String thumbnail;
  final String? svg;
  final ImageSize size;
  final ProcessingOptions? processingOptions;

  const CharacterImage({
    required this.path,
    required this.binary,
    required this.thumbnail,
    this.svg,
    required this.size,
    this.processingOptions,
  });

  @override
  List<Object?> get props => [path, binary, thumbnail, svg, size, processingOptions];

  CharacterImage copyWith({
    String? path,
    String? binary,
    String? thumbnail,
    String? svg,
    ImageSize? size,
    ProcessingOptions? processingOptions,
  }) {
    return CharacterImage(
      path: path ?? this.path,
      binary: binary ?? this.binary,
      thumbnail: thumbnail ?? this.thumbnail,
      svg: svg ?? this.svg,
      size: size ?? this.size,
      processingOptions: processingOptions ?? this.processingOptions,
    );
  }

  factory CharacterImage.fromJson(Map<String, dynamic> json) {
    return CharacterImage(
      path: json['path'] as String,
      binary: json['binary'] as String,
      thumbnail: json['thumbnail'] as String,
      svg: json['svg'] as String?,
      size: ImageSize.fromJson(json['size'] as Map<String, dynamic>),
      processingOptions: json['processingOptions'] != null
          ? ProcessingOptions.fromJson(json['processingOptions'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'binary': binary,
      'thumbnail': thumbnail,
      'svg': svg,
      'size': size.toJson(),
      'processingOptions': processingOptions?.toJson(),
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

  @override
  List<Object?> get props => [width, height];

  factory ImageSize.fromJson(Map<String, dynamic> json) {
    return ImageSize(
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
    };
  }

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
