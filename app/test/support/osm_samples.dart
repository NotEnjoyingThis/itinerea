// SPDX-License-Identifier: GPL-3.0-or-later

// Small samples of answers of Photon and Nominatim, shortened from real ones
// (16/11/2026). The data comes from OpenStreetMap: © OpenStreetMap
// contributors, ODbL.

import 'dart:async';

import 'package:itinerea/core/net/http_transport.dart';

import 'fake_transport.dart';

/// Photon, searching "Uffizi": a museum, a museum with a house number and a
/// street.
const Map<String, Object?> photonUffizi = {
  'type': 'FeatureCollection',
  'features': [
    {
      'type': 'Feature',
      'properties': {
        'osm_type': 'W',
        'osm_id': 477279033,
        'osm_key': 'tourism',
        'osm_value': 'museum',
        'type': 'house',
        'name': 'Galleria degli Uffizi',
        'street': 'Via dei Girolami',
        'city': 'Firenze',
        'state': 'Toscana',
        'country': 'Italia',
        'postcode': '50125',
        'countrycode': 'IT',
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [11.2558009, 43.7683129],
      },
    },
    {
      'type': 'Feature',
      'properties': {
        'osm_type': 'N',
        'osm_id': 1536508344,
        'osm_key': 'tourism',
        'osm_value': 'museum',
        'type': 'house',
        'housenumber': '5',
        'name': 'Gabinetto dei Disegni e delle Stampe degli Uffizi',
        'street': 'Via della Ninna',
        'city': 'Firenze',
        'country': 'Italia',
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [11.2561725, 43.7687716],
      },
    },
    {
      'type': 'Feature',
      'properties': {
        'osm_type': 'W',
        'osm_id': 23298781,
        'osm_key': 'highway',
        'osm_value': 'pedestrian',
        'type': 'street',
        'name': 'Piazzale degli Uffizi',
        'city': 'Firenze',
        'country': 'Italia',
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [11.2554494, 43.7682095],
      },
    },
  ],
};

/// Nominatim, looking up the Uffizi (W477279033) with its extra tags.
const List<Object?> nominatimUffizi = [
  {
    'place_id': 81628855,
    'licence':
        'Data © OpenStreetMap contributors, ODbL 1.0. '
        'http://osm.org/copyright',
    'osm_type': 'way',
    'osm_id': 477279033,
    'lat': '43.7683129',
    'lon': '11.2558009',
    'category': 'tourism',
    'type': 'museum',
    'name': 'Galleria degli Uffizi',
    'extratags': {
      'fee': 'yes',
      'phone': '+39 055 294883',
      'museum': 'art',
      'website': 'https://www.uffizi.it',
      'wikidata': 'Q51252',
      'opening_hours': 'Tu-Su 08:15-18:30; Mo off; Jan 1 off; Dec 25 off',
    },
  },
];

/// Nominatim, looking up a place without any of the tags the app reads.
const List<Object?> nominatimNothing = [
  {
    'osm_type': 'way',
    'osm_id': 23298781,
    'category': 'highway',
    'type': 'pedestrian',
    'name': 'Piazzale degli Uffizi',
    'extratags': <String, Object?>{},
  },
];

/// Answers as Photon for searches and as Nominatim for lookups.
FutureOr<TransportResponse> Function(Uri uri) osmServices({
  Object? search = photonUffizi,
  Object? lookup = nominatimUffizi,
}) =>
    (uri) => switch (uri.path) {
      '/api/' || '/api' => jsonAnswer(search),
      '/lookup' => jsonAnswer(lookup),
      _ => jsonAnswer({'error': 'not found'}, status: 404),
    };
