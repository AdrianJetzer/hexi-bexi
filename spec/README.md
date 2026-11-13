# Spezifikation „Letter Tetris“

Arbeitstitel: **Letter Tetris**. Handy-Game für Android first, später iOS. Engine: Godot mit GDScript (siehe `../CLAUDE.md`).

Grundidee: Buchstaben in Hexagons erscheinen im Spielfeld und füllen es von unten nach oben, der Spieler wischt Wörter, die dann verschwinden (Details in `game-rules.md`). Hier sammeln wir abgestimmte Anforderungen, Skizzen und offene Fragen, bevor implementiert wird.

## Inhalt

| Dokument | Thema | Status |
|---|---|---|
| [v1-scope.md](v1-scope.md) | **Umfang Version 1:** was drin ist, was nicht, was noch zu klären ist | v1, abgestimmt |
| [game-rules.md](game-rules.md) | Spielregeln: Buchstaben erscheinen mit 3D-Drehung, Wörter wischen, Füllen von unten, Spielende | Entwurf v2 |
| [screens.md](screens.md) | Screens und Ablauf: Start, Spiel, Game-Over, Einstellungen | Entwurf v1 |
| [look-and-sound.md](look-and-sound.md) | Optik und Ton: Theme-System, Theme „Kosmisch“ (Version 1), Effekte | Entwurf v1 |
| [architecture.md](architecture.md) | Architektur: Trennung Logik/Darstellung, Ordnerstruktur, Tests mit GUT | Entwurf v1 |
| [tech.md](tech.md) | Technik und Rahmen: Engine, Geräte, Austauschbarkeit, offline, Release, Git | Entwurf v1 |
| [screen-layout.md](screen-layout.md) | Aufbau des Hauptspiel-Screens (Hochformat, geschlossenes Spielfeld mit Zickzack-Innenkante, Raster 6 × 9) | Entwurf v3 |

## Konventionen

- Bilder liegen in `images/`, mit Versionsnummer im Namen (z. B. `screen-layout-v1.svg`).
- Jedes Dokument trennt **Festgelegt**, **Platzhalter** und **Offene Fragen**.
- Neue Fassungen eines Bildes bekommen eine neue Versionsnummer; alte bleiben zum Vergleich liegen.
- Vorlagen, aus denen Bilder gerendert werden (z. B. HTML/SVG für Mock-Screenshots), liegen in `images/src/` mit demselben Namen wie das Bild.
  PNG neu rendern (Hochformat 390 × 844, doppelte Auflösung), im Ordner `spec/images` ausführen:
  `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --hide-scrollbars --force-device-scale-factor=2 --window-size=390,844 --virtual-time-budget=2000 --screenshot="$PWD/ingame-mock-v2.png" "file://$PWD/src/ingame-mock-v2.html"`
