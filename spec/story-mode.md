# Story-Modus (Kapitel mit Themen)

Status: **Konzept v2**, noch nicht umgesetzt. Offene Fragen aus v1 sind geklärt; Details (Bildschirm-Gestaltung, Themenlisten) werden vor dem Bau abgestimmt.

**Grundsatz:** Die Spielregeln sind in allen Modi gleich (Münzen, Preise, Draft).

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
- **Nur Wörter aus einem Stück** (fürs Erste): Themenwörter mit Leerzeichen oder Bindestrich (BUENOS AIRES, NEU-DELHI, COSTA RICA) werden weggelassen.

## Kapitel-Auswahl

- **Pfad durchs All:** Die Kapitel sind Stationen (wie Planeten) auf einem Weg; man fliegt von Station zu Station. Jede Station zeigt Symbol, Name und Sterne; gesperrte Stationen sind gedimmt mit Schloss.

## Wörter und Steine

- **Das Spiel versteckt das Wort:** Zu Beginn jedes Levels wählt es ein Themenwort passender Länge (z. B. BANANE) und legt dessen Buchstaben als zusammenhängenden Weg ins Feld, dazu Füllbuchstaben (wie die Wort-Hilfe beim Tauschen/Magnet). Der Spieler muss nicht raten, ob das Wort überhaupt möglich ist.
- **Es zählt jedes Themenwort** der Kategorie mit genau passender Länge: Hat das Spiel APFEL versteckt und der Spieler findet BIRNE, zählt BIRNE.
- **Andere Wörter zählen nicht** in Themen-Zeilen (ein beliebiges Wort gleicher Länge wird abgelehnt und wackelt).
- **Steigerung über 20 Level:**
  1. Wortlänge: von kurzen (KIWI, MANGO) zu langen (PFLAUME, ERDBEERE).
  2. Ablenkung (Füllbuchstaben und Weg des Wortes):

     | Level | Füllbuchstaben | Weg des Wortes |
     |---|---|---|
     | 1–5 | wenige (Feld etwa halb voll) | eher gerade |
     | 6–15 | mehr (Feld etwa ¾ voll) | mit Knicken |
     | 16–20 | Feld fast voll | verwinkelt; Buchstaben des Wortes kommen auch als Ablenkung vor |
  3. Später evtl. mehrere Themenwörter pro Level.
- **Kein Auffüllen:** Das Spiel sorgt selbst dafür, dass die richtigen Buchstaben für ein Themenwort liegen.
- Die Block-Zeilen zeigen weiter die Länge; dazu ein **Themen-Symbol** (z. B. 🍎), damit klar ist, was gesucht wird.

## Scheitern und Sterne

- **Scheitern nur durch Aufgeben:** Wer das Wort nicht findet, gibt auf. Das Kapitel ist nicht geschafft und kann neu gestartet werden. (Kein Zeitlimit, keine Leben.)
- **Sterne (1–3)** für ein geschafftes Kapitel, je nachdem, wie wenige Hilfen gebraucht wurden → Grund, ein Kapitel nochmals zu spielen.

## Hilfen

- **Münzen und Preise wie im Lauf** (100 Münzen pro Level, gleiche Preise).
- **Draft wie im Lauf:** Start mit **Rätsel-Tipp** und **Lösen** (immer dabei; **kein Auffüllen**, siehe oben). Power-ups nach Level 5, 10 und 15 (je 2 zufällige Hilfen einer Stufe). Nach Level 20 ist das Kapitel geschafft.
- Die bekannten Hilfen behalten ihren Sinn (Tipp, Scan, Vervollständigen zeigen ein **Themenwort**).
- **Neu: Rätsel-Tipp** (nur im Story-Modus, z. B. 50 Münzen): zeigt über den Blöcken einen kurzen Rätselsatz zum versteckten Wort, z. B. „Rote Frucht aus dem Süden“, „Hauptstadt von Italien“.
  - **Zweite Stufe:** ein weiterer Kauf zeigt den **Anfangsbuchstaben** („Beginnt mit G“).
  - Jedes Themenwort braucht dafür einen Rätselsatz (Claude schreibt sie, Adrian prüft).

## Voraussetzung: Umlaute

- Viele schöne Themenwörter haben Umlaute (ÄPFEL, MÖHRE, ZÜRICH). Deshalb kommen vorher **Ä, Ö, Ü** ins ganze Spiel (eigener Schritt, siehe [game-rules.md](game-rules.md), „Sprache“).
- **ß bleibt SS** (STRASSE), kein eigener Stein.

## Offen

- Gestaltung des Pfads durchs All (Stationen, Flug-Animation).
- Rätselsätze je Themenwort (Claude schreibt, Adrian prüft).
- Genaue Zahl der Füllbuchstaben je Level (Feintuning beim Bau).

## Verlauf

- **v1:** Konzept aus dem Brainstorming: Kapitel mit Kategorien (≥ 50 Wörter), Ziel Level 20, versteckte Themenwörter, jedes Themenwort passender Länge zählt, Scheitern nur durch Aufgeben, Sterne, Rätsel-Tipp, Umlaute (ß = SS) als Voraussetzung.
- **v2:** Geklärt: Münzen/Preise und Draft wie im Lauf (Grundsatz: Regeln überall gleich); Start mit Rätsel-Tipp und Lösen, kein Auffüllen; Kapitel-Auswahl als Pfad durchs All; nur Wörter aus einem Stück; Versteck-Stärke steigt über die 20 Level.
