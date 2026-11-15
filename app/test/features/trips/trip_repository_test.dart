// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/database/data_database.dart';
import 'package:itinerea/core/database/entity_store.dart';
import 'package:itinerea/core/models/entity_kinds.dart';
import 'package:itinerea/core/models/ids.dart';
import 'package:itinerea/core/models/time.dart';
import 'package:itinerea/core/models/trip.dart';
import 'package:itinerea/core/sync/fractional_index.dart';
import 'package:itinerea/features/trips/trip_plan.dart';
import 'package:itinerea/features/trips/trip_repository.dart';

void main() {
  late DataDatabase db;
  late EntityStore store;
  late TripRepository repository;

  final start = LocalDate(2026, 3, 12);

  setUp(() async {
    db = DataDatabase(NativeDatabase.memory());
    store = await EntityStore.open(db);
    repository = TripRepository(store);
  });

  tearDown(() => db.close());

  TripDraft draft({
    String name = 'Toscana in moto',
    int dayCount = 4,
    LocalDate? startDate,
    SegmentType type = SegmentType.itinerary,
    VehicleKind? vehicleKind,
  }) => TripDraft(
    type: type,
    vehicleKind: vehicleKind,
    name: name,
    destinations: const ['Firenze', ' Siena ', ''],
    dayCount: dayCount,
    startDate: startDate,
    departure: 'Milano',
    timezone: 'Europe/Rome',
    currency: 'EUR',
  );

  /// Adds a stop to [day] at the end and returns the identifier of its slot.
  Future<EntityId> addStop(EntityId tripId, DaySummary day, String name) async {
    final existing = await store.list(EntityKinds.stopSlot, parentId: day.id);
    final keys = [
      for (final slot in existing) slot.fields['orderKey']! as String,
    ]..sort();
    final slot = EntityId.generate();
    await store.create(
      entity: EntityKinds.stopSlot,
      id: slot,
      tripId: tripId,
      fields: {
        'dayId': day.id.value,
        'orderKey': FractionalIndex.between(keys.lastOrNull, null),
      },
    );
    await store.create(
      entity: EntityKinds.stop,
      id: EntityId.generate(),
      tripId: tripId,
      fields: {'slotId': slot.value, 'name': name},
    );
    return slot;
  }

  Future<List<String>> stopNames(DaySummary day) async {
    final slots = await store.list(EntityKinds.stopSlot, parentId: day.id);
    slots.sort(
      (a, b) => FractionalIndex.compare(
        a.fields['orderKey']! as String,
        a.id.value,
        b.fields['orderKey']! as String,
        b.id.value,
      ),
    );
    return [
      for (final slot in slots)
        for (final stop in await store.list(
          EntityKinds.stop,
          parentId: slot.id,
        ))
          stop.fields['name']! as String,
    ];
  }

  group('creating a trip (F1.1)', () {
    test('creates the trip with its days, one segment and its owner', () async {
      final id = await repository.createTrip(
        draft(
          startDate: start,
          type: SegmentType.roadtrip,
          vehicleKind: VehicleKind.motorbike,
        ),
      );

      final trip = (await repository.trip(id))!;
      final days = await repository.days(id);
      final segments = await repository.segments(id);
      final owners = await store.list(EntityKinds.participant, tripId: id);

      expect(trip.name, 'Toscana in moto');
      expect(trip.destinations, ['Firenze', 'Siena']);
      expect(trip.startDate, start);
      expect(trip.endDate, LocalDate(2026, 3, 15));
      expect(days.map((day) => (day.index, day.date)), [
        (1, LocalDate(2026, 3, 12)),
        (2, LocalDate(2026, 3, 13)),
        (3, LocalDate(2026, 3, 14)),
        (4, LocalDate(2026, 3, 15)),
      ]);
      expect(segments.single.type, SegmentType.roadtrip);
      expect(segments.single.vehicleKind, VehicleKind.motorbike);
      expect(segments.single.startDayIndex, 1);
      expect(owners.single.fields['role'], 'owner');
    });

    test('a trip without dates has numbered days without dates', () async {
      final id = await repository.createTrip(draft(dayCount: 3));

      final trip = (await repository.trip(id))!;
      final days = await repository.days(id);

      expect(trip.startDate, isNull);
      expect(trip.endDate, isNull);
      expect(days.map((day) => day.index), [1, 2, 3]);
      expect(days.every((day) => day.date == null), isTrue);
    });

    test(
      'stores the time zone of the device together with its origin',
      () async {
        final id = await repository.createTrip(draft());

        final trip = (await repository.trip(id))!;
        final days = await repository.days(id);

        expect(trip.timezone, 'Europe/Rome');
        expect(trip.timezoneSource, TimezoneSource.device);
        expect(days.every((day) => day.timezone == 'Europe/Rome'), isTrue);
        expect(
          days.every((day) => day.timezoneSource == TimezoneSource.device),
          isTrue,
        );
      },
    );

    test('refuses a trip without a name and writes nothing', () async {
      expect(
        () => repository.createTrip(draft(name: ' ')),
        throwsArgumentError,
      );

      expect(await repository.trips(), isEmpty);
      expect(await store.pendingOperations(), isEmpty);
    });

    test('uses one local profile for every trip, with no account', () async {
      final first = await repository.createTrip(draft(name: 'A'));
      final second = await repository.createTrip(draft(name: 'B'));

      final profiles = await store.list(EntityKinds.profile);
      final owners = [
        ...await store.list(EntityKinds.participant, tripId: first),
        ...await store.list(EntityKinds.participant, tripId: second),
      ];

      expect(profiles, hasLength(1));
      expect(profiles.single.tripId, isNull, reason: 'personal data');
      expect(owners.map((owner) => owner.fields['profileId']).toSet(), {
        profiles.single.id.value,
      });
    });

    test('lists trips by name', () async {
      await repository.createTrip(draft(name: 'toscana'));
      await repository.createTrip(draft(name: 'Giappone'));

      expect((await repository.trips()).map((trip) => trip.name), [
        'Giappone',
        'toscana',
      ]);
    });

    test(
      'every operation of a trip belongs to the space of that trip',
      () async {
        final id = await repository.createTrip(draft(dayCount: 2));

        final ofTrip = await store.pendingOperations(space: id.value);
        final personal = await store.pendingOperations(
          space: EntityStore.personalSpace,
        );

        // Trip, owner, segment and two days; the profile is personal data.
        expect(ofTrip, hasLength(5));
        expect(personal.map((operation) => operation.entity), ['Profile']);
      },
    );
  });

  group('changing the dates (F1.1)', () {
    test('giving dates to a trip keeps every stop in its day', () async {
      final id = await repository.createTrip(draft(dayCount: 3));
      var days = await repository.days(id);
      await addStop(id, days[0], 'Uffizi');
      await addStop(id, days[2], 'Siena');

      await repository.changeDates(id, startDate: start, dayCount: 3);

      days = await repository.days(id);
      expect(days.map((day) => day.date), [
        LocalDate(2026, 3, 12),
        LocalDate(2026, 3, 13),
        LocalDate(2026, 3, 14),
      ]);
      expect(await stopNames(days[0]), ['Uffizi']);
      expect(await stopNames(days[2]), ['Siena']);
      expect((await repository.trip(id))!.endDate, LocalDate(2026, 3, 14));
    });

    test('a longer trip gets new empty days at the end', () async {
      final id = await repository.createTrip(
        draft(startDate: start, dayCount: 2),
      );

      await repository.changeDates(id, startDate: start, dayCount: 4);

      final days = await repository.days(id);
      expect(days.map((day) => day.index), [1, 2, 3, 4]);
      expect(days.last.date, LocalDate(2026, 3, 15));
      expect(days.last.timezone, 'Europe/Rome');
      expect((await repository.trip(id))!.dayCount, 4);
    });

    test(
      'removing days with stops is refused until the user chooses',
      () async {
        final id = await repository.createTrip(
          draft(startDate: start, dayCount: 3),
        );
        final days = await repository.days(id);
        await addStop(id, days[2], 'Siena');

        final plan = await repository.planDateChange(
          id,
          startDate: start,
          dayCount: 2,
        );
        expect(plan.needsDecision, isTrue);
        expect(plan.stopsInRemovedDays, 1);
        await expectLater(
          repository.changeDates(id, startDate: start, dayCount: 2),
          throwsStateError,
        );

        // Nothing changed.
        expect(await repository.days(id), hasLength(3));
        expect((await repository.trip(id))!.dayCount, 3);
      },
    );

    test(
      '"move": the stops of removed days go to the end of the last day',
      () async {
        final id = await repository.createTrip(
          draft(startDate: start, dayCount: 4),
        );
        var days = await repository.days(id);
        await addStop(id, days[1], 'Duomo');
        await addStop(id, days[2], 'San Gimignano');
        await addStop(id, days[2], 'Volterra');
        await addStop(id, days[3], 'Siena');

        await repository.changeDates(
          id,
          startDate: start,
          dayCount: 2,
          removedStops: RemovedStopsChoice.moveToLastDay,
        );

        days = await repository.days(id);
        expect(days, hasLength(2));
        expect(await stopNames(days[1]), [
          'Duomo',
          'San Gimignano',
          'Volterra',
          'Siena',
        ]);
      },
    );

    test('"delete": the stops of removed days go with their days', () async {
      final id = await repository.createTrip(
        draft(startDate: start, dayCount: 3),
      );
      var days = await repository.days(id);
      await addStop(id, days[0], 'Uffizi');
      final removedSlot = await addStop(id, days[2], 'Siena');

      await repository.changeDates(
        id,
        startDate: start,
        dayCount: 2,
        removedStops: RemovedStopsChoice.delete,
      );

      days = await repository.days(id);
      expect(days, hasLength(2));
      expect(await stopNames(days[0]), ['Uffizi']);
      expect((await store.read(removedSlot))!.isDeleted, isTrue);
      expect(await store.list(EntityKinds.stop, tripId: id), hasLength(1));
    });

    test('a segment that started in a removed day is removed too', () async {
      final id = await repository.createTrip(
        draft(startDate: start, dayCount: 5),
      );
      await repository.changeTypeFromDay(
        id,
        dayIndex: 4,
        type: SegmentType.roadtrip,
        vehicleKind: VehicleKind.car,
      );

      await repository.changeDates(id, startDate: start, dayCount: 3);

      expect((await repository.segments(id)).map((s) => s.startDayIndex), [1]);
    });

    test('a refused change leaves the trip exactly as it was', () async {
      final id = await repository.createTrip(
        draft(startDate: start, dayCount: 3),
      );
      final before = await store.pendingOperations();

      await expectLater(
        repository.changeDates(id, startDate: start, dayCount: 0),
        throwsArgumentError,
      );

      expect(await store.pendingOperations(), hasLength(before.length));
    });
  });

  group('kind of trip from a day on (FL8)', () {
    test(
      'a mixed trip shows roadtrip functions only in roadtrip days',
      () async {
        final id = await repository.createTrip(draft(dayCount: 6));

        await repository.changeTypeFromDay(
          id,
          dayIndex: 5,
          type: SegmentType.roadtrip,
          vehicleKind: VehicleKind.motorbike,
        );

        final segments = await repository.segments(id);
        expect(segments.map((s) => (s.startDayIndex, s.type)), [
          (1, SegmentType.itinerary),
          (5, SegmentType.roadtrip),
        ]);
        expect(
          [
            for (var day = 1; day <= 6; day++)
              Segments.isRoadtripDay(segments, day),
          ],
          [false, false, false, false, true, true],
        );
      },
    );

    test(
      'putting the previous kind back leaves one segment, as before',
      () async {
        final id = await repository.createTrip(draft(dayCount: 6));
        await repository.changeTypeFromDay(
          id,
          dayIndex: 5,
          type: SegmentType.roadtrip,
          vehicleKind: VehicleKind.car,
        );

        await repository.changeTypeFromDay(
          id,
          dayIndex: 5,
          type: SegmentType.itinerary,
        );

        final segments = await repository.segments(id);
        expect(segments.map((s) => (s.startDayIndex, s.type)), [
          (1, SegmentType.itinerary),
        ]);
      },
    );
  });

  group('time zone (PRD 8.3)', () {
    test(
      'a zone chosen for the trip reaches the days that had the device one',
      () async {
        final id = await repository.createTrip(draft(dayCount: 3));
        final dayTwo = (await repository.days(id))[1];
        await repository.setDayTimezone(dayTwo.id, 'Asia/Tokyo');

        await repository.setTripTimezone(id, 'Europe/Dublin');

        final trip = (await repository.trip(id))!;
        final days = await repository.days(id);
        expect(trip.timezone, 'Europe/Dublin');
        expect(trip.timezoneSource, TimezoneSource.user);
        expect(days.map((day) => day.timezone), [
          'Europe/Dublin',
          'Asia/Tokyo',
          'Europe/Dublin',
        ]);
        expect(
          days.every((day) => day.timezoneSource == TimezoneSource.user),
          isTrue,
        );
      },
    );

    test('days added later take the zone of the trip and its origin', () async {
      final id = await repository.createTrip(draft(dayCount: 1));
      await repository.setTripTimezone(id, 'Europe/Dublin');

      await repository.changeDates(id, startDate: null, dayCount: 2);

      final added = (await repository.days(id)).last;
      expect(added.timezone, 'Europe/Dublin');
      expect(added.timezoneSource, TimezoneSource.user);
    });
  });

  group('where a trip stands today', () {
    final trip = TripSummary(
      id: EntityId.generate(),
      name: 'Toscana',
      startDate: LocalDate(2026, 3, 12),
      dayCount: 4,
    );

    test('upcoming, current on its first and last day, then past', () {
      expect(trip.phaseOn(LocalDate(2026, 3, 11)), TripPhase.upcoming);
      expect(trip.phaseOn(LocalDate(2026, 3, 12)), TripPhase.current);
      expect(trip.phaseOn(LocalDate(2026, 3, 15)), TripPhase.current);
      expect(trip.phaseOn(LocalDate(2026, 3, 16)), TripPhase.past);
    });

    test('a trip without dates has no phase', () {
      final undated = TripSummary(id: EntityId.generate(), name: 'Someday');

      expect(undated.phaseOn(LocalDate(2026, 3, 12)), isNull);
    });
  });
}
