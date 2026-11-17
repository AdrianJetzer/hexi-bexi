# Lauf-Modus (Roguelike)

Status: **Entwurf v3**, Ziel Level 20 (v3.33), Preise v3.35. Aufträge als Block-Zeilen ohne Wahl und ohne Text; Umfang für Version 1 festgelegt.

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
4. **Ziel: Level 20** (in allen Modi). Ist Level 20 gelöst, ist der Lauf **geschafft**: Bilanz „Geschafft!“ mit **Sternen** und den übrigen Münzen. Neuer Lauf ab Level 1.
   - **Sterne:** ★★★ = keine Hilfe gekauft, ★★ = höchstens 500 Münzen ausgegeben, ★ = geschafft (wie im Story-Modus). Gespeichert wird die beste Wertung je Modus; sie steht in den Einstellungen auf dem Modus-Knopf.
5. **Aufgeben** (mit Nachfrage), z. B. wenn man nicht weiterkommt und kein Geld mehr für Hilfen hat: Die **Lösung** wird gezeigt, danach die Bilanz „Nicht geschafft“ (Level n von 20). Keine Sterne, kein Rekord.
6. **Rekord:** die meisten **übrigen Münzen** nach Level 20 (höchstens 20 × 100 = 2000), je Modus.

## Aufträge

### Block-Zeilen
- Ein Auftrag besteht aus **1 bis 3 Zeilen** leerer Blöcke (durch die Hilfe „Teilen“ auch 4). Jede Zeile hat ihre **eigene Länge** (3 bis 8 Blöcke).
  - ▢▢▢ = ein Wort mit 3 Buchstaben.
  - ▢▢▢ / ▢▢▢ / ▢▢▢▢ = zwei Wörter mit 3 und ein Wort mit 4 Buchstaben.
- Ein Wort passt, wenn es **genau so lang** ist wie eine noch **freie** Zeile. Gibt es mehrere freie Zeilen dieser Länge, füllt es die oberste davon.
- **Passendes Wort:** Die Steine verschwinden aus dem Feld, ihre **Buchstaben fliegen** in die Blöcke der Zeile und bleiben dort sichtbar (z. B. H A U S).
- **Nicht passendes Wort** (falsche Länge, keine freie Zeile dieser Länge, oder kein Wort): wird **abgelehnt**, die Steine **wackeln** und bleiben liegen. Kein Text.
- Mindestlänge eines Worts: 3 Buchstaben.
- Sind **alle Zeilen gefüllt**, ist der Auftrag gelöst: kurze Erfolgsrückmeldung (Münzen), die Zeilen verschwinden, die Zeilen des nächsten Auftrags erscheinen.

### Kurve (Startwerte)

Ruhig ansteigend: Jeder der zehn festen Aufträge kommt **zweimal** hintereinander.

| Level | Zeilen | Bild |
|---|---|---|
| 1–2 | 3 | ▢▢▢ |
| 3–4 | 4 | ▢▢▢▢ |
| 5–6 | 3 + 3 | ▢▢▢ / ▢▢▢ |
| 7–8 | 3 + 4 | ▢▢▢ / ▢▢▢▢ |
| 9–10 | 5 | ▢▢▢▢▢ |
| 11–12 | 4 + 4 | ▢▢▢▢ / ▢▢▢▢ |
| 13–14 | 3 + 3 + 4 | ▢▢▢ / ▢▢▢ / ▢▢▢▢ |
| 15–16 | 4 + 5 | ▢▢▢▢ / ▢▢▢▢▢ |
| 17–18 | 6 | ▢▢▢▢▢▢ |
| 19–20 | 3 + 4 + 5 | ▢▢▢ / ▢▢▢▢ / ▢▢▢▢▢ |

**Ab Level 21 (Block-Budget):**
- Ein Auftrag hat ein **Budget** an Blöcken: **12** in Level 21–30, alle **10** Levels **+1** (Level 31–40: 13 …), höchstens 24.
- Das Spiel verteilt das Budget **zufällig** auf **1 bis 3 Zeilen** mit je **3 bis 8** Blöcken (z. B. 4 + 4 + 4, 6 + 6, 3 + 4 + 5).

**Atempausen:** Ab Level 11 ist **jedes 5. Level** leicht (Level 15, 20, 25 …): nur **eine Zeile mit 3 oder 4 Blöcken** (zufällig). Das gilt auch innerhalb der festen Kurve (Level 15 und 20).

