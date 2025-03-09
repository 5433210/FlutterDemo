import 'package:demo/domain/models/processing_options.dart';
import 'package:equatable/equatable.dart';

class CharacterImage extends Equatable {
  final String path;
  final String binary;
  final String thumbnail;
  final String? svg;
  final ProcessingOptions? processingOptions;

  const CharacterImage({
    required this.path,
    required this.binary,
    required this.thumbnail,
    this.svg,
    this.processingOptions,
  });

  factory CharacterImage.fromJson(Map<String, dynamic> json) {
    return CharacterImage(
      path: json['path'] as String,
      binary: json['binary'] as String,
      thumbnail: json['thumbnail'] as String,
      svg: json['svg'] as String?,
      processingOptions: json['processingOptions'] != null
          ? ProcessingOptions.fromJson(
              json['processingOptions'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [path, binary, thumbnail, svg, processingOptions];

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
      processingOptions: processingOptions ?? this.processingOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'binary': binary,
      'thumbnail': thumbnail,
      'svg': svg,
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
