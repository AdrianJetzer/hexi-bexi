# Optik und Ton

Status: **Entwurf v1**. Stil und Effekte für Version 1 abgestimmt; Quellen für Musik und Sound offen.

Grundanforderung (siehe `../CLAUDE.md`): Das Spiel MUSS gut aussehen und **premium** wirken. Schöne, selbst gebaute Sprites, **keine Pixel Art**, **tolle Lichteffekte**.

## Allgemein

### Themes
- **Später** kann der Spieler selbst ein **Theme** wählen. Die **Musik passt** jeweils zum Theme.
- **Version 1 hat genau ein Theme: Kosmisch / Sci-Fi.**
- Von Anfang an so bauen, dass Themes **austauschbar** sind: Grafiken, Farben, Hintergrund, Effekte, Sounds und Musik gehören zum Theme, nicht fest in den Spielcode. (Gleiches Prinzip wie bei den Sprachen.)

### Wie die Grafik entsteht
- **Mix aus Sprites und Godot-Effekten:**
  - Die **Grund-Sprites** (Hexagons, Rahmen, Hintergrund-Ebenen) werden selbst gebaut, z. B. in Blender oder einem Grafikprogramm.
  - **Licht, Leuchten, Partikel und die 3D-Drehung** macht Godot **live** (Shader, 2D-Lichter, Normal Maps).
- Live-Effekte kosten Leistung: **früh auf einem echten Android-Gerät testen.**

### Ton
- Version 1 hat **Soundeffekte** und **Musik** (beides in den Einstellungen abschaltbar, siehe [screens.md](screens.md)).
- **Quelle** für Musik und Soundeffekte: **später festlegen** (z. B. selbst machen, kaufen, lizenzfreie Bibliothek, KI-generiert).

## Theme: Kosmisch / Sci-Fi (Version 1)

### Hintergrund
- **Farbiger Weltraumnebel** in Violett, Blau und Türkis, mit Sternen.
- **Leicht animiert:** Nebel wabert langsam, Sterne funkeln, mehrere Tiefenebenen (Parallax).

### Spielfeld-Rahmen
- **Dunkles Metall**, raumschiffartig.
- Die **Zickzack-Innenkante leuchtet** als Energie-Linie.

### Hexagons
- **Vorderseite:** **Kristall / Glas**, durchscheinend, mit Licht im Inneren; der **Buchstabe leuchtet hell**.
- **Rückseite** (beim Erscheinen): **milchiger, frostiger Kristall**; der Buchstabe ist nur als **spiegelverkehrter Schatten** erkennbar. Beim Drehen wird er klar.

### Effekte
| Moment | Effekt |
|---|---|
| Neues Hexagon erscheint | Fade-in mit milchiger Rückseite, dann 3D-Drehung auf die Vorderseite, eindrucksvoller Sound (siehe [game-rules.md](game-rules.md)) |
| Wischen | **Leuchtender Energie-Strahl** verbindet die gewählten Kristalle; diese leuchten von innen heller |
| Wort gefunden | **Kristalle zerspringen** in leuchtende Splitter, die verglimmen |
| Ungültiges Wort | **Kurzes Wackeln** der gewählten Hexagons, rötliches Aufleuchten, dezenter Ton |
| Game-Over | **Licht erlischt:** Hexagons gehen nacheinander aus, die Leuchtkante des Rahmens erlischt; danach Game-Over-Screen |

## Später festlegen

- Quelle für **Musik** und **Soundeffekte**.
- **Liste der Soundeffekte** und Musikstücke.
- Farbpalette und Style Guide für das Theme Kosmisch (genaue Farben, Schrift für die Buchstaben).
- Gestaltung von Logo/Titel und Screen-Übergängen.
- Weitere Themes.

## Verlauf

- **v1:** Theme-System (später wählbar), Version 1 = Kosmisch / Sci-Fi. Kristall-Hexagons, milchige Rückseite, Metallrahmen mit Leuchtkante, animierter Nebel, Effekte für Wischen, Wort, ungültiges Wort und Game-Over. Grafik als Mix aus Sprites und Godot-Effekten. Quellen für Ton offen.
