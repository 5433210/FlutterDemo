class WorkImageInfo {
  final int index;
  final WorkImageDetail original;
  final WorkImageDetail imported;
  final WorkImageThumbnailInfo thumbnail;

  const WorkImageInfo({
    required this.index,
    required this.original,
    required this.imported,
    required this.thumbnail,
  });

  Map<String, dynamic> toJson() => {
    'index': index,
    'original': original.toJson(),
    'imported': imported.toJson(),
    'thumbnail': thumbnail.toJson(),
  };

  factory WorkImageInfo.fromJson(Map<String, dynamic> json) => WorkImageInfo(
    index: json['index'] as int,
    original: WorkImageDetail.fromJson(json['original'] as Map<String, dynamic>),
    imported: WorkImageDetail.fromJson(json['imported'] as Map<String, dynamic>),
    thumbnail: WorkImageThumbnailInfo.fromJson(json['thumbnail'] as Map<String, dynamic>),
  );
}

class WorkImageDetail {
  final String path;
  final int width;
  final int height;
  final String format;
  final int size;

  const WorkImageDetail({
    required this.path,
    required this.width,
    required this.height,
    required this.format,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'width': width,
    'height': height,
    'format': format,
    'size': size,
  };

  factory WorkImageDetail.fromJson(Map<String, dynamic> json) => WorkImageDetail(
    path: json['path'] as String,
    width: json['width'] as int,
    height: json['height'] as int,
    format: json['format'] as String,
    size: json['size'] as int,
  );
}

class WorkImageThumbnailInfo {
  final String path;
  final int width;
  final int height;

  const WorkImageThumbnailInfo({
    required this.path,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'width': width,
    'height': height,
  };

  factory WorkImageThumbnailInfo.fromJson(Map<String, dynamic> json) => WorkImageThumbnailInfo(
    path: json['path'] as String,
    width: json['width'] as int,
    height: json['height'] as int,
  );
}