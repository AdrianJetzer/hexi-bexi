# Story-Modus (Kapitel mit Themen)

Status: **v3, erste Version umgesetzt** (Kapitel Früchte, Tiere, Gemüse). Screenshots: [Pfad](images/story-path-v1.png), [Rätsel](images/story-riddle-v1.png), [Kapitel geschafft](images/story-done-v1.png).

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
- Themenlisten sind kleine Textdateien je Kategorie (`data/story/<kapitel>.txt`, Zeilen „WORT;Rätselsatz“), **von Hand kuratiert** und **nach Häufigkeit sortiert** (bekannte Wörter zuerst). Erste Kapitel: Früchte (54 Wörter), Tiere (88), Gemüse (52).
- **Nur Wörter aus einem Stück** (fürs Erste): Themenwörter mit Leerzeichen oder Bindestrich (BUENOS AIRES, NEU-DELHI, COSTA RICA) werden weggelassen.

## Einstieg

- In den **Einstellungen** gibt es den Modus **„Story“** (neben einfach / mittel / schwierig). Wer ihn wählt, sieht den Pfad mit den Kapiteln; im Pfad führt „Modus wechseln“ zurück in die Einstellungen.
- Startet die App im Story-Modus, erscheint zuerst der Pfad.

## Kapitel-Auswahl

- **Pfad durchs All:** Die Kapitel sind Stationen (runde, leuchtende Planeten mit Anfangsbuchstaben) auf einem Weg von unten nach oben, verbunden durch eine Linie. Darunter Name und Sterne (☆☆☆ … ★★★); gesperrte Stationen sind gedimmt mit „gesperrt“.
- **Freischalten:** Früchte ist offen; ein Kapitel wird frei, sobald das vorherige geschafft ist.
- Erste, einfache Version; die schöne Gestaltung (Flug-Animation, Planeten) folgt.

## Wörter und Steine

- **Das Spiel versteckt das Wort:** Zu Beginn jedes Levels wählt es ein Themenwort passender Länge (z. B. BANANE) und legt dessen Buchstaben als zusammenhängenden Weg ins Feld, dazu Füllbuchstaben (wie die Wort-Hilfe beim Tauschen/Magnet). Der Spieler muss nicht raten, ob das Wort überhaupt möglich ist.
- **Es zählt jedes Themenwort** der Kategorie mit genau passender Länge: Hat das Spiel APFEL versteckt und der Spieler findet BIRNE, zählt BIRNE.
- **Andere Wörter zählen nicht** in Themen-Zeilen (ein beliebiges Wort gleicher Länge wird abgelehnt und wackelt).
- **Steigerung über 20 Level:**
  1. Wortlänge je Stufe à 5 Level: 3–5, 4–6, 5–7, 6–8 Buchstaben; dabei zuerst aus den bekanntesten 40 %, dann 60 %, 85 %, zuletzt allen Wörtern der Liste. Kein Wort kommt doppelt, solange noch andere übrig sind.
  2. Ablenkung (Füllbuchstaben und Weg des Wortes):

     | Level | Füllbuchstaben | Weg des Wortes |
     |---|---|---|
     | 1–5 | Feld zu 50 % voll | eher gerade |
     | 6–10 | 65 % | mit Knicken |
     | 11–15 | 75 % | mit Knicken |
     | 16–20 | 88 % (fast voll) | verwinkelt; Buchstaben des Wortes kommen auch als Ablenkung vor |

     Umgesetzt ist der Füllgrad; den Weg des Wortes wählt die Wort-Hilfe (noch nicht gezielt gerade/verwinkelt).
  3. Später evtl. mehrere Themenwörter pro Level.
- **Kein Auffüllen:** Das Spiel sorgt selbst dafür, dass die richtigen Buchstaben für ein Themenwort liegen.
- Die Block-Zeilen zeigen weiter die Länge; dazu ein **Themen-Symbol** (z. B. 🍎), damit klar ist, was gesucht wird.

## Scheitern und Sterne

- **Scheitern nur durch Aufgeben:** Wer das Wort nicht findet, gibt auf. Das Kapitel ist nicht geschafft und kann neu gestartet werden. (Kein Zeitlimit, keine Leben.)
- **Sterne (1–3)** für ein geschafftes Kapitel: ★★★ = keine Hilfe gekauft, ★★ = höchstens 500 Münzen ausgegeben, ★ = geschafft. Gespeichert wird die beste Wertung je Kapitel.
- Anzeige im Spiel: oben in der Mitte der Kapitel-Name, links „Level 3 von 20“, unter dem Feld „Noch n Level bis zum Power-up“ bzw. nach dem letzten Power-up „Noch n Level bis zum Ziel“.

## Hilfen

- **Münzen und Preise wie im Lauf** (100 Münzen pro Level, gleiche Preise).
- **Draft wie im Lauf:** Start mit **Rätsel-Tipp** und **Lösen** (immer dabei; **kein Auffüllen**, siehe oben). Power-ups nach Level 5, 10 und 15 (je 2 zufällige Hilfen einer Stufe). Nach Level 20 ist das Kapitel geschafft.
  - **Teilen** und **Zeile streichen** werden im Story-Modus nicht angeboten (nur eine Zeile pro Level).
- Die bekannten Hilfen behalten ihren Sinn (Tipp, Scan, Vervollständigen zeigen ein **Themenwort**).
- **Neu: Rätsel-Tipp** (nur im Story-Modus, 50 Münzen, einmal pro Level): zeigt über der Info-Zeile einen kurzen Rätselsatz zum versteckten Wort, z. B. „Gelb, krumm und bei Affen beliebt“. Für den Anfangsbuchstaben gibt es den normalen **Tipp**.
  - Jedes Themenwort braucht dafür einen Rätselsatz (Claude schreibt sie, Adrian prüft).

## Voraussetzung: Umlaute

- Viele schöne Themenwörter haben Umlaute (ÄPFEL, MÖHRE, ZÜRICH). Deshalb kommen vorher **Ä, Ö, Ü** ins ganze Spiel (eigener Schritt, siehe [game-rules.md](game-rules.md), „Sprache“).
- **ß bleibt SS** (STRASSE), kein eigener Stein.

## Offen

- Gestaltung des Pfads durchs All (Planeten, Flug-Animation).
- Weg des versteckten Wortes gezielt gerade bzw. verwinkelt legen.
- Rätselsätze und Wortlisten nach Testspielen verbessern.
- Weitere Kapitel (z. B. Länder, Musikinstrumente).

## Verlauf

- **v1:** Konzept aus dem Brainstorming: Kapitel mit Kategorien (≥ 50 Wörter), Ziel Level 20, versteckte Themenwörter, jedes Themenwort passender Länge zählt, Scheitern nur durch Aufgeben, Sterne, Rätsel-Tipp, Umlaute (ß = SS) als Voraussetzung.
- **v2:** Geklärt: Münzen/Preise und Draft wie im Lauf (Grundsatz: Regeln überall gleich); Start mit Rätsel-Tipp und Lösen, kein Auffüllen; Kapitel-Auswahl als Pfad durchs All; nur Wörter aus einem Stück; Versteck-Stärke steigt über die 20 Level.
- **v3:** Erste Version umgesetzt: Modus „Story“ in den Einstellungen, Pfad mit Früchte / Tiere / Gemüse, versteckte Themenwörter (nach Häufigkeit und Länge gestaffelt), Füllgrad je Stufe, Rätsel-Tipp (50, ohne zweite Stufe), Ziel Level 20, Sterne, Teilen/Streichen nicht im Story-Modus.
