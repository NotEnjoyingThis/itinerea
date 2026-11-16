// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cache_database.dart';
import 'data_database.dart';
import 'database_locations.dart';
import 'entity_store.dart';

/// Where the app keeps its files on this device. Tests override it.
final databaseLocationsProvider = FutureProvider<DatabaseLocations>(
  (ref) => DatabaseLocations.ofThisDevice(),
);

/// The database of trips and personal data, opened once and closed with the
/// app. Tests override it with a database in memory.
final dataDatabaseProvider = FutureProvider<DataDatabase>((ref) async {
  final locations = await ref.watch(databaseLocationsProvider.future);
  final database = locations.openData();
  ref.onDispose(database.close);
  return database;
});

/// The database of the cache (PRD 8.5), opened when first needed and closed
/// with the app. Tests override it with a database in memory.
final cacheDatabaseProvider = FutureProvider<CacheDatabase>((ref) async {
  final locations = await ref.watch(databaseLocationsProvider.future);
  final database = locations.openCache();
  ref.onDispose(database.close);
  return database;
});

/// The store every feature reads and writes entities through.
final entityStoreProvider = FutureProvider<EntityStore>(
  (ref) async => EntityStore.open(await ref.watch(dataDatabaseProvider.future)),
);
