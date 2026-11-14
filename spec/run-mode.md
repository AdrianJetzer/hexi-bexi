# Lauf-Modus (Roguelike)

Status: **Entwurf v3**. Aufträge als Block-Zeilen ohne Wahl und ohne Text; Umfang für Version 1 festgelegt.

Markierungen: **[v1]** = kommt in Version 1 · **[später]** = gute Idee, nach Version 1 · **[offen]** = noch nicht entschieden.

Abschnitte ohne Markierung gehören zum Grundgerüst und sind **[v1]**.

## Idee in einem Satz

Ein **Lauf** besteht aus Levels. Jedes Level ist ein **Auftrag**: über dem Spielfeld stehen Zeilen **leerer Blöcke**, und der Spieler sucht Wörter, die **genau** in diese Zeilen passen. Gelöste Aufträge bringen **Münzen**, mit denen man sich **Hilfen** kauft. Wer nicht weiterkommt, gibt auf, und der nächste Lauf beginnt **wieder bei Level 1**.

Grundsatz: **Symbole statt Text.** Der Spieler soll nicht lesen müssen, was zu tun ist.

Das Grundspiel bleibt: Raster, Wischen, Wörterbuch, Wort-Hilfe (siehe [game-rules.md](game-rules.md)).

## Ablauf eines Laufs

1. **Start:** Level 1, **0 Münzen**, Spielfeld mit **10 Hexagons** (Platzwahl wie bisher; weniger Steine sind übersichtlicher). Der erste Auftrag erscheint sofort.
2. **Level:** Über dem Spielfeld stehen die Block-Zeilen des Auftrags. Der Spieler wischt Wörter.
3. **Gelöst:** Sind alle Zeilen gefüllt, gibt es Münzen, der Auftrag verschwindet und der **nächste erscheint automatisch** (keine Wahl, keine Unterbrechung).
4. **Ende:** Nur durch **„Aufgeben“** (mit Nachfrage), z. B. wenn man nicht weiterkommt und kein Geld mehr für Hilfen hat. Dann wird die **Lösung** gezeigt, danach die Bilanz (erreichtes Level, Rekord). Neuer Lauf ab Level 1.
5. **Rekord:** nur das **höchste erreichte Level**.

## Aufträge

### Block-Zeilen
- Ein Auftrag besteht aus **1 bis 3 Zeilen** leerer Blöcke. Jede Zeile hat ihre **eigene Länge** (3 bis 8 Blöcke).
  - ▢▢▢ = ein Wort mit 3 Buchstaben.
  - ▢▢▢ / ▢▢▢ / ▢▢▢▢ = zwei Wörter mit 3 und ein Wort mit 4 Buchstaben.
- Ein Wort passt, wenn es **genau so lang** ist wie eine noch **freie** Zeile. Gibt es mehrere freie Zeilen dieser Länge, füllt es die oberste davon.
- **Passendes Wort:** Die Steine verschwinden aus dem Feld, ihre **Buchstaben fliegen** in die Blöcke der Zeile und bleiben dort sichtbar (z. B. H A U S).
- **Nicht passendes Wort** (falsche Länge, keine freie Zeile dieser Länge, oder kein Wort): wird **abgelehnt**, die Steine **wackeln** und bleiben liegen. Kein Text.
- Mindestlänge eines Worts: 3 Buchstaben.
- Sind **alle Zeilen gefüllt**, ist der Auftrag gelöst: kurze Erfolgsrückmeldung (Münzen), die Zeilen verschwinden, die Zeilen des nächsten Auftrags erscheinen.

### Kurve (Startwerte)

| Level | Zeilen | Bild |
|---|---|---|
| 1 | 3 | ▢▢▢ |
| 2 | 4 | ▢▢▢▢ |
| 3 | 3 + 3 | ▢▢▢ / ▢▢▢ |
| 4 | 3 + 4 | ▢▢▢ / ▢▢▢▢ |
| 5 | 5 | ▢▢▢▢▢ |
| 6 | 4 + 4 | ▢▢▢▢ / ▢▢▢▢ |
| 7 | 3 + 3 + 4 | ▢▢▢ / ▢▢▢ / ▢▢▢▢ |
| 8 | 4 + 5 | ▢▢▢▢ / ▢▢▢▢▢ |
| 9 | 6 | ▢▢▢▢▢▢ |
| 10 | 3 + 4 + 5 | ▢▢▢ / ▢▢▢▢ / ▢▢▢▢▢ |

