// SPDX-License-Identifier: GPL-3.0-or-later

// M1 prototype 1 (PRD R14): OpenFreeMap vector tiles drawn with flutter_map
// and vector_map_tiles. Not production code.
//
// Environment variables for unattended runs:
//   PROTO_AUTORUN=1   pan and zoom automatically, write results, then exit
//   PROTO_OUT=<dir>   where report.json and the screenshots are written
//   PROTO_MODE=vector|raster   rendering mode of the tile layer (default raster)

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

const String userAgent =
    'Itinerea/0.0.1 (+https://github.com/NotEnjoyingThis/itinerea)';
const Map<String, String> httpHeaders = {'User-Agent': userAgent};

const String lightStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';
const String darkStyleUrl = 'https://tiles.openfreemap.org/styles/dark';

const LatLng florence = LatLng(43.7696, 11.2558);

/// A few stops in Florence and a hand-drawn line between them, to check that
/// markers and routes can be drawn above the vector layer (needed by F1.7).
const List<LatLng> stops = [
  LatLng(43.7687, 11.2553), // Uffizi
  LatLng(43.7731, 11.2560), // Duomo
  LatLng(43.7651, 11.2500), // Palazzo Pitti
];

// On Android there are no environment variables: use --dart-define there.
final bool autorun =
    Platform.environment['PROTO_AUTORUN'] == '1' ||
    const bool.fromEnvironment('PROTO_AUTORUN');
final String outDir =
    Platform.environment['PROTO_OUT'] ?? Directory.systemTemp.path;
final VectorTileLayerMode initialMode =
    (Platform.environment['PROTO_MODE'] ??
            const String.fromEnvironment('PROTO_MODE')) ==
        'vector'
    ? VectorTileLayerMode.vector
    : VectorTileLayerMode.raster;

void main() {
  runApp(const PrototypeApp());
}

