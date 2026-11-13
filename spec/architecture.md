# Architektur

Status: **Entwurf v1**. Grundaufbau abgestimmt; Details werden bei der Umsetzung verfeinert.

Gilt für das Godot-Projekt in `letter-tetris/`. Rahmenbedingungen siehe [tech.md](tech.md), Umfang siehe [v1-scope.md](v1-scope.md).

## Grundprinzipien

1. **Spiellogik getrennt von der Darstellung.** Alle Regeln (Raster, Platzwahl, Buchstabenwahl, Wortprüfung, Punkte, Spielende) laufen als reiner GDScript-Code **ohne Grafik** in `core/`. Die Darstellung hört nur zu und zeigt an. So ist die Logik automatisch testbar, und Themes ändern nie die Regeln.
2. **Daten statt fester Code.** Sprache, Theme und Spielwerte sind Godot-Ressourcen (`.tres`) in eigenen Ordnern unter `data/`. Neue Sprache oder neues Theme = neuer Ordner, keine Code-Änderung.
3. **Kommunikation über Signale.** Die Logik meldet Ereignisse (z. B. „Hexagon erschienen“, „Wort gefunden“, „ungültiges Wort“, „Spiel vorbei“). Die Darstellung reagiert mit Effekten und Sound.
4. **Dienste mit Platzhaltern.** Rangliste und Käufe gibt es in Version 1 nur als leere Platzhalter-Dienste. Später werden sie ersetzt, ohne das Spiel umzubauen.

## Ordnerstruktur (`letter-tetris/`)

```
core/                  Reine Spiellogik (keine Grafik)
  hex_grid.gd          Raster 6×9, Koordinaten, Nachbarn, freie Plätze, Löcher
  spawner.gd           Takt, Tempo-Stufe, Platzwahl
  letter_picker.gd     Buchstabenwahl (Häufigkeit + Vokal-Ausgleich)
  dictionary.gd        Wortprüfung
  scoring.gd           Punkte = 5·n·(n−1)
  game_session.gd      Eine Runde: verbindet alles, sendet Signale

data/
  balance.tres         Spielwerte (Takt, Steigerung, Startreihen …)
  languages/de/        Alphabet, Gewichte, Vokale, Wortliste
  themes/cosmic/       Texturen, Farben, Shader-Parameter, Sounds, Musik

scenes/
  main.tscn            Wurzel: wechselt zwischen den Screens
  screens/             start, game, game_over, settings
  board/               board_view (Feld + Wisch-Eingabe), hex_tile (ein Hexagon)
  effects/             Energie-Strahl, Zerspringen, Erlöschen …

shaders/               Kristall, 3D-Drehung, Nebel, Leuchtkante

autoload/              Immer verfügbare Dienste
  settings.gd          Ton/Musik an/aus (lokal gespeichert)
  save_data.gd         Rekord (lokal)
  audio.gd             Sound und Musik aus dem aktiven Theme
  theme_manager.gd     Aktives Theme (Version 1: cosmic)
  language_manager.gd  Aktive Sprache (Version 1: de)
  services/            Rangliste, Käufe (Version 1: leere Platzhalter)

tests/                 Automatische Tests (GUT) für core/
```

## Lösungsansätze für knifflige Stellen

- **3D-Drehung im 2D-Spiel:** Shader auf dem Hexagon-Sprite, der eine perspektivische Drehung vortäuscht und bei 90° von der milchigen Rückseite zur Vorderseite wechselt. Leistungsgünstig.
- **Kristall-Licht:** Sprites mit **Normal Maps**, **2D-Lichter** und **Glow**. Ob Glow mit dem Mobile-Renderer auf Android wie gewünscht aussieht, **früh auf einem echten Gerät prüfen**.
- **Wischen:** Fingerposition wird in Raster-Koordinaten umgerechnet. Ein Hexagon zählt erst, wenn der Finger **nah genug an dessen Mitte** ist, damit an den Ecken nicht versehentlich der falsche Nachbar gewählt wird.
- **Wörterbuch:** Mit allen Wortformen, Eigennamen und Abkürzungen kann die Liste sehr groß werden. Speicherformat (kompakt in der App) wird mit der Wörterbuch-Quelle entschieden.
- **App im Hintergrund:** Godot meldet das Pausieren der App; dann stoppt die Runde automatisch.

## Tests

- Die Spiellogik in `core/` wird mit **GUT** (Godot Unit Test, Community-Plugin) automatisch getestet.
- Tests liegen in `tests/`.

## Offene Punkte

- Speicherformat des Wörterbuchs (abhängig von der Quelle).
- Genaue Signal-Namen und Schnittstellen zwischen `core/` und `scenes/`.
- Glow und Licht auf echtem Android-Gerät prüfen.

## Verlauf

- **v1:** Grundprinzipien, Ordnerstruktur, Lösungsansätze, Tests mit GUT.
