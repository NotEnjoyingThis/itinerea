# Prototypes

Isolated experiments for milestone **M1 — risk prototypes** (PRD 15.2 and 16.1). Each folder is a separate project with its own `pubspec.yaml`.

**This is not production code.** Nothing here is imported by the app, the app's analysis and tests ignore this folder, and the dependencies used here are not dependencies of the app. The results are recorded in `docs/PRD.md` and `docs/DECISIONS.md`.

| Folder | Question | Risk |
|---|---|---|
| `01_vector_map/` | Does an OpenFreeMap vector map drawn with `flutter_map` + `vector_map_tiles` work on Windows, Linux and Android? | R14 |
| `02_offline_map/` | Can a small region be downloaded and drawn without network, with the same look as the online map? Which way of getting the tiles is practical and allowed? | R3, R15 |
| `03_routing/` | Does the public Valhalla instance cover car and motorbike routes, "avoid" options, alternatives and waypoints within its terms of use? Where does elevation come from? | R2 |
| `04_drive_sync/` | Can two Google accounts share a trip folder on Google Drive with the narrow `drive.file` scope? What does the invited account see, and how fast? | R1, R10 |

Every request to a public service carries the project User-Agent and stays small and manual (PRD 5.4).
