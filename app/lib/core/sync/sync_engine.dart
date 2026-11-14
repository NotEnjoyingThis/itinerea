// SPDX-License-Identifier: GPL-3.0-or-later

import '../models/ids.dart';

/// Kinds of sync operation (PRD 8.6).
enum OperationType {
  /// A new entity, with all its fields.
  create,

  /// Changed fields of an existing entity.
  set,

  /// A tombstone.
  delete,
}

/// One change, as written on one line of an operations file (PRD 8.6).
///
/// Attachments never travel inside operations: only their SHA-256 does.
// TODO(M2): serialisation and the CRDT merge rules (PRD 4.3).
class SyncOperation {
  /// Creates an operation.
  const SyncOperation({
    required this.id,
    required this.deviceId,
    required this.hlc,
    required this.schemaVersion,
    required this.entity,
    required this.entityId,
    required this.type,
    this.fields = const {},
  });

  /// Identifier of the operation.
  final EntityId id;

  /// Device that made the change.
  final EntityId deviceId;

  /// Clock value of the change.
  final Hlc hlc;

  /// Version of the schema the operation was written with.
  final int schemaVersion;

  /// Name of the entity, for example Stop.
  final String entity;

  /// Entity the operation applies to.
  final EntityId entityId;

  /// Kind of operation.
  final OperationType type;

  /// Fields set by the operation.
  final Map<String, Object?> fields;
}

/// What the sync engine is doing, shown in the interface ("Updated 20 s ago").
enum SyncState {
  /// The trip is only on this device.
  localOnly,

  /// Everything is sent and received.
  upToDate,

  /// Sending or receiving.
  syncing,

  /// No network: changes wait on the device.
  offline,

  /// The last attempt failed.
  error,
}

/// Sends local operations to a sync space and applies the ones of the other
/// devices (PRD 9.3, 9.4).
// TODO(M2): operation log and merge, tested with several simulated devices.
// TODO(M6 F1.13): the sync cycle in file mode.
// TODO(Fase 2 F2.1): server mode over WebSocket.
abstract interface class SyncEngine {
  /// Current state, for the interface.
  Stream<SyncState> get state;

  /// Instant of the last successful sync in UTC, or null if never.
  DateTime? get lastSyncedAt;

  /// Sends what is waiting and receives what is new.
  Future<void> syncNow();
}

/// Exports and imports trips as backup files (PRD 4.5).
///
/// Imported files are untrusted: size limits, no execution, protection from
/// malicious paths in archives (PRD 13).
// TODO(M6 F1.13): the backup file format, with an optional password.
abstract interface class BackupService {
  /// Writes a trip, with its attachments, to a backup file.
  Future<List<int>> exportTrip(EntityId tripId, {String? password});

  /// Reads a backup file and returns the identifier of the restored trip.
  Future<EntityId> importTrip(List<int> bytes, {String? password});
}
