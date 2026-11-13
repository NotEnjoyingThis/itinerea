// SPDX-License-Identifier: GPL-3.0-or-later

// M1 prototype 2, road B: how do HTTP range requests on the OpenFreeMap
// planet PMTiles (about 87 GB) behave? Reads the header and a handful of
// tiles around Florence, one per zoom level, and prints the latency of each.
// At most a few dozen small requests. Not production code.
//
// Run: dart run bin/pmtiles_probe.dart <url of tiles.pmtiles>

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:pmtiles/pmtiles.dart';

const String userAgent =
    'Itinerea/0.0.1 (+https://github.com/NotEnjoyingThis/itinerea)';

/// Counts requests and bytes, and records the latency of each one.
class CountingClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  int requests = 0;
  int bytes = 0;
  final List<int> latenciesMs = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests++;
    request.headers['User-Agent'] = userAgent;
    final watch = Stopwatch()..start();
    final response = await _inner.send(request);
    final body = await response.stream.toBytes();
    latenciesMs.add(watch.elapsedMilliseconds);
    bytes += body.length;
    return http.StreamedResponse(
      Stream.value(body),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }

  @override
  void close() => _inner.close();
}

(int, int) tileXY(double lat, double lon, int z) {
  final n = 1 << z;
  final rad = lat * math.pi / 180;
  final x = ((lon + 180) / 360 * n).floor();
  final y =
      ((1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2 * n)
          .floor();
  return (x, y);
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run bin/pmtiles_probe.dart <pmtiles url>');
    exitCode = 64;
    return;
  }
  final client = CountingClient();
  final report = <String, Object?>{'url': args.first};

  final openWatch = Stopwatch()..start();
  final archive = await PmTilesArchive.fromUri(
    Uri.parse(args.first),
    client: client,
  );
  report['openMs'] = openWatch.elapsedMilliseconds;
  report['requestsToOpen'] = client.requests;
  report['minZoom'] = archive.minZoom;
  report['maxZoom'] = archive.maxZoom;
  report['tileCompression'] = archive.header.tileCompression.name;
  report['rootDirectoryKb'] = (archive.header.rootDirectoryLength / 1024)
      .round();
  report['leafDirectoriesMb'] =
      (archive.header.leafDirectoriesLength / 1024 / 1024).round();
  report['tileDataGb'] = (archive.header.tileDataLength / 1024 / 1024 / 1024)
      .round();

  final tiles = <Map<String, Object?>>[];
  for (final z in [0, 4, 8, 10, 12, 13, 14, 14, 14]) {
    // Florence; at zoom 14 also two neighbours, to see a warm directory.
    final (x, y) = tileXY(43.7696, 11.2558, z);
    final dx = z == 14 ? tiles.where((t) => t['z'] == 14).length : 0;
    final before = client.requests;
    final watch = Stopwatch()..start();
    final tile = await archive.tile(ZXY(z, x + dx, y).toTileId());
    final length = tile.bytes().length;
    tiles.add({
      'z': z,
      'ms': watch.elapsedMilliseconds,
      'requests': client.requests - before,
      'kb': (length / 1024).round(),
    });
  }
  report['tiles'] = tiles;
  report['totalRequests'] = client.requests;
  report['totalTransferKb'] = (client.bytes / 1024).round();
  final sorted = [...client.latenciesMs]..sort();
  report['requestMsMin'] = sorted.first;
  report['requestMsMedian'] = sorted[sorted.length ~/ 2];
  report['requestMsMax'] = sorted.last;

  await archive.close();
  client.close();
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
}
