# Story-Modus (Kapitel mit Themen)

Status: **v5 umgesetzt** (Kapitel-Brett mit 8 Kapiteln in 2 Reihen, Dreh-Animation, Bronze / Silber / Gold). Screenshots: [Brett v1](images/chapter-board-v1.png), [Brett mit Wertungen](images/chapter-board-v2.png), [Nachbarn aufgedeckt](images/chapter-board-v3.png). Screenshots: [Pfad](images/story-path-v1.png), [Rätsel](images/riddle-overlay-v1.png), [Kapitel geschafft](images/story-done-v1.png).

**Grundsatz:** Münzen, Preise und Sterne sind in allen Modi gleich. Ausnahme: Die Story hat feste Hilfen statt Draft (v4.3).

## Warum

„Möglichst hohes Level erreichen“ (Lauf-Modus, siehe [run-mode.md](run-mode.md)) macht auf Dauer wenig Spaß. Der Story-Modus gibt ein **klares Ziel** und ein **Thema**: Jedes Kapitel ist eine Kategorie, das Ziel ist immer **Level 20**.

## Kapitel

- Jedes Kapitel ist eine **Kategorie**, z. B. 🍎 Früchte, 🥕 Gemüse, 🐾 Tiere, 🌍 Länder, 🏛 Hauptstädte, 🚗 Automarken, 🌊 Flüsse.
- **Ziel:** Level 20 erreichen → Kapitel geschafft (Freischalten siehe „Kapitel-Brett“).
- **Reihenfolge der ersten Kapitel:** Tiere (sehr einfach), Gemüse, Früchte (am schwierigsten, nach Testspiel v4.4).
- Reihenfolge von leicht (Tiere, Gemüse) nach schwer (Flüsse, Hauptstädte).
- **Mindestens ca. 50 Wörter je Kategorie**, damit man die Lösungen nicht zu leicht auswendig lernt (unendlich wird es nicht).
  - Genug: Tiere, Früchte (mit Exoten), Gemüse, Berufe, Länder, Hauptstädte der Welt, Sportarten, Blumen/Pflanzen, Kleidung, Musikinstrumente.
  - Knapp (nachzählen): Automarken, Flüsse, Körperteile, Werkzeuge.
  - Zu klein: Farben, Planeten, Wochentage.
- Themenlisten sind kleine Textdateien je Kategorie (`data/story/<kapitel>.txt`, Zeilen „WORT;Rätselsatz“), **von Hand kuratiert** und **nach Häufigkeit sortiert** (bekannte Wörter zuerst). Erste Kapitel: Tiere (88 Wörter), Gemüse (52), Früchte (54), Kleidung (63); Flüsse (61), Automarken (109), Länder (68), Berufe (64); Sportarten (66), Instrumente (54), Hauptstädte (68), Internet (70); Götter (65), Komponisten (64), Elemente (67), Weltraum (59); Fabelwesen (60), Sagenhelden (56), Erfinder (58), Inseln (61); Japan & Anime (66), Superhelden (64), Musikstile (61), Gaming (65).
- **Nur Wörter aus einem Stück** (fürs Erste): Themenwörter mit Leerzeichen oder Bindestrich (BUENOS AIRES, NEU-DELHI, COSTA RICA) werden weggelassen.

## Einstieg

- In den **Einstellungen** gibt es den Modus **„Story“** (neben einfach / mittel / schwierig). Wer ihn wählt, sieht das Kapitel-Brett; dort führt „Modus wechseln“ zurück in die Einstellungen.
- Startet die App im Story-Modus, erscheint zuerst das Kapitel-Brett.

## Kapitel-Brett (ab v5, ersetzt den Pfad)

Die Kapitel-Auswahl ist selbst ein **Brett aus Hexagons**, wie das Spielfeld, nur mit größeren Steinen. Jedes Hexagon ist ein Kapitel.

