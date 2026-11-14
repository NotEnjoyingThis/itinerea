// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:math';

/// Identifier of an entity (PRD 8.1): a UUID version 7 (RFC 9562) created on
/// the device, so that data can be created offline.
extension type const EntityId(String value) {
  /// Creates a new identifier.
  ///
  /// The first 48 bits are the Unix time in milliseconds; the remaining 74
  /// free bits are random. In the app the random part always comes from a
  /// cryptographically secure generator: [random] and [now] exist for tests.
  factory EntityId.generate({DateTime? now, Random? random}) {
    final source = random ?? _secure;
    final millis = (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch;
    if (millis < 0 || millis > _maxMillis) {
      throw ArgumentError.value(now, 'now', 'Outside the range of UUID v7');
    }
    final bytes = List<int>.generate(16, (_) => source.nextInt(256));
    // unix_ts_ms: 48 bits, most significant byte first. Divisions instead of
    // shifts, so that the result is the same on the web.
    var rest = millis;
    for (var i = 5; i >= 0; i--) {
      bytes[i] = rest % 256;
      rest ~/= 256;
    }
    bytes[6] = 0x70 | (bytes[6] & 0x0f); // version 7
    bytes[8] = 0x80 | (bytes[8] & 0x3f); // variant 10
    final hex = [
      for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0'),
    ].join();
    return EntityId(
      '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}',
    );
  }

  static final Random _secure = Random.secure();
  static const int _maxMillis = 0xFFFFFFFFFFFF;
  static final RegExp _uuidV7 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  /// True if the value is a lower-case UUID version 7.
  bool get isValid => _uuidV7.hasMatch(value);

  /// Instant written in the identifier, in UTC.
  ///
  /// Throws a [FormatException] if the value is not a UUID version 7.
  DateTime get timestamp {
    if (!isValid) throw FormatException('Not a UUID version 7', value);
    final hex = value.substring(0, 8) + value.substring(9, 13);
    return DateTime.fromMillisecondsSinceEpoch(
      int.parse(hex, radix: 16),
      isUtc: true,
    );
  }
}

/// A hybrid logical clock value in its text form (PRD 8.1, 8.6). Comparing
/// the texts compares the clock values.
///
/// See `HlcTimestamp` in `core/sync/hlc.dart` for the parts and the rules.
extension type const Hlc(String value) implements Object {
  /// Compares two clock values: negative if this one is older.
  int compareTo(Hlc other) => value.compareTo(other.value);
}
