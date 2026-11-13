// SPDX-License-Identifier: GPL-3.0-or-later

// M1 prototype 3 (PRD R2): what does the public Valhalla instance run by
// FOSSGIS give us for car and motorbike routes, "avoid" options, alternatives
// and waypoints, and where do we get elevation from? Not production code.
//
// About 30 requests, one at a time, with a pause between them (the instance
// allows 1 call per user per second).
//
// Run: dart run bin/routing_probe.dart [output folder] [--unpaved]

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const String valhalla = 'https://valhalla1.openstreetmap.de';
const String openMeteoElevation = 'https://api.open-meteo.com/v1/elevation';
const Map<String, String> headers = {
  'User-Agent': 'Itinerea/0.0.1 (+https://github.com/NotEnjoyingThis/itinerea)',
  // Asked by the Valhalla README of apps that use the public demo server.
  'X-Client-Id': 'github.com/NotEnjoyingThis/itinerea',
  'Content-Type': 'application/json',
};
const Duration pause = Duration(milliseconds: 1500);

typedef Point = ({double lat, double lon});

const Point firenze = (lat: 43.7696, lon: 11.2558);
const Point greve = (lat: 43.5840, lon: 11.3170); // Greve in Chianti
const Point siena = (lat: 43.3188, lon: 11.3308);
const Point genova = (lat: 44.4056, lon: 8.9463);
const Point olbia = (lat: 40.9236, lon: 9.4964);
const Point como = (lat: 45.8080, lon: 9.0852);
const Point luzern = (lat: 47.0502, lon: 8.3093);
const Point aosta = (lat: 45.7372, lon: 7.3206);
const Point bari = (lat: 41.1171, lon: 16.8719);
const Point susa = (lat: 45.1370, lon: 7.0480);
const Point fenestrelle = (lat: 45.0353, lon: 7.0497);

final http.Client client = http.Client();
final List<Map<String, Object?>> results = [];
int requestCount = 0;

Future<({int status, int ms, Object? json, String raw})> post(
  String url,
  Map<String, Object?> body,
) async {
  if (requestCount > 0) await Future<void>.delayed(pause);
  requestCount++;
  final watch = Stopwatch()..start();
  final response = await client.post(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(body),
  );
  final ms = watch.elapsedMilliseconds;
  Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(response.bodyBytes));
  } on FormatException {
    decoded = null;
  }
  return (
    status: response.statusCode,
    ms: ms,
    json: decoded,
    raw: utf8.decode(response.bodyBytes, allowMalformed: true),
  );
}

/// Decodes a Valhalla polyline (precision 6).
List<Point> decodePolyline6(String encoded) {
  final points = <Point>[];
  var index = 0;
  var lat = 0;
  var lon = 0;
  int next() {
    var result = 0;
    var shift = 0;
    int byte;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  }

  while (index < encoded.length) {
    lat += next();
    lon += next();
    points.add((lat: lat / 1e6, lon: lon / 1e6));
  }
  return points;
}

/// Kilometres of a trip flagged as toll, highway, ferry and unpaved, from
/// the maneuvers.
Map<String, Object?> summarize(Map<String, dynamic> trip) {
  final summary = trip['summary'] as Map<String, dynamic>;
  var toll = 0.0;
  var highway = 0.0;
  var ferry = 0.0;
  var rough = 0.0;
  var maneuvers = 0;
  var shapePoints = 0;
  final instructions = <String>[];
  for (final leg in trip['legs'] as List) {
    shapePoints += decodePolyline6((leg as Map)['shape'] as String).length;
    for (final maneuver in leg['maneuvers'] as List) {
      final m = maneuver as Map;
      final km = (m['length'] as num).toDouble();
      maneuvers++;
      if (m['toll'] == true) toll += km;
      if (m['highway'] == true) highway += km;
      if (m['ferry'] == true) ferry += km;
      if (m['rough'] == true) rough += km;
      if (instructions.length < 3) instructions.add(m['instruction'] as String);
    }
  }
  String km(double value) => value.toStringAsFixed(1);
  return {
    'km': km((summary['length'] as num).toDouble()),
    'minutes': ((summary['time'] as num) / 60).round(),
    'hasToll': summary['has_toll'],
    'hasHighway': summary['has_highway'],
    'hasFerry': summary['has_ferry'],
    'tollKm': km(toll),
    'highwayKm': km(highway),
    'ferryKm': km(ferry),
    'unpavedKm': km(rough),
    'maneuvers': maneuvers,
    'shapePoints': shapePoints,
    'firstInstructions': instructions,
  };
}

