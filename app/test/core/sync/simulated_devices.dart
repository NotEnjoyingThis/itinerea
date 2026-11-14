// SPDX-License-Identifier: GPL-3.0-or-later

// Simulated devices for the sync tests (CLAUDE.md, section 5): each device
// has its own database, its own store and its own wall clock. They exchange
// operations through a shared folder, as in file mode (PRD 9.3).

import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:itinerea/core/database/data_database.dart';
import 'package:itinerea/core/database/entity_store.dart';
import 'package:itinerea/core/models/ids.dart';
import 'package:itinerea/core/sync/sync_engine.dart';

/// One simulated device.
class Device {
  Device._(this.name, this.db, this.store, this._wall);

  /// Starts a device whose wall clock shows [wall].
  static Future<Device> start(String name, DateTime wall) async {
    // Several databases at once is the point of these tests.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = DataDatabase(NativeDatabase.memory());
    final clock = _WallClock(wall);
    final store = await EntityStore.open(db, wallClock: clock.read);
    return Device._(name, db, store, clock);
  }

  /// Name used in failure messages.
  final String name;

  /// Database of the device.
  final DataDatabase db;

  /// Store of the device.
  final EntityStore store;

  final _WallClock _wall;

  /// Operations already read from the shared folder.
  final Set<EntityId> _read = {};

  /// Outcomes of everything received so far.
  final List<ReceiveOutcome> received = [];

  /// Moves the wall clock of the device forward (or back).
  void advance(Duration by) => _wall.now = _wall.now.add(by);

  /// Stops the device.
  Future<void> stop() => db.close();

  /// Everything the device knows, as a text that is equal for equal states:
  /// entities, tombstones and field clocks, in a fixed order.
  Future<String> fingerprint() async {
    final entities = await (db.select(
      db.entityRows,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final clocks =
        await (db.select(db.fieldClockRows)..orderBy([
              (t) => OrderingTerm.asc(t.entityId),
              (t) => OrderingTerm.asc(t.field),
            ]))
            .get();
    return jsonEncode({
      'entities': [
        for (final row in entities)
          [
            row.id,
            row.entity,
            row.tripId,
            row.parentId,
            _sorted(jsonDecode(row.fields)),
            row.deletedHlc,
          ],
      ],
      'clocks': [
        for (final row in clocks) [row.entityId, row.field, row.hlc],
      ],
    });
  }

  static Object? _sorted(Object? value) => switch (value) {
    final Map<Object?, Object?> map => {
      for (final key in map.keys.cast<String>().toList()..sort())
        key: _sorted(map[key]),
    },
    final List<Object?> list => [for (final item in list) _sorted(item)],
    _ => value,
  };
}

class _WallClock {
  _WallClock(this.now);

  DateTime now;

  DateTime read() => now;
}

/// The sync space of one trip: one list of operations per device, like the
/// `ops/<deviceId>/` folders of PRD 8.6.
class SharedFolder {
  /// Creates the folder of the trip (or personal space) named [space].
  SharedFolder(this.space, {int seed = 1}) : _random = Random(seed);

  /// Identifier of the trip, or the personal space.
  final String space;

  final Random _random;
  final Map<EntityId, List<SyncOperation>> _files = {};

  /// Number of operations in the folder.
  int get length => _files.values.fold(0, (sum, file) => sum + file.length);

  /// Uploads the operations [device] has not sent yet. Each one goes through
  /// its text form, as it would in a file.
  Future<void> push(Device device) async {
    final pending = await device.store.pendingOperations(space: space);
    final file = _files.putIfAbsent(device.store.deviceId, () => []);
    for (final operation in pending) {
      final line = jsonEncode(operation.toJson());
      file.add(
        SyncOperation.fromJson(jsonDecode(line) as Map<String, Object?>),
      );
    }
    await device.store.markSent([
      for (final operation in pending) operation.id,
    ], DateTime.utc(2026));
  }

  /// Downloads into [device] the operations of the other devices it has not
  /// read yet, in random order: the order must not matter.
  Future<void> pull(Device device) async {
    final incoming = [
      for (final MapEntry(key: author, value: file) in _files.entries)
        if (author != device.store.deviceId)
          for (final operation in file)
            if (device._read.add(operation.id)) operation,
    ]..shuffle(_random);
    for (final operation in incoming) {
      device.received.add(await device.store.receive(operation, space: space));
    }
  }

  /// Uploads, then downloads.
  Future<void> sync(Device device) async {
    await push(device);
    await pull(device);
  }

  /// Syncs every device until nothing new moves.
  Future<void> syncAll(List<Device> devices) async {
    for (var round = 0; round < 2; round++) {
      for (final device in devices) {
        await sync(device);
      }
    }
  }

  /// Delivers again to [device] everything in the folder, as if it had lost
  /// its index of the files already read.
  Future<void> redeliverEverything(Device device) async {
    device._read.clear();
    await pull(device);
  }
}
