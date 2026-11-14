// SPDX-License-Identifier: GPL-3.0-or-later

/// The local database of the app (PRD 4.2, 8.2): trip data, personal data
/// and cache, each with its own schema version.
///
/// Only the shape exists: the tables, written with drift, and the operation
/// log arrive with milestone M2.
// TODO(M2): drift tables for PRD 8.3-8.5, migrations and the operation log.
abstract interface class AppDatabase {
  /// Version of the schema, written in every sync file too (PRD 8.1).
  int get schemaVersion;

  /// Closes the database.
  Future<void> close();
}