**Ab Level 11 (Block-Budget):**
- Ein Auftrag hat ein **Budget** an Blöcken: **12** in Level 11–15, alle 5 Levels **+1** (Level 16–20: 13 …), höchstens 24.
- Das Spiel verteilt das Budget **zufällig** auf **1 bis 3 Zeilen** mit je **3 bis 8** Blöcken (z. B. 4 + 4 + 4, 6 + 6, 3 + 4 + 5).
- Die Kurve liegt als Daten vor (tunebar); alle Zahlen sind Startwerte für das Feintuning.

### Wort-Hilfe
- **Das Level steuert die Hilfe**: am Anfang stark, später schwächer (Hilfe-Stufen siehe [game-rules.md](game-rules.md)): Level 1–2 sehr stark, 3–4 stark, 5–7 mittel, 8–10 schwach, ab 11 keine.

### Bosse [später]
Alle **5 Levels** ein besonders großer Auftrag mit großer Belohnung.

## Münzen

| Ereignis | Münzen |
|---|---|
| Auftrag gelöst | **+100 + 10 × Level** (Level 1: 110, Level 10: 200) |
| Langes Wort nebenbei [später] | Bonus |
| **5 Steine nachfüllen** | **−100**, jeder weitere Kauf im Lauf **+25** (100, 125, 150 …) |
| **5 Steine tauschen** | **−50** |
| **Aufräumen: bis zu 5 wenig hilfreiche Steine entfernen (ein passendes Wort bleibt)** | **−100** |
| **Tipp: nächsten Buchstaben zeigen** | **−100** je Buchstabe |
| **Stein ersetzen** | **−100** |

- Münzen sind die **Währung** des Laufs. Es gibt keine Punkte, nur Münzen und Level.

## Spielfeld

- **Das Feld bleibt zwischen den Levels liegen.** Ein gutes oder schlechtes Feld wirkt nach.
- **Automatisch auffüllen:** Nach jedem angenommenen Wort kommen **Wortlänge − 1** neue Steine ins Feld (Platzwahl wie bisher; 5 Buchstaben → 4 neue). Das Feld leert sich so langsam; Nachfüllen bleibt wichtig.

## Hilfen

- **Nachfüllen:** 5 neue Steine an freie Plätze (Platzwahl wie bisher). Kostet 100 und wird mit jedem Kauf im selben Lauf um 25 teurer; ein neuer Lauf beginnt wieder bei 100. Ist das Feld voll, ist Nachfüllen gesperrt.
- **Tauschen:** 5 zufällige Steine im Feld drehen sich um und bekommen neue Buchstaben, gewählt von der **Wort-Hilfe**. Fester Preis 50. Auch bei vollem Feld erlaubt. Liegen weniger als 5 Steine im Feld, werden alle getauscht.
  - **Schlau, wenn man feststeckt:** Liegt kein **geläufiges** Wort im Feld, das in eine freie Zeile passt, sucht Tauschen eine Kette **benachbarter vorhandener Steine**, die mit **höchstens 5 Änderungen** ein geläufiges Wort in der Länge einer freien Zeile ergibt (möglichst wenige Änderungen, zufälliges Wort). Diese Steine drehen sich um; die übrigen Tausch-Steine werden normal getauscht, aber nie Steine der neuen Kette. Gibt es keine solche Kette (z. B. zu wenige Steine), tauscht es wie gewohnt. Das Wort muss man dann noch finden.
- **Aufräumen:** Räumt nur auf, wenn danach **noch ein passendes Wort im Feld liegt**: Das Spiel sucht ein **geläufiges Wort**, das in eine freie Zeile passt (bevorzugt das blinkende Tipp-Wort); dessen Steine bleiben **geschützt**. Von den übrigen verschwinden bis zu **5**, die **am wenigsten hilfreichen** zuerst (durch die am wenigsten passende Wörter führen; bei Gleichstand die **seltensten Buchstaben**, Q, X, Y, J …). Die Plätze bleiben **frei** (Löcher; Nachfüllen füllt sie zuerst). Preis 100. Liegt **kein** passendes Wort im Feld (man steckt fest), wird **nichts** entfernt: der Knopf wackelt, es kostet nichts – dann hilft Tauschen.
- **Tipp, Buchstabe für Buchstabe:** Der erste Tipp legt ein Wort fest, das in eine freie Zeile passt, und lässt seinen ersten Stein **blinken**; jeder weitere Tipp (je 100) lässt den nächsten Stein desselben Worts blinken. Alle gezeigten Steine **blinken weiter**, auch wenn dazwischen anders gewischt wird. Sind alle Buchstaben gezeigt, ist der Tipp gesperrt. Ändert sich ein Stein des Tipp-Worts (Tauschen, Ersetzen), verfällt der Tipp; der nächste beginnt neu. Liegt kein passendes Wort im Feld, kostet der Tipp nichts. Kein Text, nur Blinken.
- **Stein ersetzen:** Stein antippen, er bekommt einen neuen Buchstaben. Den wählt die **Wort-Hilfe**. Kein Wunschbuchstabe.
- **Lösung am Ende:** Beim Aufgeben blinken die Steine eines Worts, das in eine freie Zeile passt, und seine **Buchstaben fliegen in die Zeile**. Gibt es keines, bleiben die Zeilen leer. Mit **„Weiter“** geht es zur Bilanz.

