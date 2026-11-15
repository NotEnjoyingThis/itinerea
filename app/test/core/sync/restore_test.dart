// SPDX-License-Identifier: GPL-3.0-or-later

// "Restore" of a deleted entity (PRD 9.5): as a merge rule, in the operation
// format, in the store and between simulated devices.

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/models/entity_kinds.dart';
import 'package:itinerea/core/models/ids.dart';
import 'package:itinerea/core/sync/hlc.dart';
import 'package:itinerea/core/sync/merge.dart';
import 'package:itinerea/core/sync/sync_engine.dart';

import 'simulated_devices.dart';

const _phone = EntityId('01900000-0000-7000-8000-00000000000a');
const _laptop = EntityId('01900000-0000-7000-8000-00000000000b');
const _stop = EntityId('01900000-0000-7000-8000-0000000000f1');

var _nextOperation = 0;

SyncOperation _op(
  EntityId device,
  int at,
  OperationType type, [
  Map<String, Object?> fields = const {},
]) => SyncOperation(
  id: EntityId('restore-op-${_nextOperation++}'),
  deviceId: device,
  hlc: HlcTimestamp(wallMillis: at, counter: 0, deviceId: device).text,
  schemaVersion: 2,
  entity: 'Stop',
  entityId: _stop,
  type: type,
  fields: fields,
);

EntityState _applyAll(Iterable<SyncOperation> operations) {
  EntityState? state;
  for (final operation in operations) {
    state = Merge.apply(state, operation).state;
  }
  return state!;
}