class PrototypeApp extends StatelessWidget {
  const PrototypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prototype 1 - vector map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1F6F6B)),
      home: const MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _controller = MapController();
  final GlobalKey _repaintKey = GlobalKey();
  final Stopwatch _sinceStart = Stopwatch()..start();
  final List<FrameTiming> _timings = [];
  final Map<String, Object?> _report = {};

  Style? _style;

  /// Theme id of the loaded style. It changes together with [_style]: giving
  /// a new id to the old layers would cache light tiles under the dark id.
  String _styleId = '';
  Object? _error;
  bool _dark = false;
  VectorTileLayerMode _mode = initialMode;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_timings.addAll);
    unawaited(_loadStyle());
  }

  Future<void> _loadStyle() async {
    final dark = _dark;
    final watch = Stopwatch()..start();
    try {
      final style = await StyleReader(
        uri: dark ? darkStyleUrl : lightStyleUrl,
        httpHeaders: httpHeaders,
      ).read();
      _report['styleLoadMs${dark ? 'Dark' : 'Light'}'] =
          watch.elapsedMilliseconds;
      if (!mounted) return;
      setState(() {
        _style = style;
        _styleId = dark ? 'openfreemap-dark' : 'openfreemap-liberty';
        _error = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
      _report['styleError'] = error.toString();
    }
    if (autorun && !_autorunStarted) {
      _autorunStarted = true;
      unawaited(_runScript());
    }
  }

  bool _autorunStarted = false;

  /// Unattended script: wait for tiles, capture, pan and zoom while frame
  /// timings are recorded, switch to the dark style, capture again, exit.
  Future<void> _runScript() async {
    _report['mode'] = _mode.name;
    _report['platform'] = Platform.operatingSystem;
    _report['styleReadyAfterStartMs'] = _sinceStart.elapsedMilliseconds;

    await Future<void>.delayed(const Duration(seconds: 12));
    _report['rssAfterFirstViewMb'] = _rssMb();
    await _capture('light.png');

    _timings.clear();
    final panWatch = Stopwatch()..start();
    // 10 seconds of continuous panning around Florence at street zoom.
    while (panWatch.elapsedMilliseconds < 10000) {
      final t = panWatch.elapsedMilliseconds / 10000;
      _controller.move(
        LatLng(florence.latitude + 0.02 * t, florence.longitude + 0.04 * t),
        14,
      );
      await SchedulerBinding.instance.endOfFrame;
    }
    _report['pan'] = _summarize(_timings, panWatch.elapsedMilliseconds);

    _timings.clear();
    final zoomWatch = Stopwatch()..start();
    // 8 seconds of continuous zoom from country level to street level.
    while (zoomWatch.elapsedMilliseconds < 8000) {
      final t = zoomWatch.elapsedMilliseconds / 8000;
      _controller.move(florence, 6 + 10 * t);
      await SchedulerBinding.instance.endOfFrame;
    }
    _report['zoom'] = _summarize(_timings, zoomWatch.elapsedMilliseconds);

    await Future<void>.delayed(const Duration(seconds: 8));
    await _capture('light_zoom16.png');

    _controller.move(florence, 13);
    setState(() => _dark = true);
    await _loadStyle();
    await Future<void>.delayed(const Duration(seconds: 12));
    await _capture('dark.png');
    _report['rssAtEndMb'] = _rssMb();
    _report['totalRunMs'] = _sinceStart.elapsedMilliseconds;

    final file = File('$outDir/report_${_mode.name}.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(_report),
    );
    // debugPrint reaches logcat on Android; stdout does not.
    debugPrint('PROTO_REPORT ${jsonEncode(_report)}');
    await Future<void>.delayed(const Duration(seconds: 1));
    exit(0);
  }

  int _rssMb() => ProcessInfo.currentRss ~/ (1024 * 1024);

  Map<String, Object?> _summarize(List<FrameTiming> timings, int elapsedMs) {
    if (timings.isEmpty) return {'frames': 0};
    List<int> sorted(int Function(FrameTiming) pick) =>
        timings.map(pick).toList()..sort();
    final build = sorted((t) => t.buildDuration.inMicroseconds);
    final raster = sorted((t) => t.rasterDuration.inMicroseconds);
    final total = sorted((t) => t.totalSpan.inMicroseconds);
    double ms(List<int> values, double quantile) =>
        values[((values.length - 1) * quantile).round()] / 1000;
    return {
      'frames': timings.length,
      'fps': (timings.length * 1000 / elapsedMs).toStringAsFixed(1),
      'buildMsP50': ms(build, 0.5),
      'buildMsP90': ms(build, 0.9),
      'buildMsMax': ms(build, 1),
      'rasterMsP50': ms(raster, 0.5),
      'rasterMsP90': ms(raster, 0.9),
      'rasterMsMax': ms(raster, 1),
      'totalMsP50': ms(total, 0.5),
      'totalMsP90': ms(total, 0.9),
      'framesOver16ms': total.where((v) => v > 16667).length,
      'framesOver33ms': total.where((v) => v > 33333).length,
    };
  }

  Future<void> _capture(String name) async {
    try {
      final boundary =
          _repaintKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$outDir/${_mode.name}_$name')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } on Object catch (error) {
      _report['captureError_$name'] = error.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'OpenFreeMap - ${_mode.name} - ${_dark ? 'dark' : 'light'}',
        ),
        actions: [
          IconButton(
            tooltip: 'Light / dark style',
            icon: Icon(_dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() => _dark = !_dark);
              unawaited(_loadStyle());
            },
          ),
          IconButton(
            tooltip: 'Vector / raster rendering',
            icon: const Icon(Icons.layers),
            onPressed: () => setState(
              () => _mode = _mode == VectorTileLayerMode.vector
                  ? VectorTileLayerMode.raster
                  : VectorTileLayerMode.vector,
            ),
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _repaintKey,
        child: _error != null
            ? Center(child: Text('Style not loaded: $_error'))
            : style == null
            ? const Center(child: CircularProgressIndicator())
            : FlutterMap(
                mapController: _controller,
                options: const MapOptions(
                  initialCenter: florence,
                  initialZoom: 13,
                  maxZoom: 20,
                ),
                children: [
                  VectorTileLayer(
                    key: ValueKey('${_styleId}_$_mode'),
                    // OpenFreeMap styles have no "id": every theme would be
                    // called "default" and share the tile caches, so the
                    // dark style would show the light tiles.
                    theme: vtr.Theme(
                      id: _styleId,
                      version: style.theme.version,
                      layers: style.theme.layers,
                    ),
                    sprites: style.sprites,
                    tileProviders: style.providers,
                    layerMode: _mode,
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: stops,
                        strokeWidth: 5,
                        color: const Color(0xFF1565C0),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      for (final (index, point) in stops.indexed)
                        Marker(
                          point: point,
                          width: 32,
                          height: 32,
                          child: CircleAvatar(
                            backgroundColor: const Color(0xFFC62828),
                            foregroundColor: Colors.white,
                            child: Text('${index + 1}'),
                          ),
                        ),
                    ],
                  ),
                  const SimpleAttributionWidget(
                    source: Text(
                      'OpenFreeMap © OpenMapTiles Data from OpenStreetMap',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
