# Spezifikation „Hexaword“

Spielname: **Hexaword** (vorläufig; vorher Arbeitstitel „Letter Tetris“). Achtung: „Hexaword“ gibt es schon im Play Store; vor der Veröffentlichung neu entscheiden. Ebenfalls vergeben: Lexagon(s), Hexicon. Noch frei (Stand Nov. 2026, grob geprüft): Wortwabe. Handy-Game für Android first, später iOS. Engine: Godot mit GDScript (siehe `../CLAUDE.md`).

Grundidee: Buchstaben in Hexagons erscheinen im Spielfeld und füllen es von unten nach oben, der Spieler wischt Wörter, die dann verschwinden (Details in `game-rules.md`). Gespielt wird in **Läufen**: jedes Level ist ein Auftrag aus Block-Zeilen (gesuchte Wortlängen), Münzen kaufen Hilfen, wer aufgibt, beginnt neu (`run-mode.md`). Hier sammeln wir abgestimmte Anforderungen, Skizzen und offene Fragen, bevor implementiert wird.

## Inhalt

| Dokument | Thema | Status |
|---|---|---|
| [v1-scope.md](v1-scope.md) | **Umfang Version 1:** was drin ist, was nicht, was noch zu klären ist | v3, Entwurf |
| [run-mode.md](run-mode.md) | **Lauf-Modus (Roguelike):** Aufträge als Block-Zeilen, Ziel Level 20 mit Sternen, Münzen, Hilfen, Aufgeben, Kurve | Entwurf v3.36 |
| [story-mode.md](story-mode.md) | **Story-Modus (Konzept):** Kapitel nach Kategorien (Früchte, Tiere …), Ziel Level 20, versteckte Themenwörter, Rätsel-Tipp | v5 (Kapitel-Brett, 8 Kapitel) |
| [game-rules.md](game-rules.md) | Spielregeln des Grundspiels: Raster, Nachschub, Wörter wischen, Wort-Hilfe, Hilfe-Stufen, Wörterbuch | Entwurf v8 (Wörterbuch-Konzept) |
| [screens.md](screens.md) | Screens und Ablauf: Start, Spiel, Bilanz, Einstellungen | Entwurf v4.21 |
| [look-and-sound.md](look-and-sound.md) | Optik und Ton: Theme-System, Theme „Kosmisch“ (Version 1), 3D-Hexagons aus Rauchglas, Effekte | Entwurf v2 |
| [architecture.md](architecture.md) | Architektur: Trennung Logik/Darstellung, 3D-Spielfeld mit 2D-Oberfläche, Lauf-Modus in der Logik, Ordnerstruktur, Tests mit GUT | Entwurf v4.21 |
| [tech.md](tech.md) | Technik und Rahmen: Engine, Geräte, Austauschbarkeit, offline, Release, Git | Entwurf v1 |
| [screen-layout.md](screen-layout.md) | Aufbau des Hauptspiel-Screens (Hochformat, geschlossenes Spielfeld mit Zickzack-Innenkante, Raster 5 × 5) | Entwurf v14 |

## Konventionen

- Bilder liegen in `images/`, mit Versionsnummer im Namen (z. B. `screen-layout-v1.svg`).
- Jedes Dokument trennt **Festgelegt**, **Platzhalter** und **Offene Fragen**.
- Neue Fassungen eines Bildes bekommen eine neue Versionsnummer; alte bleiben zum Vergleich liegen.
- Vorlagen, aus denen Bilder gerendert werden (z. B. HTML/SVG für Mock-Screenshots), liegen in `images/src/` mit demselben Namen wie das Bild.
  PNG neu rendern (Hochformat 390 × 844, doppelte Auflösung), im Ordner `spec/images` ausführen:
  `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --hide-scrollbars --force-device-scale-factor=2 --window-size=390,844 --virtual-time-budget=2000 --screenshot="$PWD/ingame-mock-v2.png" "file://$PWD/src/ingame-mock-v2.html"`
