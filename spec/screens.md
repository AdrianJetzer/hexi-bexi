# Screens und Ablauf

Status: **Entwurf v4**. Angepasst an Lauf-Modus v3 mit Block-Zeilen ([run-mode.md](run-mode.md)); Optik offen.

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
   „Aufgeben?“    │ Ja
                  ▼
           ┌─────────────┐
           │   Bilanz    │── Menü ──▶ Startbildschirm
           └──────┬──────┘
                  │ Nochmal
                  ▼
           neuer Lauf (Spiel, Level 1)
```

## Screens in Version 1

Vier Screens: **Startbildschirm, Spiel, Bilanz, Einstellungen.** Keine Anleitung / kein Tutorial in Version 1.

### Startbildschirm
- **Titel/Logo**, schön inszeniert.
- **Spielen-Knopf:** startet einen neuen Lauf.
- **Rekord:** höchstes erreichtes Level.
- **Einstellungen-Knopf:** öffnet die Einstellungen.

### Spiel
- Aufbau siehe [screen-layout.md](screen-layout.md), Regeln siehe [game-rules.md](game-rules.md).
- **Kein Zeitdruck**, daher auch **keine Pause-Funktion** nötig.
- **Auftrag:** Block-Zeilen über dem Spielfeld (siehe [run-mode.md](run-mode.md)); gefundene Wörter fliegen hinein. Kein Text, kein gewischtes Wort.
- **Anzeige:** **Münzen**, **Level**, **Rekord**.
- **Hilfe-Knöpfe** mit Preis, sortiert **von gratis bis teuer**: **Auffüllen** (5 Steine, gratis), **Tipp** (25 je Buchstabe), **Stein ersetzen** (25), **Tauschen** (5 Steine, 100), **Aufräumen** (100), **Joker** (100), **Magnet** (100, Stein antippen), **Kürzen** (100, längste Zeile −1), **Teilen** (125), **Mischen** (150), **Vervollständigen** (150, Wortanfang anwischen), **Scan** (200, ein Wort für die längste Zeile), **Lösen** (ganzer Auftrag, 400). Gesperrt, wenn das Geld nicht reicht; Auffüllen auch bei vollem Feld.
- **Knopf „Aufgeben“:**
  - Tippen öffnet die Nachfrage **„Aufgeben?“** mit Ja / Nein.
  - **Ja:** Lauf endet, es folgt der **Bilanz-Screen**. **Nein:** weiterspielen.

### Bilanz (ersetzt „Game-Over“)
- Erscheint, wenn der Spieler **aufgibt**. Vorher zeigt das Spiel die **Lösung** (Steine blinken, Buchstaben fliegen in die Zeile); der Knopf **„Weiter“** öffnet die Bilanz.
- Zeigt **erreichtes Level** und **Rekord**, mit Hinweis bei **neuem Rekord**.
- Knöpfe:
  - **Nochmal:** startet sofort einen neuen Lauf ab Level 1.
  - **Menü:** zurück zum Startbildschirm.

### Einstellungen
- **Soundeffekte** an/aus.
- **Musik** an/aus (Version 1 hat also Musik).
- **Rekord zurücksetzen** (mit Nachfrage).
- Einstellungen werden lokal gespeichert.

## Rekord

- **Ein Rekord:** das **höchste erreichte Level**. Startbildschirm, Spiel und Bilanz zeigen ihn.
- Der Rekord zählt beim **Aufgeben**.
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
- **v3:** Lauf-Modus: Auftragswahl als Ebene über dem Spiel, Anzeige von Auftrag und Münzen, Hilfe-Knöpfe, „Aufgeben“ statt „Runde beenden“, Bilanz mit Level, ein Rekord (höchstes Level), Schwierigkeitsstufe aus den Einstellungen entfernt.
- **v4:** Auftragswahl entfällt; Auftrag als Block-Zeilen über dem Spielfeld; kein Text für Auftrag und gewischtes Wort; Bilanz nur nach Aufgeben.
- **v4.1:** Fünfter Hilfe-Knopf „Aufräumen“.
- **v4.2:** Sechster Hilfe-Knopf „Lösen“.
- **v4.3:** Hilfe-Knöpfe Joker, Mischen, Schwerkraft; zum Testen in zwei Reihen, gute Platzierung später.
- **v4.4:** Hilfe-Knöpfe Magnet und Säule (Antipp-Modus wie Ersetzen); zum Testen in drei Reihen.
- **v4.5:** Hilfe-Knöpfe Teilen und Scan.
- **v4.6:** Säule und Schwerkraft entfallen; Hilfe-Knöpfe nach Preis sortiert (gratis bis teuer).
- **v4.7:** Hilfe-Knopf Vervollständigen (Wisch-Modus).
- **v4.8:** Hilfe-Knopf Kürzen.