- Die Hilfe-Stufe (Wort-Hilfe) ist genauso gestreckt: 1, 1, 1, 1, 2, 2, 2, 2, 3 … (je Stufe doppelt so viele Level wie vorher).
- Die Kurve liegt als Daten vor (tunebar); alle Zahlen sind Startwerte für das Feintuning.

### Wort-Hilfe
- **Das Level steuert die Hilfe**: am Anfang stark, später schwächer (Hilfe-Stufen siehe [game-rules.md](game-rules.md)): Level 1–2 sehr stark, 3–4 stark, 5–7 mittel, 8–10 schwach, ab 11 keine.

### Bosse [später]
Alle **5 Levels** ein besonders großer Auftrag mit großer Belohnung.

## Modi

Drei Modi, wählbar in den Einstellungen (siehe [screens.md](screens.md)). Hilfen, Preise, Power-ups, Atempausen und Münzen sind in allen gleich; jeder Modus hat einen **eigenen Rekord**.

| | **Deutsch einfach** (Kinder) | **Deutsch mittel** | **Deutsch schwierig** |
|---|---|---|---|
| Gültige Wörter | die **Kinder-Liste** plus die häufigsten kurzen Wörter in jeder Form (ICH, SIE, DER, UND, IST …), zusammen ca. 3.400, 3–5 Buchstaben | alle | alle |
| Vorschläge (Wort-Hilfe, Tipp, Scan …) | die **Kinder-Liste** (ca. 3.000 bekannte Grundwörter und Mehrzahlformen) | 10.000 häufige Wörter | 10.000 häufige Wörter |
| Zeilenlänge | höchstens 5 Blöcke | höchstens 6 Blöcke | bis 8 Blöcke |
| Steigerung | langsam | mittel | wie in „Kurve“ oben |
| Wort-Hilfe | immer stark | länger stark | wie in „Kurve“ oben |

- **Schwierig** ist das bisherige Spiel (Kurve oben). Einfach und mittel haben eigene, sanftere Kurven (Daten in `data/`).
- Die Kinder-Liste entsteht aus den häufigsten Grundwörtern (Leipzig-Häufigkeit, wie die Vorschlags-Wörter) mit 3–5 Buchstaben, ohne Wörter der Sperrliste.

## Münzen

| Ereignis | Münzen |
|---|---|
| Auftrag gelöst | **+100** (fest, unabhängig vom Level und Modus) |
| Langes Wort nebenbei [später] | Bonus |
| **Auffüllen: 5 neue Steine** | **gratis** |
| **Stein ersetzen** | **−50** |
| **Mischen: Buchstaben neu verteilen** | **−100** |
| **Aufräumen: bis zu 5 wenig hilfreiche Steine entfernen** | **−150** |
| **Joker: ein Stein wird zum Joker** | **−100** |
| **Kürzen: längste Zeile um einen Block kürzen** | **−100** |
| **Tipp: nächsten Buchstaben zeigen** | **−100** je Buchstabe |
| **Tauschen: 5 Steine neu** | **−50** |
| **Teilen: lange Zeile halbieren** | **−150** |
| **Vervollständigen: angewischtes Wort zu Ende zeigen** | **−200** |
| **Magnet: Wort um einen Stein bilden** | **−150** |
| **Scan: Steine eines Worts zeigen (längste Zeile)** | **−200** |
| **Zeile streichen: die längste freie Zeile fällt weg** | **−200** |
| **Lösen: ganzen Auftrag lösen** (ohne Belohnung) | **−500** |

- **Preisstufen:** Die 12 Hilfen mit Preis stehen in **vier Stufen**: 50 (2 Hilfen), 100 (4), 150 (3), 200 (3), nach Stärke. **Lösen** ist ein **Sonderknopf**, immer da und sehr teuer (500). Die Hilfe-Knöpfe stehen in dieser Reihenfolge: von gratis bis teuer (gleicher Preis: Reihenfolge der Tabelle).
- Münzen sind die **Währung** des Laufs. Es gibt keine Punkte, nur Münzen und Level.

## Spielfeld

- **Das Feld bleibt zwischen den Levels liegen.** Ein gutes oder schlechtes Feld wirkt nach.
- **Automatisch auffüllen:** Nach jedem angenommenen Wort kommen **Wortlänge − 1** neue Steine ins Feld (Platzwahl wie bisher; 5 Buchstaben → 4 neue). Das Feld leert sich so langsam; Auffüllen bleibt wichtig.

## Hilfen

