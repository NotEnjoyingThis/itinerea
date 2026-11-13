# Prototype 3 — Valhalla routing and elevation

Questions (PRD R2): does the public Valhalla instance run by FOSSGIS cover what the app needs (car and motorbike, "avoid" options, alternatives, waypoints, Italian instructions), within its terms of use? Where does elevation come from?

A plain Dart command-line program: no interface, the same on every platform.

## Run

```sh
dart pub get
dart run bin/routing_probe.dart out            # 30 requests, about one minute
dart run bin/routing_probe.dart out --unpaved  # 5 more requests on an unpaved pass
```

The results are written to `out/report.json` (and `out/report_unpaved.json`).

## Be gentle

The instance is run by volunteers on a single server and allows **one request per second**. The program sends one request at a time with a 1.5 s pause, the project User-Agent and the `X-Client-Id` header. Do not run it in a loop and do not add it to CI.

## What it found

See PRD 5.6 (terms of use) and 16.3, and `docs/DECISIONS.md`.
