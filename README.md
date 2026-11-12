# Itinerea

**Itinerea** is a free and open source app to plan, share and live trips and road trips by car and motorbike: day-by-day itinerary, routes, bookings, tickets, budget and map in one place.

No ads, no payments, no accounts, no telemetry and no central server: your trips live on your device. Sync, when you want it, goes through a space you choose (Google Drive, OneDrive, Dropbox, WebDAV, a local folder or a self-hosted server).

> **Status: in development.** Nothing is released yet. The repository currently contains the project foundations (milestone M0): an empty app with language and theme selection. See the [product requirements](docs/PRD.md) (in Italian) for the full plan.

## Platforms

| Platform | Status |
|---|---|
| Android | Supported |
| Windows 11 | Supported |
| macOS | Supported |
| Linux | Supported |
| iOS | Not distributed. The code is kept buildable, so you can compile it for yourself on a Mac. |

## Repository layout

| Path | Content |
|---|---|
| [`app/`](app/) | The Flutter app (all platforms) |
| [`sync-server/`](sync-server/) | Optional self-hosted Itinerea Sync Server (planned, phase 2) |
| [`data-packs/`](data-packs/) | Scripts that generate static data packs (planned, phases 2–4) |
| [`docs/`](docs/) | Project documents, in Italian: [PRD](docs/PRD.md), [decisions](docs/DECISIONS.md), [design](docs/DESIGN.md) |

## Building

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel, 3.50 or later) and the toolchain of the platform you build for (run `flutter doctor`). Android builds use JDK 21.

```sh
cd app
flutter pub get
flutter run                      # run on the connected device or desktop
flutter test                     # run the tests
flutter build apk                # Android
flutter build windows            # Windows
flutter build macos              # macOS
flutter build linux              # Linux
flutter build ios --no-codesign  # iOS, unsigned (not distributed)
```

Translations are generated from the ARB files in `app/lib/l10n/` by `flutter pub get` (or `flutter gen-l10n`).

## Contributing

Contributions are welcome: see [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md). Please report security problems privately, as described in [SECURITY.md](SECURITY.md).

## License

Itinerea is free software, licensed under the **GNU General Public License, version 3 or (at your option) any later version** (`GPL-3.0-or-later`). See [LICENSE](LICENSE). Data licenses are listed in [LICENSE-DATA.md](LICENSE-DATA.md).

Map data © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors.

---

## Italiano

**Itinerea** è un'app libera e gratuita per pianificare, condividere e vivere viaggi e roadtrip in auto e in moto: itinerario giorno per giorno, percorsi, prenotazioni, biglietti, budget e mappa in un unico posto.

Niente pubblicità, pagamenti, account, telemetria o server centrale: i viaggi restano sul tuo dispositivo. La sincronizzazione, se la vuoi, passa da uno spazio scelto da te (Google Drive, OneDrive, Dropbox, WebDAV, una cartella locale o un server self-hosted).

- **Stato:** in sviluppo, nessuna versione pubblicata. Oggi il repository contiene le fondamenta del progetto (milestone M0).
- **Piattaforme:** Android, Windows 11, macOS e Linux. iOS non è distribuito, ma il codice resta compilabile.
- **Licenza:** GPL-3.0-or-later (vedi [LICENSE](LICENSE)).
- **Come compilare:** installa Flutter (canale stable, 3.50 o successivo), poi `cd app`, `flutter pub get` e `flutter run`. I comandi di build per ogni piattaforma sono nella sezione [Building](#building).
- **Documenti di progetto** (in italiano): [PRD](docs/PRD.md), [decisioni](docs/DECISIONS.md), [stile](docs/DESIGN.md).
- **Contribuire:** leggi [CONTRIBUTING.md](CONTRIBUTING.md) (in inglese).
