# Optik und Ton

Status: **Entwurf v3**. Stil und Effekte für Version 1 abgestimmt; **kein Ton, keine Musik** (v3).

Grundanforderung (siehe `../CLAUDE.md`): Das Spiel MUSS gut aussehen und **premium** wirken. Schöne, selbst gebaute Sprites, **keine Pixel Art**, **tolle Lichteffekte**.

## Allgemein

### Themes
- **Später** kann der Spieler selbst ein **Theme** wählen. 
- **Version 1 hat genau ein Theme: Kosmisch / Sci-Fi.**
- Von Anfang an so bauen, dass Themes **austauschbar** sind: Grafiken, Farben, Hintergrund und Effekte gehören zum Theme, nicht fest in den Spielcode. (Gleiches Prinzip wie bei den Sprachen.)

### Wie die Grafik entsteht
- **Das Spielfeld ist echtes 3D**, die Bedienoberfläche (Wort-Anzeige, Infobereich, Knöpfe, Screens) bleibt **2D** darüber.
  - Grund: flache Sprites wirkten nicht premium; in 3D bekommen Dicke, runde Kanten und Material echtes Licht, Spiegelungen und Schatten, und die Drehung beim Erscheinen ist eine echte 3D-Drehung.
- **Kamera:** von oben mit **leichter Perspektive** (am Rand sieht man etwas die Seiten der Hexagons).
- **Hexagons:** dickes Prisma mit **abgerundeten Kanten** und Ecken, vorerst **im Code erzeugt** (Dicke, Rundungen einstellbar; abgestimmt: Dicke ≈ 0,42 × Radius). Später kann ein Blender-Modell eingesetzt werden.
- **Material:** eigener **Kristall-Shader** (durchscheinend, Lichtbrechung, leuchtende Kante, Leuchtkern), alle Werte einstellbar.
- **Licht, Leuchten (Glow), Partikel** macht Godot **live**.
- Bilder/Texturen (z. B. Hintergrund-Nebel, Logo) können weiterhin selbst gebaut werden.
- Live-Effekte kosten Leistung: **früh auf einem echten Android-Gerät testen.**
- Prototyp zum Ausprobieren der Optik: `letter-tetris/scenes/prototypes/hex3d_proto.tscn`.

### Ton
- **Kein Ton und keine Musik** (v3, Entscheidung von Adrian): Gepiepe nervt die Leute. Das Spiel ist stumm; Rückmeldung nur über Optik und **Vibration** (kurzer Tick je verbundenem Buchstaben, abschaltbar, siehe [screens.md](screens.md)).

## Theme: Kosmisch / Sci-Fi (Version 1)

### Hintergrund
- **Farbiger Weltraumnebel** in Violett, Blau und Türkis, mit Sternen.
- **Leicht animiert:** Nebel wabert langsam, Sterne funkeln, mehrere Tiefenebenen (Parallax).

### Spielfeld-Rahmen
- **Dunkles Metall**, raumschiffartig.
- Die **Zickzack-Innenkante leuchtet** als Energie-Linie.

### Hexagons
- **Vorderseite:** **Rauchglas mit Energiekern**: dunkles, durchscheinendes Glas, **türkis glühender Kern** in der Mitte, türkis leuchtende Kante; der **Buchstabe leuchtet hell** (weiß-türkis).
- **Ausgewählt:** Kern und Kante leuchten deutlich heller türkis.
- **Rückseite** (beim Erscheinen): **gefrostetes Rauchglas mit schwachem Kern** (grau-bläulich bereift); der Buchstabe schimmert **seitenverkehrt** und dezent durch. Beim Drehen wird er klar.
- Verworfen (zum Vergleich im Prototyp erhalten): Eis-Kristall, Amethyst; Rückseiten milchig weiß, mattes Rauchglas, Metall.

### Effekte
| Moment | Effekt |
|---|---|
| Neues Hexagon erscheint | Fade-in mit milchiger Rückseite, dann 3D-Drehung auf die Vorderseite (siehe [game-rules.md](game-rules.md)) |
| Wischen | **Leuchtender Energie-Strahl** verbindet die gewählten Kristalle; diese leuchten von innen heller |
| Wort gefunden | **Kristalle zerspringen** in leuchtende Splitter, die verglimmen |
| Ungültiges Wort | **Kurzes Wackeln** der gewählten Hexagons, rötliches Aufleuchten |
| Level-Up | Ladung neuer Hexagons erscheint **nacheinander** mit Drehung (kleine Verzögerung je Hexagon) |
| Rundenende | **Licht erlischt:** Hexagons gehen nacheinander aus, die Leuchtkante des Rahmens erlischt; danach Bilanz-Screen |

## Später festlegen

- Farbpalette und Style Guide für das Theme Kosmisch (genaue Farben, Schrift für die Buchstaben).
- Gestaltung von Logo/Titel und Screen-Übergängen.
- Weitere Themes.

## Verlauf

- **v1:** Theme-System (später wählbar), Version 1 = Kosmisch / Sci-Fi. Kristall-Hexagons, milchige Rückseite, Metallrahmen mit Leuchtkante, animierter Nebel, Effekte für Wischen, Wort, ungültiges Wort und Game-Over. Grafik als Mix aus Sprites und Godot-Effekten. Quellen für Ton offen.
- **v2:** Spielfeld in **3D** (Oberfläche 2D), Kamera von oben mit leichter Perspektive, dicke Hexagons mit runden Kanten, Kristall-Shader. Vorderseite **Rauchglas mit Energiekern**, Rückseite **gefrostetes Rauchglas**.
