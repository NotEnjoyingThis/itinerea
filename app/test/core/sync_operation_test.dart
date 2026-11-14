// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/models/ids.dart';
import 'package:itinerea/core/sync/sync_engine.dart';

const _op = '0192f3a1-0000-7000-8000-000000000001';
const _device = '0192f3a1-0000-7000-8000-00000000000d';
const _stop = '0192f3a1-0000-7000-8000-0000000000aa';
const _hlc = '019ce1463280:0000:$_device';

void main() {
  group('operation line (PRD 8.6)', () {
    test('reads the example of the PRD', () {
      const line =
          '{"op":"$_op","dev":"$_device","hlc":"$_hlc","v":3,'
          '"entity":"Stop","id":"$_stop",'
          '"set":{"durationMin":90,"status":"visited"}}';

      final operation = SyncOperation.fromJson(
        jsonDecode(line) as Map<String, Object?>,
      );

      expect(operation.id, const EntityId(_op));
      expect(operation.deviceId, const EntityId(_device));
      expect(operation.hlc, const Hlc(_hlc));
      expect(operation.schemaVersion, 3);
      expect(operation.entity, 'Stop');
      expect(operation.entityId, const EntityId(_stop));
      expect(operation.type, OperationType.set);
      expect(operation.fields, {'durationMin': 90, 'status': 'visited'});
    });

    test('writes each kind of operation and reads it back', () {
      const fieldsByType = <OperationType, Map<String, Object?>>{
        OperationType.create: {
          'name': 'Uffizi',
          'durationMin': 120,
          'place': {
            'name': 'Galleria degli Uffizi',
            'coordinates': {'lat': 43.7687, 'lon': 11.2553},
          },
          'links': <Object?>[],
          'bookingId': null,
        },
        OperationType.set: {'timeFixed': true},
        OperationType.delete: {},
      };
      for (final MapEntry(key: type, value: fields) in fieldsByType.entries) {
        final written = SyncOperation(
          id: const EntityId(_op),
          deviceId: const EntityId(_device),
          hlc: const Hlc(_hlc),
          schemaVersion: 1,
          entity: 'Stop',
          entityId: const EntityId(_stop),
          type: type,
          fields: fields,
        );

        final line = jsonEncode(written.toJson());
        final read = SyncOperation.fromJson(
          jsonDecode(line) as Map<String, Object?>,
        );

        expect(line.contains('\n'), isFalse, reason: 'one operation per line');
        expect(read.type, type);
        expect(read.fields, fields);
        expect(read.toJson(), written.toJson());
      }
    });

    test('a deletion is written as a tombstone without fields', () {
      const deletion = SyncOperation(
        id: EntityId(_op),
        deviceId: EntityId(_device),
        hlc: Hlc(_hlc),
        schemaVersion: 1,
        entity: 'Stop',
        entityId: EntityId(_stop),
        type: OperationType.delete,
      );

      expect(deletion.toJson()['delete'], isTrue);
      expect(deletion.toJson().containsKey('set'), isFalse);
    });

    test('ignores keys written by a newer version of the app', () {
      final operation = SyncOperation.fromJson({
        'op': _op,
        'dev': _device,
        'hlc': _hlc,
        'v': 9,
        'entity': 'Stop',
        'id': _stop,
        'set': {'futureField': 1},
        'signature': 'added by a later version',
      });

      expect(operation.schemaVersion, 9);
      expect(operation.fields, {'futureField': 1});
    });

    test('rejects lines that are not operations', () {
      const base = <String, Object?>{
        'op': _op,
        'dev': _device,
        'hlc': _hlc,
        'v': 1,
        'entity': 'Stop',
        'id': _stop,
      };
      final broken = <Map<String, Object?>>[
        {},
        base, // no create, set or delete
        {...base, 'set': 'not an object'},
        {...base, 'delete': false},
        {...base, 'set': <String, Object?>{}, 'v': '1'},
        {...base, 'set': <String, Object?>{}}..remove('id'),
      ];
      for (final json in broken) {
        expect(
          () => SyncOperation.fromJson(json),
          throwsFormatException,
          reason: '$json',
        );
      }
    });
  });
}