```
Reihe 6   ⬡ ⬡ ⬡ ⬡    Japan & Anime · Superhelden · Musikstile · Gaming
Reihe 5   ⬡ ⬡ ⬡ ⬡    Fabelwesen · Sagenhelden · Erfinder · Inseln
Reihe 4   ⬡ ⬡ ⬡ ⬡    Götter · Komponisten · Elemente · Weltraum
Reihe 3   ⬡ ⬡ ⬡ ⬡    Sportarten · Instrumente · Hauptstädte · Internet
Reihe 2   ⬡ ⬡ ⬡ ⬡    Flüsse · Automarken · Länder · Berufe
Reihe 1   ⬡ ⬡ ⬡ ⬡    Kleidung · Gemüse · Früchte · Tiere   ← Gemüse und Tiere zu Beginn offen
```

- **Größe:** 4 Hexagons breit, 6 hoch (24 Kapitel). Leicht unten, schwer oben.
- **Anordnung** wie im Spielfeld: Spalten 2 und 4 liegen einen halben Stein tiefer. Jedes Hexagon hat bis zu 6 Nachbarn.
- **Zu Beginn** sind nur **Tiere** und **Gemüse** aufgedeckt (v5.2).
- **Optik:** Die Kapitel sind **3D-Kristall-Hexagons wie die Spielsteine** (gleiches Licht, gleicher Glanz); Aufdecken ist eine echte Drehung wie beim Tauschen der Buchstabensteine.
- **Gesperrt:** Ein Kapitel, dessen Nachbarn noch nicht geschafft sind, zeigt auf dem dunklen Stein nur ein **leuchtendes Schloss** (kein Name, v5.4). Leere Plätze (noch kein Kapitel) zeigen „bald“. Antippen eines gesperrten Steins: er wackelt samt Schloss. Screenshot: [Schloss](images/chapter-board-lock-v1.png).
- **Beschriftung:** Ein aufgedecktes Hexagon zeigt den **Namen** des Kapitels und darunter die **Sterne** (☆☆☆ … ★★★); keine Emojis (Schrift auf Android).
- **Kapitel geschafft:** Das Hexagon **dreht sich** und zeigt seine Wertung: **Bronze** (★), **Silber** (★★), **Gold** (★★★). Nochmal spielen kann die Wertung verbessern (die beste zählt).
- **Freischalten über Nachbarn (v5.2):** Ein geschafftes Kapitel deckt alle **angrenzenden** Hexagons auf. Beispiel: Gemüse geschafft → Kleidung, Früchte, Automarken; Tiere geschafft → Früchte, Berufe. Wer an einem Thema hängt, nimmt ein anderes offenes.
- **Aufdeck-Animation bei jedem Betreten** des Bretts: zuerst liegen alle Steine verdeckt, dann drehen sich die aufgedeckten **nacheinander** um (von unten nach oben, ohne Vibration); geschaffte zu Bronze / Silber / Gold. Verdeckt: dunkles Rauchglas; offen: Kristall mit gedämpftem Kern; Schrift mit dunklem Rand.
- **Erste Version: 2 Reihen, 8 Kapitel.**
  - Reihe 1 (einfach): **Kleidung, Gemüse, Früchte, Tiere**.
  - Reihe 2 (mittel): **Flüsse, Automarken, Länder, Berufe**. Flüsse und Automarken haben genug Wörter (je ≥ 57, nur 3–8 Buchstaben). Länder ohne lange Namen (DEUTSCHLAND, FRANKREICH usw. passen nicht in 8 Blöcke).
  - Reihen 3–6 bleiben verdeckt mit Hinweis „bald“; sie werden Stück für Stück gefüllt.
- **Neue Wortlisten** (Kleidung, Flüsse, Automarken, Länder, Berufe) mit Rätselsätzen schreibt Claude, Adrian prüft.
- Der bisherige Pfad durchs All entfällt.
- **Bauplan:** (1) Brett mit Freischalt-Regel ✔, (2) Dreh-Animation und Bronze / Silber / Gold ✔, (3) neue Wortlisten ✔.

