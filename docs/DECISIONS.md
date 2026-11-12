# Itinerea — Registro delle decisioni

Ogni decisione presa durante lo sviluppo si scrive qui e nella sezione pertinente di [`PRD.md`](PRD.md) (CLAUDE.md §1.4).

**Formato:** una riga per decisione, in ordine di data: **data · decisione · motivo · riferimenti**. Le decisioni non si cancellano: se una cambia, si aggiunge una riga nuova che cita quella superata.

## Decisioni

| Data | Decisione | Motivo | Rif. |
|---|---|---|---|
| 11/11/2026 | Progetto open source, gratuito, senza pubblicità, senza pagamenti e **senza server centrale**. L'app funziona in locale; la sincronizzazione passa da uno spazio scelto dall'utente. | Costo zero per il progetto, privacy, indipendenza da un gestore. | PRD 1.4, 4.1 |
| 12/11/2026 | Licenza del codice: **GPL-3.0-or-later**. | Permette di usare anche le versioni future della GPL. | PRD 12.1, D1 |
| 12/11/2026 | Nome **Itinerea**; identificativo `io.github.notenjoyingthis.itinerea`, definitivo. | Nomi alternativi già usati da altre app; l'identificativo non si può cambiare dopo la pubblicazione negli store. | PRD R13, R16, D6 |
| 12/11/2026 | Lingua: nomi, commenti e commit in inglese; README in inglese con sezione in italiano; CONTRIBUTING e CODE_OF_CONDUCT in inglese; documenti in `docs/` in italiano. | Codice aperto a contributi internazionali, documenti di progetto nella lingua di chi li scrive. | PRD intestazione |
| 12/11/2026 | Distribuzione: GitHub Releases, Google Play, F-Droid, Flathub. Niente App Store, Microsoft Store, Mac App Store. iOS resta compilabile. | Nessun costo ricorrente; iOS non è installabile in pratica senza App Store. | PRD 4.9 |
| 12/11/2026 | Donazioni solo tramite GitHub Sponsors, senza nulla in cambio. | Nessuna commissione, nessuna funzione a pagamento. | PRD 4.11 |
| 12/11/2026 | L'impalcatura di tutte le fasi si prepara **dopo M1**; le schermate segnaposto delle Fasi 2–4 si vedono solo nelle build di debug. | Dare una forma coerente al progetto usando i risultati dei prototipi, senza mostrare funzioni finte agli utenti. | PRD 15.1 |
| 12/11/2026 | **M0 — Material:** l'app usa il pacchetto `material_ui` (team Flutter, BSD-3), come il modello di progetto di Flutter 3.50, in cui Material non fa più parte dell'SDK. I delegati di localizzazione sono `GlobalMaterialLocalizations.delegates` di `material_ui`, non quelli di `flutter_localizations`. | I delegati di `flutter_localizations` non servono i widget di `material_ui`: senza questa scelta l'app in italiano non parte (errore scoperto dai test). | PRD 4.2 |
| 12/11/2026 | **M0 — Riverpod senza generatore di codice** (`riverpod_generator`, `build_runner`): i provider si scrivono a mano con `Notifier`. | Meno dipendenze e nessun passo di generazione in più. Si può rivedere in M2 se i provider diventano molti. | PRD 4.2 |
| 12/11/2026 | **M0 — File di localizzazione generati non versionati** (`app/lib/l10n/generated/`): li crea `flutter pub get` o `flutter gen-l10n`. Hanno l'intestazione SPDX e sono formattati (`l10n.yaml`); la CI esegue `flutter gen-l10n` prima di formato, analisi e test. | Niente file generati nelle differenze dei commit; i controlli di formato e SPDX valgono per tutti i file senza eccezioni. | — |
| 12/11/2026 | **M0 — Lingua e tema solo in memoria**: la scelta si azzera al riavvio fino alle impostazioni vere. | Le impostazioni (F1.15) arrivano in M6 con il database; in M0 non si aggiunge un pacchetto provvisorio. | PRD F1.15 |
| 12/11/2026 | **M0 — JDK 21 (Temurin)** per le build Android, uguale in locale e in CI. | Stessa catena di strumenti ovunque; il JDK 25 incluso in Android Studio non è quello usato dalla CI. | — |
| 12/11/2026 | **M0 — Azioni di GitHub fissate al commit** (SHA completo, con la versione in commento), aggiornate da Dependabot. Permessi dei workflow: `contents: read`. | Un tag si può spostare, un commit no (CLAUDE.md §6). | — |
| 12/11/2026 | **M0 — La CI compila l'APK di debug** e non pubblica artefatti. | Non esiste ancora una chiave di firma; le release arrivano in M6/M7. | PRD 15.2 |
| 12/11/2026 | **M0 — Intestazione SPDX sui sorgenti scritti dal progetto** (Dart in `app/lib`, `app/test`, `app/tool`), verificata da `app/tool/check_spdx.dart` in CI. I file nativi creati da `flutter create` (Kotlin, Swift, C++, CMake) restano senza intestazione. | Quei file sono modello di Flutter (BSD-3), non codice del progetto. | PRD 12.1 |
| 12/11/2026 | **M0 — `require_trailing_commas` resta attiva.** Verificato con Dart 3.14: sul codice prodotto da `dart format` la regola non segnala nulla (provati i casi tipici di conflitto: funzione come primo argomento, lista e stringa su più righe come ultimo argomento). Se in futuro entrasse in conflitto, vince il formatter e la regola si toglie. | Il formatter di Dart ≥ 3.7 gestisce da solo le virgole finali; la regola non deve mai chiedere il contrario. | — |
| 12/11/2026 | **M0 — Fine riga LF** per tutti i file di testo; unica eccezione gli script `.bat`/`.cmd` (CRLF). | Stesso contenuto su Windows, macOS e Linux; gli script batch richiedono CRLF. | — |
| 12/11/2026 | **M0 — Codice di condotta:** Contributor Covenant 2.1. Vulnerabilità: solo segnalazione privata di GitHub (`SECURITY.md`). | Testo diffuso e riconosciuto; le vulnerabilità non devono comparire in issue pubbliche. | PRD 12.2 |

## Punti aperti

| Dal | Punto aperto | Serve entro |
|---|---|---|
| 12/11/2026 | **Contatto privato per il codice di condotta.** Oggi `CODE_OF_CONDUCT.md` rimanda agli strumenti di segnalazione di GitHub e dichiara che un contatto privato verrà aggiunto più avanti. Va scelto un indirizzo pubblico del progetto (non personale). | Prima della 1.0 (M7) |
| 12/11/2026 | **Etichette delle issue** usate dai modelli (`data`, `tolls`, `booking-import`, `translation`): vanno create nel repository, altrimenti GitHub le ignora. | Quando si aprono le prime issue |
| 12/11/2026 | **Licenza delle tabelle pedaggi** mantenute dalla community (`LICENSE-DATA.md`). | Fase 3 (F3.3) |
