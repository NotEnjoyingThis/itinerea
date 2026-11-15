// SPDX-License-Identifier: GPL-3.0-or-later

import '../../core/database/entity_store.dart';
import '../../core/models/entity_kinds.dart';
import '../../core/models/ids.dart';
import '../../core/models/place.dart';
import '../../core/models/time.dart';
import '../../core/models/trip.dart';
import '../../core/sync/fractional_index.dart';
import 'trip_plan.dart';

/// A trip as the home screen and the trip screens need it.
class TripSummary {
  /// Creates the summary of a trip.
  const TripSummary({
    required this.id,
    required this.name,
    this.dayCount = 1,
    this.startDate,
    this.destinations = const [],
    this.timezone,
    this.timezoneSource = TimezoneSource.device,
  });

  /// Identifier of the trip.
  final EntityId id;

  /// Name of the trip.
  final String name;

  /// Number of days.
  final int dayCount;

  /// First day, or null if the dates are not decided yet.
  final LocalDate? startDate;

  /// Names of the destinations.
  final List<String> destinations;

  /// IANA time zone of the trip.
  final String? timezone;

  /// Where [timezone] comes from.
  final TimezoneSource timezoneSource;

  /// Last day, or null if the dates are not decided yet.
  LocalDate? get endDate => startDate?.addDays(dayCount - 1);

  /// Where the trip stands on [today]: null if it has no dates.
  TripPhase? phaseOn(LocalDate today) {
    final start = startDate;
    final end = endDate;
    if (start == null || end == null) return null;
    if (today.compareTo(start) < 0) return TripPhase.upcoming;
    if (today.compareTo(end) > 0) return TripPhase.past;
    return TripPhase.current;
  }
}

/// Where a trip with dates stands compared with today (PRD 7.2).
enum TripPhase {
  /// The trip is happening today.
  current,

  /// The trip has not started yet.
  upcoming,

  /// The trip is over.
  past,
}

/// A day of a trip, as the trip screens need it.
class DaySummary {
  /// Creates the summary of a day.
  const DaySummary({
    required this.id,
    required this.index,
    required this.timezone,
    required this.timezoneSource,
    this.date,
  });

  /// Identifier of the day.
  final EntityId id;

  /// Position in the trip, from 1.
  final int index;

  /// Date, or null while the trip has no dates.
  final LocalDate? date;

  /// IANA time zone of the day.
  final String timezone;

  /// Where [timezone] comes from.
  final TimezoneSource timezoneSource;
}

/// Reads and writes trips, with their days and segments (F1.1).
///
/// Every method that changes several entities does it as one change: a trip
/// never exists without its days.
class TripRepository {
  /// Creates the repository on [_store].
  const TripRepository(this._store);

  final EntityStore _store;

  /// Creates a trip from [draft], with its owner, its first segment and its
  /// days, and returns its identifier.
  ///
  /// Throws an [ArgumentError] if the draft has problems.
  Future<EntityId> createTrip(TripDraft draft, {DateTime? now}) {
    if (draft.problems.isNotEmpty) {
      throw ArgumentError.value(draft.problems, 'draft', 'Invalid trip');
    }
    final createdAt = (now ?? DateTime.now()).toUtc().toIso8601String();
    return _store.atomically(() async {
      final tripId = EntityId.generate();
      final ownerId = EntityId.generate();
      final profileId = await _localProfileId(createdAt);
      PlaceSnapshot? place(String? name) => name == null || name.trim().isEmpty
          ? null
          : PlaceSnapshot(name: name.trim());

      await _store.create(
        entity: EntityKinds.trip,
        id: tripId,
        tripId: tripId,
        fields: {
          'name': draft.name.trim(),
          'startDate': draft.startDate?.toIso(),
          'endDate': draft.endDate?.toIso(),
          'dayCount': draft.dayCount,
          'destinations': [
            for (final name in draft.destinations)
              if (place(name) case final destination?) destination.toJson(),
          ],
          'departurePlace': place(draft.departure)?.toJson(),
          'returnPlace': place(draft.returnPlace)?.toJson(),
          'currency': draft.currency,
          'budgetMode': BudgetMode.none.name,
          'timezone': draft.timezone,
          'timezoneSource': draft.timezoneSource.name,
          'encrypted': false,
          'ownerParticipantId': ownerId.value,
          'createdAt': createdAt,
          'createdBy': ownerId.value,
        },
      );
      // In phase 1 the only participant is the user, as owner (PRD 8.3).
      await _store.create(
        entity: EntityKinds.participant,
        id: ownerId,
        tripId: tripId,
        fields: {
          'tripId': tripId.value,
          'profileId': profileId.value,
          'displayName': '',
          'role': ParticipantRole.owner.name,
          'color': 0xFF0B6E63,
          'createdAt': createdAt,
          'createdBy': ownerId.value,
        },
      );
      await _store.create(
        entity: EntityKinds.segment,
        id: EntityId.generate(),
        tripId: tripId,
        fields: {
          'tripId': tripId.value,
          'type': draft.type.name,
          'startDayIndex': 1,
          'vehicleKind': draft.type == SegmentType.roadtrip
              ? draft.vehicleKind?.name
              : null,
          'stopPlanning': StopPlanning.manual.name,
          'createdAt': createdAt,
          'createdBy': ownerId.value,
        },
      );
      for (var index = 1; index <= draft.dayCount; index++) {
        await _createDay(
          tripId: tripId,
          index: index,
          date: TripDays.dateOf(draft.startDate, index),
          timezone: draft.timezone,
          timezoneSource: draft.timezoneSource,
          createdAt: createdAt,
          createdBy: ownerId,
        );
      }
      return tripId;
    });
  }

