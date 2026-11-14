// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:itinerea/core/database/cache_database.dart';
import 'package:itinerea/core/database/database_locations.dart';
import 'package:itinerea/core/database/entity_store.dart';
import 'package:itinerea/core/models/ids.dart';

void main() {
  late Directory root;
  late DatabaseLocations locations;

  setUp(() {
    root = Directory.systemTemp.createTempSync('itinerea_locations_test');
    locations = DatabaseLocations(
      dataFolder: Directory('${root.path}/data')..createSync(),
      cacheFolder: Directory('${root.path}/cache')..createSync(),
    );
  });

  tearDown(() => root.deleteSync(recursive: true));

  bool isInside(FileSystemEntity entity, Directory folder) =>
      entity.absolute.path.startsWith(folder.absolute.path);

  test('trips and personal data live in the data folder', () {
    expect(isInside(locations.dataDatabaseFile, locations.dataFolder), isTrue);
    expect(
      isInside(locations.dataDatabaseFile, locations.cacheFolder),
      isFalse,
    );
  });

  test('attachments, tickets and QR codes never live in the cache', () {
    expect(isInside(locations.attachmentsFolder, locations.dataFolder), isTrue);
    expect(
      isInside(locations.attachmentsFolder, locations.cacheFolder),
      isFalse,
    );
  });

  test('the cache database lives in the cache folder', () {
    expect(
      isInside(locations.cacheDatabaseFile, locations.cacheFolder),
      isTrue,
    );
    expect(
      isInside(locations.cacheDatabaseFile, locations.dataFolder),
      isFalse,
    );
  });

  test('emptying the cache folder loses no trip', () async {
    final trip = EntityId.generate();
    var data = locations.openData();
    final store = await EntityStore.open(data);
    await store.create(
      entity: 'Trip',
      id: trip,
      tripId: trip,
      fields: const {'name': 'Toscana in moto'},
    );
    final cache = locations.openCache();
    await cache
        .into(cache.cacheRows)
        .insert(
          CacheRowsCompanion.insert(
            kind: 'weather',
            cacheKey: '43.77,11.25',
            value: '{}',
            fetchedAtMillis: 0,
          ),
        );
    await data.close();
    await cache.close();

    // The system empties the cache folder.
    for (final entity in locations.cacheFolder.listSync()) {
      entity.deleteSync(recursive: true);
    }

    data = locations.openData();
    final reopenedCache = locations.openCache();
    addTearDown(data.close);
    addTearDown(reopenedCache.close);
    final reopened = await EntityStore.open(data);
    expect((await reopened.read(trip))!.fields['name'], 'Toscana in moto');
    expect(reopened.deviceId, store.deviceId);
    expect(await reopenedCache.select(reopenedCache.cacheRows).get(), isEmpty);
  });
}
