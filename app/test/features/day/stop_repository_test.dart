// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/database/data_database.dart';
import 'package:itinerea/core/database/entity_store.dart';
import 'package:itinerea/core/models/entity_kinds.dart';
import 'package:itinerea/core/models/ids.dart';
import 'package:itinerea/core/models/money.dart';
import 'package:itinerea/core/models/place.dart';
import 'package:itinerea/core/models/stop.dart';
import 'package:itinerea/core/sync/fractional_index.dart';
import 'package:itinerea/features/day/stop_repository.dart';

void main() {
  group('a key for a new position (FractionalIndex.planInsert)', () {
    List<({String id, String key})> items(Map<String, String> keysById) => [
      for (final MapEntry(key: id, value: key) in keysById.entries)
        (id: id, key: key),
    ];

    test('between two different keys changes nothing else', () {
      final plan = FractionalIndex.planInsert(
        items({'a': 'G', 'b': 'V', 'c': 'k'}),
        1,
      );

      expect(plan.key.compareTo('G'), isPositive);
      expect(plan.key.compareTo('V'), isNegative);
      expect(plan.rekeyed, isEmpty);
    });

    test('at the start and at the end of a list', () {
      final list = items({'a': 'G', 'b': 'V'});

      expect(
        FractionalIndex.planInsert(list, 0).key.compareTo('G'),
        isNegative,
      );
      expect(
        FractionalIndex.planInsert(list, 2).key.compareTo('V'),
        isPositive,
      );
      expect(FractionalIndex.planInsert(const [], 0).rekeyed, isEmpty);
    });

    test('between two equal keys gives a new key to the item after', () {
      // "b" and "c" got the same key on two devices that were offline.
      final list = items({'a': 'G', 'b': 'V', 'c': 'V', 'd': 'k'});

      final plan = FractionalIndex.planInsert(list, 2);

      expect(plan.rekeyed.keys, ['c']);
      final keys = {
        'a': 'G',
        'b': 'V',
        'new': plan.key,
        'c': plan.rekeyed['c']!,
        'd': 'k',
      };
      final ordered = keys.keys.toList()
        ..sort((x, y) => FractionalIndex.compare(keys[x]!, x, keys[y]!, y));
      expect(ordered, ['a', 'b', 'new', 'c', 'd']);
      expect(keys.values.toSet(), hasLength(5), reason: 'all keys differ now');
    });

    test('before a run of three equal keys rekeys the whole run, in order', () {
      final list = items({'a': 'V', 'b': 'V', 'c': 'V', 'd': 'V'});

      final plan = FractionalIndex.planInsert(list, 1);

      expect(plan.rekeyed.keys, ['b', 'c', 'd']);
      final after = [
        'V',
        plan.key,
        plan.rekeyed['b']!,
        plan.rekeyed['c']!,
        plan.rekeyed['d']!,
      ];
      expect(after, [...after]..sort());
      expect(after.toSet(), hasLength(5));
    });

    test('refuses a position outside the list', () {
      expect(
        () => FractionalIndex.planInsert(items({'a': 'G'}), 2),
        throwsRangeError,
      );
    });
  });

  group('stops of a day (F1.2)', () {
    late DataDatabase db;
    late EntityStore store;
    late StopRepository stops;
    final trip = EntityId.generate();
    final day = EntityId.generate();
    final otherDay = EntityId.generate();

    setUp(() async {
      db = DataDatabase(NativeDatabase.memory());
      store = await EntityStore.open(db);
      stops = StopRepository(store);
    });

    tearDown(() => db.close());

    Future<EntityId> add(String name, {EntityId? to, int? index}) =>
        stops.addStop(tripId: trip, dayId: to ?? day, name: name, index: index);

    Future<List<String>> names([EntityId? of]) async => [
      for (final stop in await stops.stopsOfDay(of ?? day)) stop.name,
    ];

    Future<DayStop> stopOf(EntityId slotId) async =>
        (await stops.stopsOfDay(day)).firstWhere((s) => s.slotId == slotId);

    test('a free stop has a name, one hour and nothing else', () async {
      final slot = await add('  Pranzo  ');

      final stop = await stopOf(slot);

      expect(stop.name, 'Pranzo');
      expect(stop.kind, StopKind.free);
      expect(stop.durationMin, 60);
      expect(stop.status, StopStatus.planned);
      expect(stop.place, isNull);
      expect(stop.plan, Plan.a);
      expect(stop.planCount, 1);
      expect(stop.timeFixed, isFalse);
      expect(stop.note, isEmpty);
    });

    test('a stop with a place keeps a copy of the place', () async {
      final slot = await stops.addStop(
        tripId: trip,
        dayId: day,
        name: 'Uffizi',
        place: const PlaceSnapshot(
          name: 'Galleria degli Uffizi',
          coordinates: Coordinates(lat: 43.7687, lon: 11.2553),
          openingHours: 'Tu-Su 08:15-18:30',
        ),
      );

      final stop = await stopOf(slot);

      expect(stop.kind, StopKind.place);
      expect(stop.place!.openingHours, 'Tu-Su 08:15-18:30');
      expect(stop.place!.coordinates!.lat, 43.7687);
    });

    test('new stops go to the end of the day, or where asked', () async {
      await add('Uffizi');
      await add('Duomo');
      await add('Pranzo', index: 1);
      await add('Colazione', index: 0);

      expect(await names(), ['Colazione', 'Uffizi', 'Pranzo', 'Duomo']);
    });

    test('a stop without a name is refused and writes nothing', () async {
      expect(() => add('   '), throwsArgumentError);

      expect(await stops.stopsOfDay(day), isEmpty);
      expect(await store.pendingOperations(), isEmpty);
    });

    test('name, duration, status, cost and links can be changed', () async {
      final stop = await stopOf(await add('Uffizi'));

      await stops.rename(stop.stopId, 'Galleria degli Uffizi');
      await stops.setDuration(stop.stopId, 150);
      await stops.setStatus(stop.stopId, StopStatus.visited);
      await stops.setEstimatedCost(
        stop.stopId,
        const Money(amountMinor: 2500, currency: 'EUR'),
      );
      await stops.setLinks(stop.stopId, [Uri.parse('https://www.uffizi.it/')]);

      final changed = await stopOf(stop.slotId);
      expect(changed.name, 'Galleria degli Uffizi');
      expect(changed.durationMin, 150);
      expect(changed.status, StopStatus.visited);
      expect(changed.estimatedCost!.amountMinor, 2500);
      expect(changed.estimatedCost!.currency, 'EUR');
      expect(changed.links, [Uri.parse('https://www.uffizi.it/')]);
    });

    test('marking as visited records when; un-marking clears it', () async {
      final stop = await stopOf(await add('Uffizi'));
      final at = DateTime.utc(2026, 3, 12, 11, 30);

      await stops.setStatus(stop.stopId, StopStatus.visited, now: at);
      expect(
        (await store.read(stop.stopId))!.fields['visitedAt'],
        '2026-03-12T11:30:00.000Z',
      );

      await stops.setStatus(stop.stopId, StopStatus.planned);
      expect((await store.read(stop.stopId))!.fields['visitedAt'], isNull);
    });

    test('invalid values are refused', () async {
      final stop = await stopOf(await add('Uffizi'));

      expect(() => stops.rename(stop.stopId, ' '), throwsArgumentError);
      expect(() => stops.setDuration(stop.stopId, -5), throwsArgumentError);
      expect(
        () => stops.setDuration(stop.stopId, 24 * 60 + 1),
        throwsArgumentError,
      );
      expect(
        () => stops.setEstimatedCost(
          stop.stopId,
          const Money(amountMinor: -1, currency: 'EUR'),
        ),
        throwsArgumentError,
      );
      for (final link in ['javascript:alert(1)', 'file:///etc/passwd', 'x']) {
        expect(
          () => stops.setLinks(stop.stopId, [Uri.parse(link)]),
          throwsArgumentError,
          reason: link,
        );
      }
    });

    test('the estimated cost can be cleared', () async {
      final stop = await stopOf(await add('Uffizi'));
      await stops.setEstimatedCost(
        stop.stopId,
        const Money(amountMinor: 2500, currency: 'EUR'),
      );

      await stops.setEstimatedCost(stop.stopId, null);

      expect((await stopOf(stop.slotId)).estimatedCost, isNull);
    });

    test('a note is created the first time and then updated', () async {
      final stop = await stopOf(await add('Uffizi'));

      await stops.setNote(
        tripId: trip,
        stopId: stop.stopId,
        text: 'Ingresso 2',
      );
      await stops.setNote(
        tripId: trip,
        stopId: stop.stopId,
        text: 'Ingresso 2, portare il documento',
      );

      expect(
        (await stopOf(stop.slotId)).note,
        'Ingresso 2, portare il documento',
      );
      expect(await store.list(EntityKinds.note, tripId: trip), hasLength(1));
    });

    test('an empty note creates nothing', () async {
      final stop = await stopOf(await add('Uffizi'));

      await stops.setNote(tripId: trip, stopId: stop.stopId, text: '');

      expect(await store.list(EntityKinds.note, tripId: trip), isEmpty);
    });

    group('reordering and moving', () {
      late EntityId uffizi;
      late EntityId pranzo;
      late EntityId duomo;

      setUp(() async {
        uffizi = await add('Uffizi');
        pranzo = await add('Pranzo');
        duomo = await add('Duomo');
      });

      test('a stop can move to any position of its day', () async {
        await stops.moveStop(duomo, toDayId: day, toIndex: 0);
        expect(await names(), ['Duomo', 'Uffizi', 'Pranzo']);

        await stops.moveStop(duomo, toDayId: day, toIndex: 1);
        expect(await names(), ['Uffizi', 'Duomo', 'Pranzo']);

        await stops.moveStop(uffizi, toDayId: day, toIndex: 2);
        expect(await names(), ['Duomo', 'Pranzo', 'Uffizi']);
      });

      test('moving writes one change: only the moved stop', () async {
        final before = (await store.pendingOperations()).length;

        await stops.moveStop(duomo, toDayId: day, toIndex: 0);

        final written = (await store.pendingOperations()).skip(before);
        expect(written.map((op) => op.entityId), [duomo]);
        expect(written.single.fields.keys, {'dayId', 'orderKey'});
      });

      test('a stop moves to another day and leaves the first', () async {
        await add('Siena', to: otherDay);

        await stops.moveStop(pranzo, toDayId: otherDay, toIndex: 0);

        expect(await names(), ['Uffizi', 'Duomo']);
        expect(await names(otherDay), ['Pranzo', 'Siena']);
      });

      test('moving to where it already is keeps the order', () async {
        await stops.moveStop(pranzo, toDayId: day, toIndex: 1);

        expect(await names(), ['Uffizi', 'Pranzo', 'Duomo']);
      });

      test('a position past the end means the end', () async {
        await stops.moveStop(uffizi, toDayId: day, toIndex: 99);

        expect(await names(), ['Pranzo', 'Duomo', 'Uffizi']);
      });

      test('a stop can be put between two stops that share a key', () async {
        // Two devices inserted at the same place while offline: same key.
        final slots = await store.list(EntityKinds.stopSlot, parentId: day);
        final sharedKey = slots
            .firstWhere((slot) => slot.id == pranzo)
            .fields['orderKey'];
        await store.set(duomo, {'orderKey': sharedKey});
        final twins = [pranzo, duomo]
          ..sort((a, b) => a.value.compareTo(b.value));
        final nameOf = {uffizi: 'Uffizi', pranzo: 'Pranzo', duomo: 'Duomo'};
        expect(await names(), ['Uffizi', nameOf[twins[0]], nameOf[twins[1]]]);

        // Uffizi goes between the two twins.
        await stops.moveStop(uffizi, toDayId: day, toIndex: 1);

        expect(await names(), [nameOf[twins[0]], 'Uffizi', nameOf[twins[1]]]);
        final keys = [
          for (final stop in await stops.stopsOfDay(day)) stop.orderKey,
        ];
        expect(keys.toSet(), hasLength(3), reason: 'the tie is gone');
        expect(keys, [...keys]..sort());
      });
    });

    group('deleting and restoring (PRD 9.5)', () {
      test('a deleted stop leaves the day', () async {
        await add('Uffizi');
        final pranzo = await add('Pranzo');

        await stops.deleteStop(pranzo);

        expect(await names(), ['Uffizi']);
        expect(await store.list(EntityKinds.stop, tripId: trip), hasLength(1));
      });

      test('"Restore" puts it back where it was, as it was', () async {
        await add('Uffizi');
        final pranzo = await add('Pranzo');
        await add('Duomo');
        final stop = await stopOf(pranzo);
        await stops.setDuration(stop.stopId, 90);
        await stops.setNote(
          tripId: trip,
          stopId: stop.stopId,
          text: 'Lampredotto',
        );
        await stops.deleteStop(pranzo);

        await stops.restoreStop(pranzo);

        expect(await names(), ['Uffizi', 'Pranzo', 'Duomo']);
        final restored = await stopOf(pranzo);
        expect(restored.durationMin, 90);
        expect(restored.note, 'Lampredotto');
      });

      test('only a deleted stop can be restored', () async {
        final uffizi = await add('Uffizi');

        expect(() => stops.restoreStop(uffizi), throwsStateError);
        expect(() => stops.restoreStop(EntityId.generate()), throwsStateError);
      });

      test('a restored stop can be deleted and restored again', () async {
        final uffizi = await add('Uffizi');

        for (var round = 0; round < 3; round++) {
          await stops.deleteStop(uffizi);
          expect(await names(), isEmpty);
          await stops.restoreStop(uffizi);
          expect(await names(), ['Uffizi']);
        }
      });

      test('"Restore" does not bring back a plan removed earlier', () async {
        final uffizi = await add('Uffizi');
        // A second plan for the same position, removed before the stop.
        final planB = EntityId.generate();
        await store.create(
          entity: EntityKinds.stop,
          id: planB,
          tripId: trip,
          fields: {'slotId': uffizi.value, 'plan': 'b', 'name': 'Bargello'},
        );
        await store.delete(planB);

        await stops.deleteStop(uffizi);
        await stops.restoreStop(uffizi);

        expect((await store.read(planB))!.isDeleted, isTrue);
        expect((await stopOf(uffizi)).planCount, 1);
      });
    });

    test('a position whose stop has not arrived yet is not shown', () async {
      await add('Uffizi');
      // Another device created a position; its stop is still on the way.
      await store.create(
        entity: EntityKinds.stopSlot,
        id: EntityId.generate(),
        tripId: trip,
        fields: {'dayId': day.value, 'orderKey': 'z', 'activePlan': 'a'},
      );

      expect(await names(), ['Uffizi']);
    });

    test('shows the stop of the active plan and counts the plans', () async {
      final uffizi = await add('Uffizi');
      await store.create(
        entity: EntityKinds.stop,
        id: EntityId.generate(),
        tripId: trip,
        fields: {'slotId': uffizi.value, 'plan': 'b', 'name': 'Bargello'},
      );

      expect((await stopOf(uffizi)).planCount, 2);
      expect(await names(), ['Uffizi']);

      await store.set(uffizi, {'activePlan': 'b'});

      expect(await names(), ['Bargello']);
    });
  });
}
