/// Utility class for handling Chinese character operations
class ChineseHelper {
  /// The regular expression pattern for matching Chinese characters using Unicode ranges
  static final RegExp _chineseRegex = RegExp(
    r'[\u{4E00}-\u{9FFF}\u{3400}-\u{4DBF}\u{20000}-\u{2A6DF}\u{2A700}-\u{2B73F}\u{2B740}-\u{2B81F}\u{2B820}-\u{2CEAF}]',
    unicode: true,
  );

  /// Checks if a string contains Chinese characters
  static bool containsChinese(String text) {
    if (text.isEmpty) return false;
    return _chineseRegex.hasMatch(text);
  }

  /// Counts the number of Chinese characters in a string
  static int countChineseCharacters(String text) {
    if (text.isEmpty) return 0;
    return _chineseRegex.allMatches(text).length;
  }

  /// Extracts Chinese characters from the given text
  /// Returns a string containing only Chinese characters
  static String extractChineseCharacters(String text) {
    if (text.isEmpty) return '';

    StringBuffer result = StringBuffer();
    Iterable<Match> matches = _chineseRegex.allMatches(text);

    for (Match match in matches) {
      result.write(match.group(0));
    }

    return result.toString();
  }
}
