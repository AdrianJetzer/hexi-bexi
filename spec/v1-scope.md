# Umfang Version 1

Status: **v1, abgestimmt**. Zusammenfassung aus den übrigen Spezifikations-Dokumenten; Details stehen dort.

Ziel von Version 1: ein **vollständig spielbares, gut aussehendes** Spiel für **Android-Handys**, als **interner Test** im Play Store.

## Drin

### Spiel ([game-rules.md](game-rules.md))
- Hexagon-Raster **6 × 9**, Hexagons unten flach.
- Start mit **15 Hexagons**, ruhiger **Level-Modus ohne Zeitdruck** (endlos).
- **Level-Up** bei wachsenden Punktschwellen (100, 250, 475 …) bringt **10 neue Hexagons** (mit **3D-Drehung**); Mindestlänge steigt (3/4/5); Knopf **„Neue Buchstaben“** (3 für 20 Punkte).
- Platzwahl: zuerst tiefste Löcher, sonst tiefste freie Plätze, bei Gleichstand zufällig.
- Buchstaben **gewichtet nach Häufigkeit** mit **Vokal-Ausgleich** und **Wort-Hilfe** (Vorausschau); **5 Schwierigkeitsstufen** (nur Hilfe), Rekord pro Stufe.
- **Wörter wischen** über Nachbarn, kein Zurückwischen, Prüfung beim Loslassen.
- Gültige Wörter **verschwinden**, Löcher bleiben offen.
- **Punkte** = 5 · n · (n − 1).
- **Rundenende** durch den Spieler, danach **Bilanz** (Punkte, Level, Rekord).
- **Deutsch**, nur A–Z, ß als SS, Wörter mit Umlauten vorerst nicht. Alle Wortformen, Eigennamen und Abkürzungen gelten.

### Screens ([screens.md](screens.md), [screen-layout.md](screen-layout.md))
- **Startbildschirm** (Titel/Logo, Spielen, Rekord, Einstellungen).
- **Spiel** mit Infobereich (Punkte, Rekord, letztes Wort, Level mit Fortschritt, Knopf „Neue Buchstaben“) und Menü-Knopf („Runde beenden?“).
- **Bilanz** (Punkte, erreichtes Level, Rekord, neuer Rekord; Nochmal, Menü).
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
- **Werbung und Käufe**.
- **Anleitung / Tutorial**.
- **Pause-Funktion**.
- **Wörter gezielt säen** (Ausbaustufe der Wort-Hilfe).
- **Vibration**.
- **Statistik und Wortliste** auf dem Bilanz-Screen.
- **Öffentliche Veröffentlichung** im Play Store.

## Muss vor oder während der Umsetzung geklärt werden

- **Wörterbuch:** Quellen, Aufbereitung und Format erledigt (850.724 Wörter, ~10 MB). Offen: evtl. Wortlänge begrenzen; Lizenz-Hinweis in der App.
- **Quelle für Musik und Soundeffekte**, Liste der Sounds.
- **Sprites** für das Theme Kosmisch (Hexagon vorne/hinten, Rahmen, Hintergrund-Ebenen, Logo).
- Farbpalette und Schrift für die Buchstaben.
- Feintuning von Level-Schwellen, Nachschub, Knopf-Kosten und Vokal-Ausgleich durch Testspiele.

## Fertig, wenn

- Eine Runde lässt sich vom Startbildschirm bis zur Bilanz spielen, alle Regeln oben funktionieren.
- Alle vier Screens und ihre Übergänge funktionieren.
- Theme Kosmisch mit allen genannten Effekten, Sound und Musik ist eingebaut.
- Läuft auf einem Android-10-Mittelklasse-Handy flüssig mit 60 fps.
- Steht als interner Test im Play Store.

## Verlauf

- **v1:** Umfang aus den Blöcken 1–4 zusammengestellt, inklusive „Fertig, wenn“. Abgestimmt.
