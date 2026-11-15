// SPDX-License-Identifier: GPL-3.0-or-later

import '../../core/database/entity_store.dart';
import '../../core/models/entity_kinds.dart';
import '../../core/models/ids.dart';
import '../../core/models/money.dart';
import '../../core/models/place.dart';
import '../../core/models/stop.dart';
import '../../core/models/time.dart';
import '../../core/sync/fractional_index.dart';

/// A stop as the day screen shows it: the position in the day together with
/// the stop of its active plan.
class DayStop {
  /// Creates a stop of a day.
  const DayStop({
    required this.slotId,
    required this.stopId,
    required this.orderKey,
    required this.name,
    required this.kind,
    required this.durationMin,
    this.plan = Plan.a,
    this.planCount = 1,
    this.status = StopStatus.planned,
    this.startTime,
    this.timeFixed = false,
    this.place,
    this.estimatedCost,
    this.links = const [],
    this.note = '',
  });

  /// Position in the day.
  final EntityId slotId;

  /// Stop of the active plan.
  final EntityId stopId;

  /// Order key of the position.
  final String orderKey;

  /// Active plan.
  final Plan plan;

  /// Number of plans of the position; 1 without alternatives.
  final int planCount;

  /// Name of the stop.
  final String name;

  /// Kind of stop.
  final StopKind kind;

  /// Duration in minutes.
  final int durationMin;

  /// Planned, visited or skipped.
  final StopStatus status;

  /// Start time, when fixed by hand or by a booking.
  final LocalTime? startTime;

  /// True if the start time is fixed.
  final bool timeFixed;

  /// Place of the stop; null for a free stop.
  final PlaceSnapshot? place;

  /// Estimated cost: an estimate only, it never enters the budget (F1.6).
  final Money? estimatedCost;

  /// Links saved with the stop.
  final List<Uri> links;

  /// Text of the note; empty if there is none.
  final String note;
}

/// Reads and writes the stops of a day (F1.2).
///
/// A stop is two entities: the position in the day (`StopSlot`) and the stop
/// that fills it under one plan (`Stop`), so that a position can have
/// alternative plans (PRD 8.3). Every method changes both as one change.
class StopRepository {
  /// Creates the repository on [_store].
  const StopRepository(this._store);

  /// Duration given to a new stop, in minutes (F1.2).
  // TODO(M6 F1.15): the default duration of the settings.
  static const int defaultDurationMin = 60;

  /// Longest duration of a stop: one day.
  static const int maxDurationMin = 24 * 60;

  final EntityStore _store;

  /// The stops of a day, in order. Positions whose active stop is missing
  /// (still on its way from another device) are left out.
  Future<List<DayStop>> stopsOfDay(EntityId dayId) async {
    final stops = <DayStop>[];
    for (final slot in await _slotsOf(dayId)) {
      final plans = await _store.list(EntityKinds.stop, parentId: slot.id);
      final active = _plan(slot.fields['activePlan']);
      final stop = plans
          .where((candidate) => _plan(candidate.fields['plan']) == active)
          .firstOrNull;
      if (stop == null) continue;
      stops.add(await _toDayStop(slot, stop, plans.length));
    }
    return stops;
  }

  /// Adds a stop to a day and returns the identifier of its position.
  ///
  /// Without [place] it is a free stop, with only a name. The stop goes at
  /// the end of the day, or at position [index] (from 0) if given.
  ///
  /// Throws an [ArgumentError] if the name is empty.
  Future<EntityId> addStop({
    required EntityId tripId,
    required EntityId dayId,
    required String name,
    PlaceSnapshot? place,
    StopKind? kind,
    int durationMin = defaultDurationMin,
    int? index,
    DateTime? now,
  }) {
    final trimmed = _checkedName(name);
    _checkDuration(durationMin);
    final createdAt = (now ?? DateTime.now()).toUtc().toIso8601String();
    return _store.atomically(() async {
      final slotId = EntityId.generate();
      final key = await _keyFor(dayId, index: index);
      await _store.create(
        entity: EntityKinds.stopSlot,
        id: slotId,
        tripId: tripId,
        fields: {
          'dayId': dayId.value,
          'orderKey': key,
          'activePlan': Plan.a.name,
          'createdAt': createdAt,
        },
      );
      await _store.create(
        entity: EntityKinds.stop,
        id: EntityId.generate(),
        tripId: tripId,
        fields: {
          'slotId': slotId.value,
          'plan': Plan.a.name,
          'kind':
              (kind ?? (place == null ? StopKind.free : StopKind.place)).name,
          'place': place?.toJson(),
          'name': trimmed,
          'startTime': null,
          'timeFixed': false,
          'durationMin': durationMin,
          'estimatedCost': null,
          'links': const <String>[],
          'status': StopStatus.planned.name,
          'visitedAt': null,
          'noteId': null,
          'createdAt': createdAt,
        },
      );
      return slotId;
    });
  }