String? lastShape;

Future<void> route(
  String label, {
  required List<Point> through,
  String costing = 'auto',
  Map<String, Object?> options = const {},
  int alternates = 0,
  String language = 'it-IT',
}) async {
  final locations = [
    for (final (index, point) in through.indexed)
      {
        'lat': point.lat,
        'lon': point.lon,
        // Intermediate points are pass-through waypoints, not stops.
        'type': index == 0 || index == through.length - 1 ? 'break' : 'through',
      },
  ];
  final result = await post('$valhalla/route', {
    'locations': locations,
    'costing': costing,
    if (options.isNotEmpty) 'costing_options': {costing: options},
    if (alternates > 0) 'alternates': alternates,
    'units': 'kilometers',
    'language': language,
  });
  final entry = <String, Object?>{
    'label': label,
    'costing': costing,
    'options': options,
    'waypoints': through.length - 2,
    'alternatesAsked': alternates,
    'language': language,
    'status': result.status,
    'ms': result.ms,
    'responseKb': (result.raw.length / 1024).round(),
  };
  final json = result.json;
  if (result.status == 200 && json is Map<String, dynamic>) {
    final trip = json['trip'] as Map<String, dynamic>;
    entry['route'] = summarize(trip);
    final alternatives = (json['alternates'] as List?) ?? const [];
    entry['alternatesReturned'] = alternatives.length;
    entry['alternates'] = [
      for (final alternative in alternatives)
        summarize((alternative as Map)['trip'] as Map<String, dynamic>),
    ];
    lastShape = ((trip['legs'] as List).first as Map)['shape'] as String;
  } else {
    entry['error'] = json ?? result.raw;
  }
  results.add(entry);
  stdout.writeln(jsonEncode(entry));
}

