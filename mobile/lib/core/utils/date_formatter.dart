import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _shortDate = DateFormat('MMM d, yyyy');
  static final DateFormat _dayMonth = DateFormat('MMM d');
  static final DateFormat _time = DateFormat('h:mm a');

  static String formatFull(DateTime date) {
    return _shortDate.format(date.toLocal());
  }

  static String formatDayMonth(DateTime date) {
    return _dayMonth.format(date.toLocal());
  }

  static String formatTime(DateTime date) {
    return _time.format(date.toLocal());
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final local = date.toLocal();
    final difference = now.difference(local);

    if (difference.inDays == 0 && now.day == local.day) {
      return 'Today, ${formatTime(local)}';
    } else if (difference.inDays <= 1 && (now.day - local.day == 1 || difference.inHours < 24)) {
      return 'Yesterday, ${formatTime(local)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatFull(local);
    }
  }
}
