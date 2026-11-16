// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/cache_store.dart';
import '../database/database_providers.dart';
import '../models/place.dart';
import '../net/http_transport.dart';
import 'nominatim_details.dart';
import 'photon_search.dart';
import 'place_details_lookup.dart';
import 'providers.dart';

/// Sends every request to external services. Tests override it: they never
/// reach the network.
final httpTransportProvider = Provider<HttpTransport>((ref) {
  final transport = IoHttpTransport();
  ref.onDispose(transport.close);
  return transport;
});

/// Search of places while the user types (F1.2). One for the whole app, so
/// that its limits hold for every screen.
// TODO(M6 F1.15): the service chosen in the settings (PRD 4.6).
final placeSearchProvider = Provider<PlaceSearchProvider>(
  (ref) => PhotonPlaceSearch(transport: ref.watch(httpTransportProvider)),
);

/// Opening hours and contacts of a chosen place (F1.2).
// TODO(M6 F1.15): the service chosen in the settings (PRD 4.6).
final placeDetailsProvider = Provider<PlaceDetailsProvider>(
  (ref) => NominatimPlaceDetails(transport: ref.watch(httpTransportProvider)),
);

/// Opening hours and contacts, from the cache or from the service.
final placeDetailsLookupProvider = FutureProvider<PlaceDetailsLookup>(
  (ref) async => PlaceDetailsLookup(
    ref.watch(placeDetailsProvider),
    CacheStore(await ref.watch(cacheDatabaseProvider.future)),
  ),
);

/// The details kept on this device for a place, for the date shown with
/// them (PRD T4). Null when this device never downloaded them.
final cachedPlaceDetailsProvider = FutureProvider.family<PlaceDetails?, String>(
  (ref, osmId) async =>
      (await ref.watch(placeDetailsLookupProvider.future)).cached(osmId),
);