Future<void> main(List<String> args) async {
  final outDir = Directory(args.isEmpty ? 'out' : args.first)
    ..createSync(recursive: true);

  if (args.contains('--unpaved')) {
    // --- Susa -> Fenestrelle: the direct road is the Colle delle Finestre,
    // a pass with about 8 km of unpaved road. Second, short run.
    const sf = [susa, fenestrelle];
    await route('SU-FE auto fastest', through: sf);
    await route(
      'SU-FE auto exclude unpaved',
      through: sf,
      options: {'exclude_unpaved': true},
    );
    await route('SU-FE moto fastest', through: sf, costing: 'motorcycle');
    await route(
      'SU-FE moto exclude unpaved',
      through: sf,
      costing: 'motorcycle',
      options: {'exclude_unpaved': true},
    );
    await route(
      'SU-FE moto use_trails 1',
      through: sf,
      costing: 'motorcycle',
      options: {'use_trails': 1},
    );
    client.close();
    File('${outDir.path}/report_unpaved.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ')
          .convert({'requests': requestCount, 'results': results}),
    );
    return;
  }

  // --- Firenze -> Siena: options, alternatives, waypoints, languages.
  const fs = [firenze, siena];
  await route('FI-SI auto fastest', through: fs);
  final firenzeSienaShape = lastShape;
  await route('FI-SI auto en-US', through: fs, language: 'en-US');
  await route(
    'FI-SI auto no highways',
    through: fs,
    options: {'use_highways': 0},
  );
  await route('FI-SI auto no tolls', through: fs, options: {'use_tolls': 0});
  await route(
    'FI-SI auto exclude unpaved',
    through: fs,
    options: {'exclude_unpaved': true},
  );
  await route('FI-SI auto alternates', through: fs, alternates: 2);
  await route('FI-SI auto via Greve', through: [firenze, greve, siena]);
  await route(
    'FI-SI auto via Greve + alternates',
    through: [firenze, greve, siena],
    alternates: 2,
  );
  await route('FI-SI moto fastest', through: fs, costing: 'motorcycle');
  await route(
    'FI-SI moto no highways',
    through: fs,
    costing: 'motorcycle',
    options: {'use_highways': 0},
  );
  await route(
    'FI-SI moto exclude unpaved',
    through: fs,
    costing: 'motorcycle',
    options: {'exclude_unpaved': true},
  );
  await route(
    'FI-SI moto use_trails 0',
    through: fs,
    costing: 'motorcycle',
    options: {'use_trails': 0},
  );
  await route(
    'FI-SI moto use_trails 1',
    through: fs,
    costing: 'motorcycle',
    options: {'use_trails': 1},
  );
  await route(
    'FI-SI moto no highways + trails 1',
    through: fs,
    costing: 'motorcycle',
    options: {'use_highways': 0, 'use_trails': 1},
  );

  // --- Genova -> Olbia: ferry, and what happens without one.
  const go = [genova, olbia];
  await route('GE-OL auto fastest', through: go);
  await route('GE-OL auto no ferry', through: go, options: {'use_ferry': 0});
  await route('GE-OL moto fastest', through: go, costing: 'motorcycle');

  // --- Como -> Luzern: Swiss vignette motorways and the Gotthard.
  const cl = [como, luzern];
  await route('CO-LU auto fastest', through: cl);
  await route('CO-LU auto no tolls', through: cl, options: {'use_tolls': 0});
  await route(
    'CO-LU auto no highways',
    through: cl,
    options: {'use_highways': 0},
  );
  await route('CO-LU auto alternates', through: cl, alternates: 2);
  await route(
    'CO-LU moto no tolls',
    through: cl,
    costing: 'motorcycle',
    options: {'use_tolls': 0},
  );

  // --- Aosta -> Bari: a long route, about 1,100 km.
  const ab = [aosta, bari];
  await route('AO-BA auto fastest', through: ab);
  await route('AO-BA auto no tolls', through: ab, options: {'use_tolls': 0});
  await route('AO-BA auto alternates', through: ab, alternates: 2);
  await route('AO-BA moto fastest', through: ab, costing: 'motorcycle');

  // --- Elevation along Firenze -> Siena.
  final shape = decodePolyline6(firenzeSienaShape!);
  final step = (shape.length / 100).ceil();
  final sampled = [for (var i = 0; i < shape.length; i += step) shape[i]];

  final status = await client.get(
    Uri.parse('$valhalla/status'),
    headers: headers,
  );
  requestCount++;
  results.add({
    'label': 'valhalla /status',
    'status': status.statusCode,
    'body': status.body.length > 600
        ? status.body.substring(0, 600)
        : status.body,
  });

  final height = await post('$valhalla/height', {
    'shape': [
      for (final p in sampled) {'lat': p.lat, 'lon': p.lon},
    ],
    'range': true,
  });
  final heightJson = height.json;
  results.add({
    'label': 'valhalla /height, ${sampled.length} points',
    'status': height.status,
    'ms': height.ms,
    if (heightJson is Map && heightJson['range_height'] is List)
      'first5': (heightJson['range_height'] as List).take(5).toList()
    else
      'error': height.raw.length > 400
          ? height.raw.substring(0, 400)
          : height.raw,
  });

  final fullHeight = await post('$valhalla/height', {
    'encoded_polyline': firenzeSienaShape,
    'shape_format': 'polyline6',
  });
  final fullJson = fullHeight.json;
  results.add({
    'label': 'valhalla /height, full shape (${shape.length} points)',
    'status': fullHeight.status,
    'ms': fullHeight.ms,
    'responseKb': (fullHeight.raw.length / 1024).round(),
    if (fullJson is Map && fullJson['height'] is List)
      'heights': (fullJson['height'] as List).length
    else
      'error': fullHeight.raw.length > 400
          ? fullHeight.raw.substring(0, 400)
          : fullHeight.raw,
  });

  await Future<void>.delayed(pause);
  final watch = Stopwatch()..start();
  // Coordinates rounded to 4 decimals (about 11 m): enough for a profile.
  final meteo = await client.get(
    Uri.parse(openMeteoElevation).replace(
      queryParameters: {
        'latitude': sampled.map((p) => p.lat.toStringAsFixed(4)).join(','),
        'longitude': sampled.map((p) => p.lon.toStringAsFixed(4)).join(','),
      },
    ),
    headers: {'User-Agent': headers['User-Agent']!},
  );
  requestCount++;
  Object? meteoJson;
  try {
    meteoJson = jsonDecode(meteo.body);
  } on FormatException {
    meteoJson = null;
  }
  results.add({
    'label': 'open-meteo elevation, ${sampled.length} points',
    'status': meteo.statusCode,
    'ms': watch.elapsedMilliseconds,
    if (meteoJson is Map && meteoJson['elevation'] is List)
      'first5': (meteoJson['elevation'] as List).take(5).toList()
    else
      'error': meteo.body.length > 400
          ? meteo.body.substring(0, 400)
          : meteo.body,
  });

  client.close();
  stdout.writeln('Requests sent: $requestCount');
  File('${outDir.path}/report.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ')
        .convert({'requests': requestCount, 'results': results}),
  );
}
