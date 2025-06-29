import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

/// 跨平台SVG图像加载器
class CrossPlatformSvgPicture {
  /// 创建一个跨平台的SVG图像组件
  static Widget fromPath(
    String path, {
    BoxFit fit = BoxFit.contain,
    Widget Function(BuildContext)? placeholderBuilder,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    if (kIsWeb) {
      // Web平台处理
      return _WebSvgPicture(
        path: path,
        fit: fit,
        placeholderBuilder: placeholderBuilder,
        errorBuilder: errorBuilder,
      );
    } else {
      // 桌面/移动平台处理
      return _NativeSvgPicture(
        path: path,
        fit: fit,
        placeholderBuilder: placeholderBuilder,
        errorBuilder: errorBuilder,
      );
    }
  }
}

/// Web平台SVG组件
class _WebSvgPicture extends StatefulWidget {
  final String path;
  final BoxFit fit;
  final Widget Function(BuildContext)? placeholderBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const _WebSvgPicture({
    required this.path,
    this.fit = BoxFit.contain,
    this.placeholderBuilder,
    this.errorBuilder,
  });

  @override
  State<_WebSvgPicture> createState() => _WebSvgPictureState();
}

class _WebSvgPictureState extends State<_WebSvgPicture> {
  String? _svgContent;
  Object? _error;
  StackTrace? _stackTrace;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSvgContent();
  }

  Future<void> _loadSvgContent() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      String content;
      if (widget.path.startsWith('http://') || widget.path.startsWith('https://')) {
        // 网络SVG
        final response = await http.get(Uri.parse(widget.path));
        if (response.statusCode == 200) {
          content = response.body;
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      } else {
        // 对于Web平台的本地文件，我们需要不同的处理方式
        // 由于Web平台安全限制，无法直接访问本地文件系统
        // 这里我们返回一个错误提示
        throw Exception('Web平台不支持加载本地SVG文件: ${widget.path}\n请将SVG文件放置在web/assets目录下并使用正确的URL路径访问');
      }

      if (mounted) {
        setState(() {
          _svgContent = content;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _error = e;
          _stackTrace = stackTrace;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholderBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!, _stackTrace) ??
          Container(
            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SVG加载失败\n$_error',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
    }

    if (_svgContent != null) {
      return SvgPicture.string(
        _svgContent!,
        fit: widget.fit,
        placeholderBuilder: widget.placeholderBuilder,
      );
    }

    return widget.errorBuilder?.call(context, Exception('未知错误'), null) ??
        const Icon(Icons.error);
  }
}

/// 原生平台SVG组件
class _NativeSvgPicture extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final Widget Function(BuildContext)? placeholderBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const _NativeSvgPicture({
    required this.path,
    this.fit = BoxFit.contain,
    this.placeholderBuilder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _validateSvgFile(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholderBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!, snapshot.stackTrace) ??
              Container(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SVG文件加载失败\n${snapshot.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
        }

        // 对于原生平台，使用字符串内容加载
        return FutureBuilder<String>(
          future: _loadSvgString(path),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return placeholderBuilder?.call(context) ??
                  const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return errorBuilder?.call(context, snapshot.error!, snapshot.stackTrace) ??
                  Container(
                    color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SVG文件加载失败\n${snapshot.error}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
            }

            if (snapshot.hasData) {
              return SvgPicture.string(
                snapshot.data!,
                fit: fit,
                placeholderBuilder: placeholderBuilder,
              );
            }

            return errorBuilder?.call(context, Exception('未知错误'), null) ??
                const Icon(Icons.error);
          },
        );
      },        );
  }

  Future<String> _loadSvgString(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('SVG文件不存在: $path');
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        throw Exception('SVG文件为空');
      }

      if (!content.toLowerCase().contains('<svg')) {
        throw Exception('不是有效的SVG文件格式');
      }

      return content;
    } catch (e) {
      throw Exception('SVG文件读取失败: $e');
    }
  }

  Future<void> _validateSvgFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('SVG文件不存在: $path');
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        throw Exception('SVG文件为空');
      }

      if (!content.toLowerCase().contains('<svg')) {
        throw Exception('不是有效的SVG文件格式');
      }
    } catch (e) {
      throw Exception('SVG文件验证失败: $e');
    }
  }
}
