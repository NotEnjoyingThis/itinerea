# Prototype 1 — OpenFreeMap vector map

Question (PRD R14): is `vector_map_tiles` (beta line) good enough to draw the OpenFreeMap vector map on Windows, Linux and Android?

It shows the OpenFreeMap "liberty" and "dark" styles with `flutter_map` 8.3.2 and `vector_map_tiles` 9.0.0-beta.13, draws a line and three markers above the map, and can switch between the two rendering modes of the tile layer.

## Run

```sh
flutter pub get
flutter run -d windows        # or -d linux, or an Android device
```

Buttons in the title bar: light/dark style, vector/raster rendering.

## Unattended run

The app pans and zooms by itself, writes `report_<mode>.json` and three screenshots, then exits.

```sh
flutter build windows --release
PROTO_AUTORUN=1 PROTO_MODE=raster PROTO_OUT=/some/folder build/windows/x64/runner/Release/vector_map.exe
```

On Android there are no environment variables; use build-time values, and read the report from logcat (line starting with `PROTO_REPORT`):

```sh
flutter build apk --profile --dart-define=PROTO_AUTORUN=true --dart-define=PROTO_MODE=raster
```

Linux is checked by the `Prototypes` workflow, under a virtual display.

## What it found

See PRD 4.2 and R14, and `docs/DECISIONS.md` (13/11/2026).
