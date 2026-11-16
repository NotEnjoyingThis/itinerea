// SPDX-License-Identifier: GPL-3.0-or-later

import '../models/place.dart';
import '../models/web_address.dart';
import '../net/http_transport.dart';
import '../net/throttle.dart';
import 'providers.dart';
import 'service_provider.dart';

/// Opening hours and contacts of a place from Nominatim, the OpenStreetMap
/// search (PRD 5.2): one lookup request when the user chooses a place.
///
/// Its usage policy (PRD 5.6) allows "an absolute maximum of 1 request per
/// second", forbids search as you type and periodic requests from apps, and
/// asks to cache the answers: this class is never used while typing, the
/// requests go one at a time more than a second apart, and the answers are
/// kept for 30 days (PlaceDetailsLookup).
class NominatimPlaceDetails implements PlaceDetailsProvider {
  /// Creates the lookup on the instance at [baseUrl].
  NominatimPlaceDetails({
    required this._transport,
    Uri? baseUrl,
    Throttle? throttle,
    DateTime Function()? now,
  }) : baseUrl = baseUrl ?? defaultBaseUrl,
       _throttle = throttle ?? Throttle(const Duration(milliseconds: 1100)),
       _now = now ?? DateTime.now;

  /// The public instance of the OpenStreetMap Foundation.
  static final Uri defaultBaseUrl = Uri.parse(
    'https://nominatim.openstreetmap.org/',
  );

  static final RegExp _osmId = RegExp(r'^[NWR][1-9][0-9]{0,15}$');

  final HttpTransport _transport;
  final Throttle _throttle;
  final DateTime Function() _now;

  @override
  final Uri baseUrl;

  @override
  String get id => 'nominatim-osmf';

  @override
  ServiceCategory get category => ServiceCategory.placeDetails;

  @override
  Future<PlaceDetails> details(String osmId, {required String language}) async {
    if (!_osmId.hasMatch(osmId)) {
      throw ArgumentError.value(osmId, 'osmId', 'Not an OpenStreetMap id');
    }
    final uri = baseUrl
        .resolve('lookup')
        .replace(
          queryParameters: {
            'osm_ids': osmId,
            'format': 'jsonv2',
            'extratags': '1',
            'addressdetails': '0',
            'accept-language': language,
          },
        );
    final response = await _throttle.run(() => _transport.get(uri));
    return parse(response.json(), fetchedAt: _now().toUtc());
  }

  /// Reads the answer of a lookup. A place that Nominatim does not know, or
  /// knows without these tags, gives empty details: never an error, since
  /// OpenStreetMap often has nothing (F1.2).
  static PlaceDetails parse(Object? json, {required DateTime fetchedAt}) {
    if (json is! List<Object?>) {
      throw const ServiceFailure(ServiceFailureKind.badResponse, 'not a list');
    }
    final tags = switch (json) {
      [{'extratags': final Map<String, Object?> tags}, ...] => tags,
      _ => const <String, Object?>{},
    };
    String? tag(List<String> keys, {int max = 500}) {
      for (final key in keys) {
        if (tags[key] case final String value when value.trim().isNotEmpty) {
          final text = value.trim();
          return text.length <= max ? text : null;
        }
      }
      return null;
    }

    // OpenStreetMap separates several values with ";": one site is enough.
    final site = tag(['website', 'contact:website', 'url'])?.split(';').first;
    return PlaceDetails(
      fetchedAt: fetchedAt,
      openingHours: tag(['opening_hours']),
      phone: tag(['phone', 'contact:phone', 'contact:mobile'], max: 100),
      // Never a link that opens something other than a web page.
      website: site == null ? null : parseWebAddress(site)?.toString(),
      wikidataId: switch (tag(['wikidata'], max: 20)) {
        final String id when RegExp(r'^Q[1-9][0-9]*$').hasMatch(id) => id,
        _ => null,
      },
    );
  }
}
