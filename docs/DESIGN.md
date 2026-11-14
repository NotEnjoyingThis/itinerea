# Itinerea — Stile e design

> **Stato:** **proposta del 14/11/2026, in attesa di approvazione** (domanda aperta **D2** del PRD, entro M3). Finché non è approvata, l'app usa il tema provvisorio di M0 (`app/lib/core/theme/app_theme.dart`) e nulla di questo documento è applicato.
> **Riferimento:** Wanderlog (lista + mappa affiancate), da rendere più snello, moderno e veloce (PRD 7.1).
> **Vincoli:** tema chiaro e scuro (T5), accessibilità (T7), layout adattivo (T8), niente login, numero di tocchi dei flussi FL1–FL9 (PRD 7.5).

## 1. Principi

**Cosa teniamo di Wanderlog:** la lista del giorno accanto alla mappa; la giornata letta come una linea del tempo (tappa, tratta, tappa); la mappa che segue ciò che si seleziona nella lista.

**Cosa togliamo:** le card grandi con foto per ogni tappa, i banner, i consigli sponsorizzati, i menu a più livelli, le schermate intermedie. Una tappa è **una riga**, non una card.

**Cosa cambia:**

1. **L'orario è il protagonista.** Ogni riga inizia con l'ora, in cifre allineate. Chi è in viaggio cerca prima "quando", poi "cosa".
2. **La mappa ha i colori, l'interfaccia no.** Superfici neutre e un solo colore di accento: così il percorso e i segnaposto risaltano sulla mappa e gli avvisi risaltano nella lista.
3. **Bordi sottili al posto delle ombre.** Meno livelli visivi, disegno più veloce sui telefoni di fascia media (T2).
4. **Onestà visibile.** Un dato stimato o vecchio ha sempre la sua etichetta accanto, con lo stesso aspetto ovunque (T4).
5. **Tutto a portata di pollice.** Su telefono le azioni stanno in basso; i dettagli si aprono in un pannello e si chiudono con un gesto.

## 2. Colori

Un accento verde-petrolio, neutri leggermente virati verso lo stesso verde, colori semantici separati dall'accento. Il percorso sulla mappa usa un colore a parte (lampone), scelto perché non si confonde con acqua, parchi e strade dello stile OpenFreeMap.

| Ruolo | Chiaro | Scuro | Uso |
|---|---|---|---|
| Sfondo | `#F6F8F7` | `#0F1513` | Fondo dell'app |
| Superficie | `#FFFFFF` | `#182120` | Liste, pannelli, barre |
| Superficie 2 | `#EEF2F0` | `#212C2A` | Riga selezionata, campi |
| Testo | `#14201D` | `#E6EEEB` | Testo principale |
| Testo secondario | `#55645F` | `#9FB0AA` | Durate, note, etichette |
| Divisore | `#DCE3E0` | `#2B3735` | Linee decorative |
| Bordo dei controlli | `#7F8F8A` | `#70807B` | Campi, pulsanti con bordo |
| **Accento** | `#0B6E63` | `#6FD6C6` | Azioni principali, selezione, orario "adesso" |
| Su accento | `#FFFFFF` | `#00382F` | Testo sopra l'accento |
| Accento tenue | `#D5EEE9` (testo `#0A4F47`) | `#12403A` (testo `#B5ECE2`) | Chip attivi, piano selezionato |
| **Percorso** | `#C2255C` | `#FF7AA8` | Percorso attivo sulla mappa |
| Percorso alternativo | `#7F8F8A` | `#70807B` | Percorsi non scelti |
| Avviso | `#9A4F00` su `#FFE9CC` | `#FFB95C` su `#4A2E00` | Orari stretti, chiusure, ritardi |
| Errore | `#B3261E` | `#FFB4AB` | Errori, sovrapposizioni |
| Offline / dato salvato | `#3F5B74` | `#9DBAD3` | "Offline – aggiornato il…" |
| Fatto | `#23703F` | `#86D6A2` | Tappa visitata, spesa saldata |

**Contrasto verificato** (formula WCAG 2.1, calcolato per ogni coppia):

| Coppia | Chiaro | Scuro | Minimo |
|---|---|---|---|
| Testo su sfondo | 15,7 | 15,7 | 4,5 |
| Testo su superficie | 16,8 | 13,9 | 4,5 |
| Testo secondario su superficie | 6,2 | 7,3 | 4,5 |
| Accento su superficie | 6,1 | 9,5 | 4,5 |
| Testo su accento | 6,1 | 7,5 | 4,5 |
| Testo su accento tenue | 7,8 | 8,8 | 4,5 |
| Avviso su superficie | 6,0 | 9,7 | 4,5 |
| Errore su superficie | 6,5 | 9,7 | 4,5 |
| Offline su superficie | 7,1 | 8,1 | 4,5 |
| Fatto su superficie | 6,1 | 9,5 | 4,5 |
| Percorso sul terreno della mappa | 4,9 | 6,5 | 3 |
| Bordo dei controlli su superficie | 3,4 | 4,0 | 3 |

