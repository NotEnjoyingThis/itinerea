// SPDX-License-Identifier: GPL-3.0-or-later

import '../database/cache_store.dart';
import '../models/place.dart';
import 'providers.dart';

/// Opening hours and contacts of places: from the cache of this device when
/// it knows them, from the service otherwise (PRD 5.4, 8.5).
///
/// Nominatim asks that "Results must be cached" and may block "Clients
/// sending repeatedly the same query" (PRD 5.6): the same place is not asked
/// again for 30 days, unless the user asks, and never twice in a day.
class PlaceDetailsLookup {
  /// Creates the lookup on [_provider], keeping the answers in [_cache].
  PlaceDetailsLookup(this._provider, this._cache, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Kind of the values in the cache.
  static const String cacheKind = 'placeDetails';

  /// After this time the details are shown as possibly old (PRD T4), and
  /// choosing the place again downloads them again.
  static const Duration lifetime = Duration(days: 30);

  /// A refresh asked sooner than this after the last download gives that
  /// download again, without asking the service.
  static const Duration minimumRefreshAge = Duration(days: 1);

  final PlaceDetailsProvider _provider;
  final CacheStore _cache;
  final DateTime Function() _now;

  // Loads under way, by place: asking again meanwhile waits for the same
  // answer instead of sending the same request twice.
  final _loading =
      <String, Future<({PlaceDetails details, PlaceDetails? previous})>>{};

  /// The details kept on this device for [osmId], however old; null if none.
  /// The details do not depend on the language, so neither does the cache.
  Future<PlaceDetails?> cached(String osmId) async =>
      switch ((await _cache.read(cacheKind, osmId))?.value) {
        final Map<String, Object?> json => PlaceDetails.fromJson(json),
        _ => null,
      };

  /// True if a place whose last download gave [known] can be downloaded
  /// again now: never downloaded, or at least [minimumRefreshAge] ago.
  bool canRefresh(PlaceDetails? known) =>
      known == null || !_isYoungerThan(known, minimumRefreshAge);

  /// The details of [osmId]: those kept on this device when younger than
  /// [lifetime], otherwise downloaded and kept. With [refresh] (the user
  /// asked) they are downloaded again unless [canRefresh] is false.
  ///
  /// Also returns the details known before, if any, for
  /// [PlaceDetails.applyTo]. Throws a ServiceFailure when the service
  /// cannot answer.
  Future<({PlaceDetails details, PlaceDetails? previous})> load(
    String osmId, {
    required String language,
    bool refresh = false,
  }) => _loading[osmId] ??= _load(osmId, language: language, refresh: refresh)
      .whenComplete(() {
        // Remove gives back this very future: waiting for it here would
        // never end, and its callers already listen to it.
        _loading.remove(osmId)?.ignore();
      });

  Future<({PlaceDetails details, PlaceDetails? previous})> _load(
    String osmId, {
    required String language,
    required bool refresh,
  }) async {
    final known = await cached(osmId);
    if (known != null &&
        _isYoungerThan(known, refresh ? minimumRefreshAge : lifetime)) {
      return (details: known, previous: known);
    }
    final fresh = await _provider.details(osmId, language: language);
    await _cache.write(
      cacheKind,
      osmId,
      fresh.toJson(),
      fetchedAt: fresh.fetchedAt,
      expiresAt: fresh.fetchedAt.add(lifetime),
    );
    return (details: fresh, previous: known);
  }

  /// True if [details] are older than [lifetime]: they are shown as such.
  bool isOld(PlaceDetails details) => !_isYoungerThan(details, lifetime);

  // A download dated in the future (a clock that was wrong) counts as old.
  bool _isYoungerThan(PlaceDetails details, Duration age) {
    final elapsed = _now().toUtc().difference(details.fetchedAt);
    return !elapsed.isNegative && elapsed < age;
  }
}
