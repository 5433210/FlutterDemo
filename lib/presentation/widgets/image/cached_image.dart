import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';

/// A simple cached image widget for loading file-based images with memory caching
class CachedImage extends StatefulWidget {
  /// The file path to the image
  final String path;

  /// How the image should be inscribed into the box
  final BoxFit? fit;

  /// Width of the image
  final double? width;

  /// Height of the image
  final double? height;

  /// Builder for displaying errors
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  /// Simple constructor
  const CachedImage({
    super.key,
    required this.path,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

/// Simple LRU (Least Recently Used) map implementation for caching
class LRUMap<K, V> {
  final int capacity;
  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();

  LRUMap({required this.capacity});

  int get length => _map.length;

  V? operator [](K key) {
    final value = _map[key];
    if (value != null) {
      // Move accessed key to the end (most recently used)
      _map.remove(key);
      _map[key] = value;
    }
    return value;
  }

  void operator []=(K key, V value) {
    if (_map.containsKey(key)) {
      _map.remove(key);
    } else if (_map.length >= capacity) {
      // Remove the first (least recently used) item
      _map.remove(_map.keys.first);
    }
    _map[key] = value;
  }

  void clear() => _map.clear();

  bool containsKey(K key) => _map.containsKey(key);

  void remove(K key) => _map.remove(key);
}

class _CachedImageState extends State<CachedImage> {
  /// Static cache for images across all instances of CachedImage
  static final LRUMap<String, FileImage> _imageCache =
      LRUMap<String, FileImage>(capacity: 100);

  FileImage? _image;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(context, _error!, _stackTrace);
    }

    if (_image == null) {
      return const SizedBox.shrink();
    }

    return Image(
      image: _image!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: widget.errorBuilder,
    );
  }

  @override
  void didUpdateWidget(CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _loadImage();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() {
    try {
      if (!File(widget.path).existsSync()) {
        setState(() {
          _error = Exception('File does not exist');
          _image = null;
        });
        return;
      }

      // Check if image is already cached
      _image = _imageCache[widget.path];

      // If not cached, create new image and cache it
      if (_image == null) {
        _image = FileImage(File(widget.path));
        _imageCache[widget.path] = _image!;
      }

      _error = null;
      _stackTrace = null;
    } catch (e, stackTrace) {
      setState(() {
        _error = e;
        _stackTrace = stackTrace;
        _image = null;
      });
    }
  }
}