**Colori dei partecipanti** (PRD 8.3, `Participant.color`), otto tinte distinguibili anche in scala di grigi grazie a un'iniziale sempre visibile: `#0B6E63`, `#C2255C`, `#3F5BD9`, `#9A4F00`, `#7A3FB8`, `#23703F`, `#B3261E`, `#44617A`. Il colore non è mai l'unico modo per distinguere due persone.

## 3. Tipografia

Due famiglie con licenza libera (SIL Open Font License 1.1), **incluse nell'app come file**: nessun download a runtime, nessuna richiesta a servizi esterni.

| Ruolo | Font | Perché |
|---|---|---|
| Testo, numeri, etichette | **Inter** | Molto leggibile a corpi piccoli; ha le cifre a larghezza fissa, indispensabili per allineare orari e importi |
| Titoli (nome del viaggio, intestazione del giorno) | **Manrope** | Più carattere di Inter, forme aperte; usato con parsimonia |

| Stile | Font e peso | Dimensione / interlinea |
|---|---|---|
| Titolo del viaggio | Manrope 700 | 24 / 30 |
| Intestazione del giorno | Manrope 700 | 20 / 26 |
| Titolo di pannello | Manrope 600 | 17 / 24 |
| Nome della tappa | Inter 600 | 16 / 22 |
| Testo | Inter 400 | 15 / 22 |
| Orario | Inter 600, cifre a larghezza fissa | 15 / 22 |
| Secondario (durate, note) | Inter 400 | 13 / 18 |
| Etichetta (chip, "Stima") | Inter 500 | 12 / 16 |

Le dimensioni seguono l'impostazione di sistema fino al 200%: le righe crescono in altezza, il testo va a capo, niente viene tagliato. Niente maiuscolo per le etichette: le parole intere si leggono meglio e si traducono meglio.

**Da decidere con l'approvazione:** due famiglie pesano più di una (ordine di grandezza: qualche centinaio di KB ciascuna). L'alternativa è usare solo Inter anche per i titoli.

## 4. Spaziature e forme

- **Griglia a passi di 4 px.** Spazi usati: 4, 8, 12, 16, 24, 32.
- **Margine laterale:** 16 px su telefono, 24 px su tablet e desktop.
- **Altezza minima di una riga toccabile:** 56 px (area toccabile minima 48 × 48).
- **Angoli:** 8 px per chip e campi, 12 px per pannelli e card, 20 px per gli angoli superiori del pannello dal basso, cerchio per il pulsante "+".
- **Elevazione:** nessuna ombra nelle liste. Ombra solo per ciò che galleggia davvero: pulsante "+", pannello dal basso, menu.

## 5. Icone

**Material Icons**, variante arrotondata (Apache-2.0), già incluse in Flutter: nessuna dipendenza nuova. Tratto pieno a 24 px; 20 px dentro i chip.

| Gruppo | Icone |
|---|---|
| Mezzi | a piedi, auto, moto, bici, bus, treno, metro, tram, traghetto, aereo |
| Tappe speciali | rifornimento, ricarica, sosta |
| Categorie di spesa | alloggio, trasporti, cibo, attività, carburante, pedaggi, acquisti, altro |
| Prenotazioni | volo, treno, bus, traghetto, alloggio, attrazione, noleggio, ristorante |
| Stato | biglietto allegato, alternative, visitata, offline, avviso |

Un'icona non compare mai da sola quando il significato non è ovvio: ha un testo accanto o un'etichetta per i lettori di schermo.

## 6. Componenti

- **Riga della tappa.** A sinistra l'orario (colonna di larghezza fissa), poi nome e una riga secondaria (durata, costo stimato, nota breve); a destra gli indicatori: biglietto, alternative, avviso. Un lucchetto piccolo accanto all'orario quando è fissato (`timeFixed`). Tappa visitata: segno di spunta e testo secondario.
- **Riga della tratta.** Sta sulla linea verticale che unisce due tappe: icona del mezzo, durata, distanza. È più bassa e più leggera di una tappa, ma toccabile (apre S05). Se la durata è inserita a mano o stimata, porta l'etichetta.
- **Pulsante "+".** In basso a destra su telefono, in fondo alla colonna del giorno su desktop. Toccandolo si aprono tre scelte: Tappa, Spesa, Prenotazione (PRD 7.1, FL1 e FL3 restano a 3 tocchi).
- **Pannello di dettaglio.** Dal basso su telefono (metà schermo, trascinabile a schermo intero); laterale su desktop, al posto della colonna del giorno o sopra la mappa. Si chiude con un gesto o con Esc.
- **Etichette di onestà (T4).** Un chip con bordo tratteggiato e testo secondario: "Stima", "Inserito a mano", "Orari salvati il 12/03". Stesso aspetto in tutta l'app. Per i dati offline il chip usa il colore "Offline".
- **Indicatore dei piani A–D.** Un chip "+2" con l'icona delle alternative sulla riga; toccandolo si apre l'elenco dei piani e il piano attivo ha l'accento tenue (FL2 resta a 2 tocchi).
- **Avvisi del giorno.** Una fascia in cima alla lista con il colore "Avviso": una frase, un'azione ("Mostra", "Sistema").
- **Stati vuoti ed errori (PRD 7.7).** Un'icona, una frase che dice cosa manca, un'azione. Mai una schermata bianca, mai un errore senza indicare cosa fare.