  /// Changes the name of a stop.
  Future<void> rename(EntityId stopId, String name) =>
      _store.set(stopId, {'name': _checkedName(name)});

  /// Changes the duration of a stop, in minutes.
  Future<void> setDuration(EntityId stopId, int durationMin) {
    _checkDuration(durationMin);
    return _store.set(stopId, {'durationMin': durationMin});
  }

  /// Marks a stop as planned, visited or skipped. A visited stop records
  /// when it was marked.
  Future<void> setStatus(EntityId stopId, StopStatus status, {DateTime? now}) =>
      _store.set(stopId, {
        'status': status.name,
        'visitedAt': status == StopStatus.visited
            ? (now ?? DateTime.now()).toUtc().toIso8601String()
            : null,
      });

  /// Sets or clears the estimated cost of a stop.
  Future<void> setEstimatedCost(EntityId stopId, Money? cost) {
    if (cost != null && cost.amountMinor < 0) {
      throw ArgumentError.value(cost.amountMinor, 'cost', 'Negative cost');
    }
    return _store.set(stopId, {'estimatedCost': cost?.toJson()});
  }

  /// Replaces the links of a stop. Only web addresses are accepted.
  Future<void> setLinks(EntityId stopId, List<Uri> links) {
    for (final link in links) {
      if (!link.hasAuthority ||
          (link.scheme != 'http' && link.scheme != 'https')) {
        throw ArgumentError.value(link, 'links', 'Not a web address');
      }
    }
    return _store.set(stopId, {
      'links': [for (final link in links) link.toString()],
    });
  }

  /// Sets the text of the note of a stop, creating the note the first time.
  Future<void> setNote({
    required EntityId tripId,
    required EntityId stopId,
    required String text,
  }) => _store.atomically(() async {
    final stop = await _store.read(stopId);
    if (stop == null || stop.isDeleted) {
      throw StateError('Stop ${stopId.value} does not exist');
    }
    if (stop.fields['noteId'] case final String noteId) {
      await _store.set(EntityId(noteId), {'text': text});
      return;
    }
    if (text.isEmpty) return;
    final noteId = EntityId.generate();
    await _store.create(
      entity: EntityKinds.note,
      id: noteId,
      tripId: tripId,
      fields: {'text': text},
    );
    await _store.set(stopId, {'noteId': noteId.value});
  });

  /// Moves a stop to position [toIndex] (from 0) of [toDayId]: a reorder
  /// inside its day, or a move to another day (F1.2, flow FL9).
  ///
  /// Only the moved stop changes, unless two stops of the day share an
  /// order key and the stop lands between them: then those get new keys too
  /// (see [FractionalIndex.planInsert]).
  Future<void> moveStop(
    EntityId slotId, {
    required EntityId toDayId,
    required int toIndex,
  }) => _store.atomically(() async {
    final key = await _keyFor(toDayId, index: toIndex, moving: slotId);
    await _store.set(slotId, {'dayId': toDayId.value, 'orderKey': key});
  });

  /// Deletes a stop: its position and every plan of it.
  Future<void> deleteStop(EntityId slotId) => _store.atomically(() async {
    final plans = await _store.list(EntityKinds.stop, parentId: slotId);
    // The position first: what is deleted after it was deleted with it.
    await _store.delete(slotId);
    for (final stop in plans) {
      await _store.delete(stop.id);
    }
  });

