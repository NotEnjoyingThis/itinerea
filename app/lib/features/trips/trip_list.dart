// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_providers.dart';
import '../../core/models/entity_kinds.dart';
import '../../core/models/ids.dart';

/// What the home screen shows of a trip.
// TODO(M3 F1.1): dates, destinations and the "current, upcoming, past"
// grouping, once trips can be created.
class TripSummary {
  /// Creates the summary of a trip.
  const TripSummary({required this.id, required this.name});

  /// Identifier of the trip.
  final EntityId id;

  /// Name of the trip.
  final String name;
}

/// The trips on this device, by name.
final tripSummariesProvider = FutureProvider<List<TripSummary>>((ref) async {
  final store = await ref.watch(entityStoreProvider.future);
  final trips = [
    for (final trip in await store.list(EntityKinds.trip))
      TripSummary(
        id: trip.id,
        name: switch (trip.fields['name']) {
          final String name => name,
          _ => '',
        },
      ),
  ];
  return trips
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
});
