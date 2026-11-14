// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/ids.dart';
import '../sync/hlc.dart';
import '../sync/sync_engine.dart';
import 'data_database.dart';

/// An entity as it is stored: its kind, where it belongs and its fields.
class StoredEntity {
  /// Creates a stored entity.
  const StoredEntity({
    required this.id,
    required this.entity,
    required this.fields,
    this.tripId,
    this.parentId,
    this.deletedHlc,
  });

  /// Identifier of the entity.
  final EntityId id;

  /// Kind of entity, for example Stop.
  final String entity;

  /// Trip the entity belongs to; null for personal data.
  final EntityId? tripId;

  /// Entity this one hangs from.
  final EntityId? parentId;

  /// Fields of the entity, including those this version does not know.
  final Map<String, Object?> fields;

  /// Clock value of the deletion, or null if the entity is not deleted.
  final Hlc? deletedHlc;

  /// True if the entity was deleted (tombstone).
  bool get isDeleted => deletedHlc != null;
}

/// Writes the changes made on this device (PRD 9.3, step 1).
///
/// Every change goes, in one transaction, into three places: the entity,
/// the clock of each changed field, and the log of operations waiting to be
/// sent. Either all three are written or none is.
// TODO(M2): applying the operations received from other devices.
class EntityStore {
  EntityStore._(this._db, this._clock);

  /// Space of the operations that belong to personal data.
  static const String personalSpace = 'personal';

  static const String _deviceIdKey = 'device.id';
  static const String _lastHlcKey = 'hlc.last';

  /// Opens the store on [db]. The first time, it gives this device its
  /// identifier; afterwards it resumes the clock from its last value.
  ///
  /// [wallClock] exists for tests.
  static Future<EntityStore> open(
    DataDatabase db, {
    DateTime Function()? wallClock,
  }) async {
    final meta = {
      for (final row in await db.select(db.metaRows).get()) row.name: row.value,
    };
    var device = meta[_deviceIdKey];
    if (device == null) {
      device = EntityId.generate().value;
      await db
          .into(db.metaRows)
          .insert(MetaRowsCompanion.insert(name: _deviceIdKey, value: device));
    }
    final last = meta[_lastHlcKey];
    return EntityStore._(
      db,
      HlcClock(
        deviceId: EntityId(device),
        wallClock: wallClock,
        last: last == null ? null : HlcTimestamp.parse(Hlc(last)),
      ),
    );
  }

  final DataDatabase _db;
  final HlcClock _clock;

  /// Identifier of this device, created the first time the store is opened.
  EntityId get deviceId => _clock.deviceId;

  /// Creates an entity of kind [entity] with the given [fields].
  ///
  /// A trip is its own [tripId]; personal data has none.
  Future<void> create({
    required String entity,
    required EntityId id,
    required Map<String, Object?> fields,
    EntityId? tripId,
    EntityId? parentId,
  }) => _db.transaction(() async {
    final hlc = await _nextHlc();
    await _db
        .into(_db.entityRows)
        .insert(
          EntityRowsCompanion.insert(
            id: id.value,
            entity: entity,
            tripId: Value(tripId?.value),
            parentId: Value(parentId?.value),
            fields: jsonEncode(fields),
          ),
        );
    await _stampFields(id, fields.keys, hlc);
    await _log(
      hlc: hlc,
      entity: entity,
      entityId: id,
      type: OperationType.create,
      fields: fields,
      space: tripId?.value ?? personalSpace,
    );
  });

  /// Changes some fields of an entity. Fields not named in [changes] keep
  /// their value, including those this version does not know.
  ///
  /// Throws a [StateError] if the entity does not exist or was deleted.
  Future<void> set(EntityId id, Map<String, Object?> changes) =>
      _db.transaction(() async {
        final row = await _existing(id);
        final hlc = await _nextHlc();
        final fields = _decode(row.fields)..addAll(changes);
        await (_db.update(_db.entityRows)..where((t) => t.id.equals(id.value)))
            .write(EntityRowsCompanion(fields: Value(jsonEncode(fields))));
        await _stampFields(id, changes.keys, hlc);
        await _log(
          hlc: hlc,
          entity: row.entity,
          entityId: id,
          type: OperationType.set,
          fields: changes,
          space: row.tripId ?? personalSpace,
        );
      });

  /// Deletes an entity by leaving a tombstone, so that it does not come
  /// back when another device syncs (PRD 4.3).
  ///
  /// Throws a [StateError] if the entity does not exist or was deleted.
  Future<void> delete(EntityId id) => _db.transaction(() async {
    final row = await _existing(id);
    final hlc = await _nextHlc();
    await (_db.update(_db.entityRows)..where((t) => t.id.equals(id.value)))
        .write(EntityRowsCompanion(deletedHlc: Value(hlc.text.value)));
    await _log(
      hlc: hlc,
      entity: row.entity,
      entityId: id,
      type: OperationType.delete,
      fields: const {},
      space: row.tripId ?? personalSpace,
    );
  });

