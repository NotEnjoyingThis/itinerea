// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/models/ids.dart';
import 'package:itinerea/core/sync/hlc.dart';
import 'package:itinerea/core/sync/merge.dart';
import 'package:itinerea/core/sync/sync_engine.dart';

const _phone = EntityId('01900000-0000-7000-8000-00000000000a');
const _laptop = EntityId('01900000-0000-7000-8000-00000000000b');
const _stop = EntityId('01900000-0000-7000-8000-0000000000f1');

var _nextOperation = 0;

/// An operation on the test stop made by [device] at wall time [at] (in
/// milliseconds), with an optional counter.
SyncOperation _op(
  EntityId device,
  int at, {
  Map<String, Object?> set = const {},
  bool create = false,
  bool delete = false,
  int counter = 0,
}) => SyncOperation(
  id: EntityId('op-${_nextOperation++}'),
  deviceId: device,
  hlc: HlcTimestamp(wallMillis: at, counter: counter, deviceId: device).text,
  schemaVersion: 1,
  entity: 'Stop',
  entityId: _stop,
  type: delete
      ? OperationType.delete
      : (create ? OperationType.create : OperationType.set),
  fields: set,
);

EntityState? _applyAll(Iterable<SyncOperation> operations) {
  EntityState? state;
  for (final operation in operations) {
    state = Merge.apply(state, operation).state;
  }
  return state;
}

/// A text that is equal for equal states, whatever the order of the keys.
String _fingerprint(EntityState? state) => jsonEncode({
  'entity': state?.entity,
  'fields': SplayTreeMapView(state?.fields ?? const {}),
  'clocks': SplayTreeMapView({
    for (final entry in (state?.clocks ?? const <String, Hlc>{}).entries)
      entry.key: entry.value.value,
  }),
  'deleted': state?.deletedHlc?.value,
});

/// A map view whose JSON form lists the keys in alphabetical order.
class SplayTreeMapView {
  SplayTreeMapView(this._map);

  final Map<String, Object?> _map;

  Map<String, Object?> toJson() => {
    for (final key in _map.keys.toList()..sort()) key: _map[key],
  };
}