## Wörter und Steine

- **Das Spiel versteckt das Wort:** Zu Beginn jedes Levels wählt es ein Themenwort passender Länge (z. B. BANANE) und legt dessen Buchstaben als zusammenhängenden Weg ins Feld, dazu Füllbuchstaben (wie die Wort-Hilfe beim Tauschen/Magnet). Der Spieler muss nicht raten, ob das Wort überhaupt möglich ist.
- **Es zählt jedes Themenwort** der Kategorie mit genau passender Länge: Hat das Spiel APFEL versteckt und der Spieler findet BIRNE, zählt BIRNE.
- **Kein Wort doppelt pro Lauf:** Ein Wort, das schon Ziel war oder gefunden wurde, zählt im selben Lauf nicht mehr und wird auch nicht mehr als Füllwort, Tipp oder Lösung gelegt (v5.1, nach Testspiel: BMW kam zweimal).
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
- Die Sterne-Regel gilt seit v4 auch im normalen Lauf (siehe [run-mode.md](run-mode.md)).
- Anzeige im Spiel: oben in der Mitte der Kapitel-Name, über dem Feld links die **Leiter** (20 Quadrate, wie im Lauf), unter dem Feld „Noch n Level bis zum Ziel“.

## Hilfen

- **Münzen und Preise wie im Lauf** (100 Münzen pro Level, gleiche Preise).
- **Kein Draft (kein Roguelike):** Im Story-Modus gibt es keine Power-up-Auswahl. Die Hilfen sind **von Anfang an fest** da (seit v4.3), weil viele Lauf-Hilfen das versteckte Wort zerstören oder nichts bringen (Mischen würfelt die Buchstaben neu, Joker, Auffüllen, Teilen, Streichen).
  - **Rätsel** (gratis), **Tipp** (100 je Buchstabe), **Aufräumen** (150, lässt das Themenwort stehen), **Scan** (200, zeigt das Themenwort), **Lösen** (500).
  - Nach Level 20 ist das Kapitel geschafft.
- Die bekannten Hilfen behalten ihren Sinn (Tipp, Scan, Vervollständigen zeigen ein **Themenwort**).
- **Neu: Rätsel** (nur im Story-Modus, **gratis**, beliebig oft): zeigt in einem **Overlay** einen kurzen Rätselsatz zum versteckten Wort, z. B. „Gelb, krumm und bei Affen beliebt“. Antippen irgendwo schließt es, der Bildschirm bleibt aufgeräumt.
  - Zu **Beginn jedes Levels** erscheint das Rätsel **automatisch** (nach einer Power-up-Auswahl erst, wenn gewählt ist). Der Knopf „Rätsel“ (gratis) öffnet es jederzeit wieder.
  - Es zählt nicht als gekaufte Hilfe (3 Sterne bleiben möglich). Rollen: Rätsel sagt, **was** gesucht ist; der **Tipp** (100) zeigt, **wo** es liegt. Screenshot: [Rätsel](images/riddle-overlay-v1.png).
  - Jedes Themenwort braucht dafür einen Rätselsatz (Claude schreibt sie, Adrian prüft).

## Voraussetzung: Umlaute

- Viele schöne Themenwörter haben Umlaute (ÄPFEL, MÖHRE, ZÜRICH). Deshalb kommen vorher **Ä, Ö, Ü** ins ganze Spiel (eigener Schritt, siehe [game-rules.md](game-rules.md), „Sprache“).
- **ß bleibt SS** (STRASSE), kein eigener Stein.

## Offen

- Kapitel-Brett: Versatz der Reihen (wie im Spielfeld?), was auf verdeckten Hexagons steht, Dreh-Animation beim Aufdecken, Platz für Titel und „Modus wechseln“.
- Weg des versteckten Wortes gezielt gerade bzw. verwinkelt legen.
- Rätselsätze und Wortlisten nach Testspielen verbessern.
- Themen für Reihen 3–6.

