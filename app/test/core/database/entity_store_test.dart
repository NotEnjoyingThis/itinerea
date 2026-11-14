// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/database/data_database.dart';
import 'package:itinerea/core/database/entity_store.dart';
import 'package:itinerea/core/models/ids.dart';
import 'package:itinerea/core/sync/hlc.dart';
import 'package:itinerea/core/sync/sync_engine.dart';

void main() {
  late DataDatabase db;
  late DateTime wall;
  late EntityStore store;

  final trip = EntityId.generate();
  final day = EntityId.generate();

  Future<EntityStore> open() => EntityStore.open(db, wallClock: () => wall);

  setUp(() async {
    db = DataDatabase(NativeDatabase.memory());
    wall = DateTime.utc(2026, 3, 12, 9);
    store = await open();
  });

  tearDown(() => db.close());

  Future<EntityId> createStop({
    Map<String, Object?> fields = const {'name': 'Uffizi', 'durationMin': 120},
  }) async {
    final id = EntityId.generate();
    await store.create(
      entity: 'Stop',
      id: id,
      tripId: trip,
      parentId: day,
      fields: fields,
    );
    return id;
  }

  group('this device', () {
    test('gets an identifier the first time and keeps it afterwards', () async {
      final first = store.deviceId;

      final reopened = await open();

      expect(first.isValid, isTrue);
      expect(reopened.deviceId, first);
    });

    test(
      'resumes its clock after a restart, even with an earlier time',
      () async {
        final id = await createStop();
        final before = (await store.fieldClocks(id))['name']!;

        // The app restarts and the wall clock is three hours behind.
        wall = wall.subtract(const Duration(hours: 3));
        final reopened = await open();
        await reopened.set(id, {'name': 'Galleria degli Uffizi'});

        final after = (await reopened.fieldClocks(id))['name']!;
        expect(after.compareTo(before), isPositive);
      },
    );
  });

  group('a local change', () {
    test(
      'creates the entity with its trip, its parent and its fields',
      () async {
        final id = await createStop();

        final stored = await store.read(id);

        expect(stored, isNotNull);
        expect(stored!.entity, 'Stop');
        expect(stored.tripId, trip);
        expect(stored.parentId, day);
        expect(stored.fields, {'name': 'Uffizi', 'durationMin': 120});
        expect(stored.isDeleted, isFalse);
      },
    );

    test(
      'stamps every field of a new entity with the same clock value',
      () async {
        final id = await createStop();

        final clocks = await store.fieldClocks(id);

        expect(clocks.keys, unorderedEquals(['name', 'durationMin']));
        expect(clocks.values.toSet(), hasLength(1));
        expect(HlcTimestamp.parse(clocks['name']!).deviceId, store.deviceId);
      },
    );

    test(
      'to one field leaves the other fields and their clocks alone',
      () async {
        final id = await createStop();
        final created = await store.fieldClocks(id);

        wall = wall.add(const Duration(minutes: 5));
        await store.set(id, {'durationMin': 90});

        final stored = await store.read(id);
        final clocks = await store.fieldClocks(id);
        expect(stored!.fields, {'name': 'Uffizi', 'durationMin': 90});
        expect(clocks['name'], created['name']);
        expect(
          clocks['durationMin']!.compareTo(created['durationMin']!),
          isPositive,
        );
      },
    );

    test('keeps the fields this version of the app does not know', () async {
      final id = await createStop(
        fields: {
          'name': 'Uffizi',
          'durationMin': 120,
          'fieldFromTheFuture': {'answer': 42},
        },
      );

      await store.set(id, {'name': 'Galleria degli Uffizi'});

      expect((await store.read(id))!.fields['fieldFromTheFuture'], {
        'answer': 42,
      });
    });

    test('can set a field to null without removing it', () async {
      final id = await createStop(
        fields: {'name': 'Uffizi', 'bookingId': 'booking-1'},
      );

      await store.set(id, {'bookingId': null});

      final fields = (await store.read(id))!.fields;
      expect(fields.containsKey('bookingId'), isTrue);
      expect(fields['bookingId'], isNull);
    });

    test(
      'deletes with a tombstone: the entity stays, marked as deleted',
      () async {
        final id = await createStop();

        await store.delete(id);

        final stored = await store.read(id);
        expect(stored!.isDeleted, isTrue);
        expect(stored.fields['name'], 'Uffizi');
        expect(await store.list('Stop', tripId: trip), isEmpty);
      },
    );

    test('is refused on an entity that is deleted or does not exist', () async {
      final id = await createStop();
      await store.delete(id);

      expect(() => store.set(id, {'name': 'x'}), throwsStateError);
      expect(() => store.delete(id), throwsStateError);
      expect(
        () => store.set(EntityId.generate(), {'name': 'x'}),
        throwsStateError,
      );
    });
  });

  group('listing', () {
    test('filters by kind, trip and parent', () async {
      final otherDay = EntityId.generate();
      final inDay = await createStop();
      final elsewhere = EntityId.generate();
      await store.create(
        entity: 'Stop',
        id: elsewhere,
        tripId: trip,
        parentId: otherDay,
        fields: const {'name': 'Duomo'},
      );
      await store.create(
        entity: 'Note',
        id: EntityId.generate(),
        tripId: trip,
        fields: const {'text': 'Bring the tickets'},
      );

      final ofTrip = await store.list('Stop', tripId: trip);
      final ofDay = await store.list('Stop', parentId: day);

      expect(ofTrip.map((e) => e.id), unorderedEquals([inDay, elsewhere]));
      expect(ofDay.map((e) => e.id), [inDay]);
    });
  });

  group('the log of operations', () {
    test('records each change as one operation, oldest first', () async {
      final id = await createStop();
      wall = wall.add(const Duration(seconds: 1));
      await store.set(id, {'durationMin': 90, 'status': 'visited'});
      wall = wall.add(const Duration(seconds: 1));
      await store.delete(id);

      final pending = await store.pendingOperations();

      expect(pending.map((op) => op.type), [
        OperationType.create,
        OperationType.set,
        OperationType.delete,
      ]);
      expect(pending[0].fields, {'name': 'Uffizi', 'durationMin': 120});
      expect(pending[1].fields, {'durationMin': 90, 'status': 'visited'});
      expect(pending[2].fields, isEmpty);
      for (final op in pending) {
        expect(op.entity, 'Stop');
        expect(op.entityId, id);
        expect(op.deviceId, store.deviceId);
        expect(op.schemaVersion, DataDatabase.currentSchemaVersion);
        expect(op.id.isValid, isTrue);
      }
      expect(
        pending.map((op) => op.hlc.value),
        [...pending.map((op) => op.hlc.value)]..sort(),
      );
    });

    test(
      'an operation carries the same clock value as the fields it set',
      () async {
        final id = await createStop();
        wall = wall.add(const Duration(seconds: 1));
        await store.set(id, {'durationMin': 90});

        final operation = (await store.pendingOperations()).last;
        final clocks = await store.fieldClocks(id);

        expect(operation.hlc, clocks['durationMin']);
      },
    );

    test('separates the operations of each trip from personal data', () async {
      await createStop();
      final otherTrip = EntityId.generate();
      await store.create(
        entity: 'Trip',
        id: otherTrip,
        tripId: otherTrip,
        fields: const {'name': 'Japan'},
      );
      await store.create(
        entity: 'Vehicle',
        id: EntityId.generate(),
        fields: const {'make': 'Moto Guzzi'},
      );

      expect(await store.pendingOperations(space: trip.value), hasLength(1));
      expect(
        await store.pendingOperations(space: otherTrip.value),
        hasLength(1),
      );
      expect(
        await store.pendingOperations(space: EntityStore.personalSpace),
        hasLength(1),
      );
    });

    test('operations marked as sent no longer wait', () async {
      final id = await createStop();
      await store.set(id, {'durationMin': 90});
      final pending = await store.pendingOperations();

      await store.markSent([pending.first.id], wall);

      expect((await store.pendingOperations()).map((op) => op.id), [
        pending.last.id,
      ]);
    });

    test('a change that fails leaves no trace anywhere', () async {
      final id = await createStop();
      final operationsBefore = await store.pendingOperations();

      // The same identifier cannot be created twice: the whole transaction
      // is undone, including the operation and the clocks.
      await expectLater(
        store.create(
          entity: 'Stop',
          id: id,
          tripId: trip,
          fields: const {'name': 'Twice', 'extra': true},
        ),
        throwsA(isA<Exception>()),
      );

      expect((await store.read(id))!.fields['name'], 'Uffizi');
      expect((await store.fieldClocks(id)).containsKey('extra'), isFalse);
      expect(
        await store.pendingOperations(),
        hasLength(operationsBefore.length),
      );
      final logged = await db.select(db.operationRows).get();
      expect(logged, hasLength(operationsBefore.length));
    });

    test('is stored as text that reads back as the same operation', () async {
      await createStop(
        fields: {
          'name': 'Caffè Gilli — 東京',
          'place': {
            'coordinates': {'lat': 43.7717, 'lon': 11.2541},
          },
          'links': ['https://example.org/a?b=c'],
        },
      );

      final row = await db.select(db.operationRows).getSingle();
      final operation = (await store.pendingOperations()).single;

      expect(row.type, 'create');
      expect(row.isLocal, isTrue);
      expect(row.sentAtMillis, isNull);
      expect(operation.fields['name'], 'Caffè Gilli — 東京');
      expect(
        SyncOperation.fromJson(operation.toJson()).toJson(),
        operation.toJson(),
      );
    });
  });
}
