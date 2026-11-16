// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:drift/drift.dart';

import 'cache_database.dart';

/// A value read from the cache.
class CacheEntry {
  /// Creates an entry.
  const CacheEntry({required this.value, required this.fetchedAt});

  /// The value, decoded from JSON.
  final Object? value;

  /// When the value was downloaded, in UTC.
  final DateTime fetchedAt;
}

/// Reads and writes the values of the cache database (PRD 8.5) as JSON, by
/// kind and key. A value that cannot be read counts as missing: everything
/// in the cache can be downloaded again.
class CacheStore {
  /// Creates the store on [_db].
  const CacheStore(this._db);

  final CacheDatabase _db;

  /// The value of [kind] saved under [key], or null.
  Future<CacheEntry?> read(String kind, String key) async {
    final row =
        await (_db.select(
              _db.cacheRows,
            )..where((row) => row.kind.equals(kind) & row.cacheKey.equals(key)))
            .getSingleOrNull();
    if (row == null) return null;
    try {
      return CacheEntry(
        value: jsonDecode(row.value),
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(
          row.fetchedAtMillis,
          isUtc: true,
        ),
      );
    } on FormatException {
      return null;
    }
  }

  /// Saves [value] of [kind] under [key], replacing what was there.
  /// [expiresAt] is when it should be downloaded again; null if never.
  Future<void> write(
    String kind,
    String key,
    Object? value, {
    required DateTime fetchedAt,
    DateTime? expiresAt,
  }) => _db
      .into(_db.cacheRows)
      .insertOnConflictUpdate(
        CacheRowsCompanion.insert(
          kind: kind,
          cacheKey: key,
          value: jsonEncode(value),
          fetchedAtMillis: fetchedAt.millisecondsSinceEpoch,
          expiresAtMillis: Value(expiresAt?.millisecondsSinceEpoch),
        ),
      );
}
