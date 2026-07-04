import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-ddTHH:mm:ss');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _displayDateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _displayDateTimeFormat = DateFormat('MMM d, yyyy HH:mm');
  static final DateFormat _dayNameFormat = DateFormat('EEEE');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');

  static String toDateString(DateTime date) => _dateFormat.format(date);

  static String toDateTimeString(DateTime date) => _dateTimeFormat.format(date);

  static DateTime fromDateString(String dateStr) => _dateFormat.parse(dateStr);

  static DateTime fromDateTimeString(String dateTimeStr) =>
      _dateTimeFormat.parse(dateTimeStr);

  static String formatDisplayDate(DateTime date) =>
      _displayDateFormat.format(date);

  static String formatDisplayDateTime(DateTime date) =>
      _displayDateTimeFormat.format(date);

  static String formatTime(DateTime date) => _timeFormat.format(date);

  static String dayName(DateTime date) => _dayNameFormat.format(date);

  static String monthYear(DateTime date) => _monthYearFormat.format(date);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static DateTime today() => DateTime.now();

  static DateTime todayDateOnly() =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  static int daysBetween(DateTime from, DateTime to) =>
      to.difference(from).inDays.abs();

  static int calculateStreak(List<DateTime> completedDates) {
    if (completedDates.isEmpty) return 0;
    final sorted = List<DateTime>.from(completedDates)
      ..sort((a, b) => b.compareTo(a));
    final unique = <DateTime>{};
    for (final d in sorted) {
      unique.add(DateTime(d.year, d.month, d.day));
    }
    final dates = unique.toList()..sort((a, b) => b.compareTo(a));
    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final diff = dates[i].difference(dates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