## 7. Layout adattivo

| Larghezza | Layout |
|---|---|
| meno di 600 px (telefono) | Una colonna. Barra in basso con le schede del viaggio. La mappa è una scheda a sé; dalla lista del giorno un pulsante apre la mappa del giorno |
| 600–1023 px (tablet, finestra stretta) | Due riquadri: lista del giorno (360–420 px) e mappa. I giorni si scelgono da un selettore sopra la lista |
| da 1024 px (desktop) | Tre riquadri: colonna dei giorni e delle schede (220 px), giorno (400 px), mappa (il resto). Il pannello di dettaglio prende il posto della colonna del giorno |

La mappa non si ricarica passando da un layout all'altro: ridimensionando la finestra cambia solo la disposizione.

## 8. Movimento

- Durate: 150 ms per comparse e cambi di stato, 250 ms per pannelli e cambi di scheda.
- Curva: decelerazione in entrata, accelerazione in uscita. Niente rimbalzi.
- Si anima ciò che aiuta a capire dove va un elemento: apertura del pannello, riordino di una tappa, ricalcolo degli orari (i numeri cambiano con una dissolvenza breve).
- Non si animano le liste al primo caricamento né la mappa oltre i suoi movimenti naturali.
- Con "riduci animazioni" attivo nel sistema, tutto diventa immediato.

## 9. Accessibilità

- Contrasto: almeno 4,5:1 per i testi e 3:1 per icone e bordi dei controlli (tabella in §2).
- Aree toccabili di almeno 48 × 48 px, anche per gli indicatori sulla riga.
- Ogni riga ha un'etichetta completa per i lettori di schermo: "Ore 9, Uffizi, 2 ore, biglietto allegato, 2 alternative".
- Il colore non porta mai da solo un'informazione: avvisi ed errori hanno sempre icona e testo.
- Desktop: tutto raggiungibile da tastiera, fuoco sempre visibile, Esc chiude il pannello, frecce per scorrere le tappe.
- Testo di sistema fino al 200% senza perdita di contenuto.

## 10. Esempio: schermata Giorno

L'anteprima visiva (telefono e desktop, tema chiaro e scuro) è stata mostrata all'utente insieme a questa proposta; non fa parte del repository.

```
TELEFONO                               DESKTOP
┌────────────────────────────┐         ┌──────────┬───────────────────────┬──────────────────┐
│ ‹ Toscana in moto        ⋯ │         │ Toscana  │ Giorno 3 · ven 14 mar │                  │
│ Giorno 3 · ven 14 mar      │         │ in moto  │ ☀ 22° Firenze         │                  │
│ ☀ 22°  Firenze             │         │          │ ⚠ Uffizi chiude 18:30 │                  │
├────────────────────────────┤         │ Giorni   ├───────────────────────┤      MAPPA       │
│ ⚠ Uffizi chiude alle 18:30 │         │  1 mer   │ 09:00 Uffizi      🎫  │  percorso del    │
├────────────────────────────┤         │  2 gio   │   │ 🚶 12 min · 900 m │  giorno in       │
│ 09:00  Uffizi           🎫 │         │ ▶3 ven   │ 12:00 Pranzo          │  lampone,        │
│   │ 🚶 12 min · 900 m      │         │  4 sab   │   │ 🚶 8 min · 600 m  │  tappe numerate  │
│ 12:00  Pranzo              │         │          │ 14:00 Duomo       +2  │                  │
│   │ 🚶 8 min · 600 m       │         │ Budget   │   │ 🏍 35 min [Stima] │                  │
│ 14:00  Duomo            +2 │         │ Prenot.  │ 16:30 Fiesole         │                  │
│   │ 🏍 35 min  [Stima]     │         │ Altro    │                 [ + ] │                  │
│ 16:30  Fiesole             │         └──────────┴───────────────────────┴──────────────────┘
│                      [ + ] │
├────────────────────────────┤
│ Giorni  Mappa  Budget  …   │
└────────────────────────────┘
```