### Power-ups und Upgrades (Roguelike) [v1]
- **Start eines Laufs:** Unten sind nur **Auffüllen** (gratis) und **Lösen** (500) sichtbar.
- **Power-up nach Level 4, 8, 12 und 16:** Ist der Auftrag gelöst, erscheint ein **Auswahl-Bildschirm** mit **2 Karten** (Name, Preis, kurze Erklärung) – **zwei zufällige** Hilfen der nächsten Preisstufe (so ist jeder Lauf anders):

  | nach Level | Stufe | Hilfen der Stufe (2 davon zur Wahl) |
  |---|---|---|
  | 4 | 50 | Ersetzen, Tauschen |
  | 8 | 100 | Mischen, Joker, Kürzen, Tipp |
  | 12 | 150 | Aufräumen, Teilen, Magnet |
  | 16 | 200 | Scan, Zeile streichen, Vervollständigen |

  Danach (Level 17–20) zählt der Hinweis bis zum Ziel.

  Man tippt eine Karte an, ihr Knopf kommt unten dazu, dann beginnt das nächste Level. Die anderen Hilfen der Stufe gibt es in diesem Lauf **nicht**.
- **Upgrade nach Level 24, 28, 32 …** (nur im endlosen Test-Betrieb ohne Ziel, `goal_level = 0`): Die Karten zeigen die eigenen Hilfen **und Lösen**; die gewählte wird **25 % günstiger** (vom aktuellen Preis, auf 5 gerundet, **nie unter 25**; z. B. 200 → 150 → 115 → 85). Mehrere Upgrades auf dieselbe Hilfe sind erlaubt. Hilfen, die schon 25 kosten, stehen nicht zur Wahl. Steht keine mehr zur Wahl, entfällt das Upgrade.
- **Hinweis über den Knöpfen** (nur diese Zeile; Leiter und Münzen stehen über dem Spielfeld): „Noch 3 Level bis zum Power-up“, nach dem letzten Power-up „Noch n Level bis zum Ziel“; bei „Noch 1 Level“ leuchtet er.
- **Knöpfe:** höchstens 6 (Auffüllen, 4 Hilfen, Lösen), in **2 Reihen zu je 3**, sortiert von gratis bis teuer – deutlich größer als vorher.
- **Neuer Lauf:** wieder nur Auffüllen und Lösen, alle Preise wie in der Tabelle.
- **Test-Modus:** Ein Spielwert (`draft_enabled` in `data/balance.tres`) schaltet den Draft ab; dann sind alle Hilfen von Anfang an da (zum Testen).

### Die Hilfen im Einzelnen

- **Auffüllen:** 5 neue Steine an freie Plätze (Platzwahl wie bisher). **Gratis.** Das balanciert sich selbst: Zu wenige Steine – kein Wort möglich; zu viele Steine – unübersichtlich, schwerer zu finden. Der Spieler entscheidet, wann er nachlegt. Ist das Feld voll, ist Auffüllen gesperrt.
  - **Blinkt als Hinweis:** Liegt im Feld **kein gültiges Wort** (ganzes Wörterbuch), das genau in eine freie Zeile passt, blinkt die **Schrift** des Knopfs dezent zwischen Weiß und dunklem Weiß (je eine halbe Sekunde). Sobald wieder ein passendes Wort liegt, hört er auf. Kein Pulsieren bei vollem Feld (Auffüllen gesperrt), während ein Auftrag abschließt, und solange ein Joker im Feld liegt (dann ist vielleicht ein Wort möglich).
  - **Feld abgedunkelt:** Gleichzeitig wird das Spielfeld abgedunkelt (die Steine wirken gesperrt), und mitten darauf erscheint ein großer Knopf **„Auffüllen – gratis“**, damit sonnenklar ist, was zu tun ist. Antippen füllt auf; sobald wieder ein passendes Wort liegt, blendet beides aus. Die Hilfe-Knöpfe unten bleiben benutzbar (z. B. Tauschen, Mischen). Siehe [Screenshot](images/stuck-refill-v1.png).
- **Tauschen (50):** 5 zufällige Steine im Feld drehen sich um und bekommen neue Buchstaben, gewählt von der **Wort-Hilfe**. Auch bei vollem Feld erlaubt. Liegen weniger als 5 Steine im Feld, werden alle getauscht.
  - **Schlau, wenn man feststeckt:** Liegt kein **geläufiges** Wort im Feld, das in eine freie Zeile passt, sucht Tauschen eine Kette **benachbarter vorhandener Steine**, die mit **höchstens 5 Änderungen** ein geläufiges Wort in der Länge einer freien Zeile ergibt (möglichst wenige Änderungen, zufälliges Wort). Diese Steine drehen sich um; die übrigen Tausch-Steine werden normal getauscht, aber nie Steine der neuen Kette. Gibt es keine solche Kette (z. B. zu wenige Steine), tauscht es wie gewohnt. Das Wort muss man dann noch finden.
