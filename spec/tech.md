# Technik und Rahmen

Status: **Entwurf v1**. Technische Rahmenbedingungen für Version 1 abgestimmt; Architektur folgt als eigener Schritt.

## Engine und Werkzeuge

- Engine: **Godot 4.7**, Standard-Editor (kein Spezial-Build).
- Entwicklungsumgebung: **Godot-Editor**, keine externe IDE.
- Sprache: **GDScript**.
- Renderer: **Mobile** (gleiche Darstellung in der Vorschau am Mac wie auf dem Handy).
- Projektordner: `letter-tetris/` (Spezifikation in `spec/`).
- Native Android- oder iOS-Plugins nur, wenn wirklich nötig; darüber wird gesondert entschieden.
- Hilfswerkzeuge außerhalb von Godot liegen in `tools/` (z. B. `tools/dictionary/` zum Bauen der Wortliste, Python 3).

## Plattformen und Geräte

- **Android first.** **iOS später**; Architekturentscheidungen dürfen iOS nicht verbauen.
- Zielgeräte: **Android-Mittelklasse ab ca. 2020** (etwa **Android 10+**).
- **Nur Handys**, keine Tablets in Version 1.
- Ausrichtung: **Hochformat** (siehe [screen-layout.md](screen-layout.md)).
- Leistung: **stabile 60 fps** auf allen Zielgeräten. Effekte früh auf einem echten Gerät testen.

## Austauschbarkeit (Architektur-Vorgaben)

- **Sprachen:** Wörterbuch, Alphabet und Buchstabenverteilung austauschbar, nichts fest im Spielcode (siehe [game-rules.md](game-rules.md)).
- **Themes:** Grafiken, Farben, Hintergrund, Effekte, Sounds und Musik austauschbar (siehe [look-and-sound.md](look-and-sound.md)).
- **Spielwerte** (Start-Hexagons, Münzen, Preise, Auftrags-Kurve usw.) als Daten, nicht fest im Code.
- **Rekord:** lokal; so bauen, dass später Online-Ranglisten (Google Play Games, Game Center) möglich sind (siehe [screens.md](screens.md)).
- **Käufe:** so bauen, dass später z. B. Theme-Käufe möglich wären.

## Geld verdienen

- **Version 1 ist kostenlos**, **ohne Werbung und ohne Käufe**.
- Spätere Monetarisierung ist offen und wird gesondert entschieden.

## Internet und Daten

- Das Spiel läuft **komplett offline**.
- **Keine Datensammlung:** kein Tracking, keine Analyse, keine Absturzberichte.
- Folge: Das **Wörterbuch ist in der App enthalten** (Größe und Lizenz beachten).
- Das Wörterbuch nutzt ein **kompaktes Binärformat** (~10 MB im Arbeitsspeicher), siehe [architecture.md](architecture.md); Quellen siehe [game-rules.md](game-rules.md).

## Veröffentlichung

- Version 1 zuerst im **Play Store als interner Test**, später öffentlich.

## Android-Build (Test aufs Handy)

- Export-Vorlage **„Android“** in `letter-tetris/export_presets.cfg`: Debug-APK nach `build/LetterTetris.apk` (nicht versioniert), nur **arm64-v8a**, Paketname vorläufig `com.lettertetris.game` (vor einer Veröffentlichung festlegen).
- **Wichtig:** Filter `*.bin`, damit das Wörterbuch (`words.bin`, `common.bin`) in die App kommt; Tests und GUT werden nicht mit exportiert.
- Voraussetzungen auf dem Mac: Godot-**Export-Vorlagen 4.7.2**, **JDK 17** (Pfad in den Editor-Einstellungen), **Android SDK** (über Android Studio). Den Debug-Schlüssel legt Godot beim ersten Export an.
- Aufs Handy: USB-Debugging einschalten, anschließen, im Editor oben rechts auf das Android-Symbol (Remote Deploy) – oder APK exportieren und installieren.

## Versionsverwaltung

- **Git** lokal im Ordner `godot-game/`, zusätzlich **GitHub** (privates Repository).
- **Eingerichtet** am 13.11.2026: Branch `main`, privates Repository `github.com/TangoPazzafini/letter-tetris`.
- Heruntergeladene Quellen und Export-Ergebnisse (APK/AAB, Signierschlüssel) sind per `.gitignore` ausgeschlossen.

## Offene Fragen

- Quelle für Musik und Soundeffekte (siehe [look-and-sound.md](look-and-sound.md)).

## Verlauf

- **v1:** Engine und Werkzeuge, Zielgeräte (Android 10+, nur Handys, 60 fps), Austauschbarkeit, kostenlos ohne Werbung, offline ohne Daten, interner Test im Play Store, Git + GitHub.
- **v1.1:** Android-Build: Export-Vorlage mit `*.bin`-Filter, Voraussetzungen.
