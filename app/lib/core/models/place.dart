// SPDX-License-Identifier: GPL-3.0-or-later

import 'json_object.dart';

/// A WGS84 position in decimal degrees (PRD 8.1).
class Coordinates {
  /// Creates the position [lat], [lon].
  const Coordinates({
    required this.lat,
    required this.lon,
    this.unknown = const {},
  });

  /// Reads a position from its JSON object.
  factory Coordinates.fromJson(Map<String, Object?> json) {
    final object = JsonObject(json);
    return Coordinates(
      lat: object.read<num>(_lat).toDouble(),
      lon: object.read<num>(_lon).toDouble(),
      unknown: object.unknownExcept(const {_lat, _lon}),
    );
  }

  static const String _lat = 'lat';
  static const String _lon = 'lon';

  /// Latitude in decimal degrees.
  final double lat;

  /// Longitude in decimal degrees.
  final double lon;

  /// Keys written by a newer version of the app, kept as they are.
  final Map<String, Object?> unknown;

  /// The position as a JSON object, unknown keys included.
  Map<String, Object?> toJson() => {...unknown, _lat: lat, _lon: lon};
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
    this.unknown = const {},
  });

  /// Reads a place from its JSON object.
  factory PlaceSnapshot.fromJson(Map<String, Object?> json) {
    final object = JsonObject(json);
    return PlaceSnapshot(
      name: object.read<String>(_name),
      coordinates: Coordinates.fromJson(object.object(_coordinates).json),
      address: object.readOptional<String>(_address),
      osmId: object.readOptional<String>(_osmId),
      wikidataId: object.readOptional<String>(_wikidataId),
      openingHours: object.readOptional<String>(_openingHours),
      unknown: object.unknownExcept(const {
        _name,
        _coordinates,
        _address,
        _osmId,
        _wikidataId,
        _openingHours,
      }),
    );
  }

  static const String _name = 'name';
  static const String _coordinates = 'coordinates';
  static const String _address = 'address';
  static const String _osmId = 'osmId';
  static const String _wikidataId = 'wikidataId';
  static const String _openingHours = 'openingHours';

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

  /// Keys written by a newer version of the app, kept as they are.
  final Map<String, Object?> unknown;

  /// Returns a copy with some values replaced. The unknown keys are kept.
  PlaceSnapshot copyWith({String? name, String? address}) => PlaceSnapshot(
    name: name ?? this.name,
    coordinates: coordinates,
    address: address ?? this.address,
    osmId: osmId,
    wikidataId: wikidataId,
    openingHours: openingHours,
    unknown: unknown,
  );

  /// The place as a JSON object, unknown keys included.
  Map<String, Object?> toJson() => {
    ...unknown,
    _name: name,
    _coordinates: coordinates.toJson(),
    if (address != null) _address: address,
    if (osmId != null) _osmId: osmId,
    if (wikidataId != null) _wikidataId: wikidataId,
    if (openingHours != null) _openingHours: openingHours,
  };
}