## Verlauf

- **v1:** Konzept aus dem Brainstorming: Kapitel mit Kategorien (≥ 50 Wörter), Ziel Level 20, versteckte Themenwörter, jedes Themenwort passender Länge zählt, Scheitern nur durch Aufgeben, Sterne, Rätsel-Tipp, Umlaute (ß = SS) als Voraussetzung.
- **v2:** Geklärt: Münzen/Preise und Draft wie im Lauf (Grundsatz: Regeln überall gleich); Start mit Rätsel-Tipp und Lösen, kein Auffüllen; Kapitel-Auswahl als Pfad durchs All; nur Wörter aus einem Stück; Versteck-Stärke steigt über die 20 Level.
- **v3:** Erste Version umgesetzt: Modus „Story“ in den Einstellungen, Pfad mit Früchte / Tiere / Gemüse, versteckte Themenwörter (nach Häufigkeit und Länge gestaffelt), Füllgrad je Stufe, Rätsel-Tipp (50, ohne zweite Stufe), Ziel Level 20, Sterne, Teilen/Streichen nicht im Story-Modus.
- **v4:** Ziel Level 20 und Sterne gelten jetzt in allen Modi; Leiter statt „Level x von 20“; Tipp kostet 100.
- **v4.1:** Power-ups wie im Lauf alle 4 Level (4, 8, 12, 16).
- **v4.2:** Rätsel gratis und beliebig oft, als Overlay (Antippen schließt), automatisch zu Beginn jedes Levels; keine Textzeile mehr über dem Feld.
- **v4.3:** Kein Draft in der Story: Rätsel, Tipp, Aufräumen, Scan und Lösen sind von Anfang an fest da; Mischen, Joker usw. entfallen (zerstören das versteckte Wort). Hinweis nur noch „bis zum Ziel“.
- **v4.4:** Nach Testspiel: Reihenfolge Tiere → Gemüse → Früchte (Früchte am schwierigsten). Rätsel MARACUJA verrät die Lösung nicht mehr; ELSBEERE (kaum bekannt) ans Ende der Liste.
- **v5 (Entwurf):** Kapitel-Brett statt Pfad: 4 × 6 große Hexagons, Reihe 1 offen, nächste Reihe dreht sich, sobald ein Kapitel der Reihe geschafft ist; Wertung Bronze / Silber / Gold. Erste Version 2 Reihen: Tiere, Gemüse, Früchte, Kleidung; Flüsse, Automarken, Länder, Berufe.
- **v5:** Kapitel-Brett umgesetzt (Schritte 1–3): 3D-Hexagons, Freischalten je Reihe, Bronze / Silber / Gold mit Dreh-Animation; neue Kapitel Kleidung, Flüsse, Automarken, Länder, Berufe (Wortlisten von Claude, Prüfung durch Adrian offen).
- **v5.1:** Kein Wort doppelt pro Lauf (auch nicht als gefundenes Themenwort statt des Ziels).
- **v5.2:** Tiere und Kleidung getauscht; Start mit Tiere und Gemüse; Freischalten über Nachbarn statt Reihen; Aufdeck-Animation bei jedem Betreten des Bretts.
- **v5.3:** Reihe 3: Sportarten, Instrumente, Hauptstädte (über Länder), Internet. Weltraum für später vorgemerkt.
- **v5.4:** Gesperrte Kapitel mit leuchtendem 3D-Schloss statt leerem dunklem Stein.
- **v5.5:** Reihe 4 (schwerer): Götter, Komponisten (über Instrumente), Elemente, Weltraum.
- **v5.6:** Brett voll (24 Kapitel). Reihe 5: Fabelwesen, Sagenhelden, Erfinder, Inseln. Reihe 6 („Gottmodus“, für Junge): Japan & Anime, Superhelden, Musikstile, Gaming.