  /// Reads an entity, deleted or not; null if it never existed here.
  Future<StoredEntity?> read(EntityId id) async {
    final row = await (_db.select(
      _db.entityRows,
    )..where((t) => t.id.equals(id.value))).getSingleOrNull();
    return row == null ? null : _toStored(row);
  }

  /// Lists the entities of one kind that are not deleted, optionally only
  /// those of a trip or under a parent.
  Future<List<StoredEntity>> list(
    String entity, {
    EntityId? tripId,
    EntityId? parentId,
  }) async {
    final query = _db.select(_db.entityRows)
      ..where((t) => t.entity.equals(entity) & t.deletedHlc.isNull());
    if (tripId != null) query.where((t) => t.tripId.equals(tripId.value));
    if (parentId != null) {
      query.where((t) => t.parentId.equals(parentId.value));
    }
    return [for (final row in await query.get()) _toStored(row)];
  }

  /// Clock value of the last change of each field of an entity.
  Future<Map<String, Hlc>> fieldClocks(EntityId id) async {
    final rows = await (_db.select(
      _db.fieldClockRows,
    )..where((t) => t.entityId.equals(id.value))).get();
    return {for (final row in rows) row.field: Hlc(row.hlc)};
  }

  /// Local operations not sent yet, oldest first, optionally of one space.
  Future<List<SyncOperation>> pendingOperations({String? space}) async {
    final query = _db.select(_db.operationRows)
      ..where((t) => t.isLocal.equals(true) & t.sentAtMillis.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.hlc)]);
    if (space != null) query.where((t) => t.space.equals(space));
    return [
      for (final row in await query.get())
        SyncOperation(
          id: EntityId(row.id),
          deviceId: EntityId(row.deviceId),
          hlc: Hlc(row.hlc),
          schemaVersion: row.schemaVersion,
          entity: row.entity,
          entityId: EntityId(row.entityId),
          type: OperationType.values.byName(row.type),
          fields: _decode(row.fields),
        ),
    ];
  }

  /// Records that the given operations reached the sync space at [at].
  Future<void> markSent(Iterable<EntityId> operationIds, DateTime at) =>
      (_db.update(
            _db.operationRows,
          )..where((t) => t.id.isIn([for (final id in operationIds) id.value])))
          .write(
            OperationRowsCompanion(
              sentAtMillis: Value(at.toUtc().millisecondsSinceEpoch),
            ),
          );

  Future<EntityRow> _existing(EntityId id) async {
    final row = await (_db.select(
      _db.entityRows,
    )..where((t) => t.id.equals(id.value))).getSingleOrNull();
    if (row == null) throw StateError('Entity ${id.value} does not exist');
    if (row.deletedHlc != null) {
      throw StateError('Entity ${id.value} was deleted');
    }
    return row;
  }

  /// Takes the next clock value and saves it, so that the clock never goes
  /// back after a restart.
  Future<HlcTimestamp> _nextHlc() async {
    final hlc = _clock.send();
    await _db
        .into(_db.metaRows)
        .insertOnConflictUpdate(
          MetaRowsCompanion.insert(name: _lastHlcKey, value: hlc.text.value),
        );
    return hlc;
  }

  Future<void> _stampFields(
    EntityId id,
    Iterable<String> fields,
    HlcTimestamp hlc,
  ) => _db.batch((batch) {
    batch.insertAllOnConflictUpdate(_db.fieldClockRows, [
      for (final field in fields)
        FieldClockRowsCompanion.insert(
          entityId: id.value,
          field: field,
          hlc: hlc.text.value,
        ),
    ]);
  });

  Future<void> _log({
    required HlcTimestamp hlc,
    required String entity,
    required EntityId entityId,
    required OperationType type,
    required Map<String, Object?> fields,
    required String space,
  }) => _db
      .into(_db.operationRows)
      .insert(
        OperationRowsCompanion.insert(
          id: EntityId.generate().value,
          deviceId: deviceId.value,
          hlc: hlc.text.value,
          schemaVersion: DataDatabase.currentSchemaVersion,
          entity: entity,
          entityId: entityId.value,
          type: type.name,
          fields: jsonEncode(fields),
          space: space,
          isLocal: true,
        ),
      );

  static StoredEntity _toStored(EntityRow row) => StoredEntity(
    id: EntityId(row.id),
    entity: row.entity,
    tripId: row.tripId == null ? null : EntityId(row.tripId!),
    parentId: row.parentId == null ? null : EntityId(row.parentId!),
    fields: _decode(row.fields),
    deletedHlc: row.deletedHlc == null ? null : Hlc(row.deletedHlc!),
  );

  static Map<String, Object?> _decode(String json) =>
      (jsonDecode(json) as Map).cast<String, Object?>();
}
