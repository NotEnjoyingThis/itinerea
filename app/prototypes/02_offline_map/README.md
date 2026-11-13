# Prototype 2 — Offline map of a small region

Questions (PRD R3, R15): can the app download the map of a small region and draw it without network, with the same look as the online map? Which way of getting the tiles is practical and allowed?

Three roads are compared:

| Road | What | Where |
|---|---|---|
| A | Download the `z/x/y` tiles of a rectangle from the OpenFreeMap tile server, inside the limits of its terms of use (at most 3,000 tiles or 50 MB, 4 parallel requests, identifying User-Agent), and store them in a local MBTiles file | `lib/region.dart`, `lib/main.dart` |
| B | Read single tiles from the 87 GB planet PMTiles with HTTP range requests (measurement only, a few requests) | `pmtiles_probe/` |
| C | Extract regions from the planet PMTiles with `pmtiles extract` in a GitHub Action and publish them as data packs (here only the size is measured, with `--dry-run`) | `region-extract-size` job in `.github/workflows/prototypes.yml` |

## Run

```sh
flutter pub get
flutter run -d windows        # then press "Download Florence"
```

Unattended:

```sh
flutter build windows --release
PROTO_PHASE=download PROTO_OUT=/some/folder build/windows/x64/runner/Release/offline_map.exe
PROTO_PHASE=offline  PROTO_OUT=/some/folder build/windows/x64/runner/Release/offline_map.exe
```

The `offline` phase refuses every network connection and counts the attempts: the report must say `"networkAttempts": 0`. On Android use `--dart-define=PROTO_PHASE=…` and read the `PROTO_REPORT` line in logcat.

Road B:

```sh
cd pmtiles_probe
dart pub get
dart run bin/pmtiles_probe.dart https://btrfs.openfreemap.com/areas/planet/<version>/tiles.pmtiles
```

## What it found

See PRD 16.3 and `docs/DECISIONS.md`.
