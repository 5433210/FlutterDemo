import 'package:equatable/equatable.dart';

/// 图像元素内容
class ImageElement extends Equatable {
  /// 图像文件路径
  final String path;

  const ImageElement({
    required this.path,
  });

  /// 从JSON数据创建图像元素
  factory ImageElement.fromJson(Map<String, dynamic> json) {
    return ImageElement(
      path: json['path'] as String,
    );
  }

  /// 从路径中提取文件扩展名
  String? get fileExtension {
    final name = fileName;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < name.length - 1) {
      return name.substring(dotIndex + 1).toLowerCase();
    }
    return null;
  }

  /// 从路径中提取文件名
  String get fileName {
    final parts = path.split(isRemoteUrl ? '/' : RegExp(r'[/\\]'));
    return parts.last;
  }

  /// 检查图像路径是否为绝对路径
  bool get isAbsolutePath {
    return path.startsWith('/') ||
        // Windows路径
        (path.length > 1 && path[1] == ':');
  }

  /// 检查图像路径是否为有效的远程URL
  bool get isRemoteUrl {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  /// 检查是否为支持的图像格式
  bool get isSupportedFormat {
    final ext = fileExtension;
    if (ext == null) return false;

    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  @override
  List<Object?> get props => [path];

  /// 更改图像路径
  ImageElement changePath(String newPath) {
    return copyWith(path: newPath);
  }

  /// 创建一个带有更新路径的新实例
  ImageElement copyWith({
    String? path,
  }) {
    return ImageElement(
      path: path ?? this.path,
    );
  }

  /// 将图像元素转换为JSON数据
  Map<String, dynamic> toJson() {
    return {
      'path': path,
    };
  }
}
