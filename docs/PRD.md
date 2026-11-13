# Itinerea — Product Requirements Document (PRD)

> **Stato del documento:** versione 1.3 del 12/11/2026 (nome definitivo Itinerea, repository creato, scelte rese esplicite), rivista e con controllo incrociato tra sezioni, librerie e servizi.
> **Repository:** https://github.com/NotEnjoyingThis/itinerea (pubblico, branch `main`).
> **Come usarlo:** per le **funzionalità** il PRD è il punto di partenza, non un vincolo rigido; per l'**aspetto grafico** il riferimento è Wanderlog, da migliorare liberamente (sezione 7). Restano vincolanti i principi (1.4), i non-obiettivi (1.5) e le decisioni segnate come "decisione presa".
> **Ultima verifica delle fonti esterne (sez. 5):** novembre 2026. Prima di implementare, ricontrollare licenze e limiti.
> **Lingua del documento:** italiano. Lingue dell'app al lancio: italiano e inglese.
> **Lingua del codice** (decisione del 12/11/2026): nomi, commenti e messaggi di commit in **inglese**; README in inglese con una sezione in italiano; CONTRIBUTING e CODE_OF_CONDUCT in inglese; documenti di progetto in `docs/` (PRD, DECISIONS, DESIGN, ROADMAP) in **italiano**.
> **Modello del progetto** (decisione dell'11/11/2026): **open source** su GitHub, **gratuito**, **senza pubblicità**, **senza pagamenti** di alcun tipo e **senza server centrale**. L'app funziona interamente in locale e, se l'utente lo vuole, si sincronizza tramite Google Drive, OneDrive, Dropbox, WebDAV, una cartella locale o un server self-hosted dell'utente. **Licenza: GPL-3.0-or-later** (decisione del 12/11/2026, D1). **Distribuzione:** GitHub, F-Droid, Flathub e Google Play (niente App Store Apple).
> **Nome dell'app:** **Itinerea** (definitivo, decisione del 12/11/2026), da *itinera*, latino "i percorsi". Scartati perché già usati da app di viaggio o da aziende del turismo: Girovia (app open source di viaggio omonima su GitHub), Itinera (app di viaggio omonime su App Store **e Google Play**, marchio registrato negli USA per servizi di viaggio), Detour, Waymark, Roamwise, Bivio. **Prima del lancio:** confermare su TMview che non ci siano marchi uguali o troppo simili (anche rispetto a Itinera, R13) e registrare il dominio.

---

## Indice

1. Visione, obiettivi e principi
2. Utenti tipo e scenari d'uso
3. Glossario
4. Architettura tecnica
5. Fonti dati e API
6. Funzionalità per fase
7. Schermate e flussi utente
8. Modello dati
9. Offline e sincronizzazione
10. Notifiche
11. Gamification: badge, punti, shop e profilo
12. Licenza, contributi e sostenibilità
13. Privacy e sicurezza
14. Lingue e localizzazione
15. Roadmap e milestone
16. Rischi e domande aperte

---

## 1. Visione, obiettivi e principi

### 1.1 Il problema

Per organizzare bene un viaggio oggi servono almeno 5–6 app diverse:

| Bisogno | App usate oggi | Cosa manca |
|---|---|---|
| Itinerario giorno per giorno | TripIt, Wanderlog, Polarsteps | Nessuna alternativa per tappe o percorsi; dati inseriti a mano; funzioni a pagamento; interfaccia lenta o con troppi passaggi |
| Percorsi su misura | Google Maps, Sygic, Roadtrippers | Danno il percorso più veloce; quello panoramico è a pagamento o va costruito a mano |
| Mezzi pubblici | Google Maps, Rome2Rio | Non collegati all'itinerario |
| Costi di carburante e pedaggi | ViaMichelin, Fuel Flash | App separate, non collegate al viaggio |
| Spese di gruppo | Splitwise, Xe | Nessuna conversione di valuta integrata, nessun collegamento all'itinerario |
| Servizi utili (bagni) | Flush Toilet Finder | App separata |
| Alloggi | Booking, Wanderlog | La prenotazione non aggiorna da sola itinerario e budget |

Chi organizza viaggi finisce per fare tutto a mano, unendo i pezzi con documenti e chat con l'AI.

### 1.2 La visione

**Itinerea è un'unica app, open source e gratuita, senza pubblicità e senza server centrale, che sostituisce tutte queste app.** Permette di pianificare, condividere e vivere un viaggio. Il viaggio può essere un itinerario (a piedi o con i mezzi), un roadtrip in auto o in moto, oppure un mix dei due.

### 1.3 Obiettivi

| # | Obiettivo | Come si misura |
|---|---|---|
| O1 | Un solo posto per tutto il viaggio | Itinerario, percorsi, prenotazioni, biglietti, budget e mappa nella stessa app |
| O2 | Pianificare velocemente | Viaggio base (destinazione, date, primo giorno) creato in meno di 2 minuti. Azioni frequenti in massimo 2–3 tocchi |
| O3 | Gestire gli imprevisti | Ogni tappa e ogni percorso può avere alternative (piano A, B, C, D) attivabili con un tocco |
| O4 | Funzionare in viaggio anche senza internet | Mappa, biglietti, itinerario e budget consultabili e modificabili offline |
| O5 | Viaggiare in gruppo senza attriti | Modifica condivisa (tramite Google Drive, OneDrive, Dropbox, WebDAV o un server self-hosted), ruoli, spese divise con saldo finale |
| O6 | Roadtrip fatti bene | Percorsi non solo veloci (panoramici, con curve, senza autostrade o sterrato), soste carburante e ricarica pianificate, costi stimati |
| O7 | Tutto gratis e aperto | Codice open source, nessun pagamento, nessuna pubblicità, nessuna funzione bloccata |

### 1.4 Principi di prodotto

Ogni decisione di design e di sviluppo deve rispettare questi principi. In caso di conflitto valgono nell'ordine in cui sono elencati.

1. **Gratis, open source, senza pubblicità né pagamenti.** Nessun acquisto di alcun tipo, né l'app né dentro l'app. I punti viaggio dello shop si guadagnano solo viaggiando.
2. **Solo locale, nessun server centrale.** Il viaggio vive sul dispositivo. L'app funziona senza account e senza internet. Per condividere e sincronizzare si usa uno spazio scelto dall'utente (Google Drive, OneDrive, Dropbox, WebDAV, cartella locale o un server self-hosted). Il progetto non gestisce alcun server.
3. **Privacy di default.** Il progetto non raccoglie nessun dato: nessuna telemetria, nessun account Itinerea. I dati vanno solo dove l'utente decide (il suo spazio di sincronizzazione e i servizi esterni necessari per mappe, percorsi, meteo…).
4. **Pochi tocchi.** Se un'azione frequente richiede più di 3 tocchi, il design va rivisto.
5. **Onestà sui dati.** Quando un dato può essere vecchio o impreciso, l'app lo dice. Esempi: orari dei mezzi scaricati offline, stime dei consumi, percorsi panoramici calcolati, legalità del campeggio libero.
6. **Stessa app ovunque.** Android, Windows 11, macOS e Linux hanno le stesse funzioni. Il layout si adatta allo schermo, le funzioni no. **iOS:** l'app non viene distribuita (niente App Store, 4.9), ma il codice resta compatibile, così chi ha un Mac può compilarla per sé.
7. **Dati aperti e servizi intercambiabili.** Si usano fonti gratuite e aperte (OpenStreetMap, Wikidata, open data pubblici). Ogni servizio esterno può essere sostituito con un server dell'utente.

### 1.5 Cosa l'app NON fa (non-obiettivi)

Queste esclusioni sono decisioni prese, non dimenticanze:

- **Nessun server centrale, nessun account Itinerea, nessuna telemetria.**
- **Nessuna pubblicità, nessun pagamento, nessuna affiliazione.**
- **Nessuna prenotazione interna.** Hotel e alloggi si vedono nell'app e si prenotano su Booking tramite un link semplice. La conferma poi entra nell'app.
- **Nessuna community online centralizzata.** Gli itinerari si condividono come file (F4.3).
- **Nessun navigatore integrato curva per curva.** Per guidare, l'app passa il percorso completo, tappe intermedie comprese, a Google Maps, Waze, Sygic o altre app installate.
- **Nessuna integrazione con Apple Wallet o Google Wallet.**
- **Nessun archivio di documenti personali** (passaporto, patente, assicurazione).
- **Nessun movimento di denaro reale.** L'app registra chi deve cosa a chi, non fa pagamenti.
- **Nessuna AI generativa per i consigli.** I consigli si basano su dati e algoritmi (vedi sezione 6).
- **Nessuna partecipazione attiva per chi non ha l'app.** Chi non ha l'app può ricevere un PDF dell'itinerario con il link per scaricarla, ma non può modificare né essere aggiunto alle spese.
- **Copertura geografica iniziale: Europa** (decisione presa). I viaggi fuori dall'Europa **si possono creare**: mappa, percorsi, luoghi, meteo e cambi funzionano ovunque ci siano dati. Le funzioni con dati solo europei (prezzi carburante, pedaggi, badge, database veicoli) mostrano "Non disponibile in questo paese". Test e dati curati a mano si concentrano sull'Europa.

---

## 2. Utenti tipo e scenari d'uso

### 2.1 Utenti tipo (personas)

**P1 — L'organizzatore di gruppo**
Organizza viaggi per sé e per amici. Fa tutto lui e poi condivide. Vuole che gli altri vedano il piano, possano proporre modifiche e che le spese si dividano senza discussioni.
*Frustrazione principale:* gestire tutto tra app diverse, chat di gruppo e fogli di calcolo.

**P2 — Il viaggiatore multi-città con i mezzi**
Fa viaggi di 1–3 settimane in più città, spostandosi in treno, bus e metro. Ha voli, treni e musei prenotati con orari precisi.
*Frustrazione principale:* le prenotazioni sparse tra le email e nessun piano B quando qualcosa salta.

**P3 — Il roadtripper in auto**
Fa roadtrip di più giorni. Non vuole la strada più veloce ma quella più bella. Vuole sapere quanto spenderà di carburante e pedaggi e dove dormire, anche in auto o in campeggio.
*Frustrazione principale:* costruire a mano il percorso panoramico e calcolare i costi su siti diversi.

**P4 — Il motociclista**
Come P3, ma l'autonomia è minore, conta di più il tipo di strada (curve, niente sterrato, niente autostrade) e serve sapere dove fermarsi a fare rifornimento.
*Frustrazione principale:* nessuna app pianifica le soste in base all'autonomia reale del mezzo.

**P5 — Il collezionista di viaggi**
Gli piace tenere traccia di dove è stato, collezionare badge e mostrare il proprio profilo di viaggiatore.
*Motivazione:* la parte di gioco (badge, livelli, profilo).

### 2.2 Scenari d'uso

Gli scenari descrivono l'esperienza completa a cui tendere, con funzioni di **tutte le fasi** (sezione 6): non sono la descrizione dell'MVP.

**S1 — Weekend a Dublino (itinerario breve, P2)**
L'utente crea un viaggio "Itinerario" di 4 giorni. Condivide con l'app l'email di conferma del volo: volo, orari e posto vengono aggiunti da soli al giorno 1 e al giorno 4. Carica lo screenshot della carta d'imbarco con il QR, che resta disponibile offline. Aggiunge le tappe di ogni giorno cercandole sulla mappa: orari di apertura e informazioni arrivano in automatico. Il giorno 2 prevede una gita alle scogliere, con piano B "museo in centro" in caso di pioggia. Il meteo della vigilia segnala pioggia e l'utente attiva il piano B con un tocco.

**S2 — Due settimane in Giappone in gruppo (P1 + P2)**
*Nota: il Giappone è fuori dalla copertura iniziale (solo Europa). Lo scenario descrive l'esperienza completa a cui tendere.*
L'organizzatore crea il viaggio nel suo Google Drive e invita 3 amici: due come editor e uno solo in visualizzazione. Le modifiche arrivano agli altri in pochi secondi o minuti; se il gruppo usa un Itinerea Sync Server installato da uno di loro, in tempo reale. Le spese si registrano in yen e la conversione usa il cambio del giorno della spesa. Un amico presta soldi a un altro, e il prestito entra nel saldo. A fine viaggio l'app mostra chi deve quanto a chi, con pochi pagamenti (F2.2).

**S3 — Roma e Firenze in 7 giorni (assistente consigli)**
L'utente vuole vedere il Colosseo e gli Uffizi e ha 7 giorni. Chiede aiuto all'assistente, che gli fa alcune domande: approfondire Roma, approfondire Firenze, fare tappe a metà strada o vedere subito le due cose e poi altre regioni; ritmo; interessi; budget. Poi propone una distribuzione dei giorni e dei luoghi, che l'utente può accettare o modificare in parte.

**S4 — Viaggio misto (itinerario + roadtrip)**
Il viaggio parte come itinerario con i mezzi pubblici. Il giorno 5 l'utente noleggia un'auto e trasforma il viaggio in roadtrip **da quel giorno in poi**. Da lì compaiono le funzioni roadtrip: percorsi con preferenze, distributori, soste, costi.

**S5 — Roadtrip in moto in Germania (P4)**
L'utente inserisce la moto con consumo e capienza del serbatoio a mano (per le moto non esiste un database aperto, 5.2). Imposta le preferenze: panoramico in montagna, curve sì, autostrade no, sterrato no. L'app propone il percorso, e l'utente lo modifica facendolo passare da una strada che vuole fare. Con la pianificazione automatica delle soste attiva, l'app indica dove fare rifornimento entro l'autonomia della moto, preferendo i distributori più economici (in Germania i prezzi richiedono la chiave Tankerkönig personale e gratuita dell'utente, 5.2). Stima il costo totale del carburante. Per la notte segna un campeggio, e l'app ricorda di verificare le regole locali se si tratta di campeggio libero.

**S6 — In viaggio senza connessione**
In una zona senza rete l'utente apre la mappa scaricata, vede le tappe del giorno, registra una spesa e sposta una tappa. Quando torna la connessione tutto si sincronizza con gli altri partecipanti senza conflitti. Gli orari dei mezzi consultati offline mostrano l'avviso che potrebbero non essere aggiornati.

**S7 — Badge di Roma (P5)**
L'utente visita il Colosseo, il Pantheon e i Fori Imperiali. La visita viene confermata dal GPS sul posto e sblocca il badge "Roma", livello 1. Visitando altri luoghi della lista (Circo Massimo, Fontana di Trevi, Musei Capitolini…) il badge sale di livello fino al 10, "Hai visto tutta Roma". Le visite contano anche per badge più grandi, come "Lazio" e "Italia", che includono monumenti importanti anche nei paesi più piccoli.

---

## 3. Glossario

Questi termini vanno usati in modo coerente nel codice, nell'interfaccia e nei documenti. Tra parentesi c'è il nome inglese da usare nel codice.

| Termine | Codice | Definizione |
|---|---|---|
| **Viaggio** | `Trip` | Il contenitore principale. Ha nome, date, partecipanti, giorni, budget e uno o più segmenti. |
| **Segmento** | `Segment` | Una porzione continua di giorni dello stesso tipo: **Itinerario** (a piedi o con i mezzi) o **Roadtrip** (auto o moto). Un viaggio misto ha più segmenti, per esempio giorni 1–4 itinerario e giorni 5–10 roadtrip. Il cambio di tipo vale dal giorno scelto in poi. |
| **Giorno** | `Day` | Un giorno del viaggio. Contiene tappe, tratte, alloggio della notte ed eventuale budget giornaliero. |
| **Tappa** | `Stop` | Un luogo o un'attività in un giorno. Campi principali: orario, durata, note, costo, link, allegati, stato (da visitare / visitata / saltata). Può essere collegata a una prenotazione. |
| **Tempo libero** | — | Tempo che avanza prima di una tappa a orario fisso (F1.3). L'assistente propone come usarlo (F3.1). |
| **Tratta** | `Leg` | Lo spostamento tra due tappe consecutive. Ha un mezzo (auto, moto, a piedi, bus, treno, metro, traghetto, aereo…), un percorso, durata e costo stimati. |
| **Alternativa (Piano A/B/C/D)** | campo `plan` | Opzioni di riserva per una tappa o per una tratta. Il piano A è quello attivo di default. Gli altri si attivano a mano con un tocco. Massimo 4 piani (A–D). |
| **Posizione** | `StopSlot` / `LegSlot` | Il posto di una tappa o di una tratta nel giorno. Contiene i piani A–D e indica quale è attivo (8.3). |
| **Percorso** | `Route` | Il tracciato geografico di una tratta, calcolato in base al profilo di percorso e modificabile dall'utente. |
| **Profilo di percorso** | `RouteProfile` | Le preferenze per calcolare il percorso: più veloce / panoramico (mare, lago, montagna) / con curve; evita autostrade, pedaggi, sterrato, traghetti. Vale per qualsiasi veicolo. |
| **Prenotazione** | `Booking` | Una prenotazione con orario vincolante: volo, treno, bus, traghetto, hotel, museo, noleggio auto, ecc. Si crea da email, PDF o screenshot, oppure a mano. Ha un orario fisso: il ricalcolo automatico degli orari non la sposta (F1.3). |
| **Allegato** | `Attachment` | File salvato in locale e collegato a una tappa, una tratta, una prenotazione o una spesa: PDF, screenshot, biglietto con QR. Disponibile offline. |
| **Alloggio** | `Lodging` | Dove si dorme una notte: hotel/B&B, campeggio, area sosta, notte in auto. Collegato ai giorni corrispondenti, con check-in e check-out. |
| **Partecipante** | `Participant` | Persona che partecipa al viaggio: ha l'app installata e accesso allo spazio di sincronizzazione del viaggio. Non esistono account Itinerea: è identificata da un profilo locale (nome + ID) collegato all'account del servizio usato. |
| **Ruolo** | `Role` | Permessi di un partecipante: **Proprietario** (tutto, compresi inviti ed eliminazione), **Editor** (modifica itinerario e spese), **Visualizzatore** (solo lettura). In modalità file coincidono con i permessi di condivisione della cartella (4.4). |
| **Spazio di sincronizzazione** | `SyncSpace` | Dove si salvano e si scambiano i dati di un viaggio: Google Drive, OneDrive, Dropbox, WebDAV, cartella locale (**modalità file**) oppure Itinerea Sync Server (**modalità server**). iCloud Drive è escluso. |
| **Fornitore** | `Provider` | Il servizio esterno usato per un tipo di dato (mappa, percorsi, ricerca, mezzi, meteo…). Di default è un servizio pubblico, sostituibile con un server dell'utente. |
| **Pacchetto dati** | `DataPack` | File scaricato e usato offline: regione di mappa (PMTiles o MBTiles), luoghi di una zona, database veicoli, liste dei badge, tabelle pedaggi. |
| **Budget** | campi `budgetMode`, `budgetTotal` (Trip) e `budget` (Day) | Limite di spesa del viaggio: generale oppure per giorno. |
| **Spesa** | `Expense` | Un costo sostenuto: importo, valuta, cambio del giorno, chi ha pagato, come si divide, categoria, foto dello scontrino facoltativa. |
| **Divisione** | `Split` | Come una spesa si ripartisce tra i partecipanti: in parti uguali, a percentuale, a quote o per importi esatti. Si sceglie per ogni spesa. |
| **Prestito** | `Loan` | Denaro prestato da un partecipante a un altro, fuori dalle spese comuni. Entra nel saldo. |
| **Saldo** | `Settlement` | Il riepilogo "chi deve quanto a chi", con pochi pagamenti (al massimo numero di persone − 1, F2.2). Si calcola, non si salva. |
| **Rimborso** | `Repayment` | Un pagamento con cui un partecipante salda un debito; entra nel saldo. |
| **Veicolo** | `Vehicle` | Auto o moto dell'utente: modello, tipo di alimentazione, consumo, capienza serbatoio o batteria, autonomia. Dati compilati dal database quando possibile, sempre modificabili. |
| **Sosta pianificata** | `Stop` con `kind` = `refuel` / `charge` | Rifornimento o ricarica proposti dall'app in base all'autonomia del veicolo, oppure inseriti dall'utente se ha scelto la pianificazione manuale. |
| **Luogo** | `Place` (`PlaceSnapshot` nel viaggio, `PlaceCache` nella cache) | Un punto d'interesse sulla mappa (monumento, museo, ristorante, distributore, bagno, campeggio…), con le informazioni prese dalle fonti dati. |
| **Assistente** | `PlannerAssistant` | La procedura guidata, facoltativa, che fa domande all'utente e propone come distribuire giorni e luoghi. |
| **Visita verificata** | `VerifiedVisit` | La visita a un luogo confermata dal GPS sul posto. Serve per badge e punti. |
| **Badge** | `Badge` | Riconoscimento legato a un'area geografica (città, regione o nazione) oppure a un traguardo speciale (es. passi alpini, km in moto, 11.3). Ha livelli da 1 a 10, che salgono con le visite verificate ai luoghi della sua lista. |
| **Punti viaggio** | `PointsLedger` (movimenti) | Valuta interna dell'app. Si guadagnano **solo viaggiando** (non si possono comprare) e si spendono solo in oggetti estetici nello shop. |
| **Itinerario condiviso** | `SharedItinerary` | Copia anonimizzata di un viaggio, esportata come file `.itinerea`, che altri possono importare e copiare (F4.3). |

