# Screens und Ablauf

Status: **Entwurf v2**. Screens und Ablauf für Version 1 abgestimmt; Optik offen.

## Übersicht

```
                ┌──────────────────┐
   App-Start ──▶│  Startbildschirm │◀───────────────┐
                └───┬─────────┬────┘                │
          Spielen   │         │ Einstellungen       │
                    ▼         ▼                     │
             ┌──────────┐  ┌───────────────┐        │
             │  Spiel   │  │ Einstellungen │──zurück┘
             └────┬─────┘  └───────────────┘
   Menü-Knopf     │
  „Runde beenden?“│ Ja
                  ▼
           ┌─────────────┐
           │   Bilanz    │── Menü ──▶ Startbildschirm
           └──────┬──────┘
                  │ Nochmal
                  ▼
           neue Runde (Spiel)
```

## Screens in Version 1

Vier Screens: **Startbildschirm, Spiel, Bilanz, Einstellungen.** Keine Anleitung / kein Tutorial in Version 1.

### Startbildschirm
- **Titel/Logo**, schön inszeniert.
- **Spielen-Knopf:** startet eine neue Runde.
- **Rekord:** bisher bester Punktestand.
- **Einstellungen-Knopf:** öffnet die Einstellungen.

### Spiel
- Aufbau siehe [screen-layout.md](screen-layout.md), Regeln siehe [game-rules.md](game-rules.md).
- **Kein Zeitdruck**, daher auch **keine Pause-Funktion** nötig.
- **Knopf „Neue Buchstaben“** (3 Hexagons für 20 Punkte, siehe [game-rules.md](game-rules.md)).
- **Kleiner Menü-Knopf** zum Beenden der Runde:
  - Tippen öffnet die Nachfrage **„Runde beenden?“** mit Ja / Nein.
  - **Ja:** Runde endet, es folgt der **Bilanz-Screen**. **Nein:** weiterspielen.

### Bilanz (ersetzt „Game-Over“)
- Erscheint, wenn der Spieler die Runde **beendet** (das Spiel ist endlos, man kann nicht verlieren).
- Zeigt **Punkte der Runde**, **erreichtes Level** und **Rekord**, mit Hinweis bei **neuem Rekord**.
- Knöpfe:
  - **Nochmal:** startet sofort eine neue Runde.
  - **Menü:** zurück zum Startbildschirm.

### Einstellungen
- **Schwierigkeitsstufe** 1–5 (Standard: 1 Sehr leicht), siehe [game-rules.md](game-rules.md). Gilt ab der nächsten Runde.
- **Soundeffekte** an/aus.
- **Musik** an/aus (Version 1 hat also Musik).
- **Rekord zurücksetzen** (mit Nachfrage; setzt die Rekorde aller Stufen zurück).
- Einstellungen werden lokal gespeichert.

## Rekord

- **Eigener Rekord pro Schwierigkeitsstufe.** Startbildschirm, Infobereich und Bilanz zeigen den Rekord der eingestellten Stufe.
- Der Rekord zählt beim **Beenden** der Runde.
- Wird **lokal auf dem Gerät** gespeichert.
- Architektur so anlegen, dass **später Online-Ranglisten** möglich sind (Google Play Games, Game Center).

## Offene Fragen

- Optik und Übergänge zwischen den Screens (Animationen).
- Gestaltung von Logo und Titel.
- Verhalten der Android-Zurück-Geste auf den einzelnen Screens.

## Verlauf

- **v1:** Screens für Version 1, Ablauf, Menü-Knopf statt Pause, Verhalten im Hintergrund, Game-Over mit Nochmal und Menü, Einstellungen, Rekord lokal.
- **v1.1:** Schwierigkeitsstufe in den Einstellungen, Rekord pro Stufe.
- **v2:** Ruhiger Level-Modus: Bilanz statt Game-Over (Rundenende durch den Spieler), Knopf „Neue Buchstaben“, keine Pause und kein Anhalten im Hintergrund nötig.
