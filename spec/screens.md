# Screens und Ablauf

Status: **Entwurf v1**. Screens und Ablauf für Version 1 abgestimmt; Optik offen.

## Übersicht

```
                ┌──────────────────┐
   App-Start ──▶│  Startbildschirm │◀───────────────┐
                └───┬─────────┬────┘                │
          Spielen   │         │ Einstellungen       │
                    ▼         ▼                     │
             ┌──────────┐  ┌───────────────┐        │
             │  Spiel   │  │ Einstellungen │──zurück┘
             └──┬────┬──┘  └───────────────┘
   Menü-Knopf   │    │ kein Platz mehr frei
  „Runde        │    ▼
   beenden?“ Ja │  ┌─────────────┐
                │  │  Game-Over  │── Menü ──▶ Startbildschirm
                │  └──────┬──────┘
                │         │ Nochmal
                │         ▼
                │      neue Runde (Spiel)
                ▼
         Startbildschirm
```

## Screens in Version 1

Vier Screens: **Startbildschirm, Spiel, Game-Over, Einstellungen.** Keine Anleitung / kein Tutorial in Version 1.

### Startbildschirm
- **Titel/Logo**, schön inszeniert.
- **Spielen-Knopf:** startet eine neue Runde.
- **Rekord:** bisher bester Punktestand.
- **Einstellungen-Knopf:** öffnet die Einstellungen.

### Spiel
- Aufbau siehe [screen-layout.md](screen-layout.md), Regeln siehe [game-rules.md](game-rules.md).
- **Keine Pause-Funktion.**
- **Kleiner Menü-Knopf** zum Abbrechen der Runde:
  - Tippen öffnet die Nachfrage **„Runde beenden?“** mit Ja / Nein.
  - Solange die Nachfrage offen ist, **hält das Spiel an** und das **Feld ist verdeckt** (kein Schummeln).
  - **Ja:** Runde endet, zurück zum Startbildschirm. **Nein:** Runde läuft weiter.
- **App geht in den Hintergrund** (Anruf, App-Wechsel): Das Spiel **hält an** und läuft beim Zurückkehren weiter.

### Game-Over
- Erscheint, wenn **kein Platz mehr frei** ist.
- Zeigt **Punkte der Runde** und **Rekord**, mit Hinweis bei **neuem Rekord**.
- Knöpfe:
  - **Nochmal:** startet sofort eine neue Runde.
  - **Menü:** zurück zum Startbildschirm.

### Einstellungen
- **Schwierigkeitsstufe** 1–5 (Standard: 3 Mittel), siehe [game-rules.md](game-rules.md). Gilt ab der nächsten Runde.
- **Soundeffekte** an/aus.
- **Musik** an/aus (Version 1 hat also Musik).
- **Rekord zurücksetzen** (mit Nachfrage; setzt die Rekorde aller Stufen zurück).
- Einstellungen werden lokal gespeichert.

## Rekord

- **Eigener Rekord pro Schwierigkeitsstufe.** Startbildschirm, Infobereich und Game-Over zeigen den Rekord der eingestellten Stufe.
- Wird **lokal auf dem Gerät** gespeichert.
- Architektur so anlegen, dass **später Online-Ranglisten** möglich sind (Google Play Games, Game Center).

## Offene Fragen

- Optik und Übergänge zwischen den Screens (Animationen).
- Gestaltung von Logo und Titel.
- Verhalten der Android-Zurück-Geste auf den einzelnen Screens.

## Verlauf

- **v1:** Screens für Version 1, Ablauf, Menü-Knopf statt Pause, Verhalten im Hintergrund, Game-Over mit Nochmal und Menü, Einstellungen, Rekord lokal.
- **v1.1:** Schwierigkeitsstufe in den Einstellungen, Rekord pro Stufe.
