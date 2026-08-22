/// Date filter options used by Transaction History.
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

/// Inclusive date range.
class DateRange {
  const DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }
}

/// Converts a selected period into real start/end dates.
///
/// Weeks start on Monday.
///
/// This Fortnight:
/// previous Monday through the end of this week.
///
/// Last Fortnight:
/// the two weeks immediately before the current fortnight.
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
      final lastMonth = DateTime(today.year, today.month - 1, 1);

      start = DateTime(lastMonth.year, lastMonth.month, 1);

      end = DateTime(lastMonth.year, lastMonth.month + 1, 0);

      break;

    case DatePeriod.custom:
      if (customStart == null || customEnd == null) {
        throw ArgumentError(
          'customStart and customEnd are required '
          'for DatePeriod.custom',
        );
      }

      if (customStart.isAfter(customEnd)) {
        throw ArgumentError(
          'Custom start date cannot be after '
          'the custom end date.',
        );
      }

      start = _dateOnly(customStart);

      end = _dateOnly(customEnd);

      break;
  }

  final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

  return DateRange(start, endOfDay);
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}