- **Aufräumen (150):** Räumt nur auf, wenn danach **noch ein passendes Wort im Feld liegt**: Das Spiel sucht ein **geläufiges Wort**, das in eine freie Zeile passt (bevorzugt das blinkende Tipp-Wort); dessen Steine bleiben **geschützt**. Von den übrigen verschwinden bis zu **5**, aber es bleiben immer **mindestens so viele Steine liegen, wie alle freien Zeilen zusammen Blöcke haben** (z. B. Zeilen 4 + 5 frei → mindestens 9 Steine); die **am wenigsten hilfreichen** verschwinden zuerst (durch die am wenigsten passende Wörter führen; bei Gleichstand die **seltensten Buchstaben**, Q, X, Y, J …). Die Plätze bleiben **frei** (Löcher; Auffüllen füllt sie zuerst). Liegt **kein** passendes Wort im Feld (man steckt fest), wird **nichts** entfernt: der Knopf wackelt, es kostet nichts – dann hilft Tauschen.
- **Tipp, Buchstabe für Buchstabe (je 50):** Der erste Tipp legt ein Wort fest, das in eine freie Zeile passt, und lässt seinen ersten Stein **blinken**; jeder weitere Tipp (je 25) lässt den nächsten Stein desselben Worts blinken. Alle gezeigten Steine **blinken weiter**, auch wenn dazwischen anders gewischt wird. Sind alle Buchstaben gezeigt, ist der Tipp gesperrt. Ändert sich ein Stein des Tipp-Worts (Tauschen, Ersetzen), verfällt der Tipp; der nächste beginnt neu. Liegt kein passendes Wort im Feld, kostet der Tipp nichts. Kein Text, nur Blinken.
- **Lösen (500):** Der aktuelle Auftrag wird sofort gelöst, es geht ins nächste Level; **keine Belohnung**. Für jede freie Zeile wird ein passendes **geläufiges Wort aus dem Feld** genommen (jeder Stein nur einmal): die Steine verschwinden, die Buchstaben fliegen in die Zeile, danach kommen wie gewohnt Wortlänge − 1 neue Steine. Gibt es für eine Zeile kein Wort im Feld, wird sie mit einem zufälligen geläufigen Wort passender Länge gefüllt (Buchstaben ploppen direkt in den Blöcken auf, das Feld bleibt dafür unverändert). Ein laufender Tipp verfällt.
- **Joker (100):** Ein zufälliger Stein wird zum **Joker** (zeigt ★). Beim Wischen steht er für **jeden Buchstaben**, mit dem ein gültiges Wort entsteht, das in eine freie Zeile passt; in die Blöcke fliegt der passende echte Buchstabe. Tipp, Lösen, Aufräumen und die Feststeck-Erkennung beziehen Joker vorerst nicht ein.
- **Mischen (100):** Die Buchstaben aller Steine werden zufällig auf die belegten Plätze neu verteilt; das Feld bleibt gleich voll. Die Steine drehen sich dabei um.
- **Magnet (150):** Knopf drücken, dann einen Stein **antippen**. Der Stein behält seinen Buchstaben; die Steine um ihn herum (eine zusammenhängende Kette, die ihn enthält) verwandeln sich so, dass mit ihm ein **geläufiges Wort** in der Länge einer freien Zeile entsteht (möglichst wenige Änderungen). Geht das nicht (zu wenige zusammenhängende Steine), wackelt der Knopf, es kostet nichts.
- **Zeile streichen (200):** Die **freie Zeile mit den meisten Blöcken** fällt ganz weg, ohne Wort (bei mehreren gleich langen die oberste). Nur möglich, solange **mindestens 2 Zeilen frei** sind – sonst wäre es ein billiges Lösen; dann wackelt der Knopf, es kostet nichts.
- **Kürzen (100):** Die **längste freie Zeile** verliert **einen Block** (z. B. 7 → 6, 4 → 3); bei mehreren gleich langen die oberste. Zeilen mit 3 Blöcken werden nicht kürzer (Mindestlänge eines Worts). Gibt es keine Zeile mit mindestens 4 Blöcken, wackelt der Knopf, es kostet nichts.
- **Teilen (150):** Die **längste freie Zeile** mit mindestens 6 Blöcken wird halbiert: 6 → 3 + 3, 7 → 4 + 3, 8 → 4 + 4. Dadurch können 4 Zeilen entstehen (die Blöcke werden dann etwas kleiner). Gibt es keine solche Zeile, wackelt der Knopf, es kostet nichts.
- **Scan (200):** Die Steine **eines** geläufigen Worts leuchten, und zwar für die **längste freie Zeile** (gibt es dafür keines, für die nächstkürzere) (nur ihr **Rand** leuchtet, damit die Buchstaben lesbar bleiben) – bis ein Wort angenommen wird oder sich das Feld ändert. Anders als der Tipp zeigt Scan alle Steine des Worts auf einmal, aber nicht ihre Reihenfolge. Gibt es kein passendes Wort, wackelt der Knopf, es kostet nichts.
- **Vervollständigen (200):** Knopf drücken (bleibt gedrückt wie bei Ersetzen und Magnet), dann **mindestens 2 Buchstaben anwischen** und loslassen. Das Spiel sucht ein Wort, das **mit genau diesen Steinen beginnt**, vom letzten Stein aus weitergeht, **länger** ist als das Angewischte und **genau in eine freie Zeile passt** – zuerst unter den Vorschlags-Wörtern, sonst unter allen gültigen Wörtern (bei mehreren zufällig eins).
  - **Treffer:** Das ganze Wort bekommt einen **leuchtenden Rand** wie beim Scan (bis ein Wort angenommen wird oder sich das Feld ändert); der Spieler wischt es danach selbst. Erst jetzt kostet es 150, der Modus geht aus. Wie beim Scan zeigt **Tipp** danach dasselbe Wort.
  - **Kein Treffer:** Die angewischten Steine wackeln, es kostet nichts, der Modus bleibt an – **beliebig viele Versuche**. Nochmals auf den Knopf drücken bricht ab.
  - Im Modus zählt Gewischtes **nicht** als Wort.
  - **Tipp folgt dem Scan:** Nach einem Scan zeigt **Tipp** Buchstabe für Buchstabe **dasselbe Wort**. Läuft schon ein Tipp mit einem Wort für dieselbe Zeilenlänge, zeigt Scan genau dieses Wort (bereits gezeigte Tipp-Buchstaben bleiben). Sonst ersetzt das Scan-Wort den bisherigen Tipp.
