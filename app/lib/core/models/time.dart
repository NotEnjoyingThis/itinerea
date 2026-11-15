// SPDX-License-Identifier: GPL-3.0-or-later

/// A calendar date without time or zone (PRD 8.1).
class LocalDate implements Comparable<LocalDate> {
  /// Creates the date [year]-[month]-[day].
  ///
  /// Throws an [ArgumentError] if the date does not exist, for example the
  /// 30th of February.
  factory LocalDate(int year, int month, int day) {
    final check = DateTime.utc(year, month, day);
    if (check.year != year || check.month != month || check.day != day) {
      throw ArgumentError('No such date: $year-$month-$day');
    }
    return LocalDate._(year, month, day);
  }

  const LocalDate._(this.year, this.month, this.day);

  /// The calendar date of [dateTime], ignoring its time and zone.
  factory LocalDate.of(DateTime dateTime) =>
      LocalDate._(dateTime.year, dateTime.month, dateTime.day);

  /// Reads a date written as YYYY-MM-DD.
  ///
  /// Throws a [FormatException] if the text is not a date.
  factory LocalDate.parse(String text) {
    final match = _format.firstMatch(text);
    if (match == null) throw FormatException('Not a date', text);
    try {
      return LocalDate(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    } on ArgumentError {
      throw FormatException('No such date', text);
    }
  }

  static final RegExp _format = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Year, for example 2026.
  final int year;

  /// Month, from 1 to 12.
  final int month;

  /// Day of the month, from 1.
  final int day;

  // Midnight UTC of the date: UTC has no daylight saving time, so days are
  // always 24 hours apart.
  DateTime get _utc => DateTime.utc(year, month, day);

  /// Day of the week, from 1 (Monday) to 7 (Sunday).
  int get weekday => _utc.weekday;

  /// The date [days] days after this one (before, if negative).
  LocalDate addDays(int days) => LocalDate.of(_utc.add(Duration(days: days)));

  /// Number of days from this date to [other]; negative if [other] is
  /// earlier.
  int daysUntil(LocalDate other) => other._utc.difference(_utc).inDays;

  /// The date as a local [DateTime] at midnight, for date pickers and
  /// formatting.
  DateTime toDateTime() => DateTime(year, month, day);

  /// The date written as YYYY-MM-DD.
  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalDate other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}

/// A wall-clock time without date or zone (PRD 8.1).
class LocalTime implements Comparable<LocalTime> {
  /// Creates the time [hour]:[minute].
  const LocalTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24, 'hour out of range'),
      assert(minute >= 0 && minute < 60, 'minute out of range');

  /// Reads a time written as HH:MM.
  ///
  /// Throws a [FormatException] if the text is not a time.
  factory LocalTime.parse(String text) {
    final match = _format.firstMatch(text);
    if (match == null) throw FormatException('Not a time', text);
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) throw FormatException('No such time', text);
    return LocalTime(hour, minute);
  }

  static final RegExp _format = RegExp(r'^(\d{2}):(\d{2})$');

  /// Hour, from 0 to 23.
  final int hour;

  /// Minute, from 0 to 59.
  final int minute;

  /// Minutes since midnight.
  int get minuteOfDay => hour * 60 + minute;

  /// The time written as HH:MM.
  String toIso() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalTime other) => minuteOfDay.compareTo(other.minuteOfDay);

  @override
  bool operator ==(Object other) =>
      other is LocalTime && other.minuteOfDay == minuteOfDay;

  @override
  int get hashCode => minuteOfDay;

  @override
  String toString() => toIso();
}

/// A local date and time together with the IANA time zone of the place
/// (PRD 8.1), for example 2026-03-12T09:30 in Europe/Dublin.
// TODO(M5 F1.9): conversion to and from absolute instants (PRD 9.6).
class ZonedLocalDateTime {
  /// Creates a local date and time in [timezone].
  const ZonedLocalDateTime({
    required this.date,
    required this.time,
    required this.timezone,
  });

  /// Local date.
  final LocalDate date;

  /// Local time.
  final LocalTime time;

  /// IANA time zone name, for example Europe/Rome.
  final String timezone;
}
