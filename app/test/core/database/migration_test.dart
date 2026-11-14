// SPDX-License-Identifier: GPL-3.0-or-later

// Checks the schema of each database against the snapshots committed in
// drift_schemas/ (PRD 8.1). The helpers in test/generated_migrations/ are
// generated from those snapshots: see CONTRIBUTING.md.

import 'dart:io';

import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/database/cache_database.dart';
import 'package:itinerea/core/database/data_database.dart';

import '../../generated_migrations/cache/schema.dart' as cache;
import '../../generated_migrations/data/schema.dart' as data;

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
