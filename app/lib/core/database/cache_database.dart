// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:drift/drift.dart';

import 'app_database.dart';

part 'cache_database.g.dart';

/// One cached value of PRD 8.5: a place, a forecast, an exchange rate…
///
/// Never an attachment, a ticket or a QR code: those live in the data folder
/// (PRD 8.2), because the system may empty the cache at any time.
class CacheRows extends Table {
  /// Kind of value, for example weather.
  TextColumn get kind => text()();

  /// Key of the value inside its kind.
  TextColumn get cacheKey => text()();

  /// The value, as JSON.
  TextColumn get value => text()();

  /// When the value was downloaded, in milliseconds since the Unix epoch.
  /// Shown to the user when the data is old (PRD T4).
  IntColumn get fetchedAtMillis => integer()();

  /// When the value should be refreshed; null if it never expires.
  IntColumn get expiresAtMillis => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {kind, cacheKey};
}

/// The database of the cache (PRD 8.2, 8.5). It lives in the cache folder of
/// the app: it is never synchronised and losing it loses nothing, everything
/// in it can be downloaded again.
// TODO(M3 F1.2): the place cache is the first user of this database.
@DriftDatabase(tables: [CacheRows])
class CacheDatabase extends _$CacheDatabase implements AppDatabase {
  /// Opens the database on [executor].
  CacheDatabase(super.executor);

  /// Version of the schema.
  static const int currentSchemaVersion = 1;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    // A cache holds nothing that cannot be downloaded again: a new schema
    // simply starts empty.
    onUpgrade: (migrator, from, to) async {
      for (final table in allTables) {
        await migrator.deleteTable(table.actualTableName);
      }
      await migrator.createAll();
    },
  );
}
