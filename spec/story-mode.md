# Story-Modus (Kapitel mit Themen)

Status: **Konzept v1**, noch nicht umgesetzt. Ergebnis eines Brainstormings; Details werden vor dem Bau abgestimmt.

## Warum

„Möglichst hohes Level erreichen“ (Lauf-Modus, siehe [run-mode.md](run-mode.md)) macht auf Dauer wenig Spaß. Der Story-Modus gibt ein **klares Ziel** und ein **Thema**: Jedes Kapitel ist eine Kategorie, das Ziel ist immer **Level 20**.

## Kapitel

- Jedes Kapitel ist eine **Kategorie**, z. B. 🍎 Früchte, 🥕 Gemüse, 🐾 Tiere, 🌍 Länder, 🏛 Hauptstädte, 🚗 Automarken, 🌊 Flüsse.
- **Ziel:** Level 20 erreichen → Kapitel geschafft, das nächste wird freigeschaltet.
- **Erstes Kapitel:** Früchte.
- Reihenfolge von leicht (Früchte, Tiere) nach schwer (Flüsse, Hauptstädte).
- **Mindestens ca. 50 Wörter je Kategorie**, damit man die Lösungen nicht zu leicht auswendig lernt (unendlich wird es nicht).
  - Genug: Tiere, Früchte (mit Exoten), Gemüse, Berufe, Länder, Hauptstädte der Welt, Sportarten, Blumen/Pflanzen, Kleidung, Musikinstrumente.
  - Knapp (nachzählen): Automarken, Flüsse, Körperteile, Werkzeuge.
  - Zu klein: Farben, Planeten, Wochentage.
- Themenlisten sind kleine Textdateien je Kategorie, **von Hand kuratiert**.

## Wörter und Steine

- **Das Spiel versteckt das Wort:** Zu Beginn jedes Levels wählt es ein Themenwort passender Länge (z. B. BANANE) und legt dessen Buchstaben als zusammenhängenden Weg ins Feld, dazu Füllbuchstaben (wie die Wort-Hilfe beim Tauschen/Magnet). Der Spieler muss nicht raten, ob das Wort überhaupt möglich ist.
- **Es zählt jedes Themenwort** der Kategorie mit genau passender Länge: Hat das Spiel APFEL versteckt und der Spieler findet BIRNE, zählt BIRNE.
- **Andere Wörter zählen nicht** in Themen-Zeilen (ein beliebiges Wort gleicher Länge wird abgelehnt und wackelt).
- **Steigerung über 20 Level:**
  1. Wortlänge: von kurzen (KIWI, MANGO) zu langen (PFLAUME, ERDBEERE).
  2. Ablenkung: mehr Füllbuchstaben, verwinkelterer Weg.
  3. Später evtl. mehrere Themenwörter pro Level.
- Die Block-Zeilen zeigen weiter die Länge; dazu ein **Themen-Symbol** (z. B. 🍎), damit klar ist, was gesucht wird.

## Scheitern und Sterne

- **Scheitern nur durch Aufgeben:** Wer das Wort nicht findet, gibt auf. Das Kapitel ist nicht geschafft und kann neu gestartet werden. (Kein Zeitlimit, keine Leben.)
- **Sterne (1–3)** für ein geschafftes Kapitel, je nachdem, wie wenige Hilfen gebraucht wurden → Grund, ein Kapitel nochmals zu spielen.

## Hilfen

- Die bekannten Hilfen behalten ihren Sinn (Tipp, Scan, Vervollständigen zeigen ein **Themenwort**; Auffüllen legt Buchstaben nach).
- **Neu: Rätsel-Tipp** (nur im Story-Modus, z. B. 50 Münzen): zeigt über den Blöcken einen kurzen Rätselsatz zum versteckten Wort, z. B. „Rote Frucht aus dem Süden“, „Hauptstadt von Italien“.
  - **Zweite Stufe:** ein weiterer Kauf zeigt den **Anfangsbuchstaben** („Beginnt mit G“).
  - Jedes Themenwort braucht dafür einen Rätselsatz (Claude schreibt sie, Adrian prüft).

## Voraussetzung: Umlaute

- Viele schöne Themenwörter haben Umlaute (ÄPFEL, MÖHRE, ZÜRICH). Deshalb kommen vorher **Ä, Ö, Ü** ins ganze Spiel (eigener Schritt, siehe [game-rules.md](game-rules.md), „Sprache“).
- **ß bleibt SS** (STRASSE), kein eigener Stein.

## Offen

- Münzen und Preise im Story-Modus (wie im Lauf, oder eigene Werte?).
- Welche Power-ups/Hilfen man im Kapitel hat (Draft wie im Lauf oder feste Auswahl?).
- Kapitel-Auswahl als Bildschirm (Optik, Fortschritt, Sterne).
- Leerzeichen und Bindestriche in Themenwörtern (BUENOS AIRES, NEU-DELHI): weglassen oder zusammenschreiben?
- Wie stark „versteckt“ wird (Anzahl Füllbuchstaben je Level).

## Verlauf

- **v1:** Konzept aus dem Brainstorming: Kapitel mit Kategorien (≥ 50 Wörter), Ziel Level 20, versteckte Themenwörter, jedes Themenwort passender Länge zählt, Scheitern nur durch Aufgeben, Sterne, Rätsel-Tipp, Umlaute (ß = SS) als Voraussetzung.
