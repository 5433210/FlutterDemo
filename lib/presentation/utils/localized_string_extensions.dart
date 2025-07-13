/// 字符串扩展，用于处理本地化文本中的转义字符
extension LocalizedStringExtensions on String {
  /// 将本地化字符串中的转义换行符转换为实际换行符
  ///
  /// 在 ARB 文件中，换行符需要使用 \\n 来表示，
  /// 但在 Flutter 的 Text widget 中需要转换为 \n
  String get processLineBreaks => replaceAll('\\n', '\n');

  /// 处理所有常见的转义字符
  String get processEscapeChars => replaceAll('\\n', '\n')
      .replaceAll('\\t', '\t')
      .replaceAll('\\"', '"')
      .replaceAll("\\'", "'");
}