void main() {
  group('fields: the last writer wins, field by field', () {
    test('the later change of the same field wins', () {
      final state = _applyAll([
        _op(_phone, 100, create: true, set: {'name': 'Uffizi'}),
        _op(_phone, 200, set: {'name': 'Galleria degli Uffizi'}),
        _op(_laptop, 300, set: {'name': 'Uffizi, ingresso 2'}),
      ]);

      expect(state!.fields['name'], 'Uffizi, ingresso 2');
    });

    test('an older change that arrives later is ignored', () {
      final older = _op(_laptop, 150, set: {'name': 'Old name'});
      final state = _applyAll([
        _op(_phone, 100, create: true, set: {'name': 'Uffizi'}),
        _op(_phone, 200, set: {'name': 'New name'}),
      ]);

      final result = Merge.apply(state, older);

      expect(result.state.fields['name'], 'New name');
      expect(result.changedFields, isEmpty);
    });

    test('changes to different fields of the same entity are both kept', () {
      final state = _applyAll([
        _op(
          _phone,
          100,
          create: true,
          set: {'name': 'Uffizi', 'durationMin': 60},
        ),
        _op(_phone, 200, set: {'durationMin': 90}),
        _op(_laptop, 150, set: {'name': 'Galleria degli Uffizi'}),
      ]);

      expect(state!.fields, {
        'name': 'Galleria degli Uffizi',
        'durationMin': 90,
      });
    });

    test('at the same instant the counter, then the device, decide', () {
      final first = _op(_phone, 500, set: {'status': 'visited'}, counter: 1);
      final second = _op(_phone, 500, set: {'status': 'skipped'}, counter: 2);
      final fromLaptop = _op(
        _laptop,
        500,
        set: {'status': 'planned'},
        counter: 2,
      );

      for (final order in [
        [first, second, fromLaptop],
        [fromLaptop, second, first],
        [second, fromLaptop, first],
      ]) {
        // Same time and counter: the laptop has the greater device id.
        expect(_applyAll(order)!.fields['status'], 'planned');
      }
    });

    test('a field can be set to null, and null can win', () {
      final state = _applyAll([
        _op(_phone, 100, create: true, set: {'bookingId': 'booking-1'}),
        _op(_laptop, 200, set: {'bookingId': null}),
      ]);

      expect(state!.fields.containsKey('bookingId'), isTrue);
      expect(state.fields['bookingId'], isNull);
    });

    test('reports the value it replaced, so that nothing is lost silently', () {
      final state = _applyAll([
        _op(_phone, 100, create: true, set: {'text': 'First draft'}),
      ]);

      final result = Merge.apply(
        state,
        _op(_laptop, 200, set: {'text': 'Second draft'}),
      );

      expect(result.overwritten, {'text': 'First draft'});
      expect(result.changedFields, {'text'});
    });
  });

  group('deletion wins', () {
    test('over a change made later on another device', () {
      final state = _applyAll([
        _op(_phone, 100, create: true, set: {'name': 'Uffizi'}),
        _op(_phone, 200, delete: true),
        _op(_laptop, 300, set: {'name': 'Edited while offline'}),
      ]);

      expect(state!.isDeleted, isTrue);
    });

    test('whatever the order in which the two arrive', () {
      final create = _op(_phone, 100, create: true, set: {'name': 'Uffizi'});
      final delete = _op(_phone, 200, delete: true);
      final edit = _op(_laptop, 300, set: {'name': 'Edited while offline'});

      final a = _applyAll([create, delete, edit]);
      final b = _applyAll([create, edit, delete]);
      final c = _applyAll([edit, delete, create]);

      expect(_fingerprint(a), _fingerprint(b));
      expect(_fingerprint(b), _fingerprint(c));
      expect(c!.isDeleted, isTrue);
    });

    test('deleted on two devices: the tombstone is the later deletion', () {
      final create = _op(_phone, 100, create: true, set: {'name': 'Uffizi'});
      final onPhone = _op(_phone, 200, delete: true);
      final onLaptop = _op(_laptop, 300, delete: true);

      final a = _applyAll([create, onPhone, onLaptop]);
      final b = _applyAll([onLaptop, create, onPhone]);

      expect(a!.deletedHlc, onLaptop.hlc);
      expect(b!.deletedHlc, onLaptop.hlc);
    });

    test('and the last text is still there for "Restore"', () {
      final state = _applyAll([
        _op(_phone, 100, create: true, set: {'name': 'Uffizi'}),
        _op(_phone, 200, delete: true),
        _op(_laptop, 300, set: {'name': 'Edited while offline'}),
      ]);

      expect(state!.fields['name'], 'Edited while offline');
    });
  });

  group('operations in any order', () {
    test('a change that arrives before the creation is not lost', () {
      final create = _op(
        _phone,
        100,
        create: true,
        set: {'name': 'Uffizi', 'durationMin': 60},
      );
      final edit = _op(_laptop, 200, set: {'durationMin': 90});

      final state = _applyAll([edit, create]);

      expect(state!.entity, 'Stop');
      expect(state.fields, {'name': 'Uffizi', 'durationMin': 90});
    });

    test('applying the same operation twice changes nothing', () {
      final operations = [
        _op(_phone, 100, create: true, set: {'name': 'Uffizi'}),
        _op(_laptop, 200, set: {'name': 'Galleria'}),
        _op(_phone, 300, delete: true),
      ];

      final once = _applyAll(operations);
      final twice = _applyAll([...operations, ...operations]);

      expect(_fingerprint(twice), _fingerprint(once));
    });

    test('fields unknown to this version are merged like any other', () {
      final state = _applyAll([
        _op(_phone, 100, create: true, set: {'name': 'Uffizi'}),
        _op(
          _laptop,
          200,
          set: {
            'accessibility': {'wheelchair': true},
          },
        ),
        _op(_phone, 300, set: {'name': 'Galleria'}),
      ]);

      expect(state!.fields['accessibility'], {'wheelchair': true});
    });

    test('500 random histories give one result in every order', () {
      final random = Random(20261114);
      const fields = ['name', 'durationMin', 'status', 'startTime', 'noteId'];
      for (var history = 0; history < 500; history++) {
        final operations = <SyncOperation>[
          for (var i = 0; i < 2 + random.nextInt(10); i++)
            _op(
              random.nextBool() ? _phone : _laptop,
              // Few distinct instants, to produce many ties.
              100 + random.nextInt(6),
              counter: random.nextInt(3),
              create: i == 0,
              delete: random.nextInt(8) == 0,
              set: {
                for (final field in fields)
                  if (random.nextInt(3) == 0) field: random.nextInt(1000),
              },
            ),
        ];
        // Two operations with the same clock value cannot exist: a device
        // never repeats one. Keep the first of each.
        final seen = <String>{};
        operations.retainWhere((op) => seen.add(op.hlc.value));
        final expected = _fingerprint(_applyAll(operations));

        for (var order = 0; order < 6; order++) {
          final shuffled = [...operations]..shuffle(random);
          expect(
            _fingerprint(_applyAll(shuffled)),
            expected,
            reason: 'history $history, order $order',
          );
        }
      }
    });
  });
}
