import 'package:equatable/equatable.dart';

class ImageDetail extends Equatable {
  final String path;
  final int width;
  final int height;
  final String format;
  final int size;

  const ImageDetail({
    required this.path,
    required this.width,
    required this.height,
    required this.format,
    required this.size,
  });

  factory ImageDetail.fromJson(Map<String, dynamic> json) {
    return ImageDetail(
      path: json['path'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      format: json['format'] as String,
      size: json['size'] as int,
    );
  }

  @override
  List<Object?> get props => [path, width, height, format, size];

  ImageDetail copyWith({
    String? path,
    int? width,
    int? height,
    String? format,
    int? size,
  }) {
    return ImageDetail(
      path: path ?? this.path,
      width: width ?? this.width,
      height: height ?? this.height,
      format: format ?? this.format,
      size: size ?? this.size,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'width': width,
      'height': height,
      'format': format,
      'size': size,
    };
  }
}

class ImageThumbnail extends Equatable {
  final String path;
  final int width;
  final int height;

  const ImageThumbnail({
    required this.path,
    required this.width,
    required this.height,
  });

  factory ImageThumbnail.fromJson(Map<String, dynamic> json) {
    return ImageThumbnail(
      path: json['path'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }

  @override
  List<Object?> get props => [path, width, height];

  ImageThumbnail copyWith({
    String? path,
    int? width,
    int? height,
  }) {
    return ImageThumbnail(
      path: path ?? this.path,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'width': width,
      'height': height,
    };
  }
}

class WorkImage extends Equatable {
  final int index;
  final ImageDetail? original;
  final ImageDetail? imported;
  final ImageThumbnail? thumbnail;

  const WorkImage({
    required this.index,
    this.original,
    this.imported,
    this.thumbnail,
  });

  factory WorkImage.fromJson(Map<String, dynamic> json) {
    return WorkImage(
      index: json['index'] as int,
      original: json['original'] != null
          ? ImageDetail.fromJson(json['original'] as Map<String, dynamic>)
          : null,
      imported: json['imported'] != null
          ? ImageDetail.fromJson(json['imported'] as Map<String, dynamic>)
          : null,
      thumbnail: json['thumbnail'] != null
          ? ImageThumbnail.fromJson(json['thumbnail'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [index, original, imported, thumbnail];

  WorkImage copyWith({
    int? index,
    ImageDetail? original,
    ImageDetail? imported,
    ImageThumbnail? thumbnail,
  }) {
    return WorkImage(
      index: index ?? this.index,
      original: original ?? this.original,
      imported: imported ?? this.imported,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'original': original?.toJson(),
      'imported': imported?.toJson(),
      'thumbnail': thumbnail?.toJson(),
    };
  }
}
