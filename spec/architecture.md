# Architektur

Status: **Entwurf v2**. Grundaufbau abgestimmt; Details werden bei der Umsetzung verfeinert.

Gilt für das Godot-Projekt in `letter-tetris/`. Rahmenbedingungen siehe [tech.md](tech.md), Umfang siehe [v1-scope.md](v1-scope.md).

## Grundprinzipien

1. **Spiellogik getrennt von der Darstellung.** Alle Regeln (Raster, Platzwahl, Buchstabenwahl, Wortprüfung, Punkte, Spielende) laufen als reiner GDScript-Code **ohne Grafik** in `core/`. Die Darstellung hört nur zu und zeigt an. So ist die Logik automatisch testbar, und Themes ändern nie die Regeln.
2. **Daten statt fester Code.** Sprache, Theme und Spielwerte sind Godot-Ressourcen (`.tres`) in eigenen Ordnern unter `data/`. Neue Sprache oder neues Theme = neuer Ordner, keine Code-Änderung.
3. **Kommunikation über Signale.** Die Logik meldet Ereignisse (z. B. „Hexagon erschienen“, „Wort gefunden“, „ungültiges Wort“, „Spiel vorbei“). Die Darstellung reagiert mit Effekten und Sound.
4. **Dienste mit Platzhaltern.** Rangliste und Käufe gibt es in Version 1 nur als leere Platzhalter-Dienste. Später werden sie ersetzt, ohne das Spiel umzubauen.

## Ordnerstruktur (`letter-tetris/`)

```
core/                  Reine Spiellogik (keine Grafik)
  hex_grid.gd          Raster 5×9, Koordinaten, Nachbarn, freie Plätze, Löcher
  board_layout.gd      Geometrie des Rasters (Mittelpunkte, Treffer-Test, Zickzack-Umriss)
  spawner.gd           Takt, Tempo-Stufe, Platzwahl
  letter_picker.gd     Buchstabenwahl (Häufigkeit + Vokal-Ausgleich)
  word_dictionary.gd   Wortprüfung
  scoring.gd           Punkte = 5·n·(n−1)
  game_session.gd      Eine Runde: verbindet alles, sendet Signale

data/
  balance.tres         Spielwerte (Takt, Steigerung, Startreihen …)
  languages/de/        Alphabet, Gewichte, Vokale, Wortliste
  themes/cosmic/       Texturen, Farben, Shader-Parameter, Sounds, Musik

scenes/
  main.tscn            Wurzel: wechselt zwischen den Screens
  screens/             start, game, game_over, settings
  board3d/             3D-Spielfeld: board_view_3d (Feld, Kamera, Wisch-Eingabe),
                       hex_tile_3d (ein Hexagon), hex_mesh (Modell im Code erzeugt),
                       cosmic_materials (Materialien des Themes Kosmisch)
  prototypes/          Prototypen zum Ausprobieren der Optik (nicht Teil des Spiels)
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

- **3D-Spielfeld, 2D-Oberfläche:** Das Spielfeld (Hexagons, Rahmen, Licht, Kamera) ist eine 3D-Szene; Wort-Anzeige, Infobereich und Knöpfe sind 2D-Controls darüber. Die Spiellogik bleibt unverändert.
  - **Kamera** senkrecht von oben mit Perspektive; ihr Abstand wird so berechnet, dass das Feld in den vorgesehenen Bildschirmbereich passt (Ränder, Bereich oben, Infobereich unten).
  - **Raster in 3D:** dieselbe Geometrie wie `BoardLayout`, in der Ebene X/Z (Bildschirm-unten = +Z).
- **Hexagon-Modell:** im Code erzeugtes Prisma mit runden Kanten (`HexMesh`), zwei Flächen (Vorder- und Rückseite), damit die Rückseite ein eigenes Material bekommt. Die milchige Rückseite wird nur gezeigt, solange sie oben liegt (sonst schiene sie durch das Glas).
- **3D-Drehung:** echte Drehung des Hexagons um die eigene Achse.
- **Kristall-Material:** eigener Shader `shaders/crystal.gdshader` (Lichtbrechung über die Bildschirmtextur, Fresnel-Kante, Leuchtkern) plus **Glow** der Umgebung. Leistung und Aussehen mit dem Mobile-Renderer **früh auf einem echten Gerät prüfen**.
- **Spiegelungen:** eine unsichtbare Himmels-Umgebung dient nur als Quelle für Spiegelungen; der sichtbare Hintergrund bleibt dunkel.
- **Wischen:** Der Fingerpunkt wird über einen Strahl von der Kamera auf die Ebene der Hexagons umgerechnet, dann in Raster-Koordinaten. Ein Hexagon zählt erst, wenn der Finger **nah genug an dessen Mitte** ist, damit an den Ecken nicht versehentlich der falsche Nachbar gewählt wird.
- **Wörterbuch:** Kompaktes Binärformat **„LTW1“** (`data/languages/<code>/words.bin`): Wörter nach Länge gruppiert, je Gruppe sortiert, ohne Trennzeichen; Suche per binärer Suche in der passenden Längengruppe. Erzeugt von `tools/dictionary/pack_words.py`.
  - Gemessen (Mac, 850.724 Wörter): **9,9 MB** Arbeitsspeicher, Laden ~1 ms, Prüfen eines Worts ~2,4 µs. (Zum Vergleich: als Text-Array 70 MB.)
  - **Beim Export beachten:** `*.bin` ist keine Godot-Ressource und muss im Export-Filter ausdrücklich eingeschlossen werden (z. B. `data/languages/*/words.bin`).
- **App im Hintergrund:** Godot meldet das Pausieren der App; dann stoppt die Runde automatisch.

## Tests

- Die Spiellogik in `core/` wird mit **GUT** (Godot Unit Test, Community-Plugin) automatisch getestet.
- Tests liegen in `tests/`.

## Offene Punkte

- Begrenzung der Wortlänge (z. B. max. 15 Buchstaben) – noch nicht entschieden; derzeit ungekürzt.
- Genaue Signal-Namen und Schnittstellen zwischen `core/` und `scenes/`.
- Glow und Licht auf echtem Android-Gerät prüfen.

## Verlauf

- **v1:** Grundprinzipien, Ordnerstruktur, Lösungsansätze, Tests mit GUT.
- **v1.1:** Wörterbuch-Format „LTW1“ (kompakt, ~10 MB).
- **v2:** Spielfeld in 3D mit 2D-Oberfläche; Hexagon-Modell im Code, Kristall-Shader, Kamera von oben mit Perspektive.
