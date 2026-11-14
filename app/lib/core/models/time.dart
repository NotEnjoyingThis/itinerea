// SPDX-License-Identifier: GPL-3.0-or-later

/// A calendar date without time or zone (PRD 8.1).
// TODO(M2): validation, comparison and serialisation.
class LocalDate {
  /// Creates the date [year]-[month]-[day].
  const LocalDate(this.year, this.month, this.day);

  /// Year, for example 2026.
  final int year;

  /// Month, from 1 to 12.
  final int month;

  /// Day of the month, from 1.
  final int day;
}

/// A wall-clock time without date or zone (PRD 8.1).
// TODO(M2): validation, comparison and serialisation.
class LocalTime {
  /// Creates the time [hour]:[minute].
  const LocalTime(this.hour, this.minute);

  /// Hour, from 0 to 23.
  final int hour;

  /// Minute, from 0 to 59.
  final int minute;
}

/// A local date and time together with the IANA time zone of the place
/// (PRD 8.1), for example 2026-03-12T09:30 in Europe/Dublin.
// TODO(M2): conversion to and from absolute instants (PRD 9.6).
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