  /// The trips on this device, by name.
  Future<List<TripSummary>> trips() async {
    final trips = [
      for (final trip in await _store.list(EntityKinds.trip)) _toTrip(trip),
    ];
    return trips
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// One trip; null if it does not exist or was deleted.
  Future<TripSummary?> trip(EntityId tripId) async {
    final stored = await _store.read(tripId);
    return stored == null || stored.isDeleted ? null : _toTrip(stored);
  }

  /// The days of a trip, in order.
  Future<List<DaySummary>> days(EntityId tripId) async {
    final days = [
      for (final day in await _store.list(EntityKinds.day, tripId: tripId))
        DaySummary(
          id: day.id,
          index: day.fields['index']! as int,
          date: _date(day.fields['date']),
          timezone: day.fields['timezone']! as String,
          timezoneSource: _source(day.fields['timezoneSource']),
        ),
    ];
    return days..sort((a, b) => a.index.compareTo(b.index));
  }

  /// The segments of a trip, in order.
  Future<List<SegmentInfo>> segments(EntityId tripId) async {
    final segments = [
      for (final s in await _store.list(EntityKinds.segment, tripId: tripId))
        SegmentInfo(
          id: s.id,
          type: SegmentType.values.byName(s.fields['type']! as String),
          startDayIndex: s.fields['startDayIndex']! as int,
          vehicleKind: switch (s.fields['vehicleKind']) {
            final String name => VehicleKind.values.byName(name),
            _ => null,
          },
        ),
    ];
    return segments..sort((a, b) => a.startDayIndex.compareTo(b.startDayIndex));
  }

  /// Works out what changing the dates of a trip would do, without doing it:
  /// the app shows the plan and asks when stops would be removed (F1.1).
  Future<DayChangePlan> planDateChange(
    EntityId tripId, {
    required LocalDate? startDate,
    required int dayCount,
  }) async => TripDays.planChange(
    existing: [
      for (final day in await days(tripId))
        DayInfo(
          id: day.id,
          index: day.index,
          date: day.date,
          stopCount: (await _slotsOf(day.id)).length,
        ),
    ],
    newStart: startDate,
    newCount: dayCount,
  );

  /// Changes the dates or the length of a trip.
  ///
  /// [removedStops] says what to do with the stops of the days that are
  /// removed. Throws a [StateError] if there are such stops and no choice
  /// was made: the app must ask first.
  Future<void> changeDates(
    EntityId tripId, {
    required LocalDate? startDate,
    required int dayCount,
    RemovedStopsChoice? removedStops,
    DateTime? now,
  }) => _store.atomically(() async {
    final plan = await planDateChange(
      tripId,
      startDate: startDate,
      dayCount: dayCount,
    );
    if (plan.needsDecision && removedStops == null) {
      throw StateError('Stops would be removed: a choice is needed');
    }
    final trip = (await _store.read(tripId))!;
    final existing = await days(tripId);

    if (plan.removed.isNotEmpty) {
      final target = existing.firstWhere((day) => day.index == dayCount);
      var lastKey = _lastKey(await _slotsOf(target.id));
      for (final day in plan.removed) {
        for (final slot in await _slotsOf(day.id)) {
          if (removedStops == RemovedStopsChoice.moveToLastDay) {
            lastKey = FractionalIndex.between(lastKey, null);
            await _store.set(slot.id, {
              'dayId': target.id.value,
              'orderKey': lastKey,
            });
          } else {
            for (final stop in await _store.list(
              EntityKinds.stop,
              parentId: slot.id,
            )) {
              await _store.delete(stop.id);
            }
            await _store.delete(slot.id);
          }
        }
        await _store.delete(day.id);
      }
      // A segment that started in a removed day no longer has any day.
      for (final segment in await segments(tripId)) {
        if (segment.startDayIndex > dayCount) await _store.delete(segment.id);
      }
    }
    for (final (:id, :date) in plan.redated) {
      await _store.set(id, {'date': date?.toIso()});
    }
    final createdAt = (now ?? DateTime.now()).toUtc().toIso8601String();
    for (final (:index, :date) in plan.added) {
      await _createDay(
        tripId: tripId,
        index: index,
        date: date,
        timezone: trip.fields['timezone']! as String,
        timezoneSource: _source(trip.fields['timezoneSource']),
        createdAt: createdAt,
        createdBy: EntityId(trip.fields['ownerParticipantId']! as String),
      );
    }
    await _store.set(tripId, {
      'startDate': startDate?.toIso(),
      'endDate': TripDays.dateOf(startDate, dayCount)?.toIso(),
      'dayCount': dayCount,
    });
  });

  /// Sets the kind of the trip from day number [dayIndex] on (flow FL8).
  /// Setting it back to the kind of the days before undoes the change.
  Future<void> changeTypeFromDay(
    EntityId tripId, {
    required int dayIndex,
    required SegmentType type,
    VehicleKind? vehicleKind,
    DateTime? now,
  }) => _store.atomically(() async {
    final change = Segments.changeFromDay(
      segments: await segments(tripId),
      dayIndex: dayIndex,
      type: type,
      vehicleKind: vehicleKind,
    );
    for (final id in change.delete) {
      await _store.delete(id);
    }
    if (change.update case (:final id, :final type, :final vehicleKind)) {
      await _store.set(id, {
        'type': type.name,
        'vehicleKind': vehicleKind?.name,
      });
    }
    if (change.create case (
      :final startDayIndex,
      :final type,
      :final vehicleKind,
    )) {
      final trip = (await _store.read(tripId))!;
      await _store.create(
        entity: EntityKinds.segment,
        id: EntityId.generate(),
        tripId: tripId,
        fields: {
          'tripId': tripId.value,
          'type': type.name,
          'startDayIndex': startDayIndex,
          'vehicleKind': vehicleKind?.name,
          'stopPlanning': StopPlanning.manual.name,
          'createdAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
          'createdBy': trip.fields['ownerParticipantId'],
        },
      );
    }
  });

  /// Sets by hand the time zone of a trip. Days that still had the zone of
  /// the device follow; days whose zone was chosen by hand keep theirs.
  Future<void> setTripTimezone(EntityId tripId, String timezone) =>
      _store.atomically(() async {
        await _store.set(tripId, {
          'timezone': timezone,
          'timezoneSource': TimezoneSource.user.name,
        });
        for (final day in await days(tripId)) {
          if (day.timezoneSource != TimezoneSource.device) continue;
          await _store.set(day.id, {
            'timezone': timezone,
            'timezoneSource': TimezoneSource.user.name,
          });
        }
      });

  /// Sets by hand the time zone of one day.
  Future<void> setDayTimezone(EntityId dayId, String timezone) => _store.set(
    dayId,
    {'timezone': timezone, 'timezoneSource': TimezoneSource.user.name},
  );

  Future<void> _createDay({
    required EntityId tripId,
    required int index,
    required LocalDate? date,
    required String timezone,
    required TimezoneSource timezoneSource,
    required String createdAt,
    required EntityId createdBy,
  }) => _store.create(
    entity: EntityKinds.day,
    id: EntityId.generate(),
    tripId: tripId,
    fields: {
      'tripId': tripId.value,
      'index': index,
      'date': date?.toIso(),
      'timezone': timezone,
      'timezoneSource': timezoneSource.name,
      'createdAt': createdAt,
      'createdBy': createdBy.value,
    },
  );

  /// The local profile of the user, created the first time it is needed.
  /// Its name is asked only when it matters (PRD 7.6).
  Future<EntityId> _localProfileId(String createdAt) async {
    final profiles = await _store.list(EntityKinds.profile);
    if (profiles.isNotEmpty) {
      return (profiles..sort((a, b) => a.id.value.compareTo(b.id.value)))
          .first
          .id;
    }
    final id = EntityId.generate();
    await _store.create(
      entity: EntityKinds.profile,
      id: id,
      fields: {'displayName': '', 'createdAt': createdAt},
    );
    return id;
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

  static String? _lastKey(List<StoredEntity> slots) =>
      slots.isEmpty ? null : slots.last.fields['orderKey']! as String;

  static TripSummary _toTrip(StoredEntity trip) => TripSummary(
    id: trip.id,
    name: switch (trip.fields['name']) {
      final String name => name,
      _ => '',
    },
    dayCount: switch (trip.fields['dayCount']) {
      final int count => count,
      _ => 1,
    },
    startDate: _date(trip.fields['startDate']),
    destinations: [
      if (trip.fields['destinations'] case final List<Object?> places)
        for (final place in places)
          if (place case {'name': final String name}) name,
    ],
    timezone: switch (trip.fields['timezone']) {
      final String zone => zone,
      _ => null,
    },
    timezoneSource: _source(trip.fields['timezoneSource']),
  );

  static LocalDate? _date(Object? value) =>
      value is String ? LocalDate.parse(value) : null;

  static TimezoneSource _source(Object? value) =>
      TimezoneSource.values.asNameMap()[value] ?? TimezoneSource.device;
}
