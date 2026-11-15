// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_providers.dart';
import 'trip_repository.dart';

export 'trip_repository.dart' show TripPhase, TripSummary;

/// Reads and writes trips on the database of this device.
final tripRepositoryProvider = FutureProvider<TripRepository>(
  (ref) async => TripRepository(await ref.watch(entityStoreProvider.future)),
);

/// The trips on this device, by name. Refreshed after every change with
/// `ref.invalidate`.
final tripSummariesProvider = FutureProvider<List<TripSummary>>(
  (ref) async => (await ref.watch(tripRepositoryProvider.future)).trips(),
);
