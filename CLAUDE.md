# CLAUDE.md — Regole del progetto Itinerea

> Itinerea è un'app open source (GPL-3.0) per pianificare viaggi e roadtrip in auto e moto.
> Il documento di riferimento è **`docs/PRD.md`**. Leggilo prima di qualsiasi lavoro e ricontrollalo quando una scelta ti sembra incerta.

## 1. Come lavorare

1. **Una milestone alla volta** (PRD 15.2). Lavora solo sulla milestone indicata. **Non implementare la logica di fasi o milestone successive**, nemmeno "già che ci sei".
   - **Impalcatura ammessa** quando richiesta (PRD 15.1): cartelle, interfacce astratte, modelli senza logica, schermate segnaposto, test segnaposto che riportano i CA (`skip: 'M4 – F1.5'`). Ogni segnaposto ha un commento `// TODO(Mx F2.1): …` con milestone e funzionalità.
   - Un'impalcatura non deve mai sembrare una funzione finita: le schermate segnaposto lo dicono chiaramente.
2. **Prima il piano, poi il codice.** All'inizio di ogni compito presenta un piano breve: file da creare o modificare, dipendenze, test. Aspetta conferma se il compito tocca più di una funzionalità (codice F*x.y*) o cambia il modello dati.
3. **Se il PRD è ambiguo o contraddittorio, chiedi.** Non indovinare. Se una scelta tecnica del PRD si rivela impraticabile, fermati, spiega il problema e proponi alternative.

### Libertà di design e di funzionalità
- **Estetica:** l'unico riferimento è **Wanderlog** (lista + mappa affiancate), da rendere più snello, moderno e veloce. Colori, font, icone, componenti, animazioni e organizzazione delle schermate li scegli tu (base Material 3). Documenta le scelte in `docs/DESIGN.md` e mostrale prima di applicarle a tutta l'app.
- **Funzionalità:** il PRD è il **punto di partenza**. Puoi proporre miglioramenti, semplificazioni o funzioni in più, unire o dividere schermate (PRD 7.2–7.3 sono una proposta). **Chiedi prima** di togliere o cambiare una funzionalità del PRD e scrivi la decisione in `docs/DECISIONS.md`.
- **Sempre vincolanti:** i principi della sezione 2 qui sotto, i non-obiettivi (PRD 1.5) e le voci del PRD segnate "decisione presa".
4. **Mantieni il PRD aggiornato.** Ogni decisione presa durante lo sviluppo va scritta nella sezione pertinente di `docs/PRD.md` e in `docs/DECISIONS.md` (data, decisione, motivo).
5. **Definizione di "finito":** criteri di accettazione (CA) della funzionalità soddisfatti, test scritti e verdi, `flutter analyze` senza errori né avvisi, build funzionanti su Android, Windows, macOS e Linux (CI), testi tradotti in italiano e inglese.

## 2. Principi non negoziabili (PRD 1.4)

- **Nessun server centrale.** Niente backend del progetto, niente account Itinerea. L'unico server ammesso è il *Itinerea Sync Server* facoltativo e self-hosted (`/sync-server`).
- **Nessuna telemetria**, analytics, crash reporting automatico, pubblicità, acquisti in-app o affiliazioni.
- **Nessun SDK proprietario** (Firebase, Google Play Services, SDK pubblicitari…): l'app deve poter entrare in F-Droid.
- **Local-first:** ogni funzione deve funzionare offline con i dati salvati, oppure degradare in modo chiaro (PRD 7.7, 9.1).
- **Onestà sui dati:** stime e dati vecchi sono sempre etichettati (T4).
- **Pochi tocchi:** rispetta i conteggi dei flussi FL1–FL9 (PRD 7.5).

## 3. Stack (PRD 4.2)

