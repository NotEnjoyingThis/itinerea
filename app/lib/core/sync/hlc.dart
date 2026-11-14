// SPDX-License-Identifier: GPL-3.0-or-later

import '../models/ids.dart';

/// One value of a hybrid logical clock (PRD 4.3, 8.1).
///
/// It orders changes made on different devices without a shared clock: first
/// by wall time, then by a counter that separates changes made in the same
/// millisecond, then by the device, so that two values are never equal.
class HlcTimestamp implements Comparable<HlcTimestamp> {
  /// Creates a clock value.
  const HlcTimestamp({
    required this.wallMillis,
    required this.counter,
    required this.deviceId,
  });

  /// Reads a clock value from its text form.
  ///
  /// Throws a [FormatException] if the text is not a clock value.
  factory HlcTimestamp.parse(Hlc hlc) {
    final text = hlc.value;
    final match = _format.firstMatch(text);
    if (match == null) throw FormatException('Not an HLC value', text);
    return HlcTimestamp(
      wallMillis: int.parse(match.group(1)!, radix: 16),
      counter: int.parse(match.group(2)!, radix: 16),
      deviceId: EntityId(match.group(3)!),
    );
  }

  static final RegExp _format = RegExp(r'^([0-9a-f]{12}):([0-9a-f]{4}):(.+)$');

  /// Largest value of [counter].
  static const int maxCounter = 0xFFFF;

  /// Largest value of [wallMillis]: 48 bits, as in a UUID version 7.
  static const int maxWallMillis = 0xFFFFFFFFFFFF;

  /// Wall time in milliseconds since the Unix epoch, in UTC.
  final int wallMillis;

  /// Counter that separates values with the same [wallMillis].
  final int counter;

  /// Device that produced the value.
  final EntityId deviceId;

  /// Text form: 12 hexadecimal digits of time, 4 of counter, the device.
  /// Its alphabetical order is the order of the clock values.
  Hlc get text => Hlc(
    '${wallMillis.toRadixString(16).padLeft(12, '0')}:'
    '${counter.toRadixString(16).padLeft(4, '0')}:'
    '${deviceId.value}',
  );

  @override
  int compareTo(HlcTimestamp other) {
    if (wallMillis != other.wallMillis) {
      return wallMillis.compareTo(other.wallMillis);
    }
    if (counter != other.counter) return counter.compareTo(other.counter);
    return deviceId.value.compareTo(other.deviceId.value);
  }

  @override
  bool operator ==(Object other) =>
      other is HlcTimestamp &&
      other.wallMillis == wallMillis &&
      other.counter == counter &&
      other.deviceId == deviceId;

  @override
  int get hashCode => Object.hash(wallMillis, counter, deviceId);

  @override
  String toString() => text.value;
}

/// The hybrid logical clock of one device (PRD 4.3).
///
/// Every local change takes a value from [send]; every change received from
/// another device goes through [receive]. Values only ever grow, even if the
/// wall clock of the device goes backwards.
class HlcClock {
  /// Creates the clock of [deviceId].
  ///
  /// [wallClock] returns the current time and exists for tests; [last] is the
  /// last value the device produced before it was restarted.
  HlcClock({
    required this.deviceId,
    DateTime Function()? wallClock,
    HlcTimestamp? last,
  }) : _wallClock = wallClock ?? DateTime.now,
       _last =
           last ?? HlcTimestamp(wallMillis: 0, counter: 0, deviceId: deviceId);

  /// A wall clock further than this from another device's is treated as
  /// wrong, and the user is warned (PRD 9.5).
  static const Duration maxSkew = Duration(hours: 24);

  /// Device the clock belongs to.
  final EntityId deviceId;

  final DateTime Function() _wallClock;
  HlcTimestamp _last;

  /// Last value produced or seen.
  HlcTimestamp get last => _last;

  int get _now => _wallClock().toUtc().millisecondsSinceEpoch;

  /// Returns the value for a new local change.
  HlcTimestamp send() => _last = _next(_now, _last);

  /// Takes note of a value received from another device and returns the
  /// value of the moment of reception, later than both.
  HlcTimestamp receive(HlcTimestamp remote) {
    final newest = remote.compareTo(_last) > 0 ? remote : _last;
    return _last = _next(_now, newest);
  }

  /// How far in the future [remote] is compared with this device's wall
  /// clock; negative if it is in the past.
  Duration skewOf(HlcTimestamp remote) =>
      Duration(milliseconds: remote.wallMillis - _now);

  /// True if [remote] is more than [maxSkew] away from this device's wall
  /// clock: one of the two clocks is wrong, and the app warns the user.
  bool isSkewed(HlcTimestamp remote) => skewOf(remote).abs() > maxSkew;

  /// The smallest value of this device that is later than [floor] and not
  /// earlier than the wall time [now].
  HlcTimestamp _next(int now, HlcTimestamp floor) {
    if (now > floor.wallMillis) {
      return HlcTimestamp(wallMillis: now, counter: 0, deviceId: deviceId);
    }
    if (floor.counter < HlcTimestamp.maxCounter) {
      return HlcTimestamp(
        wallMillis: floor.wallMillis,
        counter: floor.counter + 1,
        deviceId: deviceId,
      );
    }
    // Counter exhausted within one millisecond: borrow the next one.
    return HlcTimestamp(
      wallMillis: floor.wallMillis + 1,
      counter: 0,
      deviceId: deviceId,
    );
  }
}
