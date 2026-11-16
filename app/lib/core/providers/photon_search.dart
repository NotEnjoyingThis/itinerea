// SPDX-License-Identifier: GPL-3.0-or-later

import '../models/place.dart';
import '../net/http_transport.dart';
import '../net/throttle.dart';
import 'providers.dart';
import 'service_provider.dart';

/// Search of places on Photon (PRD 5.2), the geocoder by komoot, built for
/// search as you type.
///
/// The public instance asks to "please be fair" (PRD 5.6): requests go one
/// at a time and are not repeated for a text already searched. The wait
/// after the last key is the job of the screen (PRD 5.4).
class PhotonPlaceSearch implements PlaceSearchProvider {
  /// Creates the search on the instance at [baseUrl].
  PhotonPlaceSearch({
    required this._transport,
    Uri? baseUrl,
    Throttle? throttle,
  }) : baseUrl = baseUrl ?? defaultBaseUrl,
       _throttle = throttle ?? Throttle(const Duration(milliseconds: 400));

  /// The public instance run by komoot.
  static final Uri defaultBaseUrl = Uri.parse('https://photon.komoot.io/');

  /// Shortest text that is searched.
  static const int minimumLength = 3;

  /// Most suggestions asked for.
  static const int resultLimit = 6;

  /// Languages the public instance knows besides the local names: an
  /// Italian request is refused (checked on 16/11/2026, PRD 5.6).
  static const Set<String> supportedLanguages = {'de', 'en', 'fr'};

  final HttpTransport _transport;
  final Throttle _throttle;
  // The last texts searched, oldest first.
  final _recent = <String, List<PlaceSuggestion>>{};

  @override
  final Uri baseUrl;

  @override
  String get id => 'photon-komoot';

  @override
  ServiceCategory get category => ServiceCategory.placeSearch;

  @override
  int get minimumQueryLength => minimumLength;

  @override
  Future<List<PlaceSuggestion>> search(
    String query, {
    required String language,
    Coordinates? near,
  }) async {
    final text = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.length < minimumLength) return const [];
    final lang = supportedLanguages.contains(language) ? language : 'default';
    // The position only steers the results: about one kilometre is enough
    // (PRD 13.1), and the same area gives the same request.
    final lat = near == null ? null : _round(near.lat);
    final lon = near == null ? null : _round(near.lon);
    final key = '$lang|$lat|$lon|${text.toLowerCase()}';
    final known = _recent.remove(key);
    if (known != null) return _recent[key] = known;

    final uri = baseUrl
        .resolve('api/')
        .replace(
          queryParameters: {
            'q': text,
            'limit': '$resultLimit',
            'lang': lang,
            if (lat != null && lon != null) ...{
              'lat': '$lat',
              'lon': '$lon',
              // Without it, a café called "Uffizi" in Melbourne comes before
              // the museum in Florence (checked on 16/11/2026).
              'location_bias_scale': '0.1',
            },
          },
        );
    final response = await _throttle.run(() => _transport.get(uri));
    final suggestions = parse(response.json());
    _recent[key] = suggestions;
    if (_recent.length > 50) _recent.remove(_recent.keys.first);
    return suggestions;
  }

  /// Reads the GeoJSON answer of Photon. Features without a name or a valid
  /// position are left out, and so are repeated places. Texts are cut to a
  /// sensible length: the answer comes from outside.
  static List<PlaceSuggestion> parse(Object? json) {
    if (json case {'features': final List<Object?> features}) {
      final seen = <String>{};
      return [
        for (final feature in features)
          if (_suggestion(feature) case final suggestion?)
            if (suggestion.place.osmId == null ||
                seen.add(suggestion.place.osmId!))
              suggestion,
      ];
    }
    throw const ServiceFailure(
      ServiceFailureKind.badResponse,
      'not a FeatureCollection',
    );
  }

  static PlaceSuggestion? _suggestion(Object? feature) {
    if (feature case {
      'properties': final Map<String, Object?> properties,
      'geometry': {'coordinates': [final num lon, final num lat, ...]},
    }) {
      if (lat.abs() > 90 || lon.abs() > 180) return null;
      String? text(String key) => switch (properties[key]) {
        final String value when value.trim().isNotEmpty => _clip(value.trim()),
        _ => null,
      };
      final street = text('street');
      final number = text('housenumber');
      final streetLine = street == null
          ? null
          : (number == null ? street : '$street $number');
      final name = text('name') ?? streetLine;
      if (name == null) return null;
      final city = text('city') ?? text('town') ?? text('village');
      final parts = <String>[];
      for (final part in [
        if (streetLine != name) streetLine,
        city ?? text('state'),
        text('country'),
      ]) {
        if (part != null && part != name && !parts.contains(part)) {
          parts.add(part);
        }
      }
      final type = text('osm_type');
      final osmNumber = properties['osm_id'];
      final key = text('osm_key');
      final value = text('osm_value');
      return PlaceSuggestion(
        place: PlaceSnapshot(
          name: name,
          coordinates: Coordinates(lat: lat.toDouble(), lon: lon.toDouble()),
          address: parts.isEmpty ? null : parts.join(', '),
          osmId: const {'N', 'W', 'R'}.contains(type) && osmNumber is int
              ? '$type$osmNumber'
              : null,
        ),
        category: key == null || value == null ? null : '$key:$value',
      );
    }
    return null;
  }

  static double _round(double degrees) => (degrees * 100).round() / 100;

  static String _clip(String text) =>
      text.length <= 200 ? text : text.substring(0, 200);
}
