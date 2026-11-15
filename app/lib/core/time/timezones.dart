// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/time.dart';

/// Zone used when the device does not say which one it is in.
const String fallbackTimezone = 'UTC';

/// The IANA time zone of this device, for example Europe/Rome.
///
/// It is only a starting point for a new trip: it is stored as "from the
/// device" and the user can change it (PRD 8.3). Tests override it.
final deviceTimezoneProvider = FutureProvider<String>((ref) async {
  try {
    final zone = (await FlutterTimezone.getLocalTimezone()).identifier;
    return ref.watch(timezoneNamesProvider).contains(zone)
        ? zone
        : fallbackTimezone;
  } on Exception {
    return fallbackTimezone;
  }
});

/// Every IANA time zone name the app knows, in alphabetical order. The data
/// ships with the app: nothing is downloaded.
final timezoneNamesProvider = Provider<List<String>>((ref) {
  tzdata.initializeTimeZones();
  return tz.timeZoneDatabase.locations.keys.toList()..sort();
});

/// Today's date on this device. Tests override it.
final todayProvider = Provider<LocalDate Function()>(
  (ref) =>
      () => LocalDate.of(DateTime.now()),
);
