// SPDX-License-Identifier: GPL-3.0-or-later

// Checks the schema of each database against the snapshots committed in
// drift_schemas/ (PRD 8.1). The helpers in test/generated_migrations/ are
// generated from those snapshots: see CONTRIBUTING.md.

import 'dart:io';

import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/database/cache_database.dart';
import 'package:itinerea/core/database/data_database.dart';
import 'package:itinerea/core/database/entity_store.dart';
import 'package:itinerea/core/models/ids.dart';

import '../../generated_migrations/cache/schema.dart' as cache;
import '../../generated_migrations/data/schema.dart' as data;

const _device = '0192f3a1-0000-7000-8000-00000000000d';
const _trip = '0192f3a1-0000-7000-8000-0000000000a1';
const _alive = '0192f3a1-0000-7000-8000-0000000000b1';
const _gone = '0192f3a1-0000-7000-8000-0000000000b2';

void main() {
  group('database of trips and personal data', () {
    late SchemaVerifier verifier;

    setUpAll(() => verifier = SchemaVerifier(data.GeneratedHelper()));

    test('the current version has a committed snapshot', () {
      const version = DataDatabase.currentSchemaVersion;

      expect(
        File('drift_schemas/data/drift_schema_v$version.json').existsSync(),
        isTrue,
        reason:
            'Run: dart run drift_dev schema dump '
            'lib/core/database/data_database.dart drift_schemas/data/',
      );
      expect(data.GeneratedHelper.versions, contains(version));
    });

    test('a new database has exactly the schema of the snapshot', () async {
      // Fails when the tables change without a new schema version.
      const version = DataDatabase.currentSchemaVersion;
      final connection = await verifier.startAt(version);
      final db = DataDatabase(connection);
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, version);
    });

    for (final from in data.GeneratedHelper.versions) {
      test('upgrades from version $from to the current one', () async {
        const to = DataDatabase.currentSchemaVersion;
        final connection = await verifier.startAt(from);
        final db = DataDatabase(connection);
        addTearDown(db.close);

        await verifier.migrateAndValidate(db, to);
      });
    }

    test('version 1 to 2 keeps every trip, stop and tombstone', () async {
      // A database as milestone M2 wrote it: one stop alive, one deleted.
      final schema = await verifier.schemaAt(1);
      const deleted = '019ce1463280:0003:$_device';
      schema.rawDatabase
        ..execute(
          'INSERT INTO entity_rows (id, entity, trip_id, parent_id, fields, '
          "deleted_hlc) VALUES ('$_alive', 'Stop', '$_trip', NULL, "
          '\'{"name":"Uffizi","durationMin":120}\', NULL), '
          "('$_gone', 'Stop', '$_trip', NULL, '{\"name\":\"Duomo\"}', "
          "'$deleted')",
        )
        ..execute(
          'INSERT INTO field_clock_rows (entity_id, field, hlc) VALUES '
          "('$_alive', 'name', '019ce1463280:0001:$_device')",
        )
        ..execute(
          "INSERT INTO meta_rows (name, value) VALUES ('device.id', '$_device')",
        );
      final db = DataDatabase(schema.newConnection());
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 2);

      final store = await EntityStore.open(db);
      final alive = (await store.read(const EntityId(_alive)))!;
      final gone = (await store.read(const EntityId(_gone)))!;
      expect(store.deviceId, const EntityId(_device));
      expect(alive.fields, {'name': 'Uffizi', 'durationMin': 120});
      expect(alive.isDeleted, isFalse);
      expect(alive.restoredHlc, isNull);
      expect(gone.isDeleted, isTrue);
      expect(gone.deletedHlc, const Hlc(deleted));
      expect((await store.list('Stop')).map((stop) => stop.id), [
        const EntityId(_alive),
      ]);
      expect((await store.fieldClocks(const EntityId(_alive))).keys, ['name']);
      // What the new version adds works on the old data.
      await store.restore(const EntityId(_gone));
      expect(await store.list('Stop'), hasLength(2));
    });
  });

  group('database of the cache', () {
    late SchemaVerifier verifier;

    setUpAll(() => verifier = SchemaVerifier(cache.GeneratedHelper()));

    test('the current version has a committed snapshot', () {
      const version = CacheDatabase.currentSchemaVersion;

      expect(
        File('drift_schemas/cache/drift_schema_v$version.json').existsSync(),
        isTrue,
      );
      expect(cache.GeneratedHelper.versions, contains(version));
    });

    for (final from in cache.GeneratedHelper.versions) {
      test('upgrades from version $from to the current one', () async {
        const to = CacheDatabase.currentSchemaVersion;
        final connection = await verifier.startAt(from);
        final db = CacheDatabase(connection);
        addTearDown(db.close);

        await verifier.migrateAndValidate(db, to);
      });
    }
  });
}
