// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/entity_kinds.dart';
import '../models/ids.dart';
import '../sync/hlc.dart';
import '../sync/merge.dart';
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

/// What happened to an operation received from another device.
class ReceiveOutcome {
  /// Creates an outcome.
  const ReceiveOutcome({
    required this.alreadyKnown,
    required this.changedFields,
    required this.clockSkewed,
  });

  /// True if the operation had already been received: nothing was done.
  final bool alreadyKnown;

  /// Fields of the entity the operation changed on this device. Empty when
  /// a later change was already here, or when the operation is a deletion.
  final Set<String> changedFields;

  /// True if the clock of the operation is more than 24 hours away from the
  /// clock of this device: one of the two is wrong, and the app warns the
  /// user (PRD 9.5). The operation is applied all the same.
  final bool clockSkewed;
}

/// One version of the text of a note, as found in the log of operations.
class NoteTextVersion {
  /// Creates a version.
  const NoteTextVersion({
    required this.text,
    required this.hlc,
    required this.deviceId,
  });

  /// Text of the note in this version.
  final String text;

  /// Clock value of the change.
  final Hlc hlc;

  /// Device that wrote this version.
  final EntityId deviceId;
}

/// Writes the changes made on this device and applies those received from
/// the others (PRD 9.3, steps 1 and 4).
///
/// Every change, local or received, goes in one transaction into three
/// places: the entity, the clock of each changed field, and the log of
/// operations. Either all three are written or none is. Local and received
/// changes go through the same merge rules ([Merge]).
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
  /// A trip is its own [tripId]; personal data has none. The parent of the
  /// entity, when its kind has one, is read from the fields
  /// ([EntityKinds.parentField]).
  ///
  /// Throws a [StateError] if an entity with this identifier exists.
  Future<void> create({
    required String entity,
    required EntityId id,
    required Map<String, Object?> fields,
    EntityId? tripId,
  }) => _db.transaction(() async {
    if (await _row(id) != null) {
      throw StateError('Entity ${id.value} already exists');
    }
    await _applyLocal(
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
        await _applyLocal(
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
    await _applyLocal(
      entity: row.entity,
      entityId: id,
      type: OperationType.delete,
      fields: const {},
      space: row.tripId ?? personalSpace,
    );
  });

  /// Applies an operation made on another device, read from [space] (the
  /// identifier of a trip, or [personalSpace]).
  ///
  /// The order in which operations arrive does not matter, and receiving the
  /// same operation twice changes nothing.
  Future<ReceiveOutcome> receive(
    SyncOperation operation, {
    required String space,
  }) => _db.transaction(() async {
    final known = await (_db.select(
      _db.operationRows,
    )..where((t) => t.id.equals(operation.id.value))).getSingleOrNull();
    if (known != null) {
      return const ReceiveOutcome(
        alreadyKnown: true,
        changedFields: {},
        clockSkewed: false,
      );
    }
    final remote = HlcTimestamp.parse(operation.hlc);
    final skewed = _clock.isSkewed(remote);
    _clock.receive(remote);
    await _saveClock();
    final result = await _merge(operation, space);
    await _log(operation, space: space, isLocal: false);
    return ReceiveOutcome(
      alreadyKnown: false,
      changedFields: result.changedFields,
      clockSkewed: skewed,
    );
  });

  /// Reads an entity, deleted or not; null if it never existed here.
  Future<StoredEntity?> read(EntityId id) async {
    final row = await _row(id);
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
    return [for (final row in await query.get()) _toOperation(row)];
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

  /// Every text a note ever had, oldest first, read from the log of
  /// operations (PRD 4.3): when two people change a note at the same time
  /// the last change wins, and the other text is still here.
  ///
  /// The history is calculated, not stored, so it is the same on every
  /// device that has received the same operations.
  // TODO(Fase 2 F2.1): keep the history when old operations are replaced by
  // a snapshot, with the configurable maximum of PRD 8.3.
  Future<List<NoteTextVersion>> noteHistory(EntityId noteId) async {
    final rows =
        await (_db.select(_db.operationRows)
              ..where((t) => t.entityId.equals(noteId.value))
              ..orderBy([(t) => OrderingTerm.asc(t.hlc)]))
            .get();
    return [
      for (final row in rows)
        if (_decode(row.fields) case {'text': final String text})
          NoteTextVersion(
            text: text,
            hlc: Hlc(row.hlc),
            deviceId: EntityId(row.deviceId),
          ),
    ];
  }

  Future<void> _applyLocal({
    required String entity,
    required EntityId entityId,
    required OperationType type,
    required Map<String, Object?> fields,
    required String space,
  }) async {
    final hlc = _clock.send();
    await _saveClock();
    final operation = SyncOperation(
      id: EntityId.generate(),
      deviceId: deviceId,
      hlc: hlc.text,
      schemaVersion: DataDatabase.currentSchemaVersion,
      entity: entity,
      entityId: entityId,
      type: type,
      fields: fields,
    );
    await _merge(operation, space);
    await _log(operation, space: space, isLocal: true);
  }

  /// Merges [operation] into the stored entity and writes the result.
  Future<MergeResult> _merge(SyncOperation operation, String space) async {
    final id = operation.entityId;
    final row = await _row(id);
    final current = row == null
        ? null
        : EntityState(
            entity: row.entity,
            fields: _decode(row.fields),
            clocks: await fieldClocks(id),
            deletedHlc: row.deletedHlc == null ? null : Hlc(row.deletedHlc!),
          );
    final result = Merge.apply(current, operation);
    final state = result.state;
    await _db
        .into(_db.entityRows)
        .insertOnConflictUpdate(
          EntityRowsCompanion.insert(
            id: id.value,
            entity: state.entity,
            tripId: Value(
              row != null
                  ? row.tripId
                  : (space == personalSpace ? null : space),
            ),
            parentId: Value(EntityKinds.parentOf(state.entity, state.fields)),
            fields: jsonEncode(state.fields),
            deletedHlc: Value(state.deletedHlc?.value),
          ),
        );
    if (result.changedFields.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.fieldClockRows, [
          for (final field in result.changedFields)
            FieldClockRowsCompanion.insert(
              entityId: id.value,
              field: field,
              hlc: operation.hlc.value,
            ),
        ]);
      });
    }
    return result;
  }

  Future<EntityRow?> _row(EntityId id) => (_db.select(
    _db.entityRows,
  )..where((t) => t.id.equals(id.value))).getSingleOrNull();

  Future<EntityRow> _existing(EntityId id) async {
    final row = await _row(id);
    if (row == null) throw StateError('Entity ${id.value} does not exist');
    if (row.deletedHlc != null) {
      throw StateError('Entity ${id.value} was deleted');
    }
    return row;
  }

  /// Saves the last clock value, so that the clock never goes back after a
  /// restart.
  Future<void> _saveClock() => _db
      .into(_db.metaRows)
      .insertOnConflictUpdate(
        MetaRowsCompanion.insert(
          name: _lastHlcKey,
          value: _clock.last.text.value,
        ),
      );

  Future<void> _log(
    SyncOperation operation, {
    required String space,
    required bool isLocal,
  }) => _db
      .into(_db.operationRows)
      .insert(
        OperationRowsCompanion.insert(
          id: operation.id.value,
          deviceId: operation.deviceId.value,
          hlc: operation.hlc.value,
          schemaVersion: operation.schemaVersion,
          entity: operation.entity,
          entityId: operation.entityId.value,
          type: operation.type.name,
          fields: jsonEncode(operation.fields),
          space: space,
          isLocal: isLocal,
        ),
      );

  static SyncOperation _toOperation(OperationRow row) => SyncOperation(
    id: EntityId(row.id),
    deviceId: EntityId(row.deviceId),
    hlc: Hlc(row.hlc),
    schemaVersion: row.schemaVersion,
    entity: row.entity,
    entityId: EntityId(row.entityId),
    type: OperationType.values.byName(row.type),
    fields: _decode(row.fields),
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
