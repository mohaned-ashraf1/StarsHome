import 'package:intl/intl.dart';

enum PeriodFilterType {
  today,
  yesterday,
  currentWeek,
  previousWeek,
  currentMonth,
  previousMonth,
  currentYear,
  custom,
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});

  bool contains(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return !d.isBefore(s) && !d.isAfter(e);
  }
}

class DateHelper {
  static final DateFormat _ymdFormat = DateFormat('yyyy-MM-dd', 'en_US');
  static final DateFormat _arabicDisplayFormat = DateFormat('yyyy/MM/dd', 'en_US');
  static final DateFormat _arabicLongFormat = DateFormat('EEEE، d MMMM yyyy', 'ar');
  static final DateFormat _timeFormat = DateFormat('hh:mm a', 'ar');

  /// Convert Arabic/Indic digits to English digits
  static String toEnglishDigits(String str) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    for (int i = 0; i < arabicDigits.length; i++) {
      str = str.replaceAll(arabicDigits[i], englishDigits[i]);
    }
    return str;
  }

  static String formatYMD(DateTime date) => _ymdFormat.format(date);
  static String formatDisplay(DateTime date) => _arabicDisplayFormat.format(date);
  static String formatLong(DateTime date) => toEnglishDigits(_arabicLongFormat.format(date));
  static String formatTime(DateTime date) => toEnglishDigits(_timeFormat.format(date));

  /// Convert 24-hour time string (e.g. "19:00", "08:30") to 12-hour format (e.g. "07:00 م", "08:30 ص") with English digits
  static String formatTimeStringTo12Hour(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return '—';
    final trimmed = timeStr.trim();
    if (trimmed.contains('ص') || trimmed.contains('م') || trimmed.toLowerCase().contains('am') || trimmed.toLowerCase().contains('pm')) {
      return toEnglishDigits(trimmed);
    }
    try {
      final parts = trimmed.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(toEnglishDigits(parts[0]));
        int minute = int.parse(toEnglishDigits(parts[1]));
        final period = hour >= 12 ? 'م' : 'ص';
        if (hour == 0) {
          hour = 12;
        } else if (hour > 12) {
          hour -= 12;
        }
        final hourStr = hour.toString().padLeft(2, '0');
        final minStr = minute.toString().padLeft(2, '0');
        return '$hourStr:$minStr $period';
      }
    } catch (_) {}
    return toEnglishDigits(trimmed);
  }

  static DateTime parseYMD(String ymd) {
    try {
      return _ymdFormat.parse(toEnglishDigits(ymd));
    } catch (_) {
      return DateTime.now();
    }
  }

  static DateRange getDateRangeForPeriod(PeriodFilterType type, {DateTime? customStart, DateTime? customEnd}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (type) {
      case PeriodFilterType.today:
        return DateRange(start: today, end: today);

      case PeriodFilterType.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateRange(start: yesterday, end: yesterday);

      case PeriodFilterType.currentWeek:
        // Factory week in Egypt typically starts Saturday (weekday 6) or Friday (weekday 5)
        // Let's align to Saturday as start of week in Egyptian industrial factories:
        int daysSinceSaturday = (today.weekday == DateTime.saturday) ? 0 : (today.weekday + 1) % 7;
        final weekStart = today.subtract(Duration(days: daysSinceSaturday));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return DateRange(start: weekStart, end: weekEnd);

      case PeriodFilterType.previousWeek:
        int daysSinceSaturday = (today.weekday == DateTime.saturday) ? 0 : (today.weekday + 1) % 7;
        final currentWeekStart = today.subtract(Duration(days: daysSinceSaturday));
        final prevWeekStart = currentWeekStart.subtract(const Duration(days: 7));
        final prevWeekEnd = prevWeekStart.add(const Duration(days: 6));
        return DateRange(start: prevWeekStart, end: prevWeekEnd);

      case PeriodFilterType.currentMonth:
        final monthStart = DateTime(today.year, today.month, 1);
        final nextMonth = (today.month == 12) ? DateTime(today.year + 1, 1, 1) : DateTime(today.year, today.month + 1, 1);
        final monthEnd = nextMonth.subtract(const Duration(days: 1));
        return DateRange(start: monthStart, end: monthEnd);

      case PeriodFilterType.previousMonth:
        final prevMonthYear = (today.month == 1) ? today.year - 1 : today.year;
        final prevMonthMonth = (today.month == 1) ? 12 : today.month - 1;
        final prevMonthStart = DateTime(prevMonthYear, prevMonthMonth, 1);
        final thisMonthStart = DateTime(today.year, today.month, 1);
        final prevMonthEnd = thisMonthStart.subtract(const Duration(days: 1));
        return DateRange(start: prevMonthStart, end: prevMonthEnd);

      case PeriodFilterType.currentYear:
        final yearStart = DateTime(today.year, 1, 1);
        final yearEnd = DateTime(today.year, 12, 31);
        return DateRange(start: yearStart, end: yearEnd);

      case PeriodFilterType.custom:
        return DateRange(
          start: customStart ?? today.subtract(const Duration(days: 30)),
          end: customEnd ?? today,
        );
    }
  }

  static String getPeriodLabel(PeriodFilterType type) {
    switch (type) {
      case PeriodFilterType.today:
        return 'اليوم';
      case PeriodFilterType.yesterday:
        return 'أمس';
      case PeriodFilterType.currentWeek:
        return 'الأسبوع الحالي';
      case PeriodFilterType.previousWeek:
        return 'الأسبوع الماضي';
      case PeriodFilterType.currentMonth:
        return 'الشهر الحالي';
      case PeriodFilterType.previousMonth:
        return 'الشهر الماضي';
      case PeriodFilterType.currentYear:
        return 'السنة الحالية';
      case PeriodFilterType.custom:
        return 'فترة مخصصة';
    }
  }

  static double calculateOvertimeHours({
    required String standardEndTimeStr,
    required String actualDepartureTimeStr,
  }) {
    try {
      final stdParts = standardEndTimeStr.split(':');
      final actParts = actualDepartureTimeStr.split(':');
      if (stdParts.length < 2 || actParts.length < 2) return 0.0;

      final stdMinutes = int.parse(stdParts[0]) * 60 + int.parse(stdParts[1]);
      final actMinutes = int.parse(actParts[0]) * 60 + int.parse(actParts[1]);

      int diffMinutes = actMinutes - stdMinutes;
      // Handle overnight shift if departure is past midnight and official end was before midnight
      if (diffMinutes < -720) {
        diffMinutes += 1440;
      }

      if (diffMinutes <= 0) return 0.0;
      return double.parse((diffMinutes / 60.0).toStringAsFixed(2));
    } catch (_) {
      return 0.0;
    }
  }
}
