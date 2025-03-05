import 'work_image_size.dart';

class WorkImageInfo {
  //final String id;
  final String path;
  final String thumbnail;
  final WorkImageSize size;
  final int fileSize;
  final String format;
  final String? original;

  const WorkImageInfo({
    //required this.id,
    required this.path,
    required this.thumbnail,
    required this.size,
    required this.fileSize,
    required this.format,
    this.original,
  });

  Map<String, dynamic> toJson() => {
    //'id': id,
    'path': path,
    'thumbnail': thumbnail,
    'size': size.toJson(),
    'fileSize': fileSize,
    'format': format,
    'original': original,
  }..removeWhere((_, value) => value == null);

  factory WorkImageInfo.fromJson(Map<String, dynamic> json) => WorkImageInfo(
    //id: json['id'] as String,
    path: json['path'] as String,
    thumbnail: json['thumbnail'] as String,
    size: WorkImageSize.fromJson(json['size'] as Map<String, dynamic>),
    fileSize: json['fileSize'] as int,
    format: json['format'] as String,
    original: json['original'] as String?,
  );

  WorkImageInfo copyWith({
    //String? id,
    String? path,
    String? thumbnail,
    WorkImageSize? size,
    int? fileSize,
    String? format,
    String? original,
  }) {
    return WorkImageInfo(
      //id: id ?? this.id,
      path: path ?? this.path,
      thumbnail: thumbnail ?? this.thumbnail,
      size: size ?? this.size,
      fileSize: fileSize ?? this.fileSize,
      format: format ?? this.format,
      original: original ?? this.original,
    );
  }
}