## Laden und Vorteile [später]

### Hilfen freischalten und verbessern
- Jede Hilfe gibt es in einer **einfachen** und einer **starken (+)** Stufe. Ideen:

  | Hilfe | einfach | stark (+) |
  |---|---|---|
  | Tauschen | 5 zufällige Steine neu | legt ein passendes Wort, wenn man feststeckt |
  | Aufräumen | 5 zufällige Steine weg | die 5 am wenigsten hilfreichen weg |
  | Tipp | erster Buchstabe | Buchstabe für Buchstabe |
  | Ersetzen | zufälliger neuer Buchstabe | Wunschbuchstabe |
  | Nachfüllen | 5 Steine | 5 Steine mit stärkerer Wort-Hilfe |

- **Freigeschaltet wird im Lauf** (Roguelike): Jeder Lauf beginnt mit wenigen, einfachen Hilfen; mit Münzen schaltet man weitere Hilfen und die starken Stufen frei. Beim nächsten Lauf beginnt man wieder von vorn.
- Damit die Knopfleiste nicht überläuft (mehr als 5–6 Knöpfe passen schlecht), evtl. **Slots**: eine begrenzte Zahl Hilfe-Plätze, weitere Plätze freikaufbar.
- **[offen]** Wo man kauft: direkt am Hilfe-Knopf (z. B. „+“-Symbol, jederzeit, ohne Unterbrechung), in einem Laden zwischen den Levels, oder in einem Laden auf Wunsch. Wichtig: den Spielfluss nicht stören (deshalb sind die Auftragskarten entfallen).
- **[offen]** Mit welchen Hilfen ein Lauf beginnt, Preise der Freischaltungen.

### Weitere Vorteile
Dauerhafte Vorteile für den laufenden Lauf, bezahlt mit Münzen. Beispiele:
- **Vokal-Magnet:** mehr Vokale
- **+20 % Münzen**
- **Erster Tipp gratis** (pro Level)
- **Goldener Stein:** doppelte Münzen, wenn er im Wort ist

## Besondere Steine [später]

- **Goldener Stein:** doppelte Belohnung.
- **Rissiger Stein:** zerfällt nach einigen Wörtern und blockiert dann oder kostet Münzen.
- **Steinblock:** ganz unten, ohne Buchstabe; bricht, wenn daneben ein Wort gebildet wird.

## Fortschritt über Läufe (Meta) [später]

Über viele Läufe neue Vorteile oder besondere Steine freischalten, die dann in Läufen auftauchen können.

## Ausblick: Münzen kaufen [später]

Münzen bieten sich für **In-App-Käufe** an. Falls das kommt, muss das Spiel **ohne Kauf fair** bleiben. Entscheidung gesondert, nicht Teil dieser Spec.

## Entfallen (seit v3)

- **Auftragskarten** mit Wahl zwischen sicher und riskant: störten den Spielfluss.
- **„Finde das Wort X“** und das gezielte **Säen**: zu leicht.
- **Zuglimit** und **„ohne Nachziehen“**: lassen sich nicht ohne Text zeigen. Damit entfällt auch der Begriff „Zug“ und das automatische Ende des Laufs.
- **„Mindestens N Buchstaben“**: Wörter müssen jetzt genau passen.
- **Text-Anzeigen** für Auftrag, gewischtes Wort, Ablehnungsgrund und Tipp.

## Verlauf