- Flutter (stable), Dart, **Riverpod**, **drift** (SQLite), **flutter_map** + **vector_map_tiles** (+ `pmtiles`, `vector_map_tiles_pmtiles` per l'offline), flutter_local_notifications, flutter_secure_storage, localizzazione ufficiale Flutter (ARB).
- Mappa: **OpenFreeMap** sia online sia offline (stesso schema OpenMapTiles e stesso stile, PRD 4.6). Non mischiare tile con schemi diversi.
- Percorsi: **Valhalla** (istanza pubblica FOSSGIS come default, URL configurabile).
- Identificativo dell'app (`applicationId` / bundle id): `io.github.notenjoyingthis.itinerea` (definitivo, PRD R16): non cambiarlo.
- Piattaforme distribuite: **Android, Windows, macOS, Linux**. iOS non è distribuito, ma non introdurre codice che ne rompa la compilazione.

### Aggiungere una dipendenza
Prima di aggiungere un pacchetto verifica e riporta: licenza compatibile con GPL-3.0 (MIT, BSD, Apache-2.0, LGPL, MPL-2.0 sì; proprietarie no), supporto alle 4 piattaforme, manutenzione attiva (rilascio negli ultimi 12 mesi, anche beta: in quel caso segnalalo), nessuna dipendenza da servizi proprietari. Chiedi conferma prima di aggiungerlo. I pacchetti già indicati nella sezione 3 sono approvati, ma verificane comunque la versione e lo stato.

## 4. Convenzioni di codice

- **Struttura:** `app/lib/core/` (modelli, database, sync, fornitori, utilità) e `app/lib/features/<funzione>/` (UI, stato, logica della funzione). Nessuna logica di dominio nei widget.
- **Nomi:** quelli del glossario (PRD 3) in inglese: `Trip`, `Day`, `Segment`, `StopSlot`, `Stop`, `LegSlot`, `Leg`, `Route`, `Booking`, `Lodging`, `Expense`, `Split`, `Loan`, `Participant`, `SyncSpace`, `Provider`, `DataPack`…
- **ID:** UUID v7 generati sul dispositivo.
- **Denaro:** sempre `Money` (intero in unità minime + ISO 4217). **Mai `double` per importi.**
- **Date e ore:** data/ora locale + fuso IANA del luogo; istanti assoluti in UTC (PRD 8.1).
- **Testi:** mai stringhe visibili nel codice; sempre ARB con descrizione per i traduttori, plurali ICU, nessuna frase composta a pezzi.
- **Servizi esterni:** sempre tramite l'interfaccia `Provider` della categoria (mappa, percorsi, ricerca, mezzi, meteo, cambi, carburante…), con URL configurabile, **User-Agent** `Itinerea/<versione> (+<url del repository>)`, cache, limiti di frequenza e gestione dell'assenza di rete (PRD 5.4).
- **Segreti:** nessuna chiave o token nel repository. Le chiavi personali degli utenti vanno in `flutter_secure_storage`.
- **Licenza:** ogni nuovo file sorgente inizia con `// SPDX-License-Identifier: GPL-3.0-or-later` (finché D1 non è decisa diversamente).
- **Accessibilità:** etichette semantiche, rispetto della dimensione del testo di sistema, contrasto adeguato in tema chiaro e scuro.

## 5. Test

- Logica pura (CRDT, ricalcolo orari, saldo delle spese, valute, soglie badge, parser) → **test di unità obbligatori**, inclusi i casi limite.
- Ogni bug corretto → un test che lo riproduce.
- Sincronizzazione → test con più dispositivi simulati, modifiche concorrenti e offline.
- Non disattivare né cancellare test che falliscono per far passare la CI: segnala il problema.

## 6. Git

- Un branch per funzionalità o compito (es. `feat/F1.2-stops`).
- Commit in stile **Conventional Commits** con il codice della funzionalità: `feat(F1.3): ricalcolo automatico degli orari`.
- Ogni commit con `Signed-off-by` (DCO, PRD 12.2).
- Non fare push né aprire PR senza che te lo chieda.

## 7. Sicurezza e privacy (PRD 13)

- I file importati (`.itinerea`, PDF, email, immagini) sono **non affidabili**: limiti di dimensione, nessuna esecuzione, protezione dai percorsi malevoli negli archivi.
- Coordinate arrotondate dove la precisione non serve. Nessun identificativo dell'utente nelle richieste esterne.
- Crittografia solo con librerie affermate; mai algoritmi fatti in casa.

## 8. Quando finisci un compito

Riporta in breve: cosa è stato fatto (con i codici F*x.y*), quali CA sono verificati e come, test aggiunti, cosa resta aperto, eventuali aggiornamenti al PRD.
