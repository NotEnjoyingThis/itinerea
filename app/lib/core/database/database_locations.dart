// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:io';

import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'cache_database.dart';
import 'data_database.dart';

/// Where the app keeps its files on the device (PRD 8.2).
///
/// Data that cannot be downloaded again (trips, personal data, attachments,
/// tickets, QR codes) goes to the data folder. Only what can be downloaded
/// again goes to the cache folder, which the system may empty at any time.
class DatabaseLocations {
  /// Creates the locations from the two base folders.
  const DatabaseLocations({
    required this.dataFolder,
    required this.cacheFolder,
  });

  /// Asks the system for the data folder and the cache folder of the app.
  static Future<DatabaseLocations> ofThisDevice() async => DatabaseLocations(
    dataFolder: await getApplicationSupportDirectory(),
    cacheFolder: await getApplicationCacheDirectory(),
  );

  /// Folder for data that must not be lost.
  final Directory dataFolder;

  /// Folder for data that can be downloaded again.
  final Directory cacheFolder;

  /// File of the database of trips and personal data.
  File get dataDatabaseFile => File(_join(dataFolder, 'itinerea.sqlite'));

  /// File of the database of the cache.
  File get cacheDatabaseFile =>
      File(_join(cacheFolder, 'itinerea_cache.sqlite'));

  /// Folder of the attachments, each stored under its SHA-256. Always inside
  /// the data folder, never in the cache.
  Directory get attachmentsFolder =>
      Directory(_join(dataFolder, 'attachments'));

  /// Opens the database of trips and personal data.
  DataDatabase openData() =>
      DataDatabase(NativeDatabase.createInBackground(dataDatabaseFile));

  /// Opens the database of the cache.
  CacheDatabase openCache() =>
      CacheDatabase(NativeDatabase.createInBackground(cacheDatabaseFile));

  static String _join(Directory folder, String name) =>
      '${folder.path}${Platform.pathSeparator}$name';
}
