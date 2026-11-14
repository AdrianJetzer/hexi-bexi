# Umfang Version 1

Status: **v3, Entwurf**. Zusammenfassung aus den übrigen Spezifikations-Dokumenten; Details stehen dort.

Ziel von Version 1: ein **vollständig spielbares, gut aussehendes** Spiel für **Android-Handys**, als **interner Test** im Play Store.

## Drin

### Spiel ([game-rules.md](game-rules.md))
- Hexagon-Raster **5 × 6**, Hexagons unten flach.
- **Lauf-Modus (Roguelike)** ohne Zeitdruck ([run-mode.md](run-mode.md)): Start mit **10 Hexagons** und **0 Münzen**; jedes Level ist ein **Auftrag** aus **Block-Zeilen** über dem Spielfeld (1–3 Zeilen, je 3–8 Blöcke), der nächste kommt automatisch; Kurve für Level 1–10, danach Block-Budget; Feld bleibt zwischen den Levels liegen.
- Nach jedem gefundenen Wort automatisch **Wortlänge − 1** neue Steine; die Buchstaben des Worts **fliegen in die Blöcke**.
- **Münzen** für gelöste Aufträge (fest 100); Hilfen: **Auffüllen** (5 Steine, 100), **5 Steine tauschen** (50), **Aufräumen** (die 5 am wenigsten hilfreichen Steine, 100), **Tipp** (100 je Buchstabe, gezeigte blinken weiter); **Lösung** beim Ende des Laufs, **Stein ersetzen** (100), **Lösen** (ganzer Auftrag, vorläufig 100 zum Testen, Ziel 500, ohne Belohnung). Neue Hexagons erscheinen mit **3D-Drehung**.
- Platzwahl: zuerst tiefste Löcher, sonst tiefste freie Plätze, bei Gleichstand zufällig.
- Buchstaben **gewichtet nach Häufigkeit** mit **Vokal-Ausgleich** und **Wort-Hilfe** (Vorausschau); Stärke der Hilfe folgt dem **Level** (5 Hilfe-Stufen, nicht wählbar).
- **Wörter wischen** über Nachbarn, kein Zurückwischen, Prüfung beim Loslassen.
- Gültige Wörter **verschwinden**, Löcher bleiben offen.
- Angenommen werden nur Wörter, die **genau** in eine freie Zeile passen; andere wackeln. **Symbole statt Text.**
- **Ende** nur durch **Aufgeben**, danach **Bilanz** (erreichtes Level, Rekord) und neuer Lauf ab Level 1. **Rekord** = höchstes Level.
- **Deutsch**, nur A–Z, ß als SS, Wörter mit Umlauten vorerst nicht. Alle Wortformen gelten; Eigennamen und Abkürzungen nicht (außer sie sind auch normale Wörter).

### Screens ([screens.md](screens.md), [screen-layout.md](screen-layout.md))
- **Startbildschirm** (Titel/Logo, Spielen, Rekord, Einstellungen).
- **Spiel** mit Auftrags-Zeilen, Münzen, Level, Rekord, Hilfe-Knöpfen und Knopf „Aufgeben“.
- **Bilanz** (erreichtes Level, Rekord, neuer Rekord; Nochmal, Menü).
- **Einstellungen** (Soundeffekte, Musik, Rekord zurücksetzen).
- Spiel hält an, wenn die App in den Hintergrund geht.

### Optik und Ton ([look-and-sound.md](look-and-sound.md))
- **Ein Theme: Kosmisch / Sci-Fi** (Kristall-Hexagons, Metallrahmen mit Leuchtkante, animierter Nebel).
- Effekte: Erscheinen + Drehung, Energie-Strahl beim Wischen, Kristalle zerspringen, Wackeln bei ungültigem Wort, Licht erlischt beim Rundenende.
- **Soundeffekte und Musik.**

### Technik ([tech.md](tech.md))
- Godot 4.7, GDScript, Mobile-Renderer.
- Android 10+, nur Handys, stabile 60 fps.
- Komplett **offline**, **keine Datensammlung**, Wörterbuch in der App.
- **Rekord lokal** gespeichert.
- Architektur mit **austauschbaren Sprachen, Themes und Spielwerten**.

## Bewusst nicht drin (später)

- **iOS**.
- **Tablets**.
- **Weitere Sprachen** und **Umlaute**.
- **Weitere Themes** und Theme-Auswahl.
- **Online-Ranglisten** (Google Play Games, Game Center).
- **Werbung und Käufe** (auch Münzen kaufen).
- Lauf-Modus-Erweiterungen: **Bosse**, **Laden und Vorteile**, **besondere Steine**, **Bonus-Münzen**, **Meta-Fortschritt**.
- **Anleitung / Tutorial**.
- **Pause-Funktion**.
- **Vibration**.
- **Statistik und Wortliste** auf dem Bilanz-Screen.
- **Öffentliche Veröffentlichung** im Play Store.

## Muss vor oder während der Umsetzung geklärt werden

- **Wörterbuch:** Quellen, Aufbereitung und Format erledigt (804.367 Wörter ohne Eigennamen, Abkürzungen, Akronyme und römische Zahlen, ~10 MB). Offen: evtl. Wortlänge begrenzen; Lizenz-Hinweis in der App.
- **Quelle für Musik und Soundeffekte**, Liste der Sounds.
- **Sprites** für das Theme Kosmisch (Hexagon vorne/hinten, Rahmen, Hintergrund-Ebenen, Logo).
- Farbpalette und Schrift für die Buchstaben.
- Feintuning von Auftrags-Kurve, Münz-Preisen, Hilfe-Stufen und Vokal-Ausgleich durch Testspiele.

## Fertig, wenn

- Ein Lauf lässt sich vom Startbildschirm über mehrere Aufträge bis zur Bilanz spielen, alle Regeln oben funktionieren.
- Alle Screens und ihre Übergänge funktionieren.
- Theme Kosmisch mit allen genannten Effekten, Sound und Musik ist eingebaut.
- Läuft auf einem Android-10-Mittelklasse-Handy flüssig mit 60 fps.
- Steht als interner Test im Play Store.

## Verlauf

- **v1:** Umfang aus den Blöcken 1–4 zusammengestellt, inklusive „Fertig, wenn“. Abgestimmt.
- **v2:** Lauf-Modus statt ruhigem Level-Modus: Aufträge mit Auftragswahl, Münzen und Hilfen, Aufgeben, Rekord = höchstes Level; gezieltes Säen jetzt drin; Lauf-Erweiterungen auf später.
- **v3:** Aufträge als Block-Zeilen ohne Wahl und ohne Text; Säen, Zuglimit und Auftragswahl entfallen.
