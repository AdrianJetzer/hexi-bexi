# CLAUDE.md

## Zusammenarbeit: erst abstimmen, dann bauen

- **Nicht einfach loslegen.** Bevor du Dateien anlegst oder änderst, Code schreibst oder etwas installierst, stimme mit mir ab, *was* gebaut wird und *wie*.
- **Keine Antwort heißt keine Zustimmung.** Wenn ich bei einer Frage nichts auswähle oder „keine Präferenz“ angebe, triff keine Entscheidung für mich. Frag nach.
- **Ideen werden gemeinsam entwickelt.** Mach Vorschläge und stell Rückfragen, aber setz nichts um, bevor ich ausdrücklich zugestimmt habe.
- **Kleine Schritte.** Beschreib kurz, was du als Nächstes vorhast, und warte auf mein Okay, bevor du größere Arbeit anfängst.
- **Bremse respektieren.** Wenn ich „stop“, „warte“ oder „hold your horses“ sage, hörst du sofort auf und wartest auf mich.

## Vorgehen

- **Zuerst Architektur und Anforderungen**, danach erst Implementierung.
- Die **Spezifikation** liegt in `spec/` (Übersicht: `spec/README.md`, Bilder in `spec/images/`). Abgestimmte Anforderungen, Skizzen und offene Fragen kommen dorthin.

## Anforderungen

- **Plattform:** Handy-Game, **Android first**. Später soll es **auch auf iOS** laufen. Architekturentscheidungen dürfen iOS nicht verbauen.
- **Optik ist Pflicht:** Das Spiel MUSS gut aussehen und **premium** wirken.
  - Schöne, selbst gebaute Grafik-Sprites, **keine Pixel Art**.
  - **Tolle Lichteffekte.**

## Technik

- Engine: **Godot** (Standard-Editor, kein Spezial-Build).
- Entwicklungsumgebung: **Godot-Editor** (Standard), keine externe IDE.
- Sprache: **GDScript**. Begründung: Standardweg von Godot, volle Android- und iOS-Unterstützung, beste Doku und Community.
- Native Android- oder iOS-Plugins (z. B. Store, Login) erst, wenn wir sie wirklich brauchen. Darüber entscheiden wir dann gesondert.

## Stand

- **Godot 4.7** ist auf diesem Mac installiert (`~/Downloads/Godot.app`).
- Projekt: `letter-tetris/` (Projektname „LetterTetris“), Renderer **Mobile**, Hochformat.
- Spielidee (Arbeitstitel „Letter Tetris“): Wortspiel mit Buchstaben in 3D-Kristall-Hexagons (Raster 5 × 6), **Lauf-Modus (Roguelike)** mit Aufträgen, Münzen und Hilfen. Details in `spec/` (Einstieg: `spec/README.md`, Lauf: `spec/run-mode.md`).
- Spielbar: Lauf-Modus mit Auftragswahl, Hilfen (Nachfüllen, Tauschen, Tipp, Ersetzen), Lösung am Ende, Bilanz.
- Noch offen u. a.: Effekte (Zerspringen, Nebel), Optik von Karten/Knöpfen, Start- und Einstellungs-Screen, Sound, Test auf echtem Gerät, Spielname.
- Tests: GUT, Aufruf `tools/run-tests.sh`. Wörterbuch bauen: `tools/dictionary/build.sh`.
- Git: Feature-Branches, Commit nach jedem Schritt, **Push nur auf Zuruf**.

## Sonstiges

- Sprache für Antworten: Deutsch.
