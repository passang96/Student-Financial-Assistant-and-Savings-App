class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}

class DateRangeService {
  static DateRange thisWeek() {
    final now = DateTime.now();

    final start = now.subtract(Duration(days: now.weekday - 1));

    final end = start.add(const Duration(days: 6));

    return DateRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
  }

  static DateRange lastWeek() {
    final current = thisWeek();

    return DateRange(
      start: current.start.subtract(const Duration(days: 7)),
      end: current.start.subtract(const Duration(seconds: 1)),
    );
  }

  static DateRange thisFortnight() {
    final now = DateTime.now();

    final start = now.subtract(Duration(days: now.weekday - 1));

    final end = start.add(const Duration(days: 13));

    return DateRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
  }

  static DateRange lastFortnight() {
    final current = thisFortnight();

    return DateRange(
      start: current.start.subtract(const Duration(days: 14)),
      end: current.start.subtract(const Duration(seconds: 1)),
    );
  }

  static DateRange thisMonth() {
    final now = DateTime.now();

    return DateRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  static DateRange lastMonth() {
    final now = DateTime.now();

    return DateRange(
      start: DateTime(now.year, now.month - 1, 1),
      end: DateTime(now.year, now.month, 0, 23, 59, 59),
    );
  }

  static DateRange custom(DateTime from, DateTime to) {
    return DateRange(
      start: DateTime(from.year, from.month, from.day),
      end: DateTime(to.year, to.month, to.day, 23, 59, 59),
    );
  }
}