- **v1:** Konzept gesammelt: Lauf mit Aufträgen als Levels, Münzen (+100 pro Auftrag; Nachfüllen 5 Steine −50, Tipp −100, Stein ersetzen −100), Neustart bei Level 1 nach Scheitern (Roguelike). Ideen: Auftragswahl, Zufall, Bosse, Laden, besondere Steine, Meta-Fortschritt. Umfang und Details offen.
- **v2:** Offene Fragen geklärt: Feld bleibt zwischen Levels liegen; Start mit 0 Münzen und 20 Hexagons; Zug = angenommenes Wort; Punkte entfallen; Knopf „Aufgeben“ (kein automatisches Ende); „ohne Nachziehen“ sperrt den Knopf; Level steuert die Wort-Hilfe, die 5 Stufen entfallen; Stein ersetzen über Wort-Hilfe; volles Feld sperrt Nachfüllen; Rekord = höchstes Level; Kurve für Level 1–10. Umfang v1: Grundgerüst + Auftrag wählen + Zufall; später: Bosse, Laden, besondere Steine, Bonus-Münzen, Meta, Münzkauf.
- **v2.1:** Zuglimit verfehlt → Lauf endet automatisch.
- **v2.2:** Ab Level 11: Aufträge aus Level 6–10 gemischt, alle 5 Levels eine Verschärfung (Länge, Anzahl, Zuglimit reihum), Belohnung +50 je Verschärfung.
- **v2.3:** Bestimmtes Wort wird gesät, indem Steine sich zu einer zusammenhängenden Kette verwandeln (garantiert lösbar).
- **v2.4:** Längen-Aufträge zählen Wörter mit mindestens der verlangten Länge.
- **v2.5:** Nachfüllen kostet 100, +25 je weiterem Kauf im Lauf. Neue Hilfe „5 Steine tauschen“ für 50 (Wort-Hilfe, auch bei vollem Feld und „ohne Nachziehen“).
- **v2.6:** Nur passende Wörter werden angenommen; nicht passende werden abgelehnt (Steine bleiben). Zug = jeder Versuch ab 3 Buchstaben, auch abgelehnte.
- **v2.7:** Nach jedem angenommenen Wort automatisch Wortlänge − 1 neue Steine (nicht bei „ohne Nachziehen“).
- **v2.8:** Bestimmtes Wort ist jetzt die sichere Karte (Level 4, 6–7, 8–10), riskant ein längeres Wort. Tipp Buchstabe für Buchstabe (je 100), gezeigte Steine blinken weiter. Lösung beim Ende des Laufs, dann „Weiter“ zur Bilanz.
- **v3:** Neues Auftrags-Konzept: Block-Zeilen über dem Spielfeld (1–3 Zeilen, je 3–8 Blöcke, gemischte Längen), Wörter müssen genau passen, Buchstaben fliegen in die Blöcke, nächster Auftrag kommt automatisch. Belohnung 100 + 10 × Level. Kurve Level 1–10 fest, ab 11 Block-Budget (12, alle 5 Levels +1). Symbole statt Text. Entfallen: Auftragskarten, bestimmtes Wort/Säen, Zuglimit, „ohne Nachziehen“, Mindestlänge-Aufträge, Text-Anzeigen. Lösung beim Aufgeben fliegt in die Zeile.
- **v3.1:** Neue Hilfe „Aufräumen“: bis zu 5 nutzlose Steine (seltenste zuerst) für 100 entfernen, Löcher bleiben.
- **v3.2:** Aufräumen entfernt immer die 5 am wenigsten hilfreichen Steine (wenigste passende Wörter, dann seltenste Buchstaben), statt nur völlig nutzlose (die gab es mit dem großen Wörterbuch kaum).
- **v3.3:** Aufräumen lässt immer mindestens so viele Steine liegen, wie das längste gesuchte Wort lang ist.
- **v3.4:** Tauschen legt ein passendes geläufiges Wort ins Feld, wenn man feststeckt (Kette vorhandener Steine, höchstens 5 Änderungen).
- **v3.5:** Idee festgehalten: Hilfen in einfacher und starker Stufe, im Lauf freischalten (Roguelike), evtl. Slots; Kauf-Ort offen.
- **v3.6:** Aufräumen schützt ein passendes geläufiges Wort und räumt nur auf, wenn es eines gibt (ersetzt die Regel „Wortlänge an Steinen bleibt liegen“).
- **v3.7:** Start mit 10 statt 20 Hexagons (weniger Steine sind übersichtlicher).