- **Stein ersetzen (50):** Stein antippen, er bekommt einen neuen Buchstaben. Den wählt die **Wort-Hilfe**. Kein Wunschbuchstabe.
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
  | Auffüllen | 5 Steine | 5 Steine mit stärkerer Wort-Hilfe |

- **Freigeschaltet wird im Lauf** (Roguelike): Jeder Lauf beginnt mit wenigen, einfachen Hilfen; mit Münzen schaltet man weitere Hilfen und die starken Stufen frei. Beim nächsten Lauf beginnt man wieder von vorn.
- Damit die Knopfleiste nicht überläuft (mehr als 5–6 Knöpfe passen schlecht), evtl. **Slots**: eine begrenzte Zahl Hilfe-Plätze, weitere Plätze freikaufbar.
- **[offen]** Wo man kauft: direkt am Hilfe-Knopf (z. B. „+“-Symbol, jederzeit, ohne Unterbrechung), in einem Laden zwischen den Levels, oder in einem Laden auf Wunsch. Wichtig: den Spielfluss nicht stören (deshalb sind die Auftragskarten entfallen).
- **[offen]** Mit welchen Hilfen ein Lauf beginnt, Preise der Freischaltungen.

### Draft-Plan
- **Umgesetzt (v3.28)**, siehe „Power-ups und Upgrades“ unter „Hilfen“.

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
- **v3.8:** Hilfe heißt „Auffüllen“ (statt Nachfüllen / „+5 Steine“) und kostet fest 100 (kein Preisanstieg mehr).
- **v3.9:** Aufräumen lässt mindestens so viele Steine liegen, wie alle freien Zeilen zusammen Blöcke haben.
- **v3.10:** Neue Hilfe „Lösen“ (500, ohne Belohnung): löst den ganzen Auftrag mit Wörtern aus dem Feld, wo möglich.
- **v3.11:** Lösen vorläufig für 100 (zum Testen), später wieder 500.
- **v3.12:** Neue Hilfen Joker, Mischen, Schwerkraft (je 50, zum Testen alle sichtbar). Draft-Plan festgehalten: Start nur mit Auffüllen, alle ~5 Levels eine von zwei zufälligen Hilfen wählen (später).
- **v3.13:** Neue Hilfen Magnet und Säule (je 50, per Antippen).
- **v3.14:** Belohnung fest 100 je gelöstem Auftrag (statt 100 + 10 × Level).
- **v3.15:** Neue Hilfen Teilen und Scan (je 50).
- **v3.16:** Zum Testen kosten vorläufig alle Hilfen 50; endgültige Preise am Schluss.
- **v3.17:** Scan zeigt nur noch ein Wort, für die längste freie Zeile.
- **v3.18:** Auffüllen ist gratis (mehr Steine machen es für Menschen nicht leichter, sondern unübersichtlicher).
- **v3.19:** Preise in 25er-Schritten nach Stärke (Lösen 400 … Mischen/Schwerkraft/Ersetzen/Tipp 25), Auffüllen gratis.
- **v3.20:** Auffüllen-Knopf pulsiert, wenn kein gültiges Wort in eine freie Zeile passt.
- **v3.21:** Neue Preise: Tauschen 50, Aufräumen 100, Magnet 100, Mischen 150, Scan 200. Säule entfällt. Hilfe-Knöpfe nach Preis sortiert (gratis bis teuer).
- **v3.22:** Schwerkraft entfällt.
- **v3.23:** Nach Scan tippt Tipp dasselbe Wort; Scan übernimmt ein laufendes Tipp-Wort gleicher Länge.
- **v3.24:** Neue Hilfe Vervollständigen (150): 2+ Buchstaben anwischen, das Spiel zeigt den Rest des Worts.
- **v3.25:** Neue Hilfe Kürzen (100): längste freie Zeile verliert einen Block.
- **v3.26:** Tauschen kostet 100 statt 50 (Bot-Simulation: bei 50 hält man sich mit Tauschen fast endlos über Wasser, Ø Level 137 statt 58).
- **v3.27:** Preisstufen: je drei Hilfen für 50 (Tipp, Ersetzen, Mischen), 100 (Aufräumen, Joker, Kürzen), 150 (Tauschen, Teilen, Vervollständigen), 200 (Magnet, Scan, Zeile streichen). Neue Hilfe Zeile streichen. Lösen als Sonderknopf für 500.
- **v3.28:** Roguelike-Draft: Start nur mit Auffüllen und Lösen; nach Level 4/8/12/16 eine von drei Hilfen der Stufe 50/100/150/200 wählen; ab Level 20 alle 4 Level ein Upgrade (−25 %, auch für Lösen). Hinweis „Noch n Level bis zum Power-up“. Knöpfe in 2 × 3.
- **v3.29:** Power-up: 2 zufällige von 3 Hilfen der Stufe zur Wahl. Auffüllen-Hinweis: Schrift blinkt dezent statt Pulsieren.
- **v3.30:** Kurve doppelt so lang (jeder feste Auftrag zweimal, Budget ab Level 21, +1 alle 10 Level, Hilfe-Stufe gestreckt); Atempausen ab Level 11 jedes 5. Level (eine Zeile mit 3–4 Blöcken); Power-ups nach Level 5/10/15/20, Upgrades alle 5 Level; Belohnung 50 statt 100.
- **v3.31:** Steckt man fest: Feld abgedunkelt und großer Auffüllen-Knopf auf dem Feld.
- **v3.32:** Modi Deutsch einfach (Kinder-Wortliste, Zeilen bis 5) / mittel (Zeilen bis 6, sanfter) / schwierig (bisheriges Spiel); Rekord je Modus; Belohnung wieder 100 in allen Modi.
- **v3.33:** Ziel Level 20 in allen Modi: danach Lauf geschafft mit Sternen (wie Story); Rekord = übrige Münzen; Aufgeben = nicht geschafft. Tipp kostet 100 und gehört zur 100er-Stufe (50er-Stufe: Ersetzen, Mischen). Power-ups nur noch nach Level 5, 10, 15.
- **v3.34:** Power-ups alle 4 Level (nach 4, 8, 12, 16), damit alle vier Stufen vor dem Ziel Level 20 drankommen.
- **v3.35:** Neue Preise: Tauschen 50, Mischen 100, Aufräumen 150, Magnet 150, Vervollständigen 200. Die Power-up-Stufen folgen den Preisen (50: Ersetzen, Tauschen; 100: Mischen, Joker, Kürzen, Tipp; 150: Aufräumen, Teilen, Magnet; 200: Scan, Zeile streichen, Vervollständigen).