---

## 4. Architettura tecnica

> Le librerie nominate in questa sezione sono quelle consigliate a novembre 2026. All'avvio di ogni fase si controlla che siano ancora mantenute; se una è stata abbandonata, si sceglie un'alternativa equivalente e si aggiorna il documento.

### 4.1 Panoramica

L'architettura è **interamente locale, senza server centrale** (decisione dell'11/11/2026). Il progetto Itinerea non gestisce server, account o database online. Ogni dispositivo contiene l'app completa. Per condividere e sincronizzare, l'app usa uno **spazio di sincronizzazione** scelto dall'utente.

```
┌──────────────────────────────────────────────────────────────┐
│  APP (Flutter) — Android · Windows · macOS · Linux           │
│  ┌──────────────┐ ┌──────────────┐ ┌───────────────────────┐ │
│  │ DB locale    │ │ Allegati     │ │ Motore di sync        │ │
│  │ (SQLite)     │ │ locali (PDF, │ │ (log delle modifiche, │ │
│  │              │ │ QR, foto)    │ │ unione senza conflitti)│ │
│  └──────────────┘ └──────────────┘ └───────────────────────┘ │
│  Pacchetti offline: mappe, luoghi, orari, dati statici       │
└───────────────┬──────────────────────────────┬───────────────┘
                │ (facoltativo, scelto         │ (quando online)
                │  dall'utente)                ▼
                ▼                    ┌───────────────────────────────┐
┌─────────────────────────────────┐  │ Servizi pubblici esterni      │
│ Spazio di sincronizzazione      │  │ (fornitori intercambiabili):  │
│ • Google Drive                  │  │ mappa, percorsi, ricerca,     │
│ • Microsoft OneDrive · Dropbox  │  │ mezzi, meteo, cambi,          │
│ • WebDAV (Nextcloud, NAS…)      │  │ carburante, POI OSM           │
│ • Cartella locale (Syncthing…)  │  │ + pacchetti dati statici      │
│ • Itinerea Sync Server          │  │   (GitHub Releases)           │
│   (self-hosted dall'utente)     │  └───────────────────────────────┘
└─────────────────────────────────┘
```

**Regola d'oro:** nessun componente esterno è indispensabile. Senza internet, senza spazio di sincronizzazione o con un servizio esterno non disponibile, l'utente continua a consultare e modificare i propri viaggi. Le modifiche si sincronizzano appena possibile.

### 4.2 Stack del client

| Ambito | Scelta | Note |
|---|---|---|
| Framework | **Flutter** (canale stable), linguaggio Dart | Un solo codice: Android, Windows, macOS, Linux distribuiti; iOS compilabile |
| Interfaccia | Pacchetto **material_ui** (team Flutter, BSD-3) | Da Flutter 3.50 Material non fa più parte dell'SDK. I delegati di localizzazione sono quelli di `material_ui` (`GlobalMaterialLocalizations.delegates`), non quelli di `flutter_localizations` (decisione M0) |
| Gestione dello stato | Riverpod | Senza generatore di codice: provider scritti a mano (decisione M0) |
| Database locale | SQLite tramite **drift** | Query tipizzate, migrazioni, funziona su tutte le piattaforme |
| Mappa | **flutter_map** + **vector_map_tiles** (BSD-3) | Tile vettoriali su Android, iOS, Linux, macOS e Windows, con stili in formato JSON (lo stile deve corrispondere allo schema delle tile, 4.6). **Esito M1 (13/11/2026): funziona con limiti** (R14). Versioni provate: `flutter_map` 8.3.2 e `vector_map_tiles` **9.0.0-beta.13** (la stabile 8.0.0 è di due anni fa e richiede `flutter_map` 7; la 10 beta richiede il canale *main* di Flutter ed è esclusa). Si usa **solo la modalità `raster`** del livello (tile vettoriali disegnate in immagini sul dispositivo): la modalità `vector` è troppo lenta. Ogni stile deve ricevere un identificativo proprio, perché gli stili OpenFreeMap non hanno il campo `id`. La versione va fissata esatta nel `pubspec`. Il pacchetto `maplibre` per Flutter resta il piano B (oggi elenca anche Windows e Linux, non provato). |
| Mappe offline | **pmtiles** (BSD-2, lettura di archivi PMTiles locali o remoti) + **vector_map_tiles_pmtiles** (MIT) | Vedi 4.6 e sezione 9 |
| Navigazione | Link diretti alle app esterne (Google Maps, Waze, Apple Maps, Sygic, OsmAnd, Organic Maps…) con le tappe intermedie | Il navigatore interno è un non-obiettivo (1.5) |
| Lingue | Sistema di localizzazione ufficiale Flutter (file ARB) | Italiano e inglese al lancio |
| Notifiche | flutter_local_notifications | **Solo notifiche locali**, calcolate sul dispositivo. Niente notifiche push: richiederebbero un server. |
| Sincronizzazione | Client REST per Google Drive, Microsoft Graph (OneDrive) e Dropbox, client WebDAV, accesso a cartella locale, client WebSocket per il Sync Server | Login OAuth con PKCE nel browser di sistema. iCloud Drive escluso (l'app non è distribuita sugli store Apple). |
| Dipendenze | **Preferire librerie open source** | Evitare SDK proprietari (es. Google Play Services, Firebase), così l'app può entrare in F-Droid |
| Altre librerie | Scelte durante lo sviluppo | PDF (F1.14), posizione, condivisione, apertura di link, selettore di file e simili: le propone Claude Code rispettando le regole di CLAUDE.md (licenza, piattaforme, manutenzione) |

### 4.3 Dati locali e sincronizzazione

**Identificativi.** Ogni entità del glossario (Viaggio, Giorno, Tappa, Spesa…) ha un ID univoco generato sul dispositivo (UUID v7), così si possono creare dati offline senza chiedere nulla a nessuno.

**Strategia di unione delle modifiche (CRDT).** Più persone possono modificare lo stesso viaggio, anche offline, e le modifiche si uniscono senza conflitti:

- **Campi semplici** (orario, costo, nome, stato…): *last-writer-wins per campo*. Ogni campo ha un timestamp logico ibrido (HLC). Se due persone cambiano lo stesso campo, vince la modifica più recente. Se cambiano campi diversi della stessa tappa, si mantengono entrambe.
- **Ordine delle liste** (ordine delle tappe in un giorno): indici frazionari. Spostare una tappa non riscrive l'intera lista.
- **Eliminazioni:** cancellazione logica (tombstone), così una tappa eliminata offline non "risorge" alla sincronizzazione.
- **Testo delle note:**
  - **Cronologia delle versioni:** ogni nota conserva le versioni precedenti, consultabili e ripristinabili.
  - **Modifiche contemporanee:** vince l'ultima modifica e la versione dell'altra persona resta nella cronologia, quindi nulla va perso.
  - **Blocco morbido** ("Nome sta scrivendo…", rilascio dopo 10 secondi senza digitazione): **solo con l'Itinerea Sync Server**, l'unica modalità abbastanza veloce da renderlo affidabile.
  - **Più avanti:** la scrittura simultanea carattere per carattere, come in Google Docs, con un CRDT di testo (per esempio `dart_crdt`, compatibile con Yjs) quando le librerie Dart saranno mature. Oggi sono pre-1.0.

**Log delle modifiche.** Ogni modifica locale viene salvata come operazione in una tabella dedicata. Il motore di sync scrive le operazioni nuove nello spazio di sincronizzazione e legge quelle degli altri dispositivi.

**Due modalità di sincronizzazione:**

| | **Modalità file** | **Modalità server** |
|---|---|---|
| Spazi | Google Drive, OneDrive, Dropbox, WebDAV, cartella locale (es. sincronizzata da Syncthing) | Itinerea Sync Server installato dall'utente |
| Come funziona | Ogni viaggio è una cartella. Ogni dispositivo scrive i propri file di operazioni in una sua sottocartella (`ops/<idDispositivo>/`) e legge quelli degli altri. Periodicamente si scrive un'istantanea completa per velocizzare l'apertura. | Le operazioni passano dal server via WebSocket e arrivano subito agli altri |
| Tempo di arrivo delle modifiche | **Da pochi secondi a qualche minuto**: l'app controlla le novità all'apertura, ogni 30 secondi mentre è in primo piano e con "Aggiorna" | **Entro 2 secondi** |
| Presenza ("chi sta guardando") | No | Sì |
| Blocco morbido delle note | No | Sì |
| Ruoli | Permessi di condivisione della cartella (4.4) | Applicati dal server |

**Allegati.** Sono file salvati nella cartella del viaggio, nominati con l'impronta (hash) del contenuto, così lo stesso file non si copia due volte.

**Senza spazio di sincronizzazione:** i dati restano solo sul dispositivo, con backup facoltativo (4.5).

**Cifratura end-to-end (Fase 2, facoltativa per viaggio):**
- Proposta come scelta consigliata quando un viaggio usa Google Drive, OneDrive o Dropbox: così il fornitore del cloud non può leggerne il contenuto. Non serve per cartella locale e Sync Server dell'utente, ma si può attivare comunque.
- Ogni viaggio ha una chiave casuale. La chiave viaggia **dentro il link di invito**, quindi i compagni non devono fare nulla di più.
- Alla creazione l'app mostra un **codice di recupero** da conservare. Chi perde tutti i dispositivi e il codice non può più leggere il viaggio dal cloud: l'app lo spiega chiaramente prima di attivare la cifratura.
- Algoritmi standard (es. XChaCha20-Poly1305) tramite una libreria crittografica affermata, mai implementazioni fatte in casa.

> **Da validare con un prototipo:** modalità file con 2–5 dispositivi sullo stesso viaggio, modifiche offline e riconnessione. In M1 si prova **Google Drive** (il caso più incerto, R1); OneDrive e Dropbox si provano prima di iniziare la Fase 2.

### 4.4 Partecipanti, inviti e ruoli senza server

- **Nessun account Itinerea.** Ogni installazione ha un **profilo locale** (nome visualizzato + ID generato). Nel viaggio, il partecipante è identificato da questo profilo e dall'account del servizio usato (es. l'account Google).
- **Tutti i partecipanti di un viaggio usano lo stesso spazio**, scelto da chi crea il viaggio. Con Google Drive, ognuno deve avere un account Google; con il Sync Server, le credenziali di quel server.
- **Invito:** il proprietario condivide la cartella del viaggio (o lo invita sul Sync Server) e l'app genera un **link o codice di invito** che, aperto in Itinerea, collega il viaggio.
- **Ruoli in modalità file:** sono i **permessi della cartella**. Chi ha accesso in sola lettura è **Visualizzatore**: il servizio stesso gli impedisce di scrivere. Chi può scrivere è **Editor**. Il **Proprietario** è chi possiede la cartella. L'app mostra e modifica i ruoli attraverso le funzioni di condivisione del servizio, dove l'API lo permette; dove non lo permette, spiega passo passo come cambiarli dal sito del servizio.
- **Ruoli in modalità server:** applicati dal Sync Server.

