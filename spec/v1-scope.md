# Umfang Version 1

Status: **v1, abgestimmt**. Zusammenfassung aus den übrigen Spezifikations-Dokumenten; Details stehen dort.

Ziel von Version 1: ein **vollständig spielbares, gut aussehendes** Spiel für **Android-Handys**, als **interner Test** im Play Store.

## Drin

### Spiel ([game-rules.md](game-rules.md))
- Hexagon-Raster **6 × 9**, Hexagons unten flach.
- Start mit **2 gefüllten Reihen**.
- Neue Hexagons **erscheinen** im **festen Takt** (3 s, alle 30 s 10 % schneller, min. 0,8 s) mit Fade-in und **3D-Drehung**.
- Platzwahl: zuerst tiefste Löcher, sonst tiefste freie Plätze, bei Gleichstand zufällig.
- Buchstaben **gewichtet nach Häufigkeit** mit **Vokal-Ausgleich**.
- **Wörter wischen** über Nachbarn, Mindestlänge 3, kein Zurückwischen, Prüfung beim Loslassen.
- Gültige Wörter **verschwinden**, Löcher bleiben offen.
- **Punkte** = 5 · n · (n − 1).
- **Spielende**, wenn kein Platz mehr frei ist.
- **Deutsch**, nur A–Z, ß als SS, Wörter mit Umlauten vorerst nicht. Alle Wortformen, Eigennamen und Abkürzungen gelten.

### Screens ([screens.md](screens.md), [screen-layout.md](screen-layout.md))
- **Startbildschirm** (Titel/Logo, Spielen, Rekord, Einstellungen).
- **Spiel** mit Infobereich (Punkte, Rekord, letztes Wort, Tempo-Stufe) und Menü-Knopf („Runde beenden?“).
- **Game-Over** (Punkte, Rekord, neuer Rekord; Nochmal, Menü).
- **Einstellungen** (Soundeffekte, Musik, Rekord zurücksetzen).
- Spiel hält an, wenn die App in den Hintergrund geht.

### Optik und Ton ([look-and-sound.md](look-and-sound.md))
- **Ein Theme: Kosmisch / Sci-Fi** (Kristall-Hexagons, Metallrahmen mit Leuchtkante, animierter Nebel).
- Effekte: Erscheinen + Drehung, Energie-Strahl beim Wischen, Kristalle zerspringen, Wackeln bei ungültigem Wort, Licht erlischt bei Game-Over.
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
- **Werbung und Käufe**.
- **Anleitung / Tutorial**.
- **Pause-Funktion**.
- **Ausgefeilte Füll-Logik** (Version 1 nutzt die einfache Regel).
- **Vibration**.
- **Statistik und Wortliste** auf dem Game-Over-Screen.
- **Öffentliche Veröffentlichung** im Play Store.

## Muss vor oder während der Umsetzung geklärt werden

- **Wörterbuch:** Quellen festgelegt (Trennmuster + Wiktionary); Aufbereitung, Abdeckung und Speicherformat noch prüfen.
- **Quelle für Musik und Soundeffekte**, Liste der Sounds.
- **Sprites** für das Theme Kosmisch (Hexagon vorne/hinten, Rahmen, Hintergrund-Ebenen, Logo).
- Farbpalette und Schrift für die Buchstaben.
- Feintuning von Tempo und Vokal-Ausgleich durch Testspiele.

## Fertig, wenn

- Eine Runde lässt sich vom Startbildschirm bis zum Game-Over spielen, alle Regeln oben funktionieren.
- Alle vier Screens und ihre Übergänge funktionieren.
- Theme Kosmisch mit allen genannten Effekten, Sound und Musik ist eingebaut.
- Läuft auf einem Android-10-Mittelklasse-Handy flüssig mit 60 fps.
- Steht als interner Test im Play Store.

## Verlauf

- **v1:** Umfang aus den Blöcken 1–4 zusammengestellt, inklusive „Fertig, wenn“. Abgestimmt.
