// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:drift/drift.dart';

import 'app_database.dart';

part 'data_database.g.dart';

/// One synchronised entity of PRD 8.3 or 8.4, whatever its kind.
///
/// The fields of the entity are one JSON object. Fields written by a newer
/// version of the app stay in that object untouched, so an older version
/// never deletes them (PRD 9.5).
@TableIndex(name: 'entities_by_trip', columns: {#entity, #tripId})
@TableIndex(name: 'entities_by_parent', columns: {#entity, #parentId})
class EntityRows extends Table {
  /// Identifier of the entity (UUID version 7).
  TextColumn get id => text()();

  /// Kind of entity, for example Stop.
  TextColumn get entity => text()();

  /// Trip the entity belongs to; null for personal data.
  TextColumn get tripId => text().nullable()();

  /// Entity this one hangs from, for example the day of a stop slot.
  TextColumn get parentId => text().nullable()();

  /// Fields of the entity, as a JSON object.
  TextColumn get fields => text()();

  /// Clock value of the deletion (tombstone), or null if not deleted.
  TextColumn get deletedHlc => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Clock value of the last change of each field of each entity (PRD 8.1).
/// Kept apart from the domain model.
class FieldClockRows extends Table {
  /// Entity the field belongs to.
  TextColumn get entityId => text()();

  /// Name of the field.
  TextColumn get field => text()();

  /// Clock value of the last change of the field.
  TextColumn get hlc => text()();

  @override
  Set<Column<Object>> get primaryKey => {entityId, field};
}

/// The log of operations (PRD 4.3, 8.6): every local change, waiting to be
/// sent, and every change received from other devices.
@TableIndex(name: 'operations_by_space', columns: {#space, #hlc})
@TableIndex(name: 'operations_to_send', columns: {#isLocal, #sentAtMillis})
class OperationRows extends Table {
  /// Identifier of the operation.
  TextColumn get id => text()();

  /// Device that made the change.
  TextColumn get deviceId => text()();

  /// Clock value of the change.
  TextColumn get hlc => text()();

  /// Version of the schema the operation was written with.
  IntColumn get schemaVersion => integer()();

  /// Kind of entity.
  TextColumn get entity => text()();

  /// Entity the operation applies to.
  TextColumn get entityId => text()();

  /// Kind of operation: create, set or delete.
  TextColumn get type => text()();

  /// Fields set by the operation, as a JSON object.
  TextColumn get fields => text()();

  /// Where the operation is synchronised: the identifier of the trip, or
  /// the word personal for personal data.
  TextColumn get space => text()();

  /// True if the change was made on this device.
  BoolColumn get isLocal => boolean()();

  /// When the operation was sent to the sync space, in milliseconds since
  /// the Unix epoch; null while it waits.
  IntColumn get sentAtMillis => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Small values the database needs about itself: the identifier of this
/// device and the last value of its clock.
class MetaRows extends Table {
  /// Name of the value.
  TextColumn get name => text()();

  /// The value.
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

/// The database of trips and personal data (PRD 8.2). It lives in the data
/// folder of the app and cannot be rebuilt from the network.
///
/// Every version of the schema has a snapshot in `drift_schemas/data/` and
/// every migration has a test that starts from the previous snapshot.
@DriftDatabase(tables: [EntityRows, FieldClockRows, OperationRows, MetaRows])
class DataDatabase extends _$DataDatabase implements AppDatabase {
  /// Opens the database on [executor].
  DataDatabase(super.executor);

  /// Version of the schema; also written in every operation (PRD 8.1).
  static const int currentSchemaVersion = 1;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      // No migration exists yet: version 1 is the first schema.
      // TODO(M3): add each step here, with its test in
      // test/core/database/migration_test.dart.
      if (from != to) {
        throw StateError('No migration from schema $from to $to');
      }
    },
  );
}
