// SPDX-License-Identifier: GPL-3.0-or-later

// Cache (PRD 8.5): never synchronised, downloaded again when needed. Old or
// estimated data is always labelled as such in the interface (PRD T4).

import 'money.dart';
import 'place.dart';
import 'time.dart';

/// Data of a place from OpenStreetMap and Wikidata (PRD 8.5).
// TODO(M3 F1.2): place search and cache, refreshed after 30 days when online.
class PlaceCache {
  /// Creates a cached place.
  const PlaceCache({
    required this.place,
    required this.fetchedAt,
    this.category,
    this.phone,
    this.website,
    this.popularity,
  });

  /// Essential data of the place.
  final PlaceSnapshot place;

  /// Category of the place.
  final String? category;

  /// Phone number.
  final String? phone;

  /// Website.
  final Uri? website;

  /// Popularity score.
  final int? popularity;

  /// Instant the data was downloaded, in UTC.
  final DateTime fetchedAt;
}

/// A rectangle on the map, used by downloaded packs.
class BoundingBox {
  /// Creates a rectangle from its corners.
  const BoundingBox({required this.southWest, required this.northEast});

  /// South-west corner.
  final Coordinates southWest;

  /// North-east corner.
  final Coordinates northEast;
}

/// Places of an area for the layers of the map (PRD 8.5, F2.8).
// TODO(Fase 2 F2.8): offline places.
class PoiPack {
  /// Creates a pack of places.
  const PoiPack({
    required this.id,
    required this.area,
    required this.downloadedAt,
  });

  /// Identifier of the pack.
  final String id;

  /// Area covered.
  final BoundingBox area;

  /// Instant of the download, in UTC.
  final DateTime downloadedAt;
}

/// Vector tiles of a region in a local archive (PRD 8.5, F2.8).
// TODO(Fase 2 F2.8): offline maps. The archive format (MBTiles or PMTiles)
// is decided at the start of phase 2 (DECISIONS, open points).
class MapPack {
  /// Creates a map pack.
  const MapPack({
    required this.id,
    required this.area,
    required this.sizeBytes,
    required this.downloadedAt,
  });

  /// Identifier of the pack.
  final String id;

  /// Area covered.
  final BoundingBox area;

  /// Size on disk, in bytes.
  final int sizeBytes;

  /// Instant of the download, in UTC.
  final DateTime downloadedAt;
}

/// An exchange rate for a date and a pair of currencies (PRD 8.5).
// TODO(M5 F1.10): exchange rates; historical rates are kept for ever.
class FxRate {
  /// Creates an exchange rate.
  const FxRate({
    required this.date,
    required this.from,
    required this.to,
    required this.rate,
    this.manual = false,
  });

  /// Date of the rate.
  final LocalDate date;

  /// ISO 4217 code of the currency converted from.
  final String from;

  /// ISO 4217 code of the currency converted to.
  final String to;

  /// Rate as a decimal string, never a floating point number.
  final String rate;

  /// True if the user entered the rate by hand; it is labelled as such.
  final bool manual;
}

/// A weather forecast for a place (PRD 8.5, F1.11).
// TODO(M5 F1.11): weather, kept as long as the service says.
class WeatherCache {
  /// Creates a cached forecast.
  const WeatherCache({
    required this.coordinates,
    required this.fetchedAt,
    required this.expiresAt,
  });

  /// Place of the forecast.
  final Coordinates coordinates;

  /// Instant of the download, in UTC.
  final DateTime fetchedAt;

  /// Instant after which the forecast is refreshed, in UTC.
  final DateTime expiresAt;
}

/// The price of a fuel at a station (PRD 8.5, F2.6).
// TODO(Fase 2 F2.6): fuel prices, kept for 24 hours.
class FuelPrice {
  /// Creates a fuel price.
  const FuelPrice({
    required this.stationId,
    required this.fuel,
    required this.price,
    required this.reportedAt,
  });

  /// Identifier of the station.
  final String stationId;

  /// Kind of fuel.
  final String fuel;

  /// Price per litre.
  final Money price;

  /// Instant the price was reported, in UTC.
  final DateTime reportedAt;
}

/// A static data pack downloaded from GitHub Releases (PRD 4.6, 8.5):
/// vehicles, badges, tolls, shop.
// TODO(Fase 2 F2.5): the first data pack (vehicles).
class DataPack {
  /// Creates a data pack.
  const DataPack({
    required this.name,
    required this.version,
    required this.downloadedAt,
  });

  /// Name of the pack, for example vehicles.
  final String name;

  /// Version of the pack.
  final String version;

  /// Instant of the download, in UTC.
  final DateTime downloadedAt;
}
