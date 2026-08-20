/// The date filter options for Transaction History, as specified in the
/// Round upgrade task: This Week, Last Week, This Fortnight, Last Fortnight,
/// This Month, Last Month, Custom Range.
enum DatePeriod {
  thisWeek,
  lastWeek,
  thisFortnight,
  lastFortnight,
  thisMonth,
  lastMonth,
  custom,
}

extension DatePeriodLabel on DatePeriod {
  String get label {
    switch (this) {
      case DatePeriod.thisWeek:
        return 'This Week';
      case DatePeriod.lastWeek:
        return 'Last Week';
      case DatePeriod.thisFortnight:
        return 'This Fortnight';
      case DatePeriod.lastFortnight:
        return 'Last Fortnight';
      case DatePeriod.thisMonth:
        return 'This Month';
      case DatePeriod.lastMonth:
        return 'Last Month';
      case DatePeriod.custom:
        return 'Custom Range';
    }
  }
}

/// A simple inclusive date range (start 00:00:00 -> end 23:59:59).
class DateRange {
  const DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) =>
      !date.isBefore(start) && !date.isAfter(end);
}

/// Calculates the actual [DateRange] for a given [DatePeriod].
///
/// Weeks are treated as starting on Monday. A "fortnight" is treated as a
/// 14-day block: the current fortnight starts on the Monday of the week
/// that begins the current 14-day cycle (i.e. this week + last week for
/// "This Fortnight", and the two weeks before that for "Last Fortnight").
///
/// For [DatePeriod.custom], pass [customStart] and [customEnd] — this
/// function will throw if they're missing.
DateRange resolveDateRange(
  DatePeriod period, {
  DateTime? customStart,
  DateTime? customEnd,
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));

  DateTime start;
  DateTime end;

  switch (period) {
    case DatePeriod.thisWeek:
      start = startOfThisWeek;
      end = startOfThisWeek.add(const Duration(days: 6));
      break;

    case DatePeriod.lastWeek:
      start = startOfThisWeek.subtract(const Duration(days: 7));
      end = startOfThisWeek.subtract(const Duration(days: 1));
      break;

    case DatePeriod.thisFortnight:
      start = startOfThisWeek.subtract(const Duration(days: 7));
      end = startOfThisWeek.add(const Duration(days: 6));
      break;

    case DatePeriod.lastFortnight:
      start = startOfThisWeek.subtract(const Duration(days: 21));
      end = startOfThisWeek.subtract(const Duration(days: 8));
      break;

    case DatePeriod.thisMonth:
      start = DateTime(today.year, today.month, 1);
      end = DateTime(today.year, today.month + 1, 0);
      break;

    case DatePeriod.lastMonth:
      final lastMonthDate = DateTime(today.year, today.month - 1, 1);
      start = DateTime(lastMonthDate.year, lastMonthDate.month, 1);
      end = DateTime(lastMonthDate.year, lastMonthDate.month + 1, 0);
      break;

    case DatePeriod.custom:
      if (customStart == null || customEnd == null) {
        throw ArgumentError(
          'customStart and customEnd are required for DatePeriod.custom',
        );
      }
      start = _dateOnly(customStart);
      end = _dateOnly(customEnd);
      break;
  }

  final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
  return DateRange(start, endOfDay);
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