> **Rischi tecnici da verificare con il prototipo:**
> - Google Drive: con il permesso più ristretto (`drive.file`, accesso solo ai file creati o aperti dall'app) l'accesso a una cartella **condivisa da un altro utente** potrebbe richiedere che l'invitato la apra tramite il selettore di file di Google. Va provato. Il client OAuth va registrato presso Google, Microsoft e Dropbox a nome del progetto.
> - Microsoft OneDrive: condivisione di cartelle tra account personali via Microsoft Graph.
> - Dropbox: condivisione di cartelle tra account e permessi di sola lettura tramite API.

### 4.5 Backup ed esportazione

Il backup serve a **non perdere i dati** e a spostarli tra dispositivi senza spazio di sincronizzazione. Lo spazio di sincronizzazione, quando c'è, fa già anche da backup.

- **Formato:** un file `.itinerea` per viaggio (JSON + allegati in un unico pacchetto compresso), con password facoltativa per cifrarlo. Lo stesso formato serve per condividere itinerari (F4.3).
- **Destinazioni:** Google Drive, OneDrive, Dropbox, WebDAV oppure un file salvato dove vuole l'utente.
- **Automatico:** l'utente sceglie la frequenza (a ogni modifica / giornaliero / manuale).
- **Ripristino:** si importa il file e il viaggio torna com'era.

### 4.6 Servizi esterni, fornitori intercambiabili e dati statici

**Fornitori intercambiabili.** Ogni servizio esterno (mappa, percorsi, ricerca, mezzi, meteo…) è usato tramite un'interfaccia comune. Di default l'app usa un servizio pubblico gratuito (sezione 5). Nelle impostazioni l'utente può indicare **l'indirizzo di un proprio server** (per esempio un suo GraphHopper o Valhalla, Photon, MOTIS o server di mappe). Così chi vuole può fare tutto in self-hosting, e se un servizio pubblico chiude basta cambiare indirizzo.

| Servizio | Dove gira | Cosa fa |
|---|---|---|
| **Mappa base online** | Servizio pubblico (OpenFreeMap) o server dell'utente | Tile vettoriali della mappa |
| **Mappe offline** | **Sul dispositivo** | L'app scarica dall'archivio PMTiles pubblico di **OpenFreeMap** solo le tile della regione scelta (richieste parziali HTTP) e le salva in un archivio locale. Si usa OpenFreeMap anche offline perché ha **lo stesso schema delle tile** (OpenMapTiles) della mappa online, quindi lo stesso stile grafico. **Esito M1 (13/11/2026):** la mappa offline funziona, ma la strada descritta qui (richieste parziali sul planet PMTiles) non è quella prevista dalle condizioni d'uso di OpenFreeMap e il pacchetto per leggere PMTiles oggi non è compatibile con il resto dello stack. Tre strade provate e **decisione in sospeso**: vedi 16.3. |
| **Luoghi offline** (bagni, distributori, colonnine, campeggi, attrazioni) | **Sul dispositivo** | Scaricati dalla Overpass API di OpenStreetMap per l'area del viaggio e salvati nel database locale |
| **Calcolo percorsi** | Servizio pubblico (Valhalla di FOSSGIS) o server dell'utente | Percorsi auto, moto, bici e a piedi con preferenze. Curve e panoramicità si ottengono **valutando sul dispositivo** più percorsi alternativi (5.2). |
| **Altitudine** | Servizio pubblico (5.2) o server dell'utente | Quote lungo i percorsi, per il panoramico "montagna" (F3.4) |
| **Ricerca luoghi e indirizzi** | Servizio pubblico (Photon) o server dell'utente | |
| **Mezzi pubblici** | Servizio pubblico (Transitous) o server MOTIS dell'utente | |
| **Prezzi carburante** | Chiamate dirette dall'app alle fonti ufficiali | Nessun intermediario |
| **Lettura prenotazioni** | **Sul dispositivo** | Dati strutturati delle email, codici a barre delle carte d'imbarco, testo dei PDF (F2.3) |
| **Dati statici** (database veicoli, liste dei badge, tabelle pedaggi e vignette) | **File statici pubblicati su GitHub Releases** | Generati da script nel repository e scaricati dall'app. Non è un server: sono file scaricabili, gratuiti, aggiornati a ogni rilascio. |

### 4.7 Itinerea Sync Server (facoltativo, self-hosted)

Un piccolo server **incluso nel repository**, che **chi vuole installa per sé** (a casa, su un NAS o su un VPS). Il progetto non ne gestisce nessuna istanza pubblica.

- **Funzioni:** smistamento delle operazioni in tempo reale (WebSocket), archivio dei viaggi e degli allegati, utenti e ruoli, presenza, blocco morbido delle note.
- **Installazione:** un'immagine Docker e un singolo eseguibile. Configurazione minima: indirizzo, utenti, cartella dati.
- **Tecnologia proposta:** Dart (stesso linguaggio dell'app, modelli condivisi) con SQLite. *Alternativa:* PocketBase. **La scelta definitiva si fa all'inizio della Fase 2**; fino ad allora `/sync-server` contiene solo struttura e README (15.1).
- **Fase:** 2, insieme alla collaborazione.

### 4.8 Struttura del repository

Un unico repository GitHub pubblico (monorepo), così Claude Code ha tutto il contesto in un posto:

```
/app                Flutter (tutte le piattaforme)
  /lib
    /core           modelli, database, sync, fornitori, utilità
    /features       una cartella per funzione (trip, map, budget, bookings…)
    /l10n           traduzioni (file ARB); i file generati (/l10n/generated) non sono versionati
  /test             test automatici
  /tool             script di controllo (es. intestazione SPDX)
  /prototypes       prove di M1, separate dal codice dell'app
/sync-server        Itinerea Sync Server (facoltativo, self-hosted) + Dockerfile
/data-packs         script che generano i dati statici: veicoli, badge, pedaggi
/docs               PRD.md, DECISIONS.md (decisioni), DESIGN.md (stile), ROADMAP.md (avanzamento)
/.github            workflow della CI, modelli di issue, FUNDING.yml, dependabot.yml
README.md           presentazione (in inglese, con una sezione in italiano)
LICENSE             testo della GPL-3.0 (il progetto è GPL-3.0-or-later)
LICENSE-DATA.md     licenze dei dati (12.1)
CONTRIBUTING.md     come contribuire (codice, traduzioni, pedaggi, regole prenotazioni, badge, grafiche)
CODE_OF_CONDUCT.md  Contributor Covenant
SECURITY.md         come segnalare una vulnerabilità (segnalazione privata di GitHub)
CLAUDE.md           regole per Claude Code
```

### 4.9 Distribuzione e aggiornamenti

**Canali (decisione presa):**

| Canale | Piattaforme | Aggiornamenti | Note |
|---|---|---|---|
| **GitHub Releases** | Android (APK), Windows (installer, formato da scegliere in M7), macOS (DMG), Linux (AppImage) | Controllo nell'app (vedi sotto) | Sempre disponibile, è il canale di riferimento |
| **Google Play** | Android | Automatici dallo store | Iscrizione sviluppatore una tantum. Per i nuovi account personali Google chiede un **test chiuso con almeno 12 tester per 14 giorni consecutivi** prima della pubblicazione: vanno trovati per tempo (amici, compagni di corso). |
| **F-Droid** | Android | Automatici dallo store | Compila l'app dal codice sorgente. Richiede solo dipendenze open source. Segnalerà probabilmente l'"anti-funzione" *NonFreeNet*, perché l'app può usare servizi non liberi (Google Drive, OneDrive, Dropbox): è normale e non impedisce la pubblicazione. |
| **Flathub** | Linux | Automatici | Gratuito |
| *Non usati* | iOS (App Store), Microsoft Store, Mac App Store | — | Decisione presa |

**Conseguenze da sapere:**
- **iPhone e iPad:** nessun modo pratico di installare l'app. Il codice resta compatibile (1.4).
- **macOS e Windows senza firma a pagamento:** all'apertura il sistema mostra un avviso (Gatekeeper su macOS, SmartScreen su Windows). Il README e la pagina dei download spiegano come aprire comunque l'app.
- **Verifica degli sviluppatori Android:** Google sta introducendo la registrazione obbligatoria degli sviluppatori anche per le app installate fuori da Google Play (già in vigore dal 30/09/2026 in Brasile, Indonesia, Singapore e Thailandia, globale dal 2027). Con l'account Google Play lo sviluppatore è già verificato: andranno **registrati anche i nomi di pacchetto** dell'APK su GitHub. F-Droid si oppone a questa misura e il suo funzionamento futuro è incerto: rischio da seguire (sezione 16).
- **Firma e build riproducibili:** l'obiettivo è che la build di F-Droid sia identica a quella di GitHub (build riproducibili), così F-Droid può distribuire l'APK con la firma dello sviluppatore e gli utenti possono passare da un canale all'altro senza disinstallare.

**Aggiornamenti:**
- **Store (Google Play, F-Droid, Flathub):** l'app si aggiorna come tutte le altre, gestita dallo store.
- **Versione da GitHub:** all'avvio, al massimo una volta al giorno, l'app controlla le release pubbliche su GitHub. Se c'è una versione nuova mostra "Nuova versione disponibile" con le novità e un pulsante per scaricarla. Su Android il sistema chiede sempre conferma prima di installare; su desktop si scarica il nuovo installer o AppImage. Il controllo si può disattivare e non invia nessun dato personale.
- L'app sa da quale canale proviene grazie a un parametro di compilazione (es. `--dart-define=DISTRIBUTION=github|play|fdroid|flathub`) e mostra il controllo GitHub **solo** nelle build per GitHub. Le build per Google Play, F-Droid e Flathub non contengono nessun controllo degli aggiornamenti: lì li gestisce lo store (Google Play vieta espressamente alle app di aggiornarsi da sole).
- **Pacchetti dati** (veicoli, badge, pedaggi): hanno una versione propria e si aggiornano **senza aggiornare l'app**. L'app controlla se esistono pacchetti più recenti e li scarica in background quando è connessa (anche solo su Wi-Fi, a scelta).
- **Migrazioni:** ogni versione nuova deve leggere i dati e i file di sincronizzazione delle versioni precedenti. In un viaggio di gruppo possono convivere versioni diverse dell'app: il formato delle operazioni è versionato e un'app vecchia avvisa "Aggiorna Itinerea per vedere tutte le modifiche" invece di rompere i dati.

### 4.10 Costi

- **Per il progetto: 0 € al mese.** Nessun server, nessuno storage, nessuna API a pagamento.
- **Una tantum:** iscrizione sviluppatore Google Play. Facoltativo: un dominio per il sito.
- **Per gli utenti:** l'app è gratuita. Chi sceglie il self-hosting paga il proprio server, se ne ha uno a pagamento.

### 4.11 Donazioni (facoltative)

- **GitHub Sponsors** (decisione presa): integrato nel repository; per gli account personali GitHub non trattiene commissioni.
- Il link compare **solo** nel README, nella pagina dello store (anche F-Droid ha un campo "Dona") e nella schermata "Informazioni" dell'app. **Mai** popup, promemoria o richieste durante l'uso.
- Le donazioni non sbloccano nulla: niente funzioni, punti o oggetti estetici.
- Le donazioni ricevute sono reddito: prima di attivarle conviene chiedere a un commercialista come dichiararle.

---

## 5. Fonti dati e API

### 5.1 Criteri di scelta

1. Gratuita e utilizzabile da un'app open source e non commerciale.
2. Senza chiave, oppure con una chiave che **ogni utente può ottenere per sé** (mai chiavi segrete del progetto nel codice pubblico).
3. Dati salvabili sul dispositivo per l'uso offline.
4. Sostituibile da un server dell'utente (4.6).
5. Ogni fonte ha un **piano B**.

### 5.2 Tabella delle fonti

| Bisogno | Fonte principale | Licenza e costo | Limiti e obblighi | Piano B |
|---|---|---|---|---|
| **Mappa base online** | OpenFreeMap (dati OpenStreetMap) | Gratis, nessuna chiave | Servizio a donazioni, senza garanzie, senza limiti dichiarati sul numero di richieste. Attribuzione obbligatoria, da mostrare sulla mappa (testo esatto in 5.6). | Server di tile dell'utente |
| **Mappe offline** | Planet **PMTiles** settimanale di **OpenFreeMap** (schema OpenMapTiles, uguale alla mappa online) | ODbL (dati OSM) | Il formato PMTiles permette di leggere solo le parti necessarie di un archivio remoto; il pacchetto Dart `pmtiles` lo supporta in lettura. Salvare le tile scaricate in un archivio locale (PMTiles o MBTiles) va implementato. **Da prototipare** e da verificare con OpenFreeMap che lo scaricamento parziale del planet da parte di un'app sia gradito. **Non mischiare schemi:** le tile Protomaps hanno uno schema diverso e richiederebbero un altro stile. | Importare un file PMTiles/MBTiles preparato dall'utente; cache delle tile già viste. **Esito M1:** vedi 16.3 e le condizioni in 5.6 (download dal server delle tile ammesso entro 3.000 tile o 50 MB per download). |
| **Percorsi** (auto, moto, bici, a piedi) | **Valhalla pubblico di FOSSGIS** (lo stesso usato da openstreetmap.org) | Gratis, fair use | Opzioni utili: evitare autostrade, pedaggi, traghetti, sterrato; profilo moto. Uso moderato, User-Agent identificativo. **Condizioni d'uso da rileggere prima del rilascio** (pagina FOSSGIS non accessibile durante la verifica). | OSRM pubblico di FOSSGIS (senza preferenze avanzate) oppure server GraphHopper/Valhalla dell'utente. **Esito M1 (13/11/2026): funziona con limiti** (16.3). Condizioni lette (5.6): al massimo **una richiesta al secondo**, User-Agent dell'app, intestazione `X-Client-Id`, avviso su GitHub Discussions per le app pubblicate, email di contatto pubblica. |
| **Curve e panoramico** (mare, lago, montagna) | **Valutazione sul dispositivo**: l'app chiede a Valhalla più percorsi alternativi (parametro `alternates`, anche con punti di passaggio diversi) e li ordina per tortuosità (dalla geometria), vicinanza a coste o laghi (dati OSM via Overpass lungo il corridoio) e quota | — | **Risultato "il meglio possibile"**, non un giudizio umano sulla bellezza. **Attenzione (esito M1, 16.3):** `alternates` ha restituito alternative solo sulla tratta lunga (2 su 2 per Aosta–Bari) e nessuna su tratte da 80 e 200 km né con punti di passaggio. I percorsi candidati vanno quindi generati cambiando opzioni o punti di passaggio, una richiesta al secondo. | Profilo personalizzato su un GraphHopper dell'utente |
| **Altitudine** | Endpoint `/height` di Valhalla, se attivo sull'istanza usata; altrimenti **Open-Meteo Elevation API** | Open-Meteo: gratis per uso non commerciale (Itinerea lo è) | Da verificare in M1 quale delle due è disponibile e con quali limiti. **Esito M1 (13/11/2026): `/height` è attivo sull'istanza FOSSGIS** (1.932 punti in 0,13 s) e diventa la fonte principale; Open-Meteo funziona (100 punti per richiesta, 0,25 s) e resta il piano B. | Open-Meteo Elevation; poi solo tag OSM (passi di montagna, vette vicine) |
| **Ricerca luoghi e indirizzi** | Photon pubblico (OSM) | Fair use | Uso intensivo rallentato | Nominatim pubblico (max 1 richiesta al secondo) o server dell'utente |
| **Dettagli dei luoghi** (orari, telefono, sito, descrizione, foto) | OpenStreetMap + Wikidata e Wikimedia Commons | OSM: ODbL. Wikidata: CC0 | **Meno completi di Google**, soprattutto orari. Nessuna recensione. | Valutazioni personali dell'utente (F4.4) |
| **Luoghi offline e livelli mappa** (bagni, distributori, colonnine, campeggi, aree sosta, hotel) | Overpass API (OSM) | ODbL, fair use | Query per area, salvate in locale. Niente scaricamenti di intere nazioni a ogni avvio. | Istanze Overpass alternative o server dell'utente |
| **Mezzi pubblici** | Transitous (motore MOTIS) | Gratis | Pensato proprio per app open source e non-profit: **Itinerea rientra nell'uso previsto**. Copertura variabile da paese a paese. Condizioni d'uso da rileggere prima del rilascio, come per Valhalla (R2). | Server MOTIS dell'utente |
| **Meteo** | MET Norway (Locationforecast) | Gratis, CC BY 4.0 | User-Agent identificativo obbligatorio, cache, attribuzione | Open-Meteo (gratis per uso non commerciale) |
| **Cambio valuta** | Frankfurter | Gratis, nessuna chiave | Cambi giornalieri e storici. Se una valuta non è disponibile, l'utente inserisce il cambio a mano, etichettato come tale (T4). | Tassi di riferimento BCE scaricati direttamente |
| **Prezzi carburante — Italia** | MIMIT (open data ufficiale) | Gratis, IODL 2.0 | CSV quotidiani scaricati direttamente dall'app | — |
| **Prezzi carburante — Germania** | MTS-K tramite Tankerkönig | Gratis con chiave, CC BY 4.0 | **Ogni utente inserisce la propria chiave gratuita** (facoltativa), così non si pubblica una chiave nel codice e non si ridistribuiscono i dati | Senza chiave: prezzo medio nazionale o inserito dall'utente |
| **Prezzi carburante — altri paesi** | Open data nazionali dove esistono (es. Francia) | Da verificare paese per paese | Copertura non uniforme | Prezzo inserito dall'utente |
| **Colonnine di ricarica** | OpenStreetMap + Open Charge Map | OCM: chiave gratuita per utente, attribuzione | | Solo OSM |
| **Pedaggi** | **Tabelle tariffe nel repository**, mantenute dalla community via GitHub, + tratte a pedaggio da OSM + vignette | Licenza del repository | Non esiste un'API gratuita per auto e moto. Risultato: **stima**, con data di aggiornamento della tabella. | Importo inserito dall'utente |
| **Dati veicolo (auto)** | Dataset UE dell'Agenzia Europea dell'Ambiente, elaborato dagli script `/data-packs` e pubblicato come file statico | Open data UE | Valori **di omologazione WLTP**, più bassi del consumo reale. Auto immatricolate in UE dal 2010 circa. | Inserimento manuale |
| **Dati veicolo (moto)** | **Nessuna fonte aperta trovata** | — | — | Inserimento manuale. In futuro: valori raccolti dalla community nel repository. |
| **Hotel** | OpenStreetMap per la mappa + **link semplice a Booking.com** (nessuna affiliazione) | — | La ricerca con prezzi e filtri avviene su Booking | Link ad altri siti di prenotazione |
| **Lettura prenotazioni** | **Sul dispositivo:** dati strutturati schema.org nelle email; codice a barre delle carte d'imbarco (standard IATA BCBP); testo dei PDF con regole per compagnia | — | Le regole per singole compagnie e hotel possono essere aggiunte dalla community nel repository | Inserimento manuale con il file allegato |
| **Liste di luoghi per i badge** | Wikidata + revisione manuale delle città principali, pubblicate come file statico | CC0 | | — |
| **Popolarità dei luoghi** (consigli) | Wikidata e Wikipedia (es. quante versioni linguistiche ha la voce) + OSM | CC0 / ODbL | Approssimazione della fama, non della qualità | Valutazioni personali dell'utente |
| **Guide e itinerari consigliati** (consigli) | Wikivoyage | CC BY-SA, attribuzione | Copertura e qualità variabili per città; dati da estrarre dal testo delle guide | Solo Wikidata/OSM |

### 5.3 Fonti escluse e perché

| Fonte | Motivo |
|---|---|
| Google Maps / Places | A pagamento oltre la quota gratuita, chiave obbligatoria, divieto di salvare i dati offline |
| Sygic, ViaMichelin, Roadtrippers | API a pagamento o non pubbliche |
| Flush Toilet Finder | Nessuna API pubblica nota; i dati OSM coprono il bisogno |
| AdMob, acquisti in-app, affiliazioni Booking | Esclusi per scelta: nessuna pubblicità e nessun pagamento |
| Firebase / notifiche push | Richiedono un server e SDK proprietari |
| GraphHopper o openrouteservice pubblici | Richiedono una chiave e hanno limiti giornalieri. Restano possibili come fornitore configurato dall'utente con la sua chiave. |

### 5.4 Uso responsabile dei servizi pubblici

Senza server propri, l'app dipende da servizi gestiti da volontari e associazioni. Regole obbligatorie:
- **User-Agent identificativo** in ogni richiesta, es. `Itinerea/1.2 (+https://github.com/NotEnjoyingThis/itinerea)`.
- **Cache locale** di tutto ciò che si può riusare: percorsi già calcolati, luoghi, meteo per la durata indicata dal servizio, cambi del giorno.
- **Limiti di frequenza** lato app (es. ricerca con attesa di 300 ms dopo l'ultima lettera digitata, nessuna richiesta automatica ripetuta).
- **Niente scaricamenti massivi** automatici.
- **Fornitore configurabile** (4.6): se un servizio chiede di ridurre il traffico, gli utenti possono passare a un altro server.
- Nella schermata "Fonti dei dati" un invito a sostenere OpenStreetMap, FOSSGIS, Transitous e gli altri servizi usati.

### 5.5 Attribuzioni obbligatorie

L'app ha una schermata **"Fonti dei dati"**, raggiungibile anche dalla mappa, con almeno:
- © OpenStreetMap contributors (ODbL)
- OpenFreeMap © OpenMapTiles
- Valhalla / FOSSGIS, Photon, Overpass API, Open-Meteo (se usato)
- MET Norway (CC BY 4.0)
- Tankerkönig / MTS-K (CC BY 4.0)
- Open Charge Map e i singoli fornitori dei dati
- Frankfurter / BCE, MIMIT, Agenzia Europea dell'Ambiente, Wikidata, Wikivoyage, Transitous e i fornitori dei loro dati

### 5.6 Condizioni d'uso lette

Per ogni servizio: pagina, frase esatta (in lingua originale) e data in cui è stata letta. Vanno rilette prima di ogni rilascio.

| Servizio | Pagina | Frase esatta | Letta il |
|---|---|---|---|
| OpenFreeMap — uso del servizio pubblico | https://openfreemap.org/ | "Using our public instance is completely free: there are no limits on the number of map views or requests. There's no registration, no user database, no API keys, and no cookies." | 13/11/2026 |
| OpenFreeMap — uso commerciale | https://openfreemap.org/ | "Is commercial usage allowed? Yes." | 13/11/2026 |
| OpenFreeMap — attribuzione | https://openfreemap.org/ | "Attribution is required. If you are using MapLibre, they are automatically added, you have nothing to do. If you are using alternative clients, or if you are using this in printed media or video, you must add the following attribution: OpenFreeMap © OpenMapTiles Data from OpenStreetMap" | 13/11/2026 |
| OpenFreeMap — schema delle tile | https://openfreemap.org/ | "The map schema is unmodified OpenMapTiles." | 13/11/2026 |
| OpenFreeMap — download offline (home) | https://openfreemap.org/ | "Can my app download areas for offline use? Yes, as long as each download is at most 3,000 tiles or 50 MB, uses at most 4 parallel requests, and sends a unique User-Agent identifying your app. For anything larger, please contact us." | 13/11/2026 |
| OpenFreeMap — download offline e raccolta automatica (condizioni del 14/10/2026) | https://openfreemap.org/tos/ | "You will not: […] Collect data from the service in automated ways, except for offline downloads as described below" · "Your app may let users download areas for offline use if each download is: at most 3,000 tiles or 50 MB; made with at most 4 parallel requests; sent with a unique User-Agent identifying your app. For anything larger, please contact us" | 13/11/2026 |
| OpenFreeMap — download del planet | https://github.com/hyperknot/openfreemap (README) | "Full planet runs are uploaded weekly. You can download them in Btrfs, MBTiles and PMTiles formats." · "MBTiles files are not required for this project. We provide them for your convenience, allowing you to use the processed planet tiles with any other tool of your choice." · "Unfortunately, on Cloudflare, range requests in 90 GB files have terrible latency" | 13/11/2026 |
| GitHub Releases — dimensioni | https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases | "Each file included in a release must be under 2 GiB." · "There is no limit on the total size of a release, nor bandwidth usage." · "Up to 1000 release assets may be associated with a single release." | 13/11/2026 |
| GitHub — uso eccessivo di banda | https://docs.github.com/en/site-policy/acceptable-use-policies/github-acceptable-use-policies (sezione 9) | GitHub può limitare un account se l'uso di banda è "significantly excessive in relation to other users of similar features" (riassunto: la frase completa non è stata copiata) | 13/11/2026 |
| FOSSGIS — a chi si applicano | https://fossgis.de/arbeitsgruppen/osm-server/nutzungsbedingungen/ (versione inglese nella stessa pagina) | "These terms of use apply to: […] the FOSSGIS e.V. routing servers (routing.openstreetmap.de, valhalla1.openstreetmap.de)" · "We are generally pleased when third parties use our services for creative and innovative applications. However, excessive use restricts usability." | 13/11/2026 |
| FOSSGIS — limite dei server di routing | stessa pagina | "Maximum one request per second." | 13/11/2026 |
| FOSSGIS — requisiti tecnici | stessa pagina | "Valid HTTP User-Agent identifying the application. User agents of libraries are not sufficient." · "Maximum two downloading connections. […] Scripts are limited to one connection." | 13/11/2026 |
| FOSSGIS — attribuzione e contatto | stessa pagina | "Clear display of attribution as required by the license and the OpenStreetMap Foundation guidelines." · "Include a link to https://www.openstreetmap.org/fixthemap to allow your users to report and correct errors in our data." · "For websites, an email address of the operator must be easily identifiable and directly reachable […]. For apps, this applies to the app website and its entries in app stores." | 13/11/2026 |
| FOSSGIS — indirizzi dei servizi | stessa pagina | "Explicitly recommended: The URLs of our services should not be hardcoded into the app." | 13/11/2026 |
| FOSSGIS — usi vietati | stessa pagina | "Commercial use is only permitted if the use of the services does not constitute a substantial part of an online offering." · "Websites with high traffic volumes are generally not permitted to use our services." · "Mass downloading of data is prohibited." | 13/11/2026 |
| FOSSGIS — disponibilità | stessa pagina | "We note that permission to use the services may be revoked by us at any time without stating reasons." · "Please note that each service is backed by only a single server. We do not guarantee availability." | 13/11/2026 |
| Valhalla — server dimostrativo | https://github.com/valhalla/valhalla (README, "Demo Server") | "Usage of the demo server follows the usual fair-usage policy as OSRM & Nominatim demo servers (somewhat enforced by rate limits)." · "In case you **publish apps to end users** (be it mobile, web or desktop) which request to the public demo server, we'd ask you to let us know via Github Discussions and to include an identifying `X-Client-Id` request header, e.g. `X-Client-Id: newroutingapp.io`." | 13/11/2026 |
| Valhalla — limiti di frequenza | https://github.com/valhalla/valhalla/discussions/3373#discussioncomment-1644713 (messaggio del 15/11/2021) | "we rate limit to 1 call/user/sec and 100 calls/sec total. Service limits are a bit stricter than the defaults as well." | 13/11/2026 |
| Open-Meteo — uso gratuito | https://open-meteo.com/en/terms | "Less than 10'000 API calls per day, 5'000 per hour and 600 per minute." · "You may only use the free API services for non-commercial purposes." · "You accept to the CC-BY 4.0 licence" | 13/11/2026 |
| Open-Meteo — cosa è non commerciale | https://open-meteo.com/en/terms | "Non-commercial use is defined as elaborated by creative commons." · "Private or non-profit websites or apps that do not have subscriptions or advertising." · "Voluntary donations, including contributions through a tip jar, are permitted." | 13/11/2026 |
| Open-Meteo — API dell'altitudine | https://open-meteo.com/en/docs/elevation-api | "Up to 100 coordinates can be requested at once." · "Data is based on the Copernicus DEM 2021 release GLO-90 with 90 meters resolution." · "All users of Open-Meteo data must provide a clear attribution to the Copernicus program as well as a reference to Open-Meteo." | 13/11/2026 |

**Obblighi che ne derivano per Itinerea verso FOSSGIS/Valhalla:** al massimo una richiesta al secondo per dispositivo e una sola connessione; User-Agent `Itinerea/<versione> (+<url del repository>)` e intestazione `X-Client-Id`; attribuzione a OpenStreetMap con link a `https://www.openstreetmap.org/fixthemap` nella schermata "Fonti dei dati"; un'**email di contatto pubblica** nella pagina del progetto e nelle schede degli store; un **avviso su GitHub Discussions di Valhalla** prima della pubblicazione; indirizzo del servizio non fisso nel codice ma modificabile (il fornitore configurabile del PRD 4.6 lo soddisfa; l'indirizzo predefinito può stare in un pacchetto dati aggiornabile senza rilasciare l'app).

Le condizioni di OpenFreeMap **non dicono nulla** sull'estrazione di regioni dal planet né sulla ridistribuzione di estratti: parlano solo del servizio delle tile. I dati sono OpenStreetMap (ODbL) nello schema OpenMapTiles, entrambi ridistribuibili con attribuzione.

Itinerea non usa MapLibre, quindi l'attribuzione di OpenFreeMap va mostrata dall'app sulla mappa e nella schermata "Fonti dei dati" (5.5).

---

## 6. Funzionalità per fase

### 6.0 Come leggere questa sezione

- Ogni funzionalità ha un codice (**F1.3** = Fase 1, funzionalità 3), da usare anche nei commit e nelle issue.
- **Requisiti:** cosa deve fare.
- **Criteri di accettazione (CA):** come si verifica che è finita. Una funzionalità è finita solo quando tutti i CA passano su **tutte e 4 le piattaforme distribuite** (Android, Windows, macOS, Linux).
- Le fasi si sviluppano in ordine. Una fase si considera conclusa quando tutte le sue funzionalità sono finite e l'app è stabile. L'impalcatura senza logica di tutte le fasi (15.1) non conta come sviluppo anticipato.

| Fase | Obiettivo | Risultato |
|---|---|---|
| **1 — MVP** | Pianificare e vivere un viaggio da soli, anche offline | Prima versione pubblicabile |
| **2 — Gruppo e strada** | Collaborazione, prenotazioni automatiche, mezzi pubblici, funzioni roadtrip complete | L'app sostituisce TripIt, Splitwise e Fuel Flash |
| **3 — Consigli e costi** | Assistente, hotel, pedaggi, percorsi panoramici | L'app sostituisce Roadtrippers e ViaMichelin |
| **4 — Gioco e condivisione** | Badge, punti, shop, profilo, itinerari condivisi | Fidelizzazione, tutto in locale |

### 6.1 Requisiti trasversali (valgono sempre)

| Codice | Requisito |
|---|---|
| T1 | Le azioni frequenti (aggiungere una tappa, registrare una spesa, aprire un biglietto, attivare un piano B) richiedono **al massimo 3 tocchi** dalla schermata del giorno. |
| T2 | Un viaggio già salvato si apre in **meno di 1 secondo** su un telefono Android di fascia media (riferimento: un modello di fascia media di circa 3 anni prima). |
| T3 | Tutto ciò che è salvato nel viaggio è consultabile e modificabile **offline**. |
| T4 | Ogni dato potenzialmente vecchio o stimato è **etichettato** come tale: "Stima", "Offline – aggiornato il…", "Valore dichiarato dal costruttore". |
| T5 | Tema chiaro e scuro, oppure automatico secondo il sistema. |
| T6 | Testi dell'interfaccia sempre tradotti, mai scritti a mano nel codice. Italiano e inglese completi. |
| T7 | Accessibilità: dimensioni del testo di sistema rispettate, contrasto sufficiente, etichette per i lettori di schermo. |
| T8 | Layout adattivo: telefono (una colonna), tablet e desktop (mappa e lista affiancate). |
| T9 | **Nessuna telemetria**, nessun tracciamento, nessuna richiesta di rete verso server del progetto. |
| T10 | Ogni servizio esterno usa un **fornitore configurabile** (4.6) e ha un comportamento definito quando non risponde. |

---

### FASE 1 — MVP

#### F1.1 Creazione del viaggio
**Requisiti**
- Si sceglie il tipo: **Itinerario** o **Roadtrip**.
- Dati iniziali: nome, destinazione o destinazioni, data di inizio e di fine **oppure solo il numero di giorni** (date non ancora decise), luogo di partenza e di ritorno.
- Se ci sono voli o treni di andata e ritorno, si possono aggiungere subito come prenotazioni (F1.9).
- I giorni vengono creati in automatico in base alle date o al numero di giorni.
- **Viaggio senza date:** i giorni si chiamano "Giorno 1", "Giorno 2"… Le funzioni che hanno bisogno della data (meteo, giorni di chiusura dei luoghi, cambio del giorno, notifiche) mostrano "Imposta le date del viaggio". Quando l'utente sceglie la data di inizio, ogni giorno prende la sua data.
- In qualsiasi momento si può **cambiare tipo da un giorno in poi** (segmento, vedi glossario): per esempio giorni 1–4 Itinerario, dal giorno 5 Roadtrip. Il cambio si annulla rimettendo il tipo precedente.

**CA**
- Un viaggio base (nome, destinazione, date) si crea in meno di 2 minuti e in al massimo 4 schermate.
- Cambiando le date, i giorni si aggiungono o si rimuovono. Se un giorno da rimuovere contiene tappe, l'app chiede se spostarle o eliminarle.
- Con un viaggio misto, le funzioni roadtrip (veicolo, distributori, soste) compaiono solo nei giorni del segmento Roadtrip.
- Un viaggio creato con il solo numero di giorni si può pianificare; impostando poi la data di inizio, ogni giorno riceve la data giusta senza perdere tappe.

#### F1.2 Giorni e tappe
**Requisiti**
- Si aggiunge una tappa cercandola per nome o indirizzo, toccandola sulla mappa, oppure come tappa libera (solo nome e note).
- Se il luogo è nelle fonti dati, la tappa si compila da sola con indirizzo, coordinate, orari di apertura, telefono e sito web.
- Campi della tappa: orario di inizio, durata, note, costo stimato, link, allegati, stato (da visitare / visitata / saltata). Durata predefinita: 1 ora, sempre modificabile.
- Le tappe si riordinano trascinandole e si spostano in un altro giorno.
- Ogni giorno può avere l'**alloggio della notte**: hotel, campeggio, area sosta o notte in auto (di solito l'ultimo giorno non ce l'ha).

**CA**
- Una tappa cercata per nome mostra orari e contatti quando OSM li ha. Quando non li ha, i campi restano vuoti e modificabili, senza errori.
- Il riordino si salva subito e funziona offline.
- Spostare una tappa in un altro giorno aggiorna gli orari di entrambi i giorni (F1.3).

#### F1.3 Orari automatici e avvisi
**Requisiti**
- La prima tappa del giorno inizia all'**orario di inizio della giornata** (default 9:00, modificabile nelle impostazioni e per singolo giorno).
- Gli orari si calcolano a catena: inizio della tappa precedente + durata + tempo della tratta = inizio della tappa successiva.
- Le tappe **con prenotazione** e quelle con l'orario **fissato a mano** (lucchetto) hanno un orario **fisso**: il ricalcolo non le sposta.
- Se cambiano una durata, una tratta o l'ordine delle tappe, le tappe successive **senza orario fisso** si ricalcolano da sole.
- Se si arriva **prima** di una tappa a orario fisso, il tempo che avanza si mostra come **"tempo libero"** (usato dall'assistente, F3.1).
- Avvisi, senza blocchi:
  - "Arrivi alle 18:30, ma il luogo chiude alle 18:00" (dagli orari di apertura).
  - "Rischi di non arrivare in tempo per [prenotazione] delle 15:00".
  - "Il luogo è chiuso in questo giorno della settimana".

**CA**
- Aumentando di 30 minuti la durata della tappa 2, le tappe 3 e 4 (non prenotate) slittano di 30 minuti, mentre la tappa 5 (prenotata alle 15:00) resta ferma e, se serve, compare l'avviso di ritardo.
- Gli avvisi compaiono sia nella lista del giorno sia sulla tappa.
- Arrivando alle 14:20 a una tappa prenotata alle 15:00, il giorno mostra 40 minuti di tempo libero prima di quella tappa.

#### F1.4 Tratte e mezzi
**Requisiti**
- Tra due tappe consecutive c'è una tratta, con mezzo a scelta: a piedi, auto, moto, bici, bus, treno, metro, tram, traghetto, aereo, taxi, altro.
- A piedi, in auto, in moto e in bici: durata e distanza calcolate (F1.5).
- Mezzi pubblici in Fase 1: orario e durata **inseriti a mano**, con il biglietto allegato. Le soluzioni con orari automatici arrivano in F2.4.
- Il mezzo predefinito dipende dal segmento: a piedi negli Itinerari; auto o moto nei Roadtrip, secondo il tipo di veicolo scelto per il segmento. In Fase 1 si sceglie solo il tipo (auto o moto); dalla Fase 2 il veicolo salvato con i suoi dati (F2.5).

**CA**
- Cambiando il mezzo, durata e orari del giorno si aggiornano.
- Una tratta calcolata resta disponibile offline con l'ultimo percorso salvato.

#### F1.5 Percorsi con preferenze
**Requisiti**
- **Profilo di percorso** a livello di viaggio, con possibilità di cambiarlo per singola tratta: più veloce / con curve; evita autostrade, pedaggi, sterrato, traghetti. Le opzioni valgono per qualsiasi veicolo.
- Il percorso proposto si **modifica trascinandolo** sulla mappa: si aggiungono punti di passaggio e il percorso si ricalcola passando da lì.
- Ogni tratta può avere più **percorsi alternativi salvati** (vedi F1.6).
- "Con curve" si ottiene valutando sul dispositivo i percorsi alternativi per tortuosità (5.2).
- Il percorso panoramico (mare, lago, montagna) arriva in F3.4.

**CA**
- Con "evita autostrade" attivo, il percorso calcolato non usa autostrade, se esiste un'alternativa.
- Un percorso modificato a mano resta salvato e non viene ricalcolato da solo. Si ricalcola solo se l'utente lo chiede.

#### F1.6 Alternative (piani A, B, C, D)
**Requisiti**
- Ogni **tappa** e ogni **tratta** può avere fino a 4 piani (A–D). Il piano A è attivo di default.
- Il piano si cambia **a mano**, con un tocco. Gli orari del giorno si ricalcolano (F1.3).
- Cambiando il piano di una tappa, le tratte vicine si ricalcolano da sole per collegare la nuova tappa. Se un percorso era stato modificato a mano (F1.5), l'app chiede prima di ricalcolarlo.
- **Regola dei costi:** il budget si aggiorna in automatico **solo per gli elementi prenotati o già pagati**. Il costo stimato di un piano non prenotato resta visibile come stima, ma entra nel budget solo quando l'utente registra una spesa.
- Una spesa già sostenuta (per esempio il biglietto pagato del piano A) **resta nel budget** anche se si passa a un altro piano: i soldi sono comunque spesi.
- I piani non attivi restano visibili in modo discreto, per esempio "+2 alternative".

**CA**
- Passando dal piano A al piano B su una tappa, gli orari successivi si ricalcolano e il budget cambia solo se il piano B ha una prenotazione o una spesa registrata.
- Si può tornare al piano A e tutto torna com'era.
- Se il piano A era già pagato (spesa registrata), passando al piano B quella spesa resta nel budget.

#### F1.7 Mappa
**Requisiti**
- Mostra le tappe del giorno selezionato numerate, con i percorsi delle tratte. Si può passare alla vista di tutto il viaggio.
- Livelli attivabili: bagni, distributori, colonnine, campeggi e aree sosta, hotel, attrazioni. In Fase 1 si vedono quando si è online; offline in F2.8.
- Toccando un luogo si vedono i dettagli e il pulsante "Aggiungi al giorno…".
- La mappa segue il tema chiaro o scuro.

**CA**
- Su desktop la mappa è affiancata alla lista del giorno; su telefono si passa da una all'altra con un tocco.
- Un livello attivo mostra solo i luoghi nell'area visibile, senza rallentare lo scorrimento.

#### F1.8 Biglietti e allegati
**Requisiti**
- Si caricano PDF, immagini e screenshot e si collegano a una tappa, una tratta o una prenotazione.
- Gli allegati sono **sempre salvati sul dispositivo** e quindi disponibili offline.
- Vista "biglietto": schermo intero, luminosità al massimo, zoom sul QR o codice a barre.

**CA**
- Un PDF allegato si apre in modalità aereo.
- Un QR mostrato in vista biglietto è leggibile da un lettore standard.

#### F1.9 Prenotazioni (inserimento manuale)
**Requisiti**
- Tipi: volo, treno, bus, traghetto, hotel/alloggio, museo/attrazione/evento, noleggio auto, ristorante, altro.
- Campi comuni: data e ora (inizio e fine), luogo, codice di prenotazione, costo, valuta, allegati, note. Campi specifici per tipo: per esempio check-in e check-out per gli hotel, posto e terminal per i voli.
- Una prenotazione **compare in automatico** nei giorni giusti: un hotel di 3 notti diventa l'alloggio dei 3 giorni.
- **Dove va ogni tipo di prenotazione:**
  - **volo, treno, bus, traghetto:** una **tratta** con quel mezzo e orari di partenza e arrivo fissi, tra due tappe create in automatico (es. "Aeroporto di Fiumicino" → "Aeroporto di Dublino"). Se il viaggio passa la mezzanotte, la tratta appartiene al giorno di partenza;
  - **hotel o alloggio:** l'**alloggio** dei giorni coperti, con check-in e check-out;
  - **museo, attrazione, evento, ristorante:** una **tappa** a orario fisso;
  - **noleggio auto:** una tappa di ritiro e una di riconsegna a orario fisso; dal giorno del ritiro l'app propone "Da qui: Roadtrip" (FL8).
- Il costo di una prenotazione entra nel budget (F1.10).
- L'import automatico da email e PDF arriva in F2.3.

**CA**
- Un hotel dal 10 al 13 compare come alloggio del 10, 11 e 12, con check-in il 10 e check-out il 13.
- Una prenotazione ha orario fisso nel ricalcolo (F1.3).
- Un volo inserito a mano crea una tratta di tipo aereo con orari fissi, tra due tappe create in automatico per gli aeroporti.

#### F1.10 Budget e spese (personali)
**Requisiti**
- Budget **generale** del viaggio oppure **per giorno**, a scelta.
- Valuta principale del viaggio.
- Registrazione di una spesa: importo, valuta, data, categoria (alloggio, trasporti, cibo, attività, carburante, pedaggi, acquisti, altro), nota, foto dello scontrino facoltativa.
- **Conversione con il cambio del giorno della spesa.** Se si è offline, si usa l'ultimo cambio disponibile, la spesa viene segnata "cambio da aggiornare" e si corregge da sola al ritorno online.
- Riepilogo: speso / previsto / rimanente, per categoria e per giorno.
- In Fase 1 ogni viaggio ha un solo partecipante, l'utente: tutte le spese sono sue. La divisione tra partecipanti e i prestiti arrivano in F2.2, insieme alla collaborazione.
- Se una valuta non è disponibile dal servizio dei cambi, il cambio si inserisce a mano (5.2).

**CA**
- Una spesa di 3.000 JPY del 12 marzo usa il cambio del 12 marzo, non quello di oggi.
- Le prenotazioni con costo compaiono nel budget senza doverle inserire due volte.

#### F1.11 Meteo
**Requisiti**
- Previsioni per ogni giorno del viaggio nel **luogo principale del giorno** (di default l'alloggio della notte, altrimenti la prima tappa; modificabile), quando la data rientra nell'orizzonte di previsione.
- Icona meteo sulla giornata e sulle tappe all'aperto.

**CA**
- Fuori dall'orizzonte di previsione non si mostra nulla, oppure si mostra "Previsione non ancora disponibile". Mai dati inventati.

#### F1.12 Apri nel navigatore
**Requisiti**
- Da una tratta o da un giorno intero: "Apri in…" Google Maps, Waze, Apple Maps, Sygic o un'altra app installata, con destinazione e tappe intermedie.
- Se l'app di destinazione accetta un numero limitato di tappe intermedie, il percorso viene diviso in più parti e l'utente viene avvisato.

**CA**
- Su Android si apre l'app scelta con il percorso. Su desktop si apre la versione web, quando esiste.

#### F1.13 Spazio di sincronizzazione personale e backup
**Requisiti**
- L'app si usa **senza alcun account**.
- Facoltativo: collegare uno spazio di sincronizzazione (Google Drive, OneDrive, Dropbox, WebDAV o cartella locale) per avere i propri viaggi su tutti i propri dispositivi (modalità file, 4.3).
- Backup su Google Drive, OneDrive, Dropbox, WebDAV o file locale, manuale o automatico (sezione 4.5).

**CA**
- Un viaggio creato offline e senza spazio collegato si sincronizza correttamente quando l'utente collega uno spazio.
- Scollegando lo spazio, i viaggi restano sul dispositivo.
- Un backup ripristinato su un altro dispositivo riproduce il viaggio identico, allegati compresi.

#### F1.14 Esporta in PDF
**Requisiti**
- PDF dell'itinerario (giorni, tappe, orari, alloggi, mappe riassuntive) con il link alla pagina del progetto su GitHub, da cui si scarica l'app per tutte le piattaforme. Serve per chi non usa l'app.
- Scelta di cosa includere: per esempio senza costi o senza note.

**CA**
- Il PDF è leggibile su telefono e stampabile in A4.

#### F1.15 Impostazioni di base
- Lingua (italiano/inglese), tema, unità di misura (km/miglia, litri/galloni), valuta predefinita, formato di data e ora, orario di inizio della giornata (default 9:00), durata predefinita delle tappe (default 1 ora), profilo locale (nome), spazi di sincronizzazione e backup, **fornitori dei servizi** (indirizzi dei server alternativi, chiavi personali facoltative come Tankerkönig).

---

### FASE 2 — Gruppo e strada

#### F2.1 Collaborazione
**Requisiti**
- Il proprietario sceglie lo spazio del viaggio: **modalità file** (Google Drive, OneDrive, Dropbox, WebDAV) o **modalità server** (Itinerea Sync Server self-hosted). Vedi 4.3 e 4.4.
- Invito tramite link o codice generato dall'app. Chi lo riceve deve avere l'app e accesso allo stesso spazio (es. un account Google).
- Ruoli: **Proprietario**, **Editor**, **Visualizzatore**.
- Tempi: in modalità file le modifiche arrivano in pochi secondi o minuti (controllo all'apertura, ogni 30 secondi in primo piano e con "Aggiorna"); in modalità server entro 2 secondi, con presenza e blocco morbido delle note.
- Cronologia delle versioni delle note in entrambe le modalità.
- Cifratura end-to-end facoltativa per viaggio (4.3), consigliata con Google Drive, OneDrive e Dropbox.
- Modifiche offline unite senza conflitti al ritorno online.
- L'interfaccia indica sempre la modalità e l'ultimo aggiornamento ("Aggiornato 20 s fa").

**CA**
- Due editor che modificano offline tappe diverse dello stesso giorno ritrovano entrambe le modifiche dopo la sincronizzazione.
- Un Visualizzatore non può modificare nulla, nemmeno offline: l'interfaccia di modifica è nascosta e lo spazio di sincronizzazione (permessi della cartella o Sync Server) rifiuta le scritture.
- L'Itinerea Sync Server si installa con un solo comando Docker seguendo la documentazione del repository.

#### F2.2 Spese di gruppo
**Requisiti**
- Ogni spesa ha chi ha pagato e come si divide: **in parti uguali, a percentuale, a quote o per importi esatti**, scegliendo per ogni spesa e tra quali partecipanti.
- **Prestiti:** "A ha prestato 50 € a B", fuori dalle spese comuni.
- **Saldo finale:** chi deve quanto a chi, con **pochi pagamenti**: al massimo (numero di persone − 1). Si usa un algoritmo semplice e prevedibile: chi deve di più paga chi deve ricevere di più, finché tutti sono a zero. Cercare sempre il minimo assoluto di pagamenti è troppo costoso da calcolare e non serve.
- **Arrotondamenti:** le divisioni si fanno in centesimi interi. I centesimi che avanzano (es. 10 € in 3 = 3,34 + 3,33 + 3,33) vanno, uno a testa, ai partecipanti in ordine di ID, così il risultato è identico su tutti i dispositivi.
- Si possono segnare i rimborsi come "saldati".

**CA**
- Tre persone, spese miste e un prestito: il saldo ha al massimo 2 pagamenti e la somma dei saldi è zero.
- 10 € divisi in parti uguali tra 3 persone danno 3,34 + 3,33 + 3,33, con lo stesso risultato su tutti i dispositivi.

#### F2.3 Import automatico delle prenotazioni
**Requisiti**
- L'utente **condivide** con l'app un'email, un PDF o uno screenshot (pulsante "Condividi" del sistema, trascinamento su desktop, oppure "Importa file").
- Lettura **interamente sul dispositivo**: dati strutturati (schema.org) presenti in molte email; codice a barre delle carte d'imbarco (standard IATA BCBP) da PDF o screenshot; testo dei PDF con regole per compagnia o hotel, che la community può aggiungere nel repository.
- Nessun file lascia il dispositivo.
- La prenotazione letta va **nel giorno e all'orario giusti**, con il file originale allegato e il costo nel budget.
- Tutto ciò che è stato letto in automatico si mostra come **"Da verificare"** finché l'utente non conferma.
- Tipi: tutti quelli di F1.9.

**CA**
- Una conferma di volo con dati strutturati crea la prenotazione con orari, aeroporti e codice corretti, anche in modalità aereo.
- Lo screenshot di una carta d'imbarco con codice BCBP crea volo, data, posto e codice di prenotazione.
- Un file che non si riesce a leggere apre il modulo manuale con il file già allegato.

#### F2.4 Mezzi pubblici
**Requisiti**
- Per una tratta con mezzo pubblico: elenco di soluzioni (orari, cambi, durata), si sceglie quella da usare.
- La soluzione scelta si salva nel viaggio ed è consultabile offline, con l'avviso: "Orari salvati il [data]: potrebbero essere cambiati".
- Più soluzioni salvabili come alternative (piani B, C…).

**CA**
- Offline, la tratta mostra la soluzione salvata con l'avviso, senza errori.

#### F2.5 Veicolo
**Requisiti**
- **Auto:** scelta di marca, modello e versione dal database, con consumo, alimentazione e autonomia compilati da soli e sempre modificabili. I valori di omologazione sono etichettati come tali.
- **Moto:** inserimento manuale (consumo, serbatoio, autonomia).
- Più veicoli per utente; si sceglie quale usare in ogni segmento Roadtrip.

**CA**
- Un'auto scelta dal database mostra il consumo con l'etichetta "valore dichiarato (WLTP)".

#### F2.6 Carburante, ricarica e soste
**Requisiti**
- Distributori e colonnine sulla mappa e lungo il percorso. Prezzi dove disponibili, con data di aggiornamento.
- **Stima del costo del carburante** per tratta, per giorno e per viaggio, in base a distanza, consumo e prezzi.
- **Pianificazione delle soste**, con opzione a scelta dell'utente:
  - **Automatica:** l'app propone dove fermarsi entro l'autonomia (con un margine di sicurezza regolabile), preferendo i distributori più economici lungo il percorso.
  - **Manuale:** l'utente aggiunge le soste da sé e l'app avvisa se una tratta supera l'autonomia.
- Le soste diventano tappe di tipo "Rifornimento" o "Ricarica".

**CA**
- Con 300 km di autonomia e una tratta di 450 km, in modalità automatica compare almeno una sosta prima di aver percorso 300 km meno il margine.

#### F2.7 Bagni, campeggi e notti in auto
**Requisiti**
- Livelli mappa: bagni (con a pagamento / accessibile quando il dato c'è), campeggi, aree sosta camper, parcheggi adatti alla notte.
- Alloggio della notte di tipo **campeggio**, **area sosta** o **notte in auto**.
- Quando si sceglie una notte in auto o in campeggio libero: **"Verifica le regole sul campeggio libero in [paese] prima di partire"**. L'app non dà giudizi sulla legalità.

**CA**
- L'avviso compare una volta per paese per viaggio, non a ogni notte.

#### F2.8 Mappe e luoghi offline
**Requisiti**
- Download di pacchetti mappa e luoghi per regione o paese, con dimensione indicata prima del download. I pacchetti si creano **sul dispositivo** estraendo la zona da archivi pubblici (4.6), senza server del progetto.
- L'app suggerisce i pacchetti necessari per il viaggio ("Scarica le mappe per questo viaggio").
- Gestione dello spazio: elenco pacchetti, eliminazione, aggiornamento.

**CA**
- In modalità aereo, con il pacchetto scaricato, la mappa, i livelli (bagni, distributori…) e la ricerca dei luoghi del pacchetto funzionano.

#### F2.9 Notifiche configurabili
**Requisiti**
- Tipi, valori di default e limiti: sezione 10.
- Per ogni tipo l'utente sceglie se riceverlo, quanto prima e in quali fasce orarie (es. silenzio dalle 22 alle 8).
- **Limite massimo di notifiche al giorno**, impostabile. Default prudente: poche notifiche, nessun tono insistente.

**CA**
- Disattivando un tipo, quel tipo non arriva più su nessun dispositivo dell'utente (le impostazioni si sincronizzano tramite lo spazio personale, se collegato).
- Tutte le notifiche sono **locali**. Quelle sulle modifiche dei compagni arrivano quando l'app si sincronizza; su mobile, in background, possono arrivare in ritardo per i limiti del sistema operativo.

---

### FASE 3 — Consigli e costi

#### F3.1 Assistente di pianificazione
**Requisiti**
- **Facoltativo:** si avvia con "Aiutami a organizzare".
- **Domande:**
  - quanto approfondire o quanto vedere;
  - ritmo (rilassato / intenso);
  - interessi (arte, natura, cibo, storia, vita notturna…);
  - budget;
  - limiti di mobilità o di cammino;
  - con chi si viaggia;
  - orario di inizio e fine giornata;
  - luoghi famosi o meno turistici.
- **Scelta di struttura** (come nell'esempio Roma–Firenze): approfondire una città, approfondire l'altra, tappe a metà strada, oppure vedere subito i luoghi obbligati e poi altre zone.
- **Proposta:** l'assistente distribuisce giorni e luoghi; l'utente accetta tutto, una parte, o rifiuta.
- **Riempire i buchi:** se tra due tappe c'è tempo libero, propone luoghi raggiungibili e visitabili in quel tempo, che siano aperti a quell'ora.
- **Basato su dati e algoritmi**, non su AI generativa, e calcolato **interamente sul dispositivo**. Fonti dei punteggi:
  - **dati pubblici:** popolarità da Wikidata/Wikipedia, categorie e orari da OSM, luoghi consigliati e itinerari delle guide di **Wikivoyage** (CC BY-SA) per città e regioni;
  - **viaggi passati dell'utente:** valutazioni personali, tipi di luoghi visitati più spesso, ritmo reale (quanto tempo è rimasto davvero nei luoghi rispetto al previsto, ricavato dagli orari di visita);
  - **itinerari importati:** i luoghi presenti negli itinerari che l'utente ha ricevuto e importato (F4.3) ricevono un punteggio più alto;
  - distanza e tempi di percorrenza, orari di apertura, interessi dichiarati.
- **Nessun apprendimento globale:** senza server non si raccolgono i viaggi degli altri utenti (decisione presa). L'assistente migliora per ogni utente man mano che viaggia.

**CA**
- Con 2 ore libere tra due tappe, nessun consiglio richiede più di 2 ore tra andata, visita e arrivo alla tappa successiva.
- Nessun consiglio riguarda un luogo chiuso nell'orario proposto, quando gli orari sono noti.

#### F3.2 Hotel
**Requisiti**
- Hotel e alloggi sulla mappa vicino alle tappe della notte.
- "Cerca su Booking": apre Booking con destinazione, date e numero di persone già compilati, tramite un link semplice (nessuna affiliazione).
- Dopo la prenotazione, la conferma entra con l'import (F2.3) e diventa l'alloggio dei giorni giusti, con il costo nel budget.

**CA**
- Il link apre Booking con le date del viaggio già impostate.

#### F3.3 Pedaggi
**Requisiti**
- **Stima** del pedaggio per tratta, dalle tratte a pedaggio di OSM e dalle tabelle tariffe per paese. Le vignette (es. Austria, Svizzera) si segnalano a parte, con il costo.
- Le tabelle tariffe sono **file nel repository**, mantenuti dalla community tramite GitHub e distribuiti come pacchetto dati (4.6). Ogni tariffa ha la data dell'ultimo aggiornamento.
- **Pedaggio pagato:** dopo una tratta a pedaggio, l'utente può inserire quanto ha pagato. Il valore resta salvato sul suo dispositivo, viene riusato nei viaggi futuri ed è visibile ai compagni del viaggio.
- **"Segnala tariffa":** se l'importo pagato è diverso dalla tabella, l'app prepara una segnalazione già compilata (tratta, classe del veicolo, importo, data) da inviare come issue su GitHub. L'invio è sempre manuale.
- Etichette chiare: "Stima (tabella del [data])" oppure "Pagato da te il [data]".

**CA**
- Una tratta già pagata in un viaggio precedente mostra l'importo pagato al posto della stima.
- La segnalazione si apre precompilata nel browser e non parte mai da sola.

#### F3.4 Percorso panoramico
**Requisiti**
- Profilo "Panoramico" con preferenza **mare / lago / montagna / indifferente**. Il percorso privilegia strade vicine a coste o laghi, o in quota, se esistono nella zona.
- Il calcolo avviene **sul dispositivo** (5.2): l'app richiede più percorsi alternativi e li ordina per vicinanza a coste o laghi, quota e tortuosità. Lo stesso metodo vale per la preferenza "con curve" (F1.5).
- Etichetta: "Percorso panoramico calcolato automaticamente".

**CA**
- Tra due località costiere, con preferenza "mare", il percorso passa vicino alla costa più di quello "più veloce", se esiste una strada costiera.

---

### FASE 4 — Gioco e condivisione

#### F4.1 Badge
**Requisiti**
- Badge per **città**, **regione** e **nazione**, ciascuno con livelli da 1 a 10.
- Ogni badge ha una lista di luoghi generata da Wikidata (rivista a mano per le città principali). I badge di regione e nazione includono anche monumenti importanti dei paesi più piccoli, non solo delle città famose.
- Una visita conta solo se **verificata dal GPS sul posto** (visita verificata).
- Il livello sale con il numero di luoghi della lista visitati. Il livello 10 corrisponde a "tutta la lista".

**CA**
- Segnare una tappa come "visitata" senza GPS sul posto **non** fa salire il badge.
- Una visita conta per tutti i badge che includono quel luogo (città, regione, nazione).

#### F4.2 Punti viaggio, shop e profilo
**Requisiti**
- Punti guadagnati **solo viaggiando** (visite verificate, badge sbloccati). **Non si possono comprare.**
- Shop con **solo oggetti estetici**: sfondi e cornici del profilo, temi, icone, stili della mappa.
- Profilo **locale** con badge, statistiche e storia di viaggio.
- **Scheda profilo condivisibile:** un'immagine o un file da mandare a chi si vuole. L'utente sceglie quali elementi includere. Nessun profilo pubblico online.
- Badge, punti e oggetti si sincronizzano tra i propri dispositivi tramite lo spazio personale, se collegato.

**CA**
- Nessun oggetto dello shop sblocca funzionalità.
- Nessun punto si può ottenere con denaro.

#### F4.3 Itinerari condivisi
**Requisiti**
- "Condividi itinerario": esporta una copia anonimizzata come file `.itinerea`, da mandare a chi si vuole o pubblicare dove si vuole.
- "Importa itinerario": apre un file `.itinerea` e permette di **copiarlo** in un nuovo viaggio, tutto o in parte.
- **Anonimizzazione:** niente nomi, note personali, prenotazioni, allegati, spese individuali o date esatte.
- **Decisione presa:** solo condivisione come file, nessun catalogo pubblico.
- Gli itinerari importati migliorano i consigli **solo per chi li importa** (F3.1).

**CA**
- Un itinerario condiviso non contiene alcun dato dell'elenco "anonimizzazione".

#### F4.4 Valutazioni dei luoghi
- Valutazione personale dei luoghi visitati, salvata in locale. L'assistente (F3.1) la usa per i viaggi futuri dell'utente. Le valutazioni si possono includere negli itinerari condivisi.

#### F4.5 Altre lingue europee
- Traduzione dell'app nelle principali lingue europee, in ordine di priorità da definire (sezione 14).

---

## 7. Schermate e flussi utente

### 7.1 Principi di interfaccia

1. **La schermata del Giorno è il centro dell'app.** Quasi tutto parte da lì e ci torna.
2. **Azioni rapide sempre a portata:** su ogni Giorno un pulsante "+" con 3 scelte immediate: Tappa, Spesa, Prenotazione.
3. **Dettagli in pannelli, non in pagine nuove:** toccando una tappa o una tratta si apre un pannello dal basso (mobile) o laterale (desktop). Si chiude con un gesto senza perdere il punto in cui si era.
4. **Niente login:** l'app si usa subito e non esistono account Itinerea. Lo spazio di sincronizzazione si propone solo quando serve (collaborazione, sync tra dispositivi).
5. **Riferimento visivo:** **Wanderlog** è l'unico punto di partenza per l'estetica (lista + mappa affiancate). Va reso più snello e veloce: meno livelli di menu, niente schermate intermedie inutili.
6. **Libertà di design:** colori, font, icone, componenti, animazioni e organizzazione delle schermate sono **scelti da chi sviluppa** (Claude Code), partendo da Wanderlog. I componenti Material 3 di Flutter sono solo una base tecnica, da personalizzare liberamente. Vincoli: stile moderno e comodo, tema chiaro e scuro, i principi 1.4 e i tocchi della tabella 7.5. Lo stile scelto si documenta in `docs/DESIGN.md`.

> **Nota:** i principi 1–3 qui sopra, la navigazione (7.2), le schermate (7.3) e gli schemi sono una **proposta di partenza**. Si possono unire, dividere o riorganizzare se il risultato è più semplice, purché le funzionalità restino raggiungibili e i flussi principali non richiedano più tocchi. **Vincolanti:** niente login (principio 4), tema chiaro e scuro, numero massimo di tocchi della tabella 7.5.

### 7.2 Struttura della navigazione

**Livello app:**

| Sezione | Contenuto | Fase |
|---|---|---|
| **Viaggi** (home) | Viaggio in corso in evidenza, prossimi viaggi, viaggi passati | 1 |
| **Esplora** | Importa e condividi itinerari (file `.itinerea`) | 4 |
| **Profilo** | Badge, statistiche, shop | 4 (prima: solo impostazioni) |

Su mobile è una barra in basso. Finché le sezioni Esplora e Profilo non esistono, resta solo la home con l'accesso alle impostazioni.

**Dentro un viaggio** (barra in basso su mobile, schede su desktop):

| Scheda | Contenuto |
|---|---|
| **Giorni** | Elenco dei giorni → vista del Giorno |
| **Mappa** | Tutto il viaggio o il giorno selezionato |
| **Budget** | Riepilogo, spese, saldo (F2) |
| **Prenotazioni** | Tutte le prenotazioni e i biglietti, in ordine di data |
| **Altro** | Partecipanti (F2), veicolo (F2), pacchetti offline (F2), esporta PDF, impostazioni del viaggio |

**Layout per schermo:**

```
TELEFONO (una colonna)          DESKTOP / TABLET (affiancati)
┌──────────────────┐            ┌────────┬────────────────┬──────────────────────┐
│ Giorno 3 · Ven 14│            │ Giorni │ Giorno 3       │                      │
│ ☀ 22°  Firenze   │            │  1     │ 09:00 Uffizi   │        MAPPA         │
├──────────────────┤            │  2     │  │ 🚶 12 min    │   (tappe e percorsi  │
│ 09:00 Uffizi  🎫 │            │ ▶3     │ 12:00 Pranzo   │    del giorno)       │
│  │ 🚶 12 min      │            │  4     │  │ 🚶 8 min     │                      │
│ 12:00 Pranzo     │            │        │ 14:00 Duomo    │                      │
│  │ 🚶 8 min       │            │ Budget │                │                      │
│ 14:00 Duomo  +2⇄ │            │ Pren.  │ [pannello      │                      │
│ ...              │            │ Altro  │  dettaglio]    │                      │
│            [ + ] │            └────────┴────────────────┴──────────────────────┘
├──────────────────┤
│Giorni Mappa € 🎫 …│
└──────────────────┘
🎫 = ha un biglietto/prenotazione   +2⇄ = ha 2 alternative   [ + ] = azioni rapide
```

### 7.3 Elenco delle schermate

| Cod. | Schermata | Scopo e contenuto principale | Fase |
|---|---|---|---|
| S01 | **Home – Viaggi** | Card "In viaggio oggi" se un viaggio è in corso (7.4); poi prossimi viaggi e viaggi passati; pulsante "Nuovo viaggio" | 1 |
| S02 | **Nuovo viaggio** | Procedura in 3 passi: 1) Itinerario o Roadtrip; 2) destinazione e date; 3) partenza, ritorno e (facoltativo) volo o treno di andata e ritorno. Alla fine si apre il Giorno 1. | 1 |
| S03 | **Giorno** | Meteo, alloggio della notte, elenco cronologico di tappe e tratte, avvisi (orari, chiusure), pulsante "+" | 1 |
| S04 | **Dettaglio tappa** (pannello) | Info del luogo (orari, contatti, sito), orario e durata, costo, note, allegati, piani A–D, "Segna come visitata", "Naviga fin qui" | 1 |
| S05 | **Dettaglio tratta** (pannello) | Mezzo, durata, distanza, profilo di percorso, percorsi alternativi, "Modifica percorso", "Apri nel navigatore"; costi carburante e pedaggi (F2/F3); soluzioni dei mezzi pubblici (F2) | 1 |
| S06 | **Mappa** | Tappe e percorsi; selettore giorno; livelli (bagni, distributori, colonnine, campeggi, hotel, attrazioni); tocco su un luogo → "Aggiungi al giorno…" | 1 |
| S07 | **Modifica percorso** | Percorso sulla mappa con punti trascinabili, preferenze di percorso, "Salva come alternativa" | 1 |
| S08 | **Budget** | Speso / previsto / rimanente, per categoria e per giorno; elenco spese; in F2 il saldo "chi deve a chi" | 1 |
| S09 | **Nuova spesa** (pannello) | Importo con tastierino grande, valuta, categoria, giorno; in F2: chi ha pagato e divisione; foto scontrino | 1 |
| S10 | **Prenotazioni** | Elenco per data; filtro per tipo; prenotazioni "Da verificare" in evidenza (F2) | 1 |
| S11 | **Biglietto** | Vista a schermo intero, luminosità massima, zoom sul codice | 1 |
| S12 | **Nuova prenotazione / Importa** | Modulo per tipo; in F2 l'anteprima dei dati letti dal file, da confermare | 1 / 2 |
| S13 | **Partecipanti** | Spazio del viaggio e modalità (file o server), invito con link o codice, ruoli, ultimo aggiornamento; chi è online (solo modalità server) | 2 |
| S14 | **Veicolo** | Scelta dal database o inserimento manuale, autonomia, margine di sicurezza, pianificazione soste automatica o manuale | 2 |
| S15 | **Mappe offline** | Pacchetti consigliati per il viaggio, dimensione, scarica, aggiorna, elimina | 2 |
| S16 | **Notifiche** | Per tipo: attiva/disattiva, anticipo, fasce di silenzio, massimo al giorno | 2 |
| S17 | **Assistente** | Domande una per schermata, poi proposta con "Accetta tutto / Scegli / Annulla" | 3 |
| S18 | **Profilo** | Badge e livelli, statistiche, storia di viaggio, punti e shop, "Crea scheda condivisibile" | 4 |
| S19 | **Esplora** | Importa un itinerario da file, anteprima, "Copia nel mio viaggio"; elenco degli itinerari importati | 4 |
| S20 | **Impostazioni** | Lingua, tema, unità, valuta, profilo locale, spazi di sincronizzazione, backup, fornitori dei servizi, fonti dei dati | 1 |
| S21 | **Fonti dei dati** | Attribuzioni obbligatorie (sezione 5.5) | 1 |

### 7.4 Modalità "In viaggio"

Quando un viaggio è in corso, la home (S01) apre la card **"Oggi"** in cima:
- prossima tappa con orario e **"Parti tra X minuti"**;
- pulsante **Naviga** verso la prossima tappa;
- il **biglietto del momento**, per esempio quello del treno di oggi, apribile con un tocco;
- avvisi del giorno (meteo, ritardi rispetto al piano, chiusure).

Così le cose che servono in viaggio sono a **1 tocco** dall'apertura dell'app.

### 7.5 Flussi principali e numero di tocchi

Il conteggio parte dalla schermata del Giorno (S03), salvo dove indicato. La digitazione non conta come tocco.

| Cod. | Flusso | Passaggi | Tocchi |
|---|---|---|---|
| FL1 | **Aggiungere una tappa** | "+" → "Tappa" → scrivo il nome → tocco il risultato. La tappa entra in fondo al giorno con orari calcolati. | 3 |
| FL2 | **Attivare il piano B** | Tocco "+2⇄" sulla tappa → tocco "Piano B" | 2 |
| FL3 | **Registrare una spesa** | "+" → "Spesa" → importo → "Salva" (categoria e giorno precompilati, modificabili) | 3 |
| FL4 | **Aprire il biglietto in viaggio** | Da Home: tocco il biglietto nella card "Oggi" | 1 |
| FL5 | **Navigare verso la prossima tappa** | Da Home: "Naviga" nella card "Oggi" → app di navigazione predefinita | 1 |
| FL6 | **Importare una prenotazione** (F2) | Dall'email: "Condividi" → Itinerea → "Conferma" | 3 |
| FL7 | **Cambiare percorso a una tratta** | Tocco la tratta → "Modifica percorso" → trascino → "Salva" | 3 + trascinamento |
| FL8 | **Da un giorno in poi: Roadtrip** | Menu del giorno "⋯" → "Da qui: Roadtrip" → scelgo auto o moto (dalla Fase 2: il veicolo salvato, F2.5) | 3 |
| FL9 | **Spostare una tappa in un altro giorno** | Tengo premuto sulla tappa → "Sposta a…" → scelgo il giorno (su desktop: trascino sul giorno nella colonna a sinistra) | 2–3 |

### 7.6 Prima apertura

1. Lingua impostata dal sistema (modificabile).
2. Una sola schermata di benvenuto con "Crea il tuo primo viaggio". **Nessuna registrazione obbligatoria.**
3. Si arriva a S02 (Nuovo viaggio).
4. Il **nome** da mostrare ai compagni di viaggio si chiede solo la prima volta che serve (invito o collegamento di uno spazio di sincronizzazione), insieme alla scelta dello spazio.

### 7.7 Stati speciali

| Stato | Comportamento |
|---|---|
| **Offline** | Piccola etichetta "Offline" nella barra in alto. Le funzioni che richiedono rete sono grigie, con il motivo spiegato al tocco, mai nascoste senza spiegazione. |
| **Sincronizzazione** | Icona discreta: sincronizzato / in attesa / errore, con "Aggiornato X fa" in modalità file. In caso di errore, tocco → spiegazione e "Riprova". |
| **Dato stimato o vecchio** | Etichetta testuale accanto al dato (T4), es. "Stima", "Orari salvati il 12/03". |
| **Elenchi vuoti** | Messaggio breve + azione principale, es. "Nessuna tappa. Aggiungi la prima". |
| **Errori dei servizi esterni** | Messaggio chiaro senza codici tecnici, con alternativa: es. "Percorso non calcolabile ora. Inserisci la durata a mano o riprova". |

---

## 8. Modello dati

### 8.1 Convenzioni

| Regola | Dettaglio |
|---|---|
| **ID** | UUID v7 generato sul dispositivo per ogni entità |
| **Campi di sync** | Ogni entità sincronizzata ha `createdAt`, `createdBy` (ID partecipante), `deletedAt` (tombstone) e, per ogni campo, l'HLC dell'ultima modifica (tabella separata dei metadati, non nel modello di dominio) |
| **Denaro** | Tipo `Money` = importo intero in **unità minime** (centesimi, yen…) + codice valuta ISO 4217. Mai numeri decimali in virgola mobile. |
| **Date e orari** | Data/ora **locale** + fuso orario IANA del luogo (es. `2026-03-12T09:30` + `Europe/Dublin`). Indispensabile per i voli tra fusi diversi. Gli istanti assoluti (HLC, `visitedAt`) in UTC. |
| **Coordinate** | WGS84, gradi decimali (`lat`, `lon`) |
| **Durate e distanze** | Minuti interi, metri interi |
| **Orari di apertura** | Stringa nel formato `opening_hours` di OpenStreetMap, interpretata da un parser dedicato |
| **Enumerazioni** | Valori in inglese nel codice (es. `train`), tradotti nell'interfaccia |
| **Versione dello schema** | Ogni database e ogni file di sincronizzazione riporta `schemaVersion` (4.9, migrazioni) |

### 8.2 I tre contenitori di dati

| Contenitore | Contenuto | Dove si sincronizza |
|---|---|---|
| **Dati del viaggio** | Tutto ciò che appartiene a un viaggio (8.3) | Spazio di sincronizzazione del viaggio, condiviso con i partecipanti |
| **Dati personali** | Profilo, veicoli, impostazioni, badge, punti, valutazioni, pedaggi pagati (8.4) | Spazio personale dell'utente (facoltativo), **mai** condiviso con altri |
| **Cache** | Luoghi, mappe, meteo, cambi, pacchetti dati (8.5) | Non si sincronizza: si riscarica quando serve |

### 8.3 Entità del viaggio

**Trip** (Viaggio)
| Campo | Tipo | Note |
|---|---|---|
| `name` | testo | |
| `startDate`, `endDate` | data? | Facoltative: un viaggio può avere solo il numero di giorni (F1.1) |
| `dayCount` | intero | Numero di giorni; i giorni (`Day`) si generano da qui e, se ci sono, dalle date |
| `destinations` | lista di `PlaceSnapshot` | Destinazioni indicate alla creazione (F1.1) |
| `departurePlace`, `returnPlace` | `PlaceSnapshot` | |
| `currency` | ISO 4217 | Valuta principale |
| `budgetMode` | `total` \| `perDay` \| `none` | |
| `budgetTotal` | `Money?` | Se `budgetMode = total` |
| `defaultRouteProfile` | `RouteProfile` | |
| `syncSpace` | riferimento | Tipo di spazio e percorso; `null` se solo locale |
| `encrypted` | booleano | Cifratura end-to-end (4.3) |
| `ownerParticipantId` | ID | |

**Participant** (Partecipante)
| Campo | Tipo | Note |
|---|---|---|
| `profileId` | ID | Profilo locale della persona |
| `displayName` | testo | |
| `role` | `owner` \| `editor` \| `viewer` | In modalità file è un riflesso dei permessi della cartella. In Fase 1 c'è un solo partecipante, l'utente (`owner`). |
| `providerAccount` | testo? | Es. email dell'account Google, solo per gestire la condivisione |
| `color` | colore | Per distinguere le persone nell'interfaccia |

**Segment** (Segmento)
| Campo | Tipo | Note |
|---|---|---|
| `type` | `itinerary` \| `roadtrip` | |
| `startDayIndex` | intero | Primo giorno del segmento; il segmento vale fino all'inizio del successivo |
| `vehicleKind` | `car` \| `motorbike`? | Tipo di veicolo, solo per i Roadtrip (Fase 1) |
| `vehicleSnapshot` | `VehicleSnapshot?` | Fase 2: copia dei dati del veicolo usato (i veicoli sono dati personali, 8.4) |
| `routeProfile` | `RouteProfile?` | Sostituisce quello del viaggio, se presente |
| `stopPlanning` | `auto` \| `manual` | Pianificazione delle soste carburante o ricarica |

**Day** (Giorno)
| Campo | Tipo | Note |
|---|---|---|
| `index` | intero | Posizione nel viaggio (Giorno 1, 2…) |
| `date` | data? | Vuota se il viaggio non ha ancora date |
| `timezone` | fuso IANA | Fuso del giorno (dal luogo principale); gli orari delle tappe sono in questo fuso |
| `mainPlace` | `PlaceSnapshot?` | Luogo principale, usato per meteo e fuso (F1.11). Di default l'alloggio della notte, altrimenti la prima tappa |
| `budget` | `Money?` | Se `budgetMode = perDay` |
| `startTime` | ora? | Orario di inizio della giornata; se vuoto vale quello delle impostazioni (default 9:00) |
| `noteId` | ID? | |

**Slot e Stop** (posizione nel giorno e Tappa)

Le alternative (piani A–D) richiedono di separare la **posizione** nel giorno dalla **tappa**:

- `StopSlot`: `dayId`, `orderKey` (indice frazionario), `activePlan` (`A`–`D`).
- `Stop`: `slotId`, `plan` (`A`–`D`) e i campi della tappa.

Una posizione senza alternative ha una sola tappa con `plan = A`.

| Campo di `Stop` | Tipo | Note |
|---|---|---|
| `kind` | `place` \| `free` \| `refuel` \| `charge` \| `rest` | |
| `place` | `PlaceSnapshot?` | Copia dei dati del luogo al momento dell'aggiunta |
| `name` | testo | |
| `startTime` | ora locale? | Nel fuso del giorno (`Day.timezone`); calcolato se `timeFixed = false` |
| `timeFixed` | booleano | `true` se collegato a una prenotazione o fissato a mano |
| `durationMin` | intero | |
| `estimatedCost` | `Money?` | Solo stima, non entra nel budget (F1.6) |
| `links` | lista di URL | |
| `status` | `planned` \| `visited` \| `skipped` | |
| `visitedAt` | istante? | |
| `verifiedVisitId` | ID? | Visita confermata dal GPS (8.4) |
| `bookingId` | ID? | |
| `noteId` | ID? | |

**LegSlot e Leg** (Tratta)

Stesso principio: `LegSlot` (`dayId`, `fromSlotId`, `toSlotId`, `activePlan`) e `Leg` (`legSlotId`, `plan`).
I `LegSlot` seguono le coppie di posizioni vicine: quando le tappe si riordinano, si crea un `LegSlot` per ogni nuova coppia e quelli non più usati si eliminano (tombstone). Se una coppia torna vicina, si riusa il `LegSlot` esistente con i suoi percorsi salvati.

| Campo di `Leg` | Tipo | Note |
|---|---|---|
| `mode` | `walk` \| `car` \| `motorbike` \| `bike` \| `bus` \| `train` \| `metro` \| `tram` \| `ferry` \| `plane` \| `taxi` \| `other` | |
| `routeProfile` | `RouteProfile?` | Sostituisce quello del segmento |
| `route` | `Route?` | Solo per mezzi su strada o a piedi |
| `transitSolution` | `TransitSolution?` | Soluzione dei mezzi salvata, con `savedAt` |
| `durationMin`, `distanceM` | interi | Calcolati o inseriti a mano |
| `manual` | booleano | Durata inserita a mano |
| `fuelCostEstimate`, `tollEstimate` | `Money?` | |
| `bookingId` | ID? | Es. biglietto del treno |

**Route** (Percorso, oggetto incorporato in `Leg`)
| Campo | Tipo | Note |
|---|---|---|
| `fromStopId`, `toStopId` | ID | Le tappe per cui è stato calcolato. Se nel frattempo cambiano le tappe attive, il percorso si segna "da ricalcolare". |
| `geometry` | polilinea codificata | |
| `waypoints` | lista di coordinate | Punti di passaggio aggiunti trascinando |
| `provider` | testo | Es. `valhalla-fossgis` |
| `profileUsed` | `RouteProfile` | |
| `computedAt` | istante | |
| `editedByUser` | booleano | Se `true` non si ricalcola da solo (F1.5) |

**RouteProfile** (Profilo di percorso, oggetto incorporato)
`preference` (`fastest` \| `curvy` \| `scenic`), `scenicType` (`sea` \| `lake` \| `mountain` \| `any`), `avoidHighways`, `avoidTolls`, `avoidUnpaved`, `avoidFerries` (booleani).

**VehicleSnapshot** (oggetto incorporato in `Segment`, Fase 2): copia dei campi di `Vehicle` (8.4) al momento della scelta, così il viaggio resta corretto anche se l'utente modifica o cancella il veicolo.

**TransitSolution** (oggetto incorporato in `Leg`, Fase 2): elenco dei tratti (mezzo, linea, fermata di partenza e di arrivo, orari), durata totale, fornitore e `savedAt`.

**Booking** (Prenotazione)
| Campo | Tipo | Note |
|---|---|---|
| `type` | `flight` \| `train` \| `bus` \| `ferry` \| `lodging` \| `attraction` \| `carRental` \| `restaurant` \| `other` | |
| `title` | testo | |
| `start`, `end` | data/ora locale + fuso | |
| `fromPlace`, `toPlace` | `PlaceSnapshot?` | Per i trasporti |
| `confirmationCode` | testo? | |
| `provider` | testo? | Es. compagnia aerea |
| `cost` | `Money?` | Entra nel budget |
| `paid` | booleano | |
| `details` | oggetto per tipo | Volo: numero, terminal, posto; hotel: camere, colazione… |
| `source` | `manual` \| `schemaOrg` \| `bcbp` \| `pdfRule` | Come è stata creata |
| `needsReview` | booleano | "Da verificare" (F2.3) |
| `attachmentIds` | lista | |

**Lodging** (Alloggio)
| Campo | Tipo | Note |
|---|---|---|
| `type` | `hotel` \| `camping` \| `camperArea` \| `carNight` \| `other` | |
| `name`, `place` | | |
| `checkIn`, `checkOut` | data/ora locale + fuso | I giorni coperti si calcolano da queste date (F1.9) |
| `bookingId` | ID? | |
| `cost` | `Money?` | Solo se non c'è una prenotazione con costo |

**Attachment** (Allegato)
`sha256`, `mimeType`, `fileName`, `sizeBytes`, `ownerType` + `ownerId` (tappa, tratta, prenotazione, spesa), `isTicket` (mostra in vista biglietto), `barcode` (dati letti dal codice, se presenti). Il file vive in `attachments/<sha256>`.

**Expense** (Spesa)
| Campo | Tipo | Note |
|---|---|---|
| `date` | data | Determina il cambio usato |
| `dayId` | ID? | |
| `amount` | `Money` | Nella valuta originale |
| `fxRate`, `fxDate` | decimale in stringa, data | Cambio verso la valuta del viaggio |
| `fxPending` | booleano | Cambio provvisorio, offline (F1.10) |
| `amountTripCurrency` | `Money` | Calcolato |
| `category` | `lodging` \| `transport` \| `food` \| `activities` \| `fuel` \| `tolls` \| `shopping` \| `other` | |
| `paidBy` | ID partecipante | |
| `split` | `Split` | |
| `bookingId` | ID? | Se generata da una prenotazione |
| `receiptAttachmentId` | ID? | |

**Split** (Divisione, oggetto incorporato)
`type` (`equal` \| `percent` \| `shares` \| `exact`) e `entries` (lista di `participantId` + valore). La somma va validata: 100% per le percentuali, il totale esatto per gli importi.

**Loan** (Prestito): `from`, `to`, `amount`, `date`, `noteId?`.
**Repayment** (Rimborso saldato): `from`, `to`, `amount`, `date`.
Il **saldo** (`Settlement`) non si salva: si calcola ogni volta da spese, prestiti e rimborsi.

**Note** e **NoteVersion** (Nota e versioni)
`Note`: `text`. `NoteVersion`: `noteId`, `text`, `author`, `hlc`. Si crea una versione a ogni salvataggio, con un massimo configurabile (es. ultime 50).

### 8.4 Dati personali

| Entità | Campi principali |
|---|---|
| **Profile** | `displayName`, lingua, tema, unità, valuta predefinita, orario di inizio giornata (default 9:00), durata predefinita delle tappe (default 1 ora) |
| **Vehicle** | `kind` (`car` \| `motorbike`), marca, modello, versione, `fuelType` (`petrol` \| `diesel` \| `lpg` \| `cng` \| `electric` \| `hybrid` \| `plugInHybrid`), consumo (l/100 km o kWh/100 km), serbatoio o batteria, autonomia, `source` (`eea:<id>` \| `manual`), margine di sicurezza (km), classe per i pedaggi |
| **TollRecord** | casello di entrata, casello di uscita, classe del veicolo, importo, data |
| **VerifiedVisit** | ID Wikidata del luogo, istante, coordinate, precisione GPS, `tripId?` |
| **BadgeProgress** | `badgeId` (dal pacchetto dati), luoghi visitati della lista, livello |
| **PointsLedger** | movimenti di punti: importo, motivo (visita, badge, acquisto nello shop), istante. Il saldo si calcola dai movimenti. |
| **OwnedItem** | oggetto estetico posseduto, attivo o no |
| **PlaceRating** | ID del luogo, voto 1–5, nota |
| **NotificationSettings** | per tipo: attivo, anticipo; fasce di silenzio; massimo al giorno (sezione 10) |
| **ProviderSettings** | per servizio: fornitore scelto, URL personalizzato, chiave personale (salvata nel portachiavi sicuro del sistema) |
| **ImportedItinerary** | file `.itinerea` importati, con data |

### 8.5 Cache (non sincronizzata)

| Entità | Contenuto | Durata |
|---|---|---|
| **PlaceCache** | Dati OSM/Wikidata dei luoghi: nome, categoria, coordinate, indirizzo, `opening_hours`, telefono, sito, ID Wikidata, punteggio di popolarità, `fetchedAt` | Aggiornata dopo 30 giorni, se online |
| **PoiPack** | Luoghi di un'area per i livelli della mappa (bagni, distributori…) | Finché l'utente non la elimina o la aggiorna |
| **MapPack** | Tile vettoriali di una regione, in un archivio locale (PMTiles o MBTiles) | Come sopra |
| **FxRate** | Cambio per data e coppia di valute | Per sempre (i cambi storici non cambiano) |
| **WeatherCache** | Previsione per luogo | Secondo le indicazioni del servizio (intestazioni HTTP) |
| **FuelPrices** | Prezzi per distributore, con data | 24 ore |
| **DataPack** | Veicoli, badge, pedaggi, shop | Fino alla versione successiva |

`PlaceSnapshot` (dentro tappe e prenotazioni) è una **copia** dei dati essenziali del luogo (nome, coordinate, indirizzo, ID OSM e Wikidata, `opening_hours`). Così il viaggio resta completo anche senza cache e per i compagni di viaggio.

### 8.6 Formato dei file di sincronizzazione

```
Itinerea/
├── trips/<tripId>/
│   ├── manifest.json              id, schemaVersion, cifratura (sale, parametri), data di creazione
│   ├── ops/<deviceId>/
│   │   └── <seqDa>-<seqA>.jsonl   operazioni, un file per gruppo di modifiche
│   ├── snapshots/
│   │   └── <hlc>.json.zst         istantanea completa compressa
│   └── attachments/<sha256>       allegati
└── personal/<profileId>/          stessa struttura, per i dati personali
```

Con la cifratura attiva, tutti i file tranne `manifest.json` sono cifrati (estensione `.enc`). Anche i nomi dei file non rivelano contenuti: contengono solo ID e impronte.

**Operazione** (una riga di un file `.jsonl`):
```json
{"op":"<uuid>","dev":"<deviceId>","hlc":"<hlc>","v":3,
 "entity":"Stop","id":"<uuid>","set":{"durationMin":90,"status":"visited"}}
```
Tipi di operazione: `create` (tutti i campi), `set` (campi modificati), `delete` (tombstone). Gli allegati non passano nelle operazioni: le operazioni ne riportano solo l'impronta.

---

## 9. Offline e sincronizzazione

### 9.1 Cosa funziona senza internet

| Funzione | Offline | Note |
|---|---|---|
| Consultare e modificare viaggi, tappe, note | ✅ | |
| Orari automatici e avvisi | ✅ | Con i dati salvati |
| Biglietti e allegati | ✅ | Sempre salvati sul dispositivo |
| Spese, divisioni, saldo | ✅ | Cambio provvisorio, corretto al ritorno online |
| Mappa | ✅ con pacchetto scaricato | Senza pacchetto: solo le zone già viste (cache) |
| Livelli (bagni, distributori, campeggi…) | ✅ con pacchetto luoghi | |
| Ricerca luoghi | ⚠️ Parziale | Solo tra i luoghi dei pacchetti scaricati |
| Percorsi già calcolati | ✅ | |
| Nuovi percorsi | ❌ | Si può inserire la durata a mano; il calcolo parte al ritorno online |
| Mezzi pubblici | ⚠️ Solo soluzioni salvate | Con l'avviso "Orari salvati il…" |
| Meteo | ⚠️ Ultima previsione scaricata | Con data |
| Prezzi carburante | ⚠️ Ultimi scaricati | Con data |
| Import prenotazioni | ✅ | Avviene sul dispositivo |
| Visite verificate e badge | ✅ | Il GPS funziona senza rete |
| Apri nel navigatore | Dipende dall'app esterna | |

### 9.2 Cosa si scarica per un viaggio

Alla creazione e quando si avvicina la partenza, l'app propone **"Prepara il viaggio per l'offline"**, con la dimensione totale:
1. pacchetti mappa delle regioni del viaggio;
2. pacchetti luoghi delle stesse aree;
3. tutti gli allegati del viaggio (sempre, già al momento della sincronizzazione);
4. percorsi delle tratte non ancora calcolate;
5. ultime previsioni meteo e prezzi carburante.

Scelte possibili: tutto, solo con Wi-Fi, oppure scelta manuale. In **Impostazioni → Spazio** si vedono i pacchetti scaricati e si possono eliminare.

### 9.3 Ciclo di sincronizzazione (modalità file)

1. **Scrittura locale:** ogni modifica va subito nel database e nel log locale delle operazioni.
2. **Invio:** le operazioni non ancora inviate si raccolgono in un file `.jsonl` (al massimo ogni 5 secondi, oppure subito quando l'app va in background) e si caricano in `ops/<mioDispositivo>/`.
3. **Ricezione:** si elencano le cartelle `ops/` degli altri dispositivi e si scaricano solo i file nuovi, grazie a un indice locale di quelli già letti.
4. **Unione:** le operazioni ricevute si applicano con le regole CRDT (4.3). Il risultato non dipende dall'ordine in cui arrivano.
5. **Allegati:** si scaricano quelli nuovi citati nelle operazioni.
6. **Istantanee:** quando i file di operazioni superano una soglia (es. 500 operazioni), un dispositivo scrive un'istantanea completa. Un dispositivo nuovo parte dall'istantanea più recente e legge solo le operazioni successive. I file di operazioni coperti da un'istantanea si possono cancellare dopo 30 giorni.

**Quando si sincronizza:** all'apertura del viaggio, ogni 30 secondi con l'app in primo piano, con "Aggiorna" e, su Android, periodicamente in background quando il sistema lo permette. Dove il servizio offre un modo per sapere cosa è cambiato senza rileggere tutte le cartelle (Google Drive *changes*, Microsoft Graph *delta*, Dropbox *longpoll*), si usa quello: meno richieste e modifiche che arrivano prima.

### 9.4 Modalità server

Stesso formato delle operazioni (8.6), ma trasportate via WebSocket. Il server conserva operazioni, istantanee e allegati e le inoltra subito agli altri partecipanti collegati. Se la connessione cade, l'app accoda le operazioni e le invia alla riconnessione.

### 9.5 Casi particolari

| Caso | Comportamento |
|---|---|
| Due persone cambiano lo stesso campo | Vince l'HLC più recente. Per le note, l'altra versione resta nella cronologia. |
| Una persona elimina una tappa che un'altra stava modificando | Vince l'eliminazione. Chi modificava vede "Questa tappa è stata eliminata da Marco", con "Ripristina". |
| Tappe spostate da due persone nello stesso giorno | Gli indici frazionari mantengono un ordine coerente. Se due indici coincidono, decide l'ID. |
| Spesa con divisione non più valida (partecipante rimosso) | La spesa resta, segnata "Da rivedere" nel budget |
| Orologio di un dispositivo sbagliato | L'HLC corregge le piccole differenze. Se lo scarto supera 24 ore l'app avvisa l'utente. |
| Spazio pieno o permessi revocati | Messaggio chiaro e sync sospesa. I dati locali restano. |
| Partecipante con app più vecchia | Ignora i campi che non conosce senza cancellarli e mostra "Aggiorna Itinerea" (4.9) |
| Cifratura e codice di recupero perso | Il viaggio resta leggibile sui dispositivi che hanno già la chiave. Senza dispositivi e senza codice non si recupera: avviso esplicito all'attivazione. |

### 9.6 Fusi orari

- Ogni orario si salva con il fuso del luogo (8.1) e si mostra **nell'ora locale del luogo**, con l'indicazione del fuso quando è diverso da quello del dispositivo.
- I voli mostrano partenza e arrivo ciascuno nel proprio fuso (es. "10:05 Roma → 12:20 Dublino").
- Le notifiche si calcolano sull'istante assoluto, così arrivano giuste anche cambiando fuso.

---

## 10. Notifiche

### 10.1 Principi

- **Poche e utili**, mai insistenti o colpevolizzanti: niente "Ci manchi!" o promemoria per usare l'app.
- **Tutte locali**, calcolate sul dispositivo (niente push, 4.2).
- **Ogni tipo si può attivare o disattivare**, con anticipo regolabile.
- **Fasce di silenzio:** default 22:00–08:00, modificabili. Le notifiche legate a una partenza imminente (es. volo) possono superare il silenzio solo se l'utente lo consente per quel tipo.
- **Massimo al giorno:** default 6, modificabile. Superato il limite, le notifiche restanti si raggruppano in una sola.

### 10.2 Tipi di notifica

Le notifiche configurabili arrivano con F2.9. In Fase 1 c'è solo l'avviso di nuova versione per chi installa da GitHub.

| Tipo | Esempio | Default | Anticipo default | Fase |
|---|---|---|---|---|
| **Partenza per la prossima tappa** | "Parti tra 15 min per arrivare agli Uffizi alle 14:00" | Attiva, solo durante il viaggio | 15 min prima dell'orario di partenza calcolato | 2 |
| **Prenotazione imminente** | "Treno Roma → Firenze alle 9:12, binario sul biglietto" | Attiva | 60 min | 2 |
| **Volo** | "Volo FR1234 domani alle 6:40. Check-in online?" | Attiva | 24 h e 3 h | 2 |
| **Check-in / check-out alloggio** | "Check-out entro le 11:00" | Attiva | 60 min | 2 |
| **Rischio ritardo** | "Con gli orari attuali arrivi tardi alla visita delle 15:00" | Attiva | Quando si verifica | 2 |
| **Meteo** | "Domani pioggia sulle Scogliere di Moher: hai un piano B" | Attiva solo se la tappa ha un'alternativa | La sera prima, alle 19:00 | 2 |
| **Preparazione offline** | "Partenza tra 3 giorni: scarica mappe e luoghi" | Attiva | 3 giorni | 2 |
| **Modifiche dei compagni** | "Giulia ha modificato il giorno 3" | Disattivata, oppure riepilogo giornaliero | Alla sincronizzazione | 2 |
| **Saldo da regolare** | "Viaggio finito: vedi chi deve a chi" | Attiva | Il giorno dopo la fine | 2 |
| **Badge e punti** | "Badge Roma salito al livello 3" | Attiva | Subito, senza suono | 4 |
| **Aggiornamento disponibile** (solo versione GitHub) | "Itinerea 1.3 disponibile" | Attiva | Una volta per versione | 1 |

### 10.3 Limiti delle piattaforme

- **Android:** notifiche programmate affidabili. Per gli orari esatti serve il permesso di allarmi esatti (Android 12+). Se l'utente lo nega, le notifiche possono arrivare con qualche minuto di ritardo.
- **macOS:** notifiche programmate supportate.
- **Windows e Linux:** il supporto alle notifiche **programmate** è limitato e va verificato con `flutter_local_notifications` all'avvio dello sviluppo. Se manca, le notifiche funzionano solo con l'app aperta, anche ridotta a icona o nell'area di notifica. Nelle impostazioni l'app dice chiaramente cosa è garantito su quel sistema.
- Le notifiche sulle **modifiche dei compagni** dipendono da quando l'app riesce a sincronizzare: su mobile, in background, possono arrivare in ritardo.

---

## 11. Gamification: badge, punti, shop e profilo

### 11.1 Principi

- **Facoltativa:** si può disattivare tutta in Impostazioni. In quel caso badge, punti e shop spariscono dall'interfaccia, ma le visite verificate restano salvate.
- **Mai d'intralcio:** nessuna animazione che blocca, nessun popup durante le azioni rapide (FL1–FL5).
- **Nessuno schema manipolativo:** niente serie di giorni consecutivi da non perdere, niente scadenze artificiali, niente scatole a sorpresa, niente acquisti.
- **Tutto locale:** non esistono classifiche online. Imbrogliare (es. con posizioni GPS simulate) toglierebbe il divertimento solo a chi lo fa, quindi non servono controlli anti-trucco.

### 11.2 Visita verificata

- Si verifica quando l'utente tocca **"Segna come visitata"** sulla tappa: l'app legge la posizione GPS in quel momento.
- **Valida se:** la posizione è dentro l'area del luogo (dal poligono OSM, se esiste) oppure entro **150 m** dal punto del luogo, con una precisione GPS **migliore di 50 m**.
- **Senza GPS valido:** la tappa si segna comunque come visitata, ma non conta per badge e punti. L'app lo dice: "Visita non verificata: serve la posizione sul posto".
- **Rilevamento automatico** (facoltativo, Fase 4+): durante un viaggio in corso l'app può proporre "Sei agli Uffizi: segnare come visitata?". Solo su Android, solo con permesso di posizione esplicito e disattivabile.
- **Privacy:** si salva solo il risultato (luogo, istante, precisione), mai il percorso o la cronologia delle posizioni.
- **Desktop:** i computer di solito non hanno GPS e la posizione è stimata dalla rete, con precisione insufficiente. Le visite si verificano in pratica da Android.

### 11.3 Badge

**Struttura:**

| Livello geografico | Esempi | Lista di luoghi | Dimensione tipica |
|---|---|---|---|
| **Città** | Roma, Firenze, Dublino | Monumenti e luoghi principali della città | 10–50 luoghi |
| **Regione** | Lazio, Toscana, Baviera | Città principali **e** monumenti importanti dei paesi più piccoli | 20–100 |
| **Nazione** | Italia, Germania | Come sopra, a livello nazionale | 50–300 |
| **Speciali** | "Passi alpini", "1.000 km in moto", "10 paesi europei" | Regole proprie (km percorsi, passi, paesi) | — |

**Livelli da 1 a 10:**
- **Livello 1:** 3 luoghi della lista, oppure il 10% se la lista ha più di 30 luoghi.
- **Livelli 2–9:** soglie distribuite in modo uniforme tra il livello 1 e il 100%: con N luoghi in lista e S₁ la soglia del livello 1, la soglia del livello k è `arrotonda_per_eccesso(S₁ + (N − S₁) × (k − 1) / 9)`. Con liste corte più livelli possono avere la stessa soglia: in quel caso si sale di più livelli insieme.
- **Livello 10:** tutti i luoghi della lista ("Hai visto tutta Roma").
- Una visita conta per **tutti** i badge che includono quel luogo (città, regione, nazione).

**Generazione delle liste** (script in `/data-packs`, pubblicate come pacchetto dati):
1. Query su Wikidata dei luoghi dell'area con riconoscimenti come patrimonio UNESCO o monumento nazionale, più i più noti per numero di voci Wikipedia.
2. Ordinamento per importanza, con quote per evitare che la lista di una regione sia fatta solo dal capoluogo.
3. **Revisione manuale** delle città principali; la community può proporre correzioni tramite issue o pull request.
4. **Aggiornamenti delle liste:** il livello già raggiunto non si perde mai. Se una lista si allunga, il livello si ricalcola ma resta almeno quello precedente.

**Aspetto:** ogni badge ha un'icona e un colore per livello (es. bronzo per i livelli 1–3, argento 4–6, oro 7–9, speciale per il 10). Le grafiche si possono disegnare in un secondo momento: all'inizio basta un set generico per livello.

### 11.4 Punti viaggio

Si guadagnano **solo viaggiando** (decisione presa). Valori iniziali, da bilanciare:

| Azione | Punti |
|---|---|
| Visita verificata | 10 |
| Primo luogo verificato in un paese nuovo | 100 |
| Livello di badge raggiunto | 25 × livello (es. livello 4 = 100) |
| Badge al livello 10 | 500 extra |
| Viaggio completato (almeno una visita verificata) | 50 |

Una visita allo stesso luogo dà punti una sola volta.

### 11.5 Shop

- Contiene **solo oggetti estetici**, comprati con i punti:

| Categoria | Esempi | Prezzo indicativo |
|---|---|---|
| Sfondi del profilo | Paesaggi illustrati, mappe stilizzate | 200–500 |
| Cornici del profilo | Per stile o paese | 150–400 |
| Colori dell'app | Colori di accento alternativi (sopra il tema chiaro o scuro) | 300 |
| Stili della mappa | Varianti di colore della mappa base | 500–800 |
| Icone delle tappe | Set di icone alternativi | 200 |
| Stili dei badge | Modo di mostrare i badge nel profilo | 300 |

- Gli oggetti sono definiti in un **pacchetto dati** e le grafiche sono distribuite con l'app o con il pacchetto, con licenza libera (es. CC BY-SA 4.0). Gli artisti possono contribuire tramite il repository.
- Un oggetto comprato resta per sempre e si sincronizza tra i propri dispositivi.

### 11.6 Profilo

- **Contenuto:** nome, sfondo e cornice, badge con livelli, statistiche (paesi, città, km percorsi, viaggi, luoghi verificati), storia dei viaggi su mappa.
- **Solo locale**, nessun profilo pubblico online.
- **Scheda condivisibile:** l'utente sceglie cosa includere e l'app genera un'immagine (PNG) da condividere dove vuole.

---

## 12. Licenza, contributi e sostenibilità

### 12.1 Licenza

- **Codice:** **GPL-3.0-or-later** (decisione presa, 12/11/2026): permette di usare anche versioni future della GPL. Ogni file sorgente ha l'intestazione SPDX `// SPDX-License-Identifier: GPL-3.0-or-later`.
- **Dipendenze:** ammesse solo licenze compatibili con la GPL-3.0 (es. MIT, BSD, Apache-2.0, LGPL, MPL-2.0). Vietati SDK proprietari. Prima di aggiungere una dipendenza si controlla la licenza (CLAUDE.md).
- **Dati:** i pacchetti dati hanno la licenza delle fonti, indicata in un file `LICENSE-DATA.md`. Esempi: ODbL per i dati derivati da OpenStreetMap, CC BY-SA per Wikivoyage, CC0 per Wikidata.
- **Grafiche e icone originali:** CC BY-SA 4.0.

### 12.2 Contributi

- `CONTRIBUTING.md` con le istruzioni per: codice, traduzioni, tabelle dei pedaggi, regole di lettura delle prenotazioni, liste dei badge, grafiche.
- **Modelli di issue:** bug, nuova funzione, tariffa pedaggio (F3.3), prenotazione non riconosciuta (senza dati personali), traduzione.
- **Firma dei contributi:** DCO (`Signed-off-by` nel commit), senza contratti di cessione dei diritti.
- **Codice di condotta:** Contributor Covenant.
- **Traduzioni:** **Hosted Weblate**, gratuito per i progetti liberi, collegato al repository.
- **CI gratuita:** GitHub Actions (gratuito per i repository pubblici) per test e build di tutte le piattaforme.

### 12.3 Sostenibilità

- Unico canale di sostegno economico: **GitHub Sponsors** (4.11).
- Nessuna funzione, priorità o oggetto in cambio di donazioni.
- Roadmap pubblica tramite GitHub Projects.

---

## 13. Privacy e sicurezza

### 13.1 Dati che lasciano il dispositivo

Il progetto non raccoglie nulla. Alcune funzioni però inviano dati a servizi esterni. L'elenco completo sta nella schermata **"Privacy"** e nella privacy policy (obbligatoria per Google Play):

| Servizio | Cosa riceve | Quando |
|---|---|---|
| Mappa (OpenFreeMap o server dell'utente) | Area della mappa visualizzata (IP, tile richieste) | Mappa online |
| Percorsi (Valhalla) | Coordinate di partenza, arrivo e passaggio | Calcolo di un percorso |
| Ricerca (Photon/Nominatim) | Testo cercato, area | Ricerca |
| Overpass (OSM) | Area richiesta | Download luoghi e livelli |
| Mezzi (Transitous) | Partenza, arrivo, data e ora | Ricerca di una soluzione |
| Meteo (MET Norway) | Coordinate arrotondate | Previsioni |
| Cambi (Frankfurter) | Valute e date | Conversioni |
| Carburante (MIMIT, Tankerkönig) | Area (Tankerkönig); nulla di personale (file MIMIT) | Prezzi |
| Altitudine (Valhalla o Open-Meteo) | Coordinate dei percorsi | Percorso panoramico |
| Wikidata, Wikipedia, Wikivoyage | Luoghi o aree richiesti | Dettagli dei luoghi e consigli |
| Open Charge Map | Area | Colonnine (con chiave personale) |
| Booking.com, app di navigazione | Destinazione, date, tappe | Solo quando l'utente apre il link o il navigatore |
| GitHub | Richiesta di release e pacchetti dati | Aggiornamenti |
| Spazio di sincronizzazione | Dati del viaggio (cifrati, se attivato) | Sincronizzazione |

**Regole:** coordinate arrotondate dove la precisione non serve (es. meteo a ~1 km); nessun identificativo dell'utente nelle richieste; nessun servizio di statistiche, crash reporting o pubblicità.

**Segnalazione errori:** nessun invio automatico. L'app può creare un file di log **senza dati personali** che l'utente allega a mano a una issue.

### 13.2 Permessi richiesti

| Permesso | Perché | Quando si chiede |
|---|---|---|
| Posizione (solo durante l'uso) | Visite verificate, "Parti tra X minuti", mappa | Al primo utilizzo di una di queste funzioni |
| Posizione in background | Rilevamento automatico delle visite (11.2) | Solo se l'utente attiva quella funzione |
| Notifiche | Sezione 10 | Alla prima notifica utile |
| Allarmi esatti (Android 12+) | Notifiche puntuali | Insieme alle notifiche, spiegando perché |
| File / foto | Allegati, scontrini, import | Tramite il selettore di sistema, senza accesso a tutta la galleria |

Mai: contatti, microfono, calendario (in questa versione).

### 13.3 Sicurezza

- **Token di accesso** a Drive, OneDrive, Dropbox e Sync Server, chiavi personali e chiavi di cifratura: salvati nel **portachiavi sicuro del sistema** (`flutter_secure_storage`), mai nel database.
- **Permessi OAuth minimi:** solo la cartella dell'app o i file creati dall'app, dove il servizio lo consente. Quali permessi servono per le cartelle condivise si verifica con il prototipo (4.4).
- **Link di invito:** contengono la chiave del viaggio se la cifratura è attiva. L'app avvisa: "Chi ha questo link può leggere il viaggio". Il proprietario può generare un nuovo link e una nuova chiave, rimuovendo un partecipante.
- **File importati** (`.itinerea`, PDF, email, immagini) trattati come non affidabili: limiti di dimensione, nessuna esecuzione di contenuti, protezione dai percorsi malevoli negli archivi, parser robusti agli errori.
- **Download degli aggiornamenti** (versione GitHub): verifica dell'impronta SHA-256 pubblicata con la release. Su Android la firma dell'APK deve coincidere con quella installata.
- **Itinerea Sync Server:** HTTPS obbligatorio (documentazione con un proxy come Caddy), password con hash robusto, limiti di tentativi, guida all'installazione sicura.
- **Blocco app** (facoltativo, Fase 2 o successive): PIN o impronta per aprire l'app, utile su dispositivi condivisi.

### 13.4 GDPR

Il progetto **non tratta dati personali** degli utenti: non ha server e non riceve nulla. La privacy policy lo dice chiaramente ed elenca i servizi esterni (13.1) con i link alle loro informative. Per Google Play va compilata con attenzione la sezione "Sicurezza dei dati", seguendo le definizioni di Google su cosa conta come dato "raccolto" o "condiviso".

---

## 14. Lingue e localizzazione

### 14.1 Lingue

- **Al lancio:** italiano e inglese, complete.
- **Ordine proposto per le successive** (in base alla diffusione in Europa e alla presenza di Wikivoyage): tedesco, francese, spagnolo, portoghese, olandese, polacco. Poi le altre lingue europee, anche grazie ai volontari su Weblate.
- Una lingua si pubblica quando è tradotta almeno al 90%. Le stringhe mancanti appaiono in inglese.

### 14.2 Regole per le stringhe

- Tutti i testi in file ARB, **mai scritti nel codice**.
- Plurali e generi con il formato ICU (es. "1 tappa" / "3 tappe").
- Mai frasi composte unendo pezzi: ogni frase intera è una stringa con segnaposto.
- Ogni stringa ha una descrizione per i traduttori (dove compare, cosa significa).

### 14.3 Formati

- Date, ore, numeri e valute con le regole della lingua (`intl`).
- Unità di misura impostabili a parte (km/miglia, litri/galloni, °C/°F).
- Primo giorno della settimana secondo la lingua.

### 14.4 Lingua dei dati

- Nomi dei luoghi: `name:<lingua>` di OSM ed etichette Wikidata nella lingua dell'utente, poi il nome locale.
- Descrizioni e guide: Wikivoyage o Wikipedia nella lingua dell'utente, se esiste, altrimenti in inglese con l'indicazione della lingua.

---

## 15. Roadmap e milestone

### 15.1 Metodo

- Sviluppo da solo con Claude Code: le milestone si definiscono per **risultato**, non per data.
- Ogni milestone termina con: criteri di accettazione superati, test automatici verdi in CI, build funzionanti su Android, Windows, macOS e Linux, PRD aggiornato se qualcosa è cambiato.
- **Si procede in ordine.** Le funzioni di una fase successiva non si iniziano prima della fine della fase in corso.
- **Impalcatura (decisione presa, 12/11/2026):** **dopo M1**, usando i risultati dei prototipi, si prepara la struttura di **tutto il progetto**: milestone M2–M7 della Fase 1 **e** funzioni delle Fasi 2–4. Comprende cartelle, modelli senza logica, interfacce astratte, schermate segnaposto, test segnaposto con i CA e lo scheletro di `/sync-server` e `/data-packs`. **Nessuna logica.** Serve a dare a tutto il progetto una forma coerente fin dall'inizio.
- Le schermate segnaposto delle Fasi 2–4 sono raggiungibili **solo nelle build di debug** e dicono chiaramente "Fase X – non ancora disponibile": non devono mai comparire agli utenti nelle versioni pubblicate.

### 15.2 Milestone della Fase 1 (MVP)

| Milestone | Contenuto | Risultato |
|---|---|---|
| **M0 — Fondamenta** | Repository, licenza, CLAUDE.md, struttura cartelle (4.8), progetto Flutter che parte su 4 piattaforme, CI con test e build, localizzazione it/en, tema chiaro e scuro | Schermata vuota con tema e lingua su tutte le piattaforme. **Completata il 13/11/2026** (PR n. 1): verificata in locale su Android e Windows e in CI su Android, Linux, Windows, macOS e iOS senza firma |
| **M1 — Prototipi di rischio** | Prove isolate dei punti incerti (16.1): mappa vettoriale OpenFreeMap con `vector_map_tiles` su Linux e Windows; download regionale dal PMTiles di OpenFreeMap e lettura offline; percorsi Valhalla con opzioni e alternative; altitudine; sync in modalità file su Google Drive tra 2 dispositivi (con registrazione del client OAuth); notifiche programmate su desktop | Per ogni prova: funziona / funziona con limiti / non funziona, e PRD aggiornato. **In corso**: esiti in 16.3 |
| **M2 — Nucleo dei dati** | Modello dati (8), database drift, log delle operazioni e regole CRDT con test | Test che simulano modifiche concorrenti e offline |
| **M3 — Viaggio, giorni e tappe** | F1.1, F1.2, F1.3, F1.6 (tappe), schermate S01–S04 | Si pianifica un viaggio senza mappa |
| **M4 — Mappa e percorsi** | F1.4, F1.5, F1.6 (tratte), F1.7, F1.12, S05–S07 | Si pianifica un roadtrip con percorsi e alternative |
| **M5 — Prenotazioni, biglietti, budget, meteo** | F1.8, F1.9, F1.10, F1.11, S08–S12 | Un viaggio completo da usare davvero |
| **M6 — Sync personale, backup, PDF, impostazioni** | F1.13, F1.14, F1.15, S20–S21 | **v0.1 beta** su GitHub Releases |
| **M7 — Rilascio 1.0** | Correzioni dalla beta, accessibilità, prestazioni (T2), privacy policy, schede degli store, test chiuso Google Play (12 tester per 14 giorni), F-Droid e Flathub | **v1.0** |

### 15.3 Fasi successive

Le milestone delle Fasi 2–4 si definiscono alla fine della Fase 1, con lo stesso metodo (risultati e CA), e si aggiungono a `docs/ROADMAP.md`.

| Fase | Versione | Contenuto principale |
|---|---|---|
| 2 — Gruppo e strada | 2.x | Collaborazione e Sync Server, spese di gruppo, cifratura, import prenotazioni, mezzi pubblici, veicolo, carburante e soste, campeggi e bagni, mappe e luoghi offline, notifiche |
| 3 — Consigli e costi | 3.x | Assistente, hotel, pedaggi, percorso panoramico |
| 4 — Gioco e condivisione | 4.x | Badge, punti, shop, profilo, itinerari condivisi, valutazioni, altre lingue |

### 15.4 Strategia di test

| Livello | Cosa si testa | Esempi |
|---|---|---|
| Unità | Logica pura | Regole CRDT, ricalcolo orari (F1.3), saldo con pochi pagamenti e arrotondamenti (F2.2), conversioni di valuta, soglie dei badge, parser `opening_hours` e BCBP |
| Widget | Schermate e componenti | Numero di tocchi dei flussi FL1–FL9, tema chiaro e scuro, testi lunghi in tedesco |
| Integrazione | Flussi completi | Viaggio creato offline e sincronizzato; due dispositivi simulati con modifiche concorrenti |
| Manuale | Prima di ogni rilascio | Lista di controllo per piattaforma, con particolare attenzione a mappa, notifiche, file |

---

## 16. Rischi e domande aperte

### 16.1 Rischi tecnici

| # | Rischio | Impatto | Mitigazione |
|---|---|---|---|
| R1 | Google Drive: l'accesso alle cartelle condivise con il permesso ristretto potrebbe essere scomodo per chi riceve l'invito | Alto (collaborazione) | Prototipo in M1. Piani B: selettore di file di Google per l'invitato, oppure consigliare Dropbox, WebDAV o Sync Server per i gruppi |
| R2 | Valhalla di FOSSGIS: condizioni d'uso o limiti incompatibili con l'uso da parte di un'app | Alto (percorsi) | Rileggere le condizioni prima del rilascio, cache aggressiva, fornitore configurabile (4.6), documentare come installare un proprio server. **Condizioni lette il 13/11/2026 (5.6): l'uso da parte di un'app non commerciale è compatibile**, con obblighi precisi: una richiesta al secondo, User-Agent dell'app, `X-Client-Id`, avviso su GitHub Discussions di Valhalla, email di contatto pubblica, attribuzione con link a "fixthemap". Il permesso può essere revocato in qualsiasi momento e dietro al servizio c'è un solo server: il rischio resta alto se l'app diventa popolare (R9) |
| R3 | Download regionale delle tile più complesso del previsto (il pacchetto `pmtiles` legge ma non scrive archivi) | Medio (mappe offline) | Prototipo in M1; salvare le tile in un archivio locale semplice (es. MBTiles/SQLite). Piano B: cache delle tile visitate o import di file preparati. **Provato in M1: funziona con limiti** (16.3). Scrivere un archivio MBTiles locale è semplice (pacchetto `mbtiles`); il limite vero sono le condizioni d'uso (50 MB per download) e la lettura di PMTiles nell'app |
| R4 | Verifica obbligatoria degli sviluppatori Android e futuro di F-Droid | Medio (distribuzione) | Registrare i nomi di pacchetto con l'account Google Play; seguire gli sviluppi di F-Droid |
| R5 | Notifiche programmate limitate su Windows e Linux | Basso | Verifica in M1; comportamento con app aperta o in area di notifica |
| R6 | Dati OSM incompleti (orari di apertura, colonnine) | Medio | Etichette di onestà (T4), campi sempre modificabili, invito a contribuire a OSM |
| R7 | Qualità del percorso panoramico calcolato sul dispositivo | Medio | Etichetta "il meglio possibile", modifica manuale sempre disponibile |
| R8 | Estrarre consigli dal testo di Wikivoyage | Medio | Partire dai dati strutturati (Wikidata, OSM) e aggiungere Wikivoyage solo dove la struttura delle pagine lo permette |
| R9 | Servizi pubblici sovraccarichi se l'app diventa popolare | Medio | Regole 5.4, fornitori configurabili, guide al self-hosting |
| R10 | Registrazione delle app OAuth presso Google, Microsoft e Dropbox (verifiche, schermate di consenso) | Medio | Avviare le registrazioni in M1, usare permessi non sensibili |
| R11 | Progetto molto grande per una persona sola | Alto | Ordine rigoroso delle fasi, MVP piccolo, CLAUDE.md che vieta di anticipare le fasi |
| R12 | Google Play: trovare 12 tester per 14 giorni | Basso | Cercarli durante la beta (M6) |
| R13 | Nome "Itinerea" troppo simile a marchi esistenti, in particolare "Itinera" (app di viaggio, marchio registrato negli USA per servizi di viaggio) | Medio | Controllo su TMview (UE e Italia) prima della 1.0; l'app è distribuita in Europa e non negli store Apple |
| R14 | `vector_map_tiles`: ultima versione stabile dell'agosto 2024, sviluppo attuale solo in beta | Medio (mappa) | **Provato in M1: funziona con limiti** (16.3). Si usa la 9.0.0-beta.13 in modalità `raster`, con versione fissata. Resta il rischio di dipendere da una beta mantenuta da una sola persona; piano B: pacchetto `maplibre` o tile raster per la mappa online |
| R15 | Schemi di tile diversi tra mappa online e offline | Medio | Usare OpenFreeMap sia online sia offline (stesso schema OpenMapTiles e stesso stile). **Verificato in M1** (16.3): con le tile di OpenFreeMap salvate in locale e lo stile `liberty` salvato in locale la mappa offline è identica a quella online. Offline manca solo il rilievo ombreggiato (livello raster visibile sotto lo zoom 7) |
| R16 | Identificativo dell'app Android (`applicationId`) non modificabile dopo la pubblicazione su Google Play e F-Droid | Medio | Deciso: `io.github.notenjoyingthis.itinerea` (12/11/2026). Non va più cambiato. |

### 16.2 Domande aperte

| # | Domanda | Serve entro |
|---|---|---|
| D1 | ~~Licenza GPL-3.0 "or-later" oppure "only"~~ — **Deciso:** GPL-3.0-or-later (12/11/2026) | — |
| D2 | Approvare lo stile proposto da Claude Code in `docs/DESIGN.md` (partendo da Wanderlog) | M3 |
| D3 | Conferma dei default delle notifiche (10.2) | Fase 2 |
| D4 | Valori di punti, prezzi dello shop e soglie dei badge (11.3–11.5) | Fase 4 |
| D5 | Ordine delle lingue dopo italiano e inglese (14.1) | Fase 4 |
| D6 | ~~Nome definitivo e identificativo dell'app~~ — **Deciso:** Itinerea, `io.github.notenjoyingthis.itinerea` (12/11/2026) | — |

### 16.3 Esiti dei prototipi di M1

I prototipi stanno in `app/prototypes/` e non fanno parte dell'app. Le misure sono state prese con esecuzioni automatiche (10 secondi di spostamento e 8 di zoom su Firenze) in build release o profile.

**Prova 1 — Mappa vettoriale OpenFreeMap (R14) — 13/11/2026 — funziona con limiti**

Pacchetti: `flutter_map` 8.3.2, `vector_map_tiles` 9.0.0-beta.13, `vector_tile_renderer` 6.1.0. Stili `liberty` (chiaro) e `dark` di OpenFreeMap.

| Misura | Windows (PC di sviluppo) | Android (emulatore x86_64) | Linux (runner CI, senza scheda grafica) |
|---|---|---|---|
| Compila e parte | sì | sì | sì |
| Stile corretto (strade, etichette, icone, chiaro e scuro) | sì | sì | sì |
| Tracciato e segnaposto sopra la mappa | sì | sì | sì |
| Caricamento dello stile | 0,35–0,5 s | 0,5–0,7 s | 0,2–0,6 s |
| Modalità `raster`: spostamento | 53–55 fps | 38 fps | 23 fps |
| Modalità `raster`: zoom continuo | 58–61 fps | 39 fps | 32 fps |
| Modalità `vector`: spostamento | **2 fps** | non misurata | **1 fps** |
| Modalità `vector`: zoom continuo | 19–20 fps | non misurata | 18 fps |
| Memoria del processo, `raster` (inizio → fine) | 165 → 220 MB | 277 → 283 MB | 627 → 1.018 MB |
| Memoria del processo, `vector` (inizio → fine) | 457 → 535 MB | non misurata | 907 → 1.901 MB |

Limiti trovati:
- **La modalità `vector` non è utilizzabile** (1–2 fps in spostamento). Si usa la modalità `raster`: i dati restano vettoriali, il disegno avviene in immagini per tile.
- In modalità `raster`, dopo uno spostamento o al primo avvio le tile compaiono prima sfocate (ingrandite dallo zoom precedente) e poi nitide; sull'emulatore Android sono servite parecchi secondi.
- Gli stili di OpenFreeMap non hanno il campo `id`: il pacchetto li chiama tutti `default` e ne mescola le cache. Ogni stile deve ricevere un identificativo proprio, assegnato **insieme** ai suoi livelli.
- Durante lo spostamento il pacchetto annulla i caricamenti superati con eccezioni non gestite ("Cancelled") nel log: da intercettare nell'app.
- I numeri di Linux vengono da un runner senza scheda grafica (disegno via software) e quelli di Android da un emulatore: **mancano misure su un telefono reale e su un PC Linux reale**. Il consumo di memoria su Linux va ricontrollato lì.
- Dipendenza da una versione beta: va fissata la versione esatta e riprovata a ogni aggiornamento.

Proposta: tenere `flutter_map` + `vector_map_tiles` 9 beta in modalità `raster` per M4; riprovare su un telefono Android reale all'inizio di M4, con il requisito T2 in mente; tenere `maplibre` come piano B.

**Prova 2 — Mappa offline di una piccola regione (R3, R15) — 13/11/2026 — funziona con limiti; strada da decidere**

Zona di prova: Firenze e dintorni, rettangolo di circa 48 × 39 km (1.879 km²), zoom 0–14. La mappa si disegna con le stesse librerie della prova 1, da un file **MBTiles** locale e dallo stile `liberty` salvato in locale.

*Strada A — tile dal server di OpenFreeMap entro i limiti delle condizioni d'uso (5.6):*

| Misura | Windows | Android (emulatore) | Linux (runner CI) |
|---|---|---|---|
| Tile scaricate | 891 su 891, nessun errore | 891 su 891 | 891 su 891 |
| Dati trasferiti (compressi) | 25,25 MB | 25,25 MB | 25,25 MB |
| File MBTiles su disco | 26,1 MB | 26,1 MB | 26,1 MB |
| Stile e icone | 57 KB | 57 KB | 57 KB |
| Tempo (4 richieste parallele) | 15 s | 18 s | 42 s |
| Mappa disegnata con la rete bloccata | sì, 0 tentativi di rete | sì (tentativi di rete non letti) | sì, 0 tentativi di rete |
| Stesso aspetto della mappa online (R15) | sì | sì | sì |

Peso per zoom: gli zoom 0–9 valgono circa 3,8 MB **fissi** (10 tile che coprono zone enormi, da scaricare una volta sola); gli zoom 10–14 valgono 21,6 MB, di cui 14,9 MB il solo zoom 14 (644 tile, 23 KB in media). In città si arriva quindi a circa 11,5 KB per km²; la media su tutta la Toscana (strada C) è di circa 4,7 KB per km².

Conseguenza dei limiti (3.000 tile **o** 50 MB): un download copre circa **4.000 km² in zona urbana e fino a circa 7.000 km² in zona poco abitata** (qui il limite diventa quello delle 3.000 tile). È una provincia, non una regione: per il rettangolo della Toscana (23.161 tile) servirebbero circa 8 download, per quello dell'Italia (511.862 tile) più di 170.

*Strada B — richieste parziali HTTP sul planet PMTiles (87 GB), solo misura (16 richieste):* funzionano. Apertura dell'archivio in 0,35 s con 1 richiesta; ogni tile richiede 1–2 richieste e 0,3–1,2 s (mediana per richiesta 0,33 s). Tile per tile è molto più lenta della strada A. Lo strumento `pmtiles extract` però raggruppa le richieste: per tutta la Toscana gliene bastano 98 (vedi strada C).

*Strada C — estratti regionali preparati in una GitHub Action con `pmtiles extract` e pubblicati su GitHub Releases, solo misura (`--dry-run`, nessun dato scaricato):*

| Rettangolo | Tile | Dimensione dell'estratto | Richieste al planet |
|---|---|---|---|
| Firenze e dintorni (come sopra) | 891 | 26 MB | 42 |
| Toscana (9,69–12,37 E; 42,24–44,47 N, mare compreso) | 23.161 | 253 MB | 98 |
| Italia intera | 511.862 | 3,0 GB | 168 |

Un estratto regionale sta largamente sotto i 2 GiB per file di GitHub Releases; l'Italia intera no, quindi i pacchetti vanno fatti **per regione**. I rettangoli includono mare e territori vicini: con i confini veri (opzione `--region` con un file GeoJSON) i pacchetti sarebbero più piccoli.

Limiti e punti aperti:
- **PMTiles nell'app oggi non si installa.** `vector_map_tiles_pmtiles` 1.5.2 richiede `pmtiles` ^1.3.0, che richiede `latlong2` ^0.9, mentre `vector_map_tiles` 9.0.0-beta.13 richiede `latlong2` ^0.10.1; `pmtiles` 2.2.0 richiede `protobuf` ^6, incompatibile con `vector_tile_renderer` 6.1.0. `mbtiles` 0.5.1 e `vector_map_tiles_mbtiles` 1.2.2 invece si installano e funzionano. Il PRD e CLAUDE.md §3 indicano PMTiles: **cambiare formato è una decisione dell'utente**.
- **Condizioni d'uso.** La strada A è esplicitamente ammessa. Le strade B e C non sono né ammesse né vietate dal testo (5.6): prima di automatizzarle conviene chiedere a OpenFreeMap. Lo strumento `pmtiles` non permette di impostare lo User-Agent del progetto.
- **Fuori dalla zona scaricata** la mappa resta vuota (nessun errore, nessuna richiesta di rete).
- Offline manca il rilievo ombreggiato dello stile (livello raster online, visibile solo sotto lo zoom 7).
- Strada C: GitHub non mette limiti di banda alle release, ma può intervenire su usi "significativamente eccessivi" (5.6); i pacchetti vanno rigenerati quando cambia il planet (settimanale) e aggiunti a `LICENSE-DATA.md` (ODbL + attribuzione OpenMapTiles).

Proposte, da decidere:
1. **Formato locale:** MBTiles (funziona oggi, ma cambia lo stack scritto nel PRD) oppure PMTiles (richiede un lettore scritto da noi o l'attesa di un aggiornamento dei pacchetti).
2. **Come si ottengono le tile:** strada A per le zone piccole (ammessa, subito disponibile), più eventualmente strada C per regioni intere, dopo aver chiesto a OpenFreeMap.

**Prova 3 — Percorsi Valhalla e altitudine (R2) — 13/11/2026 — funziona con limiti**

Istanza `https://valhalla1.openstreetmap.de` (Valhalla 3.9.1), 37 richieste in tutto, una alla volta con 1,5 s di pausa, con User-Agent del progetto e `X-Client-Id`. Tutte hanno risposto 200; nessun limite di frequenza incontrato.

| Tratta e opzioni | km | Durata | km a pedaggio | km in autostrada | km in traghetto | Tempo di risposta |
|---|---|---|---|---|---|---|
| Firenze → Siena, auto, più veloce | 79,8 | 1 h 11 | 6,1 | 60,2 | 0 | 0,49 s |
| idem, `use_highways: 0` | 73,0 | 1 h 58 | 0 | 0 | 0 | 0,21 s |
| idem, `use_tolls: 0` | 78,7 | 1 h 14 | 0 | 55,0 | 0 | 0,16 s |
| idem, passando da Greve in Chianti | 89,8 | 2 h 00 | 0 | 34,2 | 0 | 0,20 s |
| Genova → Olbia, auto, più veloce | 536,2 | 12 h 07 | 0 | 0 | 404,3 | 0,38 s |
| idem, `use_ferry: 0` | 860,6 | 14 h 50 | 398,7 | 398,3 | **320,1** | 1,81 s |
| Como → Lucerna, auto, più veloce | 201,5 | 2 h 55 | 189,2 | 189,2 | 0 | 0,30 s |
| idem, `use_tolls: 0` | 238,6 | 6 h 13 | 13,8 | 12,7 | 0 | 0,33 s |
| idem, `use_highways: 0` | 238,6 | 6 h 08 | 18,8 | 17,7 | 0 | 0,35 s |
| Como → Lucerna, moto, `use_tolls: 0` | 234,7 | 5 h 34 | 42,1 | 39,6 | 0 | 0,31 s |
| Aosta → Bari, auto, più veloce | 1.070,7 | 10 h 34 | 1.023,9 | 1.052,0 | 0 | 0,38 s |
| idem, `use_tolls: 0` | 1.302,5 | 20 h 45 | 0 | 85,4 | 0 | 0,55 s |
| idem, `alternates: 2` | 1.070,7 + alternative da 1.164,5 e 1.173,1 | — | — | — | — | 0,54 s |

Risposte alle domande della prova:
- **Tratta lunga:** 1.071 km calcolati in 0,4 s, risposta di 67 KB (295 KB senza pedaggi, per le molte più manovre). Nessun limite di distanza incontrato.
- **Vignette (Svizzera):** le autostrade svizzere risultano "a pedaggio" (189,2 km su 201,5), quindi `use_tolls: 0` evita anche le strade con vignetta; ne restano 13,8 km. La risposta **non distingue** vignetta e casello: per F3.3 servono dati propri per paese.
- **`use_ferry: 0` senza alternativa via terra:** nessun errore; Valhalla restituisce comunque un percorso con traghetto (320 km di mare, 860 km in tutto). Le opzioni "evita" sono **preferenze, non divieti**: l'app deve controllare il risultato e avvisare ("il percorso include comunque un traghetto").
- **`alternates`:** 2 alternative su 2 per Aosta–Bari; **nessuna** per Firenze–Siena e Como–Lucerna; **nessuna** quando c'è un punto di passaggio intermedio.
- **Lingua e unità:** con `language: it-IT` e `units: kilometers` le istruzioni arrivano in italiano corretto ("Guida verso est su Via Ghibellina.", "Svolta a destra su Viale della Giovine Italia.").
- **Moto:** in tutte le prove il profilo `motorcycle` ha dato lo stesso percorso e la stessa durata di `auto`, tranne Como–Lucerna senza pedaggi. `exclude_unpaved` e `use_trails` **non hanno avuto alcun effetto osservabile** in nessuna prova, comprese 7 richieste sul Colle delle Finestre (passo sterrato): di default Valhalla gira già al largo del passo (67,6 km invece di 36), e con un punto di passaggio sul passo lo percorre anche con `exclude_unpaved`. Il loro effetto resta **non dimostrato**. Le manovre su sterrato sono però riconoscibili nella risposta (campo `rough`), quindi l'app può segnalarle.
- **Altitudine:** `/height` è attivo (97 punti in 0,08 s; l'intero tracciato Firenze–Siena, 1.932 punti, in 0,13 s e 15 KB). Open-Meteo Elevation: 97 punti in 0,25 s, massimo 100 per richiesta. I due modelli danno quote leggermente diverse nello stesso punto (76 m e 64 m al primo punto).

Proposta:
- Percorsi su Valhalla FOSSGIS con le opzioni del `RouteProfile` così come sono; dopo ogni calcolo l'app ricava dalle manovre i km di pedaggio, autostrada, traghetto e sterrato e **avvisa se un "evita" non è stato rispettato** (CA di F1.5).
- Una richiesta alla volta e al massimo una al secondo per dispositivo; durante il trascinamento di un percorso (F1.5) si calcola solo al rilascio; cache dei percorsi calcolati.
- Altitudine da `/height` di Valhalla, con Open-Meteo come piano B.
- Per "con curve" e "panoramico" non si può contare su `alternates`: i candidati si ottengono con richieste diverse (opzioni o punti di passaggio), in sequenza.
- Prima del rilascio: avviso su GitHub Discussions di Valhalla ed email di contatto pubblica (5.6).

---

*Fine del documento.*

