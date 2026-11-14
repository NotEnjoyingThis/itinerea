# Itinerea — Avanzamento

> Questo documento dice **a che punto siamo**. Che cosa va costruito e perché sta in [`PRD.md`](PRD.md); le decisioni prese e i punti aperti stanno in [`DECISIONS.md`](DECISIONS.md).
> Si aggiorna alla fine di ogni milestone. Ultimo aggiornamento: **14/11/2026**.

## Dove siamo

**M0, M1 e M2 sono concluse. È in corso M3 (viaggio, giorni e tappe):** la prima milestone con schermate vere.

Tra M1 e M2 è stata preparata l'**impalcatura** di tutto il progetto (PRD 15.1): cartelle, modelli senza logica, interfacce, schermate segnaposto e test segnaposto. L'impalcatura **non è funzionalità**: ogni elemento porta un commento `TODO` con la milestone o la fase in cui diventa vero.

## Come leggere gli stati

| Stato | Significato |
|---|---|
| **Conclusa** | Criteri di accettazione superati, test verdi in CI, build su tutte le piattaforme, PRD aggiornato |
| **In corso** | È la milestone su cui si lavora adesso |
| **Da fare** | Non iniziata; può esistere solo l'impalcatura |

Si procede in ordine: le funzioni di una milestone successiva non si iniziano prima della fine di quella in corso (PRD 15.1).

## Fase 1 — MVP

| Milestone | Stato | Funzionalità | Schermate | Risultato atteso |
|---|---|---|---|---|
| **M0 — Fondamenta** | **Conclusa** il 13/11/2026 | Progetto Flutter, CI, localizzazione it/en, tema chiaro e scuro | segnaposto iniziale | App vuota che parte su tutte le piattaforme |
| **M1 — Prototipi di rischio** | **Conclusa** il 14/11/2026 | Cinque prove isolate (esiti in PRD 16.3) | — | Per ogni rischio: funziona, funziona con limiti o non funziona |
| **M2 — Nucleo dei dati** | **Conclusa** il 14/11/2026 | Modello dati (PRD 8), database drift, log delle operazioni, regole CRDT | — | Test che simulano modifiche concorrenti e offline |
| **M3 — Viaggio, giorni e tappe** | **In corso** | F1.1, F1.2, F1.3, F1.6 (tappe) | S01–S04 | Si pianifica un viaggio senza mappa |
| **M4 — Mappa e percorsi** | Da fare | F1.4, F1.5, F1.6 (tratte), F1.7, F1.12 | S05–S07 | Si pianifica un roadtrip con percorsi e alternative |
| **M5 — Prenotazioni, biglietti, budget, meteo** | Da fare | F1.8, F1.9, F1.10, F1.11 | S08–S12 | Un viaggio completo da usare davvero |
| **M6 — Sync personale, backup, PDF, impostazioni** | Da fare | F1.13, F1.14, F1.15 | S20, S21 | **v0.1 beta** su GitHub Releases |
| **M7 — Rilascio 1.0** | Da fare | Correzioni dalla beta, accessibilità, prestazioni, privacy policy, schede degli store | — | **v1.0** |

### Esiti di M1 in breve

| Prova | Esito | Conseguenza per le milestone |
|---|---|---|
| 1 — Mappa vettoriale OpenFreeMap | Funziona con limiti | M4 usa `vector_map_tiles` 9 beta in modalità `raster`; da riprovare su un telefono reale all'inizio di M4 |
| 2 — Mappa offline | Funziona con limiti | Formato locale e download per regioni rimandati alla Fase 2 (F2.8) |
| 3 — Percorsi Valhalla e altitudine | Funziona con limiti | M4 controlla il risultato di ogni "evita" e avvisa se non è rispettato |
| 4 — Google Drive tra due account | Limiti pesanti | Google Drive solo per sync personale e backup, solo su desktop (M6); per i gruppi altri spazi (Fase 2) |
| 5 — Notifiche su Windows e Linux | Funziona con limiti | Windows vuole una voce nel menu Start; Linux notifica solo con l'app aperta |

### Funzionalità della Fase 1