  /// Brings back a deleted stop where it was, with the plans it had when it
  /// was deleted (PRD 9.5, "Restore"). A plan removed earlier stays removed.
  Future<void> restoreStop(EntityId slotId) => _store.atomically(() async {
    final slot = await _store.read(slotId);
    if (slot == null || !slot.isDeleted) {
      throw StateError('Stop ${slotId.value} is not deleted');
    }
    final deletedAt = slot.deletedHlc!;
    final plans = await _store.list(
      EntityKinds.stop,
      parentId: slotId,
      includeDeleted: true,
    );
    await _store.restore(slotId);
    for (final stop in plans) {
      final deleted = stop.deletedHlc;
      if (stop.isDeleted &&
          deleted != null &&
          deleted.compareTo(deletedAt) > 0) {
        await _store.restore(stop.id);
      }
    }
  });

  /// The key for a stop that goes at [index] of the day (at the end if
  /// null), applying the new keys of the stops that need one. [moving] is
  /// the position being moved, which does not count among the others.
  Future<String> _keyFor(EntityId dayId, {int? index, EntityId? moving}) async {
    final others = [
      for (final slot in await _slotsOf(dayId))
        if (slot.id != moving)
          (id: slot.id.value, key: slot.fields['orderKey']! as String),
    ];
    final plan = FractionalIndex.planInsert(
      others,
      (index ?? others.length).clamp(0, others.length),
    );
    for (final MapEntry(key: id, value: key) in plan.rekeyed.entries) {
      await _store.set(EntityId(id), {'orderKey': key});
    }
    return plan.key;
  }

  /// The positions of a day, in order.
  Future<List<StoredEntity>> _slotsOf(EntityId dayId) async {
    final slots = await _store.list(EntityKinds.stopSlot, parentId: dayId);
    return slots..sort(
      (a, b) => FractionalIndex.compare(
        a.fields['orderKey']! as String,
        a.id.value,
        b.fields['orderKey']! as String,
        b.id.value,
      ),
    );
  }

  Future<DayStop> _toDayStop(
    StoredEntity slot,
    StoredEntity stop,
    int planCount,
  ) async {
    final fields = stop.fields;
    var note = '';
    if (fields['noteId'] case final String noteId) {
      final stored = await _store.read(EntityId(noteId));
      if (stored != null && !stored.isDeleted) {
        note = switch (stored.fields['text']) {
          final String text => text,
          _ => '',
        };
      }
    }
    return DayStop(
      slotId: slot.id,
      stopId: stop.id,
      orderKey: slot.fields['orderKey']! as String,
      plan: _plan(fields['plan']),
      planCount: planCount,
      name: switch (fields['name']) {
        final String name => name,
        _ => '',
      },
      kind: StopKind.values.asNameMap()[fields['kind']] ?? StopKind.free,
      durationMin: switch (fields['durationMin']) {
        final int minutes => minutes,
        _ => defaultDurationMin,
      },
      status:
          StopStatus.values.asNameMap()[fields['status']] ?? StopStatus.planned,
      startTime: switch (fields['startTime']) {
        final String time => LocalTime.parse(time),
        _ => null,
      },
      timeFixed: fields['timeFixed'] == true,
      place: switch (fields['place']) {
        final Map<Object?, Object?> place => PlaceSnapshot.fromJson(
          place.cast<String, Object?>(),
        ),
        _ => null,
      },
      estimatedCost: switch (fields['estimatedCost']) {
        final Map<Object?, Object?> cost => Money.fromJson(
          cost.cast<String, Object?>(),
        ),
        _ => null,
      },
      links: [
        if (fields['links'] case final List<Object?> links)
          for (final link in links)
            if (link is String) ?Uri.tryParse(link),
      ],
      note: note,
    );
  }

  static Plan _plan(Object? value) => Plan.values.asNameMap()[value] ?? Plan.a;

  static String _checkedName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'A stop needs a name');
    }
    return trimmed;
  }

  static void _checkDuration(int minutes) {
    if (minutes < 0 || minutes > maxDurationMin) {
      throw ArgumentError.value(minutes, 'durationMin', 'Not a duration');
    }
  }
}
