import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

class DateFormatter {
  static final _compactFormatter = DateFormat('yyyy/MM/dd');
  static final _fullFormatter = DateFormat('yyyy年MM月dd日');
  static final _timeFormatter = DateFormat('HH:mm:ss');

  /// Format date to compact format: 2024/02/22
  static String formatCompact(DateTime date) {
    return _compactFormatter.format(date);
  }

  /// Format date to full format: 2024年02月22日
  static String formatFull(DateTime date) {
    return _fullFormatter.format(date);
  }

  /// Format relative date: 今天/昨天/前天/日期
  static String formatRelative(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return l10n.today;
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays == 2) {
      return l10n.dayBeforeYesterday;
    } else {
      return formatCompact(date);
    }
  }

  /// Format date with time: 2024/02/22 14:30
  static String formatWithTime(DateTime date) {
    return '${formatCompact(date)} ${_timeFormatter.format(date)}';
  }
}
