// SPDX-License-Identifier: GPL-3.0-or-later

import 'ids.dart';

/// Fields shared by every synchronised entity (PRD 8.1).
///
/// The per-field HLC of the last change lives in a separate metadata table,
/// not in the domain model.
abstract class SyncedEntity {
  /// Creates the shared fields.
  const SyncedEntity({
    required this.id,
    required this.createdAt,
    required this.createdBy,
    this.deletedAt,
  });

  /// Identifier of the entity.
  final EntityId id;

  /// Instant of creation, in UTC.
  final DateTime createdAt;

  /// Participant that created the entity.
  final EntityId createdBy;

  /// Instant of deletion in UTC (tombstone), or null if not deleted.
  final DateTime? deletedAt;
}
