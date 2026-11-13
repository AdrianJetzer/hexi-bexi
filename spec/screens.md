# Screens und Ablauf

Status: **Entwurf v3**. Angepasst an den Lauf-Modus ([run-mode.md](run-mode.md)); Optik offen.

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

Vier Screens: **Startbildschirm, Spiel, Bilanz, Einstellungen.** Dazu die **Auftragswahl** als Ebene über dem Spiel. Keine Anleitung / kein Tutorial in Version 1.

### Startbildschirm
- **Titel/Logo**, schön inszeniert.
- **Spielen-Knopf:** startet einen neuen Lauf.
- **Rekord:** höchstes erreichtes Level.
- **Einstellungen-Knopf:** öffnet die Einstellungen.

### Spiel
- Aufbau siehe [screen-layout.md](screen-layout.md), Regeln siehe [game-rules.md](game-rules.md).
- **Kein Zeitdruck**, daher auch **keine Pause-Funktion** nötig.
- **Anzeige:** aktueller **Auftrag** mit Fortschritt (z. B. „2 von 3 Wörtern“), **Münzen**, **Level**, **Rekord**.
- **Hilfe-Knöpfe** mit Preis: **Nachfüllen** (5 Steine, ab 100, steigt), **Tauschen** (5 Steine, 50), **Tipp** (100), **Stein ersetzen** (100). Gesperrt, wenn das Geld nicht reicht; Nachfüllen auch bei vollem Feld oder Auftrag „ohne Nachziehen“.
- **Knopf „Aufgeben“:**
  - Tippen öffnet die Nachfrage **„Aufgeben?“** mit Ja / Nein.
  - **Ja:** Lauf endet, es folgt der **Bilanz-Screen**. **Nein:** weiterspielen.

### Auftragswahl
- Erscheint **vor jedem Level** als Ebene über dem Spielfeld.
- Zeigt **2 Auftragskarten** mit Belohnung (sicher und riskant); Tippen wählt.
- Nach einem erfüllten Auftrag: kurze Erfolgsmeldung mit Münzen, dann die nächste Auftragswahl.

### Bilanz (ersetzt „Game-Over“)
- Erscheint, wenn der Spieler **aufgibt** oder ein **Zuglimit verfehlt** (dann mit Hinweis „Züge aufgebraucht“). Vorher zeigt das Spielfeld die **Lösung** (blinkende Steine, „Lösung: WORT“); der Knopf **„Weiter“** öffnet die Bilanz.
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
