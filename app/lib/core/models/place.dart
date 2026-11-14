// SPDX-License-Identifier: GPL-3.0-or-later

/// A WGS84 position in decimal degrees (PRD 8.1).
class Coordinates {
  /// Creates the position [lat], [lon].
  const Coordinates({required this.lat, required this.lon});

  /// Latitude in decimal degrees.
  final double lat;

  /// Longitude in decimal degrees.
  final double lon;
}

/// A copy of the essential data of a place, stored inside stops and bookings
/// so that a trip stays complete without the cache (PRD 8.5).
class PlaceSnapshot {
  /// Creates a place snapshot.
  const PlaceSnapshot({
    required this.name,
    required this.coordinates,
    this.address,
    this.osmId,
    this.wikidataId,
    this.openingHours,
  });

  /// Name of the place.
  final String name;

  /// Position of the place.
  final Coordinates coordinates;

  /// Postal address, if known.
  final String? address;

  /// OpenStreetMap identifier, if known.
  final String? osmId;

  /// Wikidata identifier, if known.
  final String? wikidataId;

  /// Opening hours in the OpenStreetMap opening_hours format (PRD 8.1).
  final String? openingHours;
}
