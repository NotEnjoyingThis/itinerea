// SPDX-License-Identifier: GPL-3.0-or-later

/// The local database of the app (PRD 4.2, 8.2): trip data, personal data
/// and cache, each with its own schema version.
///
/// The two databases are written with drift: see data_database.dart and
/// cache_database.dart.
// Implemented by DataDatabase and CacheDatabase.
abstract interface class AppDatabase {
  /// Version of the schema, written in every sync file too (PRD 8.1).
  int get schemaVersion;

  /// Closes the database.
  Future<void> close();
}
