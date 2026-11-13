// SPDX-License-Identifier: GPL-3.0-or-later

// M1 prototype 2 (PRD R3, R15), road A: download the tiles of a small region
// from the OpenFreeMap tile server, inside the limits of its terms of use,
// and store them in a local MBTiles file. Not production code.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:mbtiles/mbtiles.dart';

const String userAgent =
    'Itinerea/0.0.1 (+https://github.com/NotEnjoyingThis/itinerea)';

/// Limits from https://openfreemap.org/tos/ (read on 2026-11-13): "at most
/// 3,000 tiles or 50 MB", "at most 4 parallel requests".
const int maxTilesPerDownload = 3000;
const int maxBytesPerDownload = 50 * 1024 * 1024;
const int maxParallelRequests = 4;

const String tileJsonUrl = 'https://tiles.openfreemap.org/planet';
const String styleUrl = 'https://tiles.openfreemap.org/styles/liberty';

/// A rectangle in WGS84 degrees.
class Bounds {
  const Bounds({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  final double west;
  final double south;
  final double east;
  final double north;

  /// Rough area in square kilometres, good enough for a report.
  double get areaKm2 {
    const kmPerDegree = 111.32;
    final midLat = (south + north) / 2 * math.pi / 180;
    return (east - west) *
        kmPerDegree *
        math.cos(midLat) *
        (north - south) *
        kmPerDegree;
  }
}

class Tile {
  const Tile(this.z, this.x, this.y);

  final int z;
  final int x;
  final int y;
}

int _tileX(double lon, int z) =>
    ((lon + 180) / 360 * (1 << z)).floor().clamp(0, (1 << z) - 1);

int _tileY(double lat, int z) {
  final rad = lat * math.pi / 180;
  final y = (1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2;
  return (y * (1 << z)).floor().clamp(0, (1 << z) - 1);
}

/// Every tile that touches [bounds] from [minZoom] to [maxZoom].
List<Tile> tilesFor(Bounds bounds, {int minZoom = 0, required int maxZoom}) {
  final tiles = <Tile>[];
  for (var z = minZoom; z <= maxZoom; z++) {
    final x0 = _tileX(bounds.west, z);
    final x1 = _tileX(bounds.east, z);
    final y0 = _tileY(bounds.north, z);
    final y1 = _tileY(bounds.south, z);
    for (var x = x0; x <= x1; x++) {
      for (var y = y0; y <= y1; y++) {
        tiles.add(Tile(z, x, y));
      }
    }
  }
  return tiles;
}

class ZoomStats {
  int tiles = 0;
  int empty = 0;
  int transferBytes = 0;
  int rawBytes = 0;

  Map<String, Object> toJson() => {
    'tiles': tiles,
    'empty': empty,
    'transferKb': (transferBytes / 1024).round(),
    'rawKb': (rawBytes / 1024).round(),
  };
}

class DownloadRefused implements Exception {
  DownloadRefused(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Downloads [bounds] into [directory]: `region.mbtiles`, `style.json`,
/// `sprite.json` and `sprite.png`. Returns the numbers for the report.
Future<Map<String, Object?>> downloadRegion({
  required Bounds bounds,
  required Directory directory,
  void Function(int done, int total)? onProgress,
}) async {
  final client = HttpClient()
    ..userAgent = userAgent
    // Keep the compressed bytes as sent, to measure the real transfer.
    ..autoUncompress = false
    ..maxConnectionsPerHost = maxParallelRequests;
  final watch = Stopwatch()..start();

  Future<({Uint8List raw, int transfer, int status})> get(String url) async {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
    final response = await request.close();
    final builder = BytesBuilder(copy: false);
    await response.forEach(builder.add);
    final body = builder.takeBytes();
    final gzipped =
        response.headers.value(HttpHeaders.contentEncodingHeader) == 'gzip';
    return (
      raw: gzipped ? Uint8List.fromList(gzip.decode(body)) : body,
      transfer: body.length,
      status: response.statusCode,
    );
  }

  try {
    final tileJson = jsonDecode(
      utf8.decode((await get(tileJsonUrl)).raw),
    ) as Map<String, dynamic>;
    final template = (tileJson['tiles'] as List).first as String;
    final maxZoom = (tileJson['maxzoom'] as num).toInt();

    final tiles = tilesFor(bounds, maxZoom: maxZoom);
    if (tiles.length > maxTilesPerDownload) {
      throw DownloadRefused(
        'Region needs ${tiles.length} tiles, the limit is '
        '$maxTilesPerDownload.',
      );
    }

    await directory.create(recursive: true);
    final mbtilesFile = File('${directory.path}/region.mbtiles');
    if (mbtilesFile.existsSync()) mbtilesFile.deleteSync();
    final mbtiles = MbTiles.create(
      path: mbtilesFile.path,
      metadata: MbTilesMetadata(
        name: 'Itinerea prototype region',
        format: 'pbf',
        minZoom: 0,
        maxZoom: maxZoom.toDouble(),
        type: TileLayerType.baseLayer,
        attributionHtml: 'OpenFreeMap © OpenMapTiles Data from OpenStreetMap',
      ),
    );

    final stats = <int, ZoomStats>{};
    var transferTotal = 0;
    var done = 0;
    var next = 0;
    var failures = 0;

    Future<void> worker() async {
      while (next < tiles.length) {
        if (transferTotal > maxBytesPerDownload) {
          throw DownloadRefused('Download went over 50 MB, stopped.');
        }
        final tile = tiles[next++];
        final url = template
            .replaceFirst('{z}', '${tile.z}')
            .replaceFirst('{x}', '${tile.x}')
            .replaceFirst('{y}', '${tile.y}');
        final result = await get(url);
        final zoom = stats.putIfAbsent(tile.z, ZoomStats.new);
        if (result.status == 200 && result.raw.isNotEmpty) {
          zoom
            ..tiles += 1
            ..transferBytes += result.transfer
            ..rawBytes += result.raw.length;
          transferTotal += result.transfer;
          // MBTiles rows are numbered from the bottom (TMS).
          mbtiles.putTile(
            z: tile.z,
            x: tile.x,
            y: ((1 << tile.z) - 1) - tile.y,
            bytes: result.raw,
          );
        } else if (result.status == 200 || result.status == 204) {
          zoom.empty += 1;
        } else {
          failures += 1;
        }
        done += 1;
        onProgress?.call(done, tiles.length);
      }
    }

    await Future.wait([for (var i = 0; i < maxParallelRequests; i++) worker()]);
    mbtiles.close();
    final tilesMs = watch.elapsedMilliseconds;

    // The style and its sprite, so the map can be drawn without network.
    final style = await get(styleUrl);
    await File('${directory.path}/style.json').writeAsBytes(style.raw);
    final styleJson =
        jsonDecode(utf8.decode(style.raw)) as Map<String, dynamic>;
    final sprite = styleJson['sprite'] as String;
    final spriteJson = await get('$sprite.json');
    final spritePng = await get('$sprite.png');
    await File('${directory.path}/sprite.json').writeAsBytes(spriteJson.raw);
    await File('${directory.path}/sprite.png').writeAsBytes(spritePng.raw);

    return {
      'boundsWSEN': [bounds.west, bounds.south, bounds.east, bounds.north],
      'areaKm2': bounds.areaKm2.round(),
      'maxZoom': maxZoom,
      'tilesRequested': tiles.length,
      'tilesStored': stats.values.fold<int>(0, (sum, z) => sum + z.tiles),
      'failures': failures,
      'transferMb': (transferTotal / 1024 / 1024).toStringAsFixed(2),
      'mbtilesFileMb': (mbtilesFile.lengthSync() / 1024 / 1024).toStringAsFixed(
        2,
      ),
      'styleAndSpriteKb':
          ((style.transfer + spriteJson.transfer + spritePng.transfer) / 1024)
              .round(),
      'tilesDownloadMs': tilesMs,
      'tilesPerSecond': (tiles.length * 1000 / tilesMs).toStringAsFixed(1),
      'perZoom': {
        for (final entry in stats.entries) '${entry.key}': entry.value.toJson(),
      },
    };
  } finally {
    client.close(force: true);
  }
}
