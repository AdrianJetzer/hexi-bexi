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

- **Godot 4.7** ist auf diesem Mac installiert.
- Projekt: `letter-tetris/` (Projektname „LetterTetris“), vom Nutzer im Godot-Editor angelegt, noch leer.
  - Renderer: **Mobile** (passend zu Android first; Desktop-Vorschau = Handy-Darstellung).
- Spielidee: Arbeitstitel „Letter Tetris“, Details und Anforderungen **noch nicht besprochen**.
- Der frühere Prototyp `neon-drift/` ist entfernt.

## Sonstiges

- Sprache für Antworten: Deutsch.
