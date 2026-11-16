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
/// so that a trip stays complete without the cache and reaches the other
/// participants with it (PRD 8.5).
///
/// Opening hours, phone and website come from OpenStreetMap when the place is
/// chosen from a search, and the user can change them (F1.2).
class PlaceSnapshot {
  /// Creates a place snapshot.
  const PlaceSnapshot({
    required this.name,
    this.coordinates,
    this.address,
    this.osmId,
    this.wikidataId,
    this.openingHours,
    this.phone,
    this.website,
    this.unknown = const {},
  });

  /// Reads a place from its JSON object.
  factory PlaceSnapshot.fromJson(Map<String, Object?> json) {
    final object = JsonObject(json);
    return PlaceSnapshot(
      name: object.read<String>(_name),
      coordinates: switch (object.readOptional<Map<Object?, Object?>>(
        _coordinates,
      )) {
        final Map<Object?, Object?> value => Coordinates.fromJson(
          value.cast<String, Object?>(),
        ),
        null => null,
      },
      address: object.readOptional<String>(_address),
      osmId: object.readOptional<String>(_osmId),
      wikidataId: object.readOptional<String>(_wikidataId),
      openingHours: object.readOptional<String>(_openingHours),
      phone: object.readOptional<String>(_phone),
      website: object.readOptional<String>(_website),
      unknown: object.unknownExcept(const {
        _name,
        _coordinates,
        _address,
        _osmId,
        _wikidataId,
        _openingHours,
        _phone,
        _website,
      }),
    );
  }

  static const String _name = 'name';
  static const String _coordinates = 'coordinates';
  static const String _address = 'address';
  static const String _osmId = 'osmId';
  static const String _wikidataId = 'wikidataId';
  static const String _openingHours = 'openingHours';
  static const String _phone = 'phone';
  static const String _website = 'website';

  // Marks a value of copyWith that was not given, so that null can mean
  // "clear this value".
  static const Object _keep = Object();

  /// Name of the place.
  final String name;

  /// Position of the place; null for a place the user only typed the name
  /// of, without picking it from a search.
  final Coordinates? coordinates;

  /// Postal address, if known.
  final String? address;

  /// OpenStreetMap identifier with its type letter, for example W477279033
  /// (N node, W way, R relation), if known.
  final String? osmId;

  /// Wikidata identifier, if known.
  final String? wikidataId;

  /// Opening hours in the OpenStreetMap opening_hours format (PRD 8.1), as
  /// written there or by the user.
  final String? openingHours;

  /// Phone number, as written in OpenStreetMap or by the user.
  final String? phone;

  /// Website: always an http or https address.
  final String? website;

  /// Keys written by a newer version of the app, kept as they are.
  final Map<String, Object?> unknown;

  /// Returns a copy with some values replaced. A value given as null is
  /// cleared; a value not given is kept. The unknown keys are kept.
  PlaceSnapshot copyWith({
    String? name,
    Object? address = _keep,
    Object? wikidataId = _keep,
    Object? openingHours = _keep,
    Object? phone = _keep,
    Object? website = _keep,
  }) {
    String? pick(Object? value, String? current) =>
        identical(value, _keep) ? current : value as String?;
    return PlaceSnapshot(
      name: name ?? this.name,
      coordinates: coordinates,
      address: pick(address, this.address),
      osmId: osmId,
      wikidataId: pick(wikidataId, this.wikidataId),
      openingHours: pick(openingHours, this.openingHours),
      phone: pick(phone, this.phone),
      website: pick(website, this.website),
      unknown: unknown,
    );
  }

  /// The place as a JSON object, unknown keys included.
  Map<String, Object?> toJson() => {
    ...unknown,
    _name: name,
    if (coordinates != null) _coordinates: coordinates!.toJson(),
    if (address != null) _address: address,
    if (osmId != null) _osmId: osmId,
    if (wikidataId != null) _wikidataId: wikidataId,
    if (openingHours != null) _openingHours: openingHours,
    if (phone != null) _phone: phone,
    if (website != null) _website: website,
  };
}

/// A place offered while the user types the name of a stop (F1.2).
class PlaceSuggestion {
  /// Creates a suggestion.
  const PlaceSuggestion({required this.place, this.category});

  /// The place, with name, position, address and OpenStreetMap identifier.
  final PlaceSnapshot place;

  /// Kind of place as an OpenStreetMap tag, for example tourism:museum or
  /// amenity:restaurant. Used to choose an icon.
  final String? category;
}

/// Opening hours and contacts of a place, as OpenStreetMap has them
/// (PRD 8.5). Any value may be missing: OpenStreetMap often does not know.
class PlaceDetails {
  /// Creates the details of a place.
  const PlaceDetails({
    required this.fetchedAt,
    this.openingHours,
    this.phone,
    this.website,
    this.wikidataId,
  });

  /// Reads details saved in the cache. Missing or wrong values are ignored.
  factory PlaceDetails.fromJson(Map<String, Object?> json) {
    String? text(String key) => switch (json[key]) {
      final String value when value.isNotEmpty => value,
      _ => null,
    };
    return PlaceDetails(
      fetchedAt:
          DateTime.tryParse(text('fetchedAt') ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      openingHours: text('openingHours'),
      phone: text('phone'),
      website: text('website'),
      wikidataId: text('wikidataId'),
    );
  }

  /// Opening hours in the OpenStreetMap opening_hours format.
  final String? openingHours;

  /// Phone number.
  final String? phone;

  /// Website, always an http or https address.
  final String? website;

  /// Wikidata identifier.
  final String? wikidataId;

  /// When the details were downloaded, in UTC.
  final DateTime fetchedAt;

  /// The details as saved in the cache.
  Map<String, Object?> toJson() => {
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    'openingHours': ?openingHours,
    'phone': ?phone,
    'website': ?website,
    'wikidataId': ?wikidataId,
  };

  /// Puts these details into [place] without undoing the user's changes.
  ///
  /// A value of the place is replaced when it is empty, or when it is still
  /// the one OpenStreetMap gave last time ([previous]): then the user did not
  /// change it, and the newer value is better. A value the user wrote stays.
  PlaceSnapshot applyTo(PlaceSnapshot place, {PlaceDetails? previous}) {
    String? merge(String? current, String? last, String? fresh) =>
        current == null || current.isEmpty || current == last
        ? fresh ?? (current == last ? null : current)
        : current;
    return place.copyWith(
      openingHours: merge(
        place.openingHours,
        previous?.openingHours,
        openingHours,
      ),
      phone: merge(place.phone, previous?.phone, phone),
      website: merge(place.website, previous?.website, website),
      wikidataId: merge(place.wikidataId, previous?.wikidataId, wikidataId),
    );
  }
}
