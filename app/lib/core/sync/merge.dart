// SPDX-License-Identifier: GPL-3.0-or-later

import '../models/ids.dart';
import 'sync_engine.dart';

/// Everything the merge needs to know about one entity: its fields, the
/// clock of the last change of each field, and its tombstone.
class EntityState {
  /// Creates the state of an entity of kind [entity].
  const EntityState({
    required this.entity,
    this.fields = const {},
    this.clocks = const {},
    this.deletedHlc,
  });

  /// Kind of entity, for example Stop.
  final String entity;

  /// Current value of each field, including fields this version of the app
  /// does not know.
  final Map<String, Object?> fields;

  /// Clock value of the last change of each field.
  final Map<String, Hlc> clocks;

  /// Clock value of the deletion, or null if the entity is not deleted.
  final Hlc? deletedHlc;

  /// True if the entity was deleted.
  bool get isDeleted => deletedHlc != null;
}

/// What an operation changed in an entity.
class MergeResult {
  /// Creates the result of a merge.
  const MergeResult({
    required this.state,
    required this.changedFields,
    required this.overwritten,
  });

  /// State of the entity after the operation.
  final EntityState state;

  /// Fields whose value or clock the operation changed. Empty when the
  /// operation was older than what the entity already had.
  final Set<String> changedFields;

  /// Previous values of the fields the operation replaced. Nothing is ever
  /// thrown away silently: the caller may keep these, as for note texts.
  final Map<String, Object?> overwritten;
}

/// The rules that merge changes made on different devices (PRD 4.3).
///
/// - **Fields: the last writer wins, field by field.** A field takes the
///   value of an operation only if the clock of the operation is later than
///   the clock of the field. Two people changing different fields of the same
///   entity both keep their change.
/// - **Deletion wins.** A tombstone is never removed by a change to a field,
///   whatever the order in which they arrive.
/// - **Unknown fields are kept.** Fields are merged by name without knowing
///   what they mean, so data written by a newer version survives.
///
/// The result depends only on the set of operations, not on the order in
/// which they arrive, and applying an operation twice changes nothing. This
/// is what lets devices sync through plain files, in any order.
abstract final class Merge {
  /// Applies [operation] to [current]; a null [current] means the entity is
  /// not known yet on this device.
  ///
  /// An operation that sets fields of an entity never seen before creates
  /// it: the operation that created it may simply arrive later.
  static MergeResult apply(EntityState? current, SyncOperation operation) {
    final before = current ?? EntityState(entity: operation.entity);

    if (operation.type == OperationType.delete) {
      final tombstone = before.deletedHlc;
      final wins = tombstone == null || operation.hlc.compareTo(tombstone) > 0;
      return MergeResult(
        state: wins
            ? EntityState(
                entity: before.entity,
                fields: before.fields,
                clocks: before.clocks,
                deletedHlc: operation.hlc,
              )
            : before,
        changedFields: const {},
        overwritten: const {},
      );
    }

    final fields = {...before.fields};
    final clocks = {...before.clocks};
    final changed = <String>{};
    final overwritten = <String, Object?>{};
    for (final MapEntry(key: field, :value) in operation.fields.entries) {
      final clock = clocks[field];
      if (clock != null && operation.hlc.compareTo(clock) <= 0) continue;
      if (fields.containsKey(field)) overwritten[field] = fields[field];
      fields[field] = value;
      clocks[field] = operation.hlc;
      changed.add(field);
    }
    return MergeResult(
      state: EntityState(
        entity: before.entity,
        fields: fields,
        clocks: clocks,
        deletedHlc: before.deletedHlc,
      ),
      changedFields: changed,
      overwritten: overwritten,
    );
  }
}
