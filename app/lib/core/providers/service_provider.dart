// SPDX-License-Identifier: GPL-3.0-or-later

/// Kinds of external service the app can use (PRD 4.6, 5.2).
enum ServiceCategory {
  /// Online base map.
  mapTiles,

  /// Route calculation.
  routing,

  /// Elevation along routes.
  elevation,

  /// Search of places and addresses.
  placeSearch,

  /// Details of a place.
  placeDetails,

  /// Places for the layers of the map.
  poi,

  /// Public transport.
  transit,

  /// Weather.
  weather,

  /// Exchange rates.
  fxRates,

  /// Fuel prices.
  fuelPrices,

  /// Charging stations.
  charging,

  /// Static data packs.
  dataPacks,
}

/// An external service used by the app (PRD 3 "Fornitore", 4.6).
///
/// The glossary calls this a Provider. The class is named ServiceProvider
/// because Provider is already a class of Riverpod, used all over the app.
///
/// Every implementation must follow PRD 5.4: a configurable base address,
/// the User-Agent `Itinerea/<version> (+<repository url>)`, a local cache,
/// rate limits on the app side, and a clear behaviour without network.
// TODO(M4 F1.5): shared HTTP client with User-Agent, cache and rate limits.
abstract interface class ServiceProvider {
  /// Stable identifier, for example valhalla-fossgis.
  String get id;

  /// Kind of service.
  ServiceCategory get category;

  /// Address in use: the default one or the one set by the user.
  Uri get baseUrl;
}