void main() {
  group('restore as a merge rule', () {
    final create = _op(_phone, 100, OperationType.create, {'name': 'Uffizi'});
    final delete = _op(_phone, 200, OperationType.delete);
    final restore = _op(_phone, 300, OperationType.restore);

    test('brings back an entity deleted before it, with its fields', () {
      final state = _applyAll([create, delete, restore]);

      expect(state.isDeleted, isFalse);
      expect(state.fields, {'name': 'Uffizi'});
    });

    test('does not undo a deletion made after it', () {
      final deletedAgain = _op(_laptop, 400, OperationType.delete);

      final state = _applyAll([create, delete, restore, deletedAgain]);

      expect(state.isDeleted, isTrue);
    });

    test('a change to a field still never undoes a deletion', () {
      final edit = _op(_laptop, 300, OperationType.set, {'name': 'Edited'});

      expect(_applyAll([create, delete, edit]).isDeleted, isTrue);
    });

    test('keeps the changes other devices made while it was deleted', () {
      final edit = _op(_laptop, 250, OperationType.set, {'durationMin': 90});

      final state = _applyAll([create, delete, edit, restore]);

      expect(state.isDeleted, isFalse);
      expect(state.fields, {'name': 'Uffizi', 'durationMin': 90});
    });

    test('on an entity that was never deleted changes nothing visible', () {
      final state = _applyAll([create, restore]);

      expect(state.isDeleted, isFalse);
      expect(state.fields, {'name': 'Uffizi'});
    });

    test('200 random histories of deletes and restores end the same in '
        'every order', () {
      final random = Random(20261115);
      for (var history = 0; history < 200; history++) {
        final operations = [
          create,
          for (var i = 0; i < 1 + random.nextInt(8); i++)
            _op(
              random.nextBool() ? _phone : _laptop,
              101 + i * 2 + (random.nextBool() ? 0 : 1),
              switch (random.nextInt(3)) {
                0 => OperationType.delete,
                1 => OperationType.restore,
                _ => OperationType.set,
              },
              {'durationMin': random.nextInt(500)},
            ),
        ];
        final expected = _applyAll(operations);

        for (var order = 0; order < 5; order++) {
          final state = _applyAll([...operations]..shuffle(random));
          expect(state.isDeleted, expected.isDeleted, reason: '$history');
          expect(state.deletedHlc, expected.deletedHlc);
          expect(state.restoredHlc, expected.restoredHlc);
          expect(state.fields, expected.fields);
        }
      }
    });
  });

  test('a restore is written and read as one line', () {
    final restore = _op(_phone, 300, OperationType.restore);

    final line = jsonEncode(restore.toJson());
    final read = SyncOperation.fromJson(
      jsonDecode(line) as Map<String, Object?>,
    );

    expect(restore.toJson()['restore'], isTrue);
    expect(read.type, OperationType.restore);
    expect(read.fields, isEmpty);
    expect(read.toJson(), restore.toJson());
  });

  group('restore between two devices', () {
    final trip = EntityId.generate();
    late SharedFolder folder;
    late Device phone;
    late Device laptop;

    setUp(() async {
      final start = DateTime.utc(2026, 3, 12, 9);
      folder = SharedFolder(trip.value);
      phone = await Device.start('phone', start);
      laptop = await Device.start('laptop', start);
    });

    tearDown(() async {
      await phone.stop();
      await laptop.stop();
    });

    Future<EntityId> sharedStop() async {
      final id = EntityId.generate();
      await phone.store.create(
        entity: EntityKinds.stop,
        id: id,
        tripId: trip,
        fields: const {'name': 'Uffizi', 'durationMin': 120},
      );
      await folder.syncAll([phone, laptop]);
      return id;
    }

    test('a stop deleted on one device and restored there is back on both, '
        'with what the other changed meanwhile', () async {
      final stop = await sharedStop();

      phone.advance(const Duration(minutes: 1));
      await phone.store.delete(stop);
      laptop.advance(const Duration(minutes: 2));
      await laptop.store.set(stop, {'durationMin': 90});
      await folder.syncAll([phone, laptop]);
      expect((await laptop.store.read(stop))!.isDeleted, isTrue);

      // "This stop was deleted" -> "Restore", on the laptop.
      laptop.advance(const Duration(minutes: 1));
      await laptop.store.restore(stop);
      await folder.syncAll([phone, laptop]);

      for (final device in [phone, laptop]) {
        final stored = (await device.store.read(stop))!;
        expect(stored.isDeleted, isFalse, reason: device.name);
        expect(stored.fields, {'name': 'Uffizi', 'durationMin': 90});
        expect(
          await device.store.list(EntityKinds.stop, tripId: trip),
          hasLength(1),
        );
      }
      expect(await phone.fingerprint(), await laptop.fingerprint());
    });

    test('restored on one device and deleted again later on the other: '
        'deleted on both', () async {
      final stop = await sharedStop();
      await phone.store.delete(stop);
      await folder.syncAll([phone, laptop]);

      laptop.advance(const Duration(minutes: 1));
      await laptop.store.restore(stop);
      await folder.syncAll([phone, laptop]);
      phone.advance(const Duration(minutes: 5));
      await phone.store.delete(stop);
      await folder.syncAll([phone, laptop]);

      for (final device in [phone, laptop]) {
        expect((await device.store.read(stop))!.isDeleted, isTrue);
      }
      expect(await phone.fingerprint(), await laptop.fingerprint());
    });

    test('only a deleted entity can be restored', () async {
      final stop = await sharedStop();

      expect(() => phone.store.restore(stop), throwsStateError);
      expect(() => phone.store.restore(EntityId.generate()), throwsStateError);
    });

    test('a restored entity can be changed and deleted again', () async {
      final stop = await sharedStop();
      await phone.store.delete(stop);
      phone.advance(const Duration(seconds: 1));
      await phone.store.restore(stop);

      phone.advance(const Duration(seconds: 1));
      await phone.store.set(stop, {'name': 'Galleria degli Uffizi'});
      phone.advance(const Duration(seconds: 1));
      await phone.store.delete(stop);

      expect((await phone.store.read(stop))!.isDeleted, isTrue);
      expect(
        (await phone.store.pendingOperations()).map((op) => op.type),
        containsAllInOrder([
          OperationType.delete,
          OperationType.restore,
          OperationType.set,
          OperationType.delete,
        ]),
      );
    });
  });
}
