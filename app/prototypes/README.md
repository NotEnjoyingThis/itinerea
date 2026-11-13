# Prototypes

Isolated experiments for milestone **M1 — risk prototypes** (PRD 15.2 and 16.1). Each folder is a separate project with its own `pubspec.yaml`.

**This is not production code.** Nothing here is imported by the app, the app's analysis and tests ignore this folder, and the dependencies used here are not dependencies of the app. The results are recorded in `docs/PRD.md` and `docs/DECISIONS.md`.

| Folder | Question | Risk |
|---|---|---|
| `01_vector_map/` | Does an OpenFreeMap vector map drawn with `flutter_map` + `vector_map_tiles` work on Windows, Linux and Android? | R14 |

Every request to a public service carries the project User-Agent and stays small and manual (PRD 5.4).
