// SPDX-License-Identifier: GPL-3.0-or-later

// Several simulated devices changing the same trip, online and offline
// (PRD 4.3, 9.3, 9.5). "Offline" means that a device does not sync between
// two changes.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/models/entity_kinds.dart';
import 'package:itinerea/core/models/expense.dart';
import 'package:itinerea/core/models/expense_check.dart';
import 'package:itinerea/core/models/ids.dart';
import 'package:itinerea/core/models/money.dart';
import 'package:itinerea/core/models/place.dart';
import 'package:itinerea/core/sync/fractional_index.dart';

import 'simulated_devices.dart';

void main() {
  final start = DateTime.utc(2026, 3, 12, 9);
  final trip = EntityId.generate();
  final day = EntityId.generate();
  late SharedFolder folder;
  late Device phone;
  late Device laptop;

  setUp(() async {
    folder = SharedFolder(trip.value);
    phone = await Device.start('phone', start);
    laptop = await Device.start('laptop', start);
  });

  tearDown(() async {
    await phone.stop();
    await laptop.stop();
  });

  Future<void> expectSameState(List<Device> devices) async {
    final expected = await devices.first.fingerprint();
    for (final device in devices.skip(1)) {
      expect(
        await device.fingerprint(),
        expected,
        reason: '${device.name} differs from ${devices.first.name}',
      );
    }
  }

  /// Creates a stop on [device] and returns its identifier.
  Future<EntityId> createStop(
    Device device, {
    Map<String, Object?> fields = const {'name': 'Uffizi', 'durationMin': 120},
  }) async {
    final id = EntityId.generate();
    await device.store.create(
      entity: EntityKinds.stop,
      id: id,
      tripId: trip,
      fields: fields,
    );
    return id;
  }

  group('two devices', () {
    test('a trip planned on one appears on the other', () async {
      final stop = await createStop(phone);

      await folder.syncAll([phone, laptop]);

      expect((await laptop.store.read(stop))!.fields['name'], 'Uffizi');
      expect((await laptop.store.read(stop))!.tripId, trip);
      await expectSameState([phone, laptop]);
    });

    test(
      'changing the same field offline: the later change wins on both',
      () async {
        final stop = await createStop(phone);
        await folder.syncAll([phone, laptop]);

        phone.advance(const Duration(minutes: 1));
        await phone.store.set(stop, {'durationMin': 90});
        laptop.advance(const Duration(minutes: 2));
        await laptop.store.set(stop, {'durationMin': 150});
        await folder.syncAll([phone, laptop]);

        expect((await phone.store.read(stop))!.fields['durationMin'], 150);
        expect((await laptop.store.read(stop))!.fields['durationMin'], 150);
        await expectSameState([phone, laptop]);
      },
    );

    test(
      'changing different fields of the same stop offline: both kept',
      () async {
        final stop = await createStop(phone);
        await folder.syncAll([phone, laptop]);

        phone.advance(const Duration(minutes: 1));
        await phone.store.set(stop, {'durationMin': 90});
        laptop.advance(const Duration(minutes: 2));
        await laptop.store.set(stop, {'name': 'Galleria degli Uffizi'});
        await folder.syncAll([phone, laptop]);

        for (final device in [phone, laptop]) {
          expect((await device.store.read(stop))!.fields, {
            'name': 'Galleria degli Uffizi',
            'durationMin': 90,
          });
        }
      },
    );

    test(
      'one deletes a stop the other is editing: the deletion wins',
      () async {
        final stop = await createStop(phone);
        await folder.syncAll([phone, laptop]);

        phone.advance(const Duration(minutes: 1));
        await phone.store.delete(stop);
        laptop.advance(const Duration(minutes: 5));
        await laptop.store.set(stop, {'name': 'Edited after the deletion'});
        await folder.syncAll([phone, laptop]);

        for (final device in [phone, laptop]) {
          expect((await device.store.read(stop))!.isDeleted, isTrue);
          expect(
            await device.store.list(EntityKinds.stop, tripId: trip),
            isEmpty,
          );
        }
        await expectSameState([phone, laptop]);
      },
    );

    test('a stop deleted offline does not come back after syncing', () async {
      final stop = await createStop(phone);
      await folder.syncAll([phone, laptop]);
      await laptop.store.delete(stop);

      // The phone syncs twice before and after the laptop.
      await folder.sync(phone);
      await folder.syncAll([phone, laptop]);
      await folder.redeliverEverything(phone);

      expect((await phone.store.read(stop))!.isDeleted, isTrue);
      await expectSameState([phone, laptop]);
    });

    test(
      'inserting a stop at the same place offline: same order on both',
      () async {
        Future<EntityId> slot(Device device, String key) async {
          final id = EntityId.generate();
          await device.store.create(
            entity: EntityKinds.stopSlot,
            id: id,
            tripId: trip,
            fields: {'dayId': day.value, 'orderKey': key},
          );
          return id;
        }

        Future<List<EntityId>> order(Device device) async {
          final slots = await device.store.list(
            EntityKinds.stopSlot,
            parentId: day,
          );
          slots.sort(
            (a, b) => FractionalIndex.compare(
              a.fields['orderKey']! as String,
              a.id.value,
              b.fields['orderKey']! as String,
              b.id.value,
            ),
          );
          return [for (final slot in slots) slot.id];
        }

        final first = await slot(phone, FractionalIndex.between(null, null));
        final last = await slot(phone, FractionalIndex.between('V', null));
        await folder.syncAll([phone, laptop]);

        // Both insert between the two stops of the day, without syncing.
        final between = FractionalIndex.between('V', 'k');
        final onPhone = await slot(phone, between);
        final onLaptop = await slot(laptop, between);
        await folder.syncAll([phone, laptop]);

        final phoneOrder = await order(phone);
        expect(phoneOrder, await order(laptop));
        expect(phoneOrder.first, first);
        expect(phoneOrder.last, last);
        expect(phoneOrder.sublist(1, 3), unorderedEquals([onPhone, onLaptop]));
        // Equal keys: the identifier decides.
        expect(phoneOrder[1].value.compareTo(phoneOrder[2].value), isNegative);
      },
    );

    test('receiving everything a second time changes nothing', () async {
      final stop = await createStop(phone);
      await laptop.store.create(
        entity: EntityKinds.note,
        id: EntityId.generate(),
        tripId: trip,
        fields: const {'text': 'Bring the tickets'},
      );
      await folder.syncAll([phone, laptop]);
      await phone.store.set(stop, {'status': 'visited'});
      await folder.syncAll([phone, laptop]);
      final before = await laptop.fingerprint();
      final alreadyReceived = laptop.received.length;

      await folder.redeliverEverything(laptop);

      expect(await laptop.fingerprint(), before);
      expect(
        laptop.received.skip(alreadyReceived).every((o) => o.alreadyKnown),
        isTrue,
      );
    });

    test(
      'a device whose clock is days ahead is reported, and still merges',
      () async {
        final stop = await createStop(phone);
        await folder.syncAll([phone, laptop]);

        // The laptop's clock is three days ahead.
        laptop.advance(const Duration(days: 3));
        await laptop.store.set(stop, {'name': 'From the future'});
        await folder.syncAll([phone, laptop]);

        expect(phone.received.any((outcome) => outcome.clockSkewed), isTrue);
        expect(
          (await phone.store.read(stop))!.fields['name'],
          'From the future',
        );
        // The phone's next change is not lost behind the laptop's clock.
        await phone.store.set(stop, {'name': 'Fixed on the phone'});
        await folder.syncAll([phone, laptop]);
        expect(
          (await laptop.store.read(stop))!.fields['name'],
          'Fixed on the phone',
        );
        await expectSameState([phone, laptop]);
      },
    );

    test('a clock within a day of the others is not reported', () async {
      final stop = await createStop(phone);
      await folder.syncAll([phone, laptop]);
      laptop.advance(const Duration(hours: 23));
      await laptop.store.set(stop, {'durationMin': 30});
      await folder.syncAll([phone, laptop]);

      expect(phone.received.any((outcome) => outcome.clockSkewed), isFalse);
    });
  });

  group('notes', () {
    test(
      'edited by two people at once: the last wins, nothing is lost',
      () async {
        final note = EntityId.generate();
        await phone.store.create(
          entity: EntityKinds.note,
          id: note,
          tripId: trip,
          fields: const {'text': 'Meet at the hotel'},
        );
        await folder.syncAll([phone, laptop]);

        phone.advance(const Duration(minutes: 1));
        await phone.store.set(note, {'text': 'Meet at the hotel at 9'});
        laptop.advance(const Duration(minutes: 2));
        await laptop.store.set(note, {'text': 'Meet at the station'});
        await folder.syncAll([phone, laptop]);

        for (final device in [phone, laptop]) {
          expect(
            (await device.store.read(note))!.fields['text'],
            'Meet at the station',
          );
          final history = await device.store.noteHistory(note);
          expect(history.map((version) => version.text), [
            'Meet at the hotel',
            'Meet at the hotel at 9',
            'Meet at the station',
          ]);
          expect(history[1].deviceId, phone.store.deviceId);
          expect(history[2].deviceId, laptop.store.deviceId);
        }
      },
    );
  });

  group('expenses: amount and split changed on two devices (PRD 9.5)', () {
    final anna = EntityId.generate();
    final marco = EntityId.generate();

    Split split(SplitType type, int forAnna, int forMarco) => Split(
      type: type,
      entries: [
        SplitEntry(participantId: anna, value: forAnna),
        SplitEntry(participantId: marco, value: forMarco),
      ],
    );

    Future<EntityId> createExpense(Split initial) async {
      final id = EntityId.generate();
      await phone.store.create(
        entity: EntityKinds.expense,
        id: id,
        tripId: trip,
        fields: {
          'amount': const Money(amountMinor: 10000, currency: 'EUR').toJson(),
          'category': 'food',
          'paidBy': anna.value,
          'split': initial.toJson(),
        },
      );
      await folder.syncAll([phone, laptop]);
      return id;
    }

    /// The phone corrects the amount to 120.00 EUR while the laptop changes
    /// the split, both offline.
    Future<void> changeBoth(EntityId expense, Split newSplit) async {
      phone.advance(const Duration(minutes: 1));
      await phone.store.set(expense, {
        'amount': const Money(amountMinor: 12000, currency: 'EUR').toJson(),
      });
      laptop.advance(const Duration(minutes: 2));
      await laptop.store.set(expense, {'split': newSplit.toJson()});
      await folder.syncAll([phone, laptop]);
    }

    test('a split in percentages adapts to the new amount', () async {
      final expense = await createExpense(split(SplitType.percent, 5000, 5000));

      await changeBoth(expense, split(SplitType.percent, 7000, 3000));

      for (final device in [phone, laptop]) {
        final fields = (await device.store.read(expense))!.fields;
        expect(
          Money.fromJson(fields['amount']! as Map<String, Object?>).amountMinor,
          12000,
        );
        expect(
          Split.fromJson(fields['split']! as Map<String, Object?>)
              .entries
              .first
              .value,
          7000,
        );
        expect(ExpenseCheck.problemOfFields(fields), isNull);
      }
      await expectSameState([phone, laptop]);
    });

    test('a split in shares adapts to the new amount', () async {
      final expense = await createExpense(split(SplitType.equal, 0, 0));

      await changeBoth(expense, split(SplitType.shares, 2, 1));

      for (final device in [phone, laptop]) {
        final fields = (await device.store.read(expense))!.fields;
        expect(ExpenseCheck.needsReview(fields), isFalse);
      }
    });

    test(
      'a split in exact amounts that no longer adds up is marked for review',
      () async {
        final expense = await createExpense(split(SplitType.equal, 0, 0));

        // The laptop splits the 100.00 EUR it knows as 60.00 + 40.00.
        await changeBoth(expense, split(SplitType.exact, 6000, 4000));

        for (final device in [phone, laptop]) {
          final fields = (await device.store.read(expense))!.fields;
          expect(
            ExpenseCheck.problemOfFields(fields),
            SplitProblem.exactAmountsDoNotAddUp,
            reason: device.name,
          );
          expect(ExpenseCheck.needsReview(fields), isTrue);
        }
        // The mark is calculated: it created nothing more to synchronise.
        expect(await phone.store.pendingOperations(), isEmpty);
        expect(await laptop.store.pendingOperations(), isEmpty);
        await expectSameState([phone, laptop]);
      },
    );

    test(
      'once someone fixes the exact amounts the mark goes away everywhere',
      () async {
        final expense = await createExpense(split(SplitType.equal, 0, 0));
        await changeBoth(expense, split(SplitType.exact, 6000, 4000));

        phone.advance(const Duration(minutes: 10));
        await phone.store.set(expense, {
          'split': split(SplitType.exact, 7000, 5000).toJson(),
        });
        await folder.syncAll([phone, laptop]);

        for (final device in [phone, laptop]) {
          final fields = (await device.store.read(expense))!.fields;
          expect(
            ExpenseCheck.needsReview(fields),
            isFalse,
            reason: device.name,
          );
        }
      },
    );
  });

  group('an older version of the app (PRD 9.5)', () {
    test('rewrites a place and keeps the fields it does not know', () async {
      // The laptop runs a newer version, which knows two more things about a
      // place and one more about its coordinates.
      final stop = await createStop(
        laptop,
        fields: {
          'name': 'Uffizi',
          'place': {
            'name': 'Uffizi',
            'coordinates': {'lat': 43.7687, 'lon': 11.2553, 'altitudeM': 50},
            'wheelchair': 'yes',
            'photos': ['a.jpg', 'b.jpg'],
          },
        },
      );
      await folder.syncAll([phone, laptop]);

      // The phone runs this version: it reads the place into its own class,
      // renames it and writes the whole object back.
      final stored = (await phone.store.read(stop))!.fields['place']!;
      final place = PlaceSnapshot.fromJson(stored as Map<String, Object?>);
      phone.advance(const Duration(minutes: 1));
      await phone.store.set(stop, {
        'place': place.copyWith(name: 'Galleria degli Uffizi').toJson(),
      });
      await folder.syncAll([phone, laptop]);

      for (final device in [phone, laptop]) {
        final after = (await device.store.read(stop))!.fields['place']!;
        expect(after, {
          'name': 'Galleria degli Uffizi',
          'coordinates': {'lat': 43.7687, 'lon': 11.2553, 'altitudeM': 50},
          'wheelchair': 'yes',
          'photos': ['a.jpg', 'b.jpg'],
        }, reason: device.name);
      }
      await expectSameState([phone, laptop]);
    });

    test('rewrites a split and keeps the fields it does not know', () async {
      final anna = EntityId.generate();
      final expense = EntityId.generate();
      await laptop.store.create(
        entity: EntityKinds.expense,
        id: expense,
        tripId: trip,
        fields: {
          'amount': {'amountMinor': 9000, 'currency': 'EUR'},
          'split': {
            'type': 'shares',
            'rounding': 'toPayer',
            'entries': [
              {'participantId': anna.value, 'value': 1, 'label': 'adult'},
            ],
          },
        },
      );
      await folder.syncAll([phone, laptop]);

      final stored = (await phone.store.read(expense))!.fields['split']!;
      final old = Split.fromJson(stored as Map<String, Object?>);
      phone.advance(const Duration(minutes: 1));
      await phone.store.set(expense, {
        'split': Split(
          type: old.type,
          unknown: old.unknown,
          entries: [
            for (final entry in old.entries)
              SplitEntry(
                participantId: entry.participantId,
                value: entry.value + 1,
                unknown: entry.unknown,
              ),
          ],
        ).toJson(),
      });
      await folder.syncAll([phone, laptop]);

      expect((await laptop.store.read(expense))!.fields['split'], {
        'type': 'shares',
        'rounding': 'toPayer',
        'entries': [
          {'participantId': anna.value, 'value': 2, 'label': 'adult'},
        ],
      });
    });

    test('keeps fields and kinds of entity it has never heard of', () async {
      final stop = await createStop(
        laptop,
        fields: {'name': 'Uffizi', 'crowdLevel': 'high'},
      );
      final unknownKind = EntityId.generate();
      await laptop.store.create(
        entity: 'PackingItem',
        id: unknownKind,
        tripId: trip,
        fields: const {'label': 'Helmet', 'packed': false},
      );
      await folder.syncAll([phone, laptop]);

      phone.advance(const Duration(minutes: 1));
      await phone.store.set(stop, {'name': 'Galleria degli Uffizi'});
      await folder.syncAll([phone, laptop]);

      expect((await laptop.store.read(stop))!.fields, {
        'name': 'Galleria degli Uffizi',
        'crowdLevel': 'high',
      });
      expect((await phone.store.read(unknownKind))!.fields, {
        'label': 'Helmet',
        'packed': false,
      });
      await expectSameState([phone, laptop]);
    });
  });

  group('five devices', () {
    test(
      'working offline for a long time converge once they all sync',
      () async {
        final random = Random(20261114);
        final devices = [
          phone,
          laptop,
          for (final name in ['tablet', 'second phone', 'work laptop'])
            await Device.start(name, start),
        ];
        addTearDown(() async {
          for (final device in devices.skip(2)) {
            await device.stop();
          }
        });
        final shuffledFolder = SharedFolder(trip.value, seed: 7);
        final stops = [for (var i = 0; i < 6; i++) await createStop(phone)];
        await shuffledFolder.syncAll(devices);

        const fields = ['name', 'durationMin', 'status', 'startTime'];
        for (var step = 0; step < 300; step++) {
          final device = devices[random.nextInt(devices.length)];
          device.advance(Duration(seconds: random.nextInt(600)));
          final stop = stops[random.nextInt(stops.length)];
          final known = await device.store.read(stop);
          if (known == null || known.isDeleted) continue;
          if (random.nextInt(40) == 0) {
            await device.store.delete(stop);
          } else {
            await device.store.set(stop, {
              fields[random.nextInt(fields.length)]: random.nextInt(1000),
            });
          }
          // Now and then one device syncs, alone: the others stay offline.
          if (random.nextInt(10) == 0) await shuffledFolder.sync(device);
        }
        await shuffledFolder.syncAll(devices);

        await expectSameState(devices);
        expect(shuffledFolder.length, greaterThan(200));
      },
    );
  });
}
