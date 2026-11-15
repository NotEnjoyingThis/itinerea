// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_providers.dart';
import '../../core/models/ids.dart';
import '../day/stop_repository.dart';
import 'trip_list.dart';
import 'trip_plan.dart';
import 'trip_repository.dart';

/// One trip; null if it does not exist or was deleted.
final tripProvider = FutureProvider.family<TripSummary?, EntityId>(
  (ref, tripId) async =>
      (await ref.watch(tripRepositoryProvider.future)).trip(tripId),
);

/// The days of a trip, in order.
final tripDaysProvider = FutureProvider.family<List<DaySummary>, EntityId>(
  (ref, tripId) async =>
      (await ref.watch(tripRepositoryProvider.future)).days(tripId),
);

/// The segments of a trip, in order.
final tripSegmentsProvider = FutureProvider.family<List<SegmentInfo>, EntityId>(
  (ref, tripId) async =>
      (await ref.watch(tripRepositoryProvider.future)).segments(tripId),
);

/// Reads and writes stops on the database of this device.
final stopRepositoryProvider = FutureProvider<StopRepository>(
  (ref) async => StopRepository(await ref.watch(entityStoreProvider.future)),
);

/// The stops of a day, in order.
final dayStopsProvider = FutureProvider.family<List<DayStop>, EntityId>(
  (ref, dayId) async =>
      (await ref.watch(stopRepositoryProvider.future)).stopsOfDay(dayId),
);

/// Refreshes everything shown about a trip after its dates, its time zone or
/// its segments changed. The stops of every day are read again too: days
/// may have been removed and their stops moved.
void refreshTrip(WidgetRef ref, EntityId tripId) {
  ref
    ..invalidate(tripSummariesProvider)
    ..invalidate(tripProvider(tripId))
    ..invalidate(tripDaysProvider(tripId))
    ..invalidate(tripSegmentsProvider(tripId))
    ..invalidate(dayStopsProvider);
}