| Codice | Funzionalità | Milestone |
|---|---|---|
| F1.1 | Creazione del viaggio | M3 |
| F1.2 | Giorni e tappe | M3 |
| F1.3 | Orari automatici e avvisi | M3 |
| F1.4 | Tratte e mezzi | M4 |
| F1.5 | Percorsi con preferenze | M4 |
| F1.6 | Alternative (piani A, B, C, D) | M3 (tappe), M4 (tratte) |
| F1.7 | Mappa | M4 |
| F1.8 | Biglietti e allegati | M5 |
| F1.9 | Prenotazioni (inserimento manuale) | M5 |
| F1.10 | Budget e spese (personali) | M5 |
| F1.11 | Meteo | M5 |
| F1.12 | Apri nel navigatore | M4 |
| F1.13 | Spazio di sincronizzazione personale e backup | M6 |
| F1.14 | Esporta in PDF | M6 |
| F1.15 | Impostazioni di base | M6 |

## Fasi successive

Le milestone delle Fasi 2–4 si definiscono alla fine della Fase 1 (PRD 15.3) e si aggiungono qui. Fino ad allora esiste solo l'impalcatura, e le loro schermate segnaposto si vedono **solo nelle build di debug**.

### Fase 2 — Gruppo e strada (versione 2.x)

| Codice | Funzionalità | Schermate | Stato |
|---|---|---|---|
| F2.1 | Collaborazione (e Itinerea Sync Server) | S13 | Da fare |
| F2.2 | Spese di gruppo | S08, S09 | Da fare |
| F2.3 | Import automatico delle prenotazioni | S12 | Da fare |
| F2.4 | Mezzi pubblici | S05 | Da fare |
| F2.5 | Veicolo | S14 | Da fare |
| F2.6 | Carburante, ricarica e soste | S05, S06 | Da fare |
| F2.7 | Bagni, campeggi e notti in auto | S06 | Da fare |
| F2.8 | Mappe e luoghi offline | S15 | Da fare |
| F2.9 | Notifiche configurabili | S16 | Da fare |

### Fase 3 — Consigli e costi (versione 3.x)

| Codice | Funzionalità | Schermate | Stato |
|---|---|---|---|
| F3.1 | Assistente di pianificazione | S17 | Da fare |
| F3.2 | Hotel | S06 | Da fare |
| F3.3 | Pedaggi | S05 | Da fare |
| F3.4 | Percorso panoramico | S05, S07 | Da fare |

### Fase 4 — Gioco e condivisione (versione 4.x)

| Codice | Funzionalità | Schermate | Stato |
|---|---|---|---|
| F4.1 | Badge | S18 | Da fare |
| F4.2 | Punti viaggio, shop e profilo | S18 | Da fare |
| F4.3 | Itinerari condivisi | S19 | Da fare |
| F4.4 | Valutazioni dei luoghi | S04 | Da fare |
| F4.5 | Altre lingue europee | — | Da fare |

## Cose da sistemare prima di certe milestone

L'elenco completo, con il motivo di ognuna, è nei **punti aperti** di [`DECISIONS.md`](DECISIONS.md). Qui solo le scadenze.

| Entro | Che cosa |
|---|---|
| Prime issue | Creare nel repository le etichette usate dai modelli di issue |
| M3 | Includere nell'app i caratteri Inter e Manrope e applicare lo stile approvato |
| Inizio di M4 | Misurare la mappa su un telefono Android reale e su un PC Linux con scheda grafica; allineare `CLAUDE.md` al nome `ServiceProvider` |
| M4 (F1.5) | Trovare un caso reale per "evita sterrato", oppure presentarlo come "segnala lo sterrato" |
| Milestone che introduce le notifiche | Scrivere in CONTRIBUTING il requisito C++ ATL per compilare su Windows; risolvere il clic sulla notifica |
| M6 (F1.13) | Provare Google Drive tra due dispositivi dello stesso account; registrare il client OAuth definitivo |
| Beta (M6) | Email di contatto pubblica del progetto; avviso su GitHub Discussions di Valhalla |
| 1.0 (M7) | Contatto privato per il codice di condotta |
| Inizio della Fase 2 | Provare OneDrive e Dropbox con due account; scegliere la tecnologia del Sync Server; scegliere il formato delle mappe offline; chiedere a OpenFreeMap degli estratti regionali |
| Fase 3 (F3.3) | Licenza delle tabelle dei pedaggi; dati sulle vignette per paese |
