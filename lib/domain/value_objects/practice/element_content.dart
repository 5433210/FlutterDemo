import 'package:equatable/equatable.dart';

import 'char_element.dart';
import 'image_element.dart';
import 'text_element.dart';

/// 字符内容
class CharsContent extends ElementContent {
  /// 字符列表
  final List<CharElement> chars;

  const CharsContent({
    required this.chars,
  });

  factory CharsContent.fromJson(Map<String, dynamic> json) {
    return CharsContent(
      chars: (json['chars'] as List?)
              ?.map((x) => CharElement.fromJson(x as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [chars];

  /// 添加字符
  CharsContent addChar(CharElement char) {
    return copyWith(chars: [...chars, char]);
  }

  CharsContent copyWith({
    List<CharElement>? chars,
  }) {
    return CharsContent(
      chars: chars ?? this.chars,
    );
  }

  /// 移除字符
  CharsContent removeChar(String charId) {
    return copyWith(
      chars: chars.where((c) => c.charId != charId).toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'chars': chars.map((char) => char.toJson()).toList(),
    };
  }

  /// 更新字符
  CharsContent updateChar(CharElement char) {
    return copyWith(
      chars: chars.map((c) => c.charId == char.charId ? char : c).toList(),
    );
  }
}

/// 元素内容基类
abstract class ElementContent extends Equatable {
  const ElementContent();

  Map<String, dynamic> toJson();

  /// 从JSON创建正确的内容类型
  static ElementContent fromJson(String type, Map<String, dynamic> json) {
    switch (type) {
      case 'chars':
        return CharsContent.fromJson(json);
      case 'text':
        return TextContent.fromJson(json);
      case 'image':
        return ImageContent.fromJson(json);
      default:
        throw ArgumentError('Unknown element type: $type');
    }
  }
}

/// 图片内容
class ImageContent extends ElementContent {
  /// 图片对象
  final ImageElement image;

  const ImageContent({
    required this.image,
  });

  factory ImageContent.fromJson(Map<String, dynamic> json) {
    return ImageContent(
      image: ImageElement.fromJson(json['image'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [image];

  ImageContent copyWith({
    ImageElement? image,
  }) {
    return ImageContent(
      image: image ?? this.image,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'image': image.toJson(),
    };
  }
}

/// 文本内容
class TextContent extends ElementContent {
  /// 文本对象
  final TextElement text;

  const TextContent({
    required this.text,
  });

  factory TextContent.fromJson(Map<String, dynamic> json) {
    return TextContent(
      text: TextElement.fromJson(json['text'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [text];

  TextContent copyWith({
    TextElement? text,
  }) {
    return TextContent(
      text: text ?? this.text,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'text': text.toJson(),
    };
  }
}
