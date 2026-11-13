// SPDX-License-Identifier: GPL-3.0-or-later

// M1 prototype 2 (PRD R3, R15): offline map of a small region. Not
// production code.
//
// Unattended runs (environment variables, or --dart-define on Android):
//   PROTO_PHASE=download   download the region, write report_download.json, exit
//   PROTO_PHASE=offline    block every network connection, draw the map from
//                          the local files, write report_offline.json, exit
//   PROTO_OUT=<dir>        where reports and screenshots are written

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mbtiles/mbtiles.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_mbtiles/vector_map_tiles_mbtiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

import 'region.dart';

/// Florence and its surroundings, about 48 x 39 km.
const Bounds florenceArea = Bounds(
  west: 10.95,
  south: 43.60,
  east: 11.55,
  north: 43.95,
);
const LatLng florence = LatLng(43.7696, 11.2558);

final String phase =
    Platform.environment['PROTO_PHASE'] ??
    const String.fromEnvironment('PROTO_PHASE');
final String outDir =
    Platform.environment['PROTO_OUT'] ?? Directory.systemTemp.path;

/// Counts every attempt to open a network connection and refuses it. Used in
/// the offline phase to prove that the map needs no network.
class NoNetwork extends HttpOverrides {
  static int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw const SocketException('Network disabled by the prototype');
  }
}

Future<Directory> dataDirectory() async =>
    Directory('${(await getApplicationSupportDirectory()).path}/offline');

void main() {
  if (phase == 'offline') HttpOverrides.global = NoNetwork();
  runApp(
    MaterialApp(
      title: 'Prototype 2 - offline map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1F6F6B)),
      home: const OfflinePage(),
    ),
  );
}

class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  final MapController _controller = MapController();
  final GlobalKey _repaintKey = GlobalKey();

  String _status = 'Nothing downloaded yet.';
  bool _busy = false;
  vtr.Theme? _theme;
  SpriteStyle? _sprites;
  MbTilesVectorTileProvider? _provider;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    if (phase == 'download') {
      final report = await _download();
      await _finish('report_download.json', report);
    } else if (phase == 'offline') {
      final report = <String, Object?>{};
      try {
        await _openLocal();
        await Future<void>.delayed(const Duration(seconds: 12));
        await _capture('offline_z13.png');
        _controller.move(florence, 15.5);
        await Future<void>.delayed(const Duration(seconds: 10));
        await _capture('offline_z15.png');
        // Outside the downloaded region: nothing must be fetched.
        _controller.move(const LatLng(45.4642, 9.19), 13);
        await Future<void>.delayed(const Duration(seconds: 6));
        await _capture('offline_outside.png');
        report['mapShown'] = true;
      } on Object catch (error) {
        report['error'] = error.toString();
      }
      report['networkAttempts'] = NoNetwork.attempts;
      report['rssMb'] = ProcessInfo.currentRss ~/ (1024 * 1024);
      await _finish('report_offline.json', report);
    } else if (File('${(await dataDirectory()).path}/region.mbtiles')
        .existsSync()) {
      await _openLocal();
    }
  }

  Future<Map<String, Object?>> _download() async {
    setState(() {
      _busy = true;
      _status = 'Downloading…';
    });
    Map<String, Object?> report;
    try {
      report = await downloadRegion(
        bounds: florenceArea,
        directory: await dataDirectory(),
        onProgress: (done, total) {
          if (done % 50 == 0 && mounted) {
            setState(() => _status = 'Downloading… $done / $total tiles');
          }
        },
      );
      _status =
          'Downloaded ${report['tilesStored']} tiles, '
          '${report['transferMb']} MB.';
    } on Object catch (error) {
      report = {'error': error.toString()};
      _status = 'Download failed: $error';
    }
    if (mounted) setState(() => _busy = false);
    return report;
  }

  /// Builds theme, sprites and tile provider from the local files only.
  Future<void> _openLocal() async {
    final dir = (await dataDirectory()).path;
    final style = jsonDecode(
      await File('$dir/style.json').readAsString(),
    ) as Map<String, dynamic>;
    // The style also has a raster relief layer served online; offline it is
    // left out (it is only visible below zoom 7).
    final sources = (style['sources'] as Map<String, dynamic>)
      ..removeWhere((_, source) => (source as Map)['type'] != 'vector');
    style['layers'] = (style['layers'] as List)
        .where(
          (layer) =>
              (layer as Map)['source'] == null ||
              sources.containsKey(layer['source']),
        )
        .toList();
    final parsed = vtr.ThemeReader().read(style);
    final spriteIndex = vtr.SpriteIndexReader().read(
      jsonDecode(await File('$dir/sprite.json').readAsString())
          as Map<String, dynamic>,
    );
    final mbtiles = MbTiles(path: '$dir/region.mbtiles', gzip: true);
    setState(() {
      _theme = vtr.Theme(
        id: 'openfreemap-liberty-offline',
        version: parsed.version,
        layers: parsed.layers,
      );
      _sprites = SpriteStyle(
        atlasProvider: () => File('$dir/sprite.png').readAsBytes(),
        index: spriteIndex,
      );
      _provider = MbTilesVectorTileProvider(mbtiles: mbtiles);
      _status = 'Map drawn from local files.';
    });
  }

  Future<void> _capture(String name) async {
    final boundary =
        _repaintKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$outDir/$name').writeAsBytes(bytes!.buffer.asUint8List());
  }

  Future<void> _finish(String name, Map<String, Object?> report) async {
    report['platform'] = Platform.operatingSystem;
    await File('$outDir/$name')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
    debugPrint('PROTO_REPORT ${jsonEncode(report)}');
    await Future<void>.delayed(const Duration(seconds: 1));
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final provider = _provider;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline map'),
        actions: [
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    await _download();
                    await _openLocal();
                  },
            child: const Text('Download Florence'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(8), child: Text(_status)),
          Expanded(
            child: RepaintBoundary(
              key: _repaintKey,
              child: theme == null || provider == null
                  ? const ColoredBox(color: Color(0xFFE0E0E0))
                  : FlutterMap(
                      mapController: _controller,
                      options: const MapOptions(
                        initialCenter: florence,
                        initialZoom: 13,
                        maxZoom: 20,
                      ),
                      children: [
                        VectorTileLayer(
                          theme: theme,
                          sprites: _sprites,
                          tileProviders: TileProviders({
                            'openmaptiles': provider,
                          }),
                          layerMode: VectorTileLayerMode.raster,
                        ),
                        const SimpleAttributionWidget(
                          source: Text(
                            'OpenFreeMap © OpenMapTiles Data from '
                            'OpenStreetMap',
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
