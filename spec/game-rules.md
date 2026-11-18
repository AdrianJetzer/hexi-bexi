# Spielregeln

Status: **Entwurf v8.5** (Wörterbuch: Namen gelten, schöne Wörter; Spiel zeigt nur schöne Wörter; Durchsicht offen). Lauf-Modus (Roguelike mit Aufträgen und Münzen) ersetzt den ruhigen Level-Modus; Details in [run-mode.md](run-mode.md).

## Grundidee

Ein **Denk-Spiel ohne Zeitdruck** als **Roguelike**: Im Spielfeld liegen Buchstaben in Hexagons. Jedes Level ist ein **Auftrag**: Zeilen leerer Blöcke über dem Spielfeld zeigen, welche Wortlängen gesucht sind. Gelöste Aufträge bringen **Münzen**, mit denen man Hilfen kauft (Steine nachfüllen, Steine tauschen, Tipp, Stein ersetzen). Wer nicht weiterkommt, gibt auf, und der nächste **Lauf** beginnt wieder bei Level 1. Alles zum Lauf steht in [run-mode.md](run-mode.md); hier stehen die Regeln des Grundspiels.

## Festgelegt

### Hexagons und Raster
- Jeder Buchstabe sitzt in einem **Hexagon**, **unten flach** (flache Unter- und Oberseite).
- Das Raster hat senkrechte Spalten; jede zweite Spalte ist um ein halbes Feld versetzt.
- Größe: **5 Spalten × 5 Reihen = 25 Plätze** (siehe [screen-layout.md](screen-layout.md)).
- Das Spielfeld ist **geschlossen**; seine Innenkante folgt dem Raster im Zickzack (siehe [screen-layout.md](screen-layout.md)).

### Spielstart
- Ein Lauf beginnt mit **10 Hexagons**, verteilt nach der Platzwahl (zuerst die tiefsten Plätze).
- Start in **Level 1** mit **0 Münzen** (siehe [run-mode.md](run-mode.md)).
- Das Feld bleibt zwischen den Levels liegen.

### Neue Buchstaben erscheinen
- Buchstaben **fallen nicht**. Ein neues Hexagon **erscheint direkt an einem freien Platz**.
- Ablauf:
  1. Das Hexagon **blendet ein** (Fade-in) und zeigt dabei seine **Rückseite**. Der Buchstabe **schimmert spiegelverkehrt** durch.
  2. Dann **dreht sich das Hexagon in 3D** auf die Vorderseite, mit eindrucksvollem **Soundeffekt**.
- Das Hexagon ist **sofort nutzbar**, sobald es sichtbar ist, also schon während es spiegelverkehrt zu sehen ist.
- Der Spieler kann nicht beeinflussen, wo oder welcher Buchstabe erscheint.

### Füllen von unten nach oben
- Neue Hexagons erscheinen **nicht schwebend**: Das Feld füllt sich **von unten nach oben**.
- **Löcher**, die durch gefundene Wörter entstehen, **bleiben offen**. Es rutscht nichts nach.
- Neue Hexagons erscheinen **zuerst in den Löchern**, und zwar ebenfalls von unten nach oben.
- **Platzwahl (Version 1):**
  1. Gibt es Löcher, kommt das neue Hexagon in eines der **tiefsten Löcher**.
  2. Sonst auf einen der **tiefsten freien Plätze**, auf dem es nicht schwebt.
  3. Bei mehreren gleich tiefen Plätzen wird **zufällig** gewählt.

### Nachschub (kein Takt)
- Es gibt **keinen Takt**: Neue Hexagons kommen **nicht nach Zeit**.
- Nach jedem gefundenen Wort kommen automatisch **Wortlänge − 1** neue Hexagons (siehe [run-mode.md](run-mode.md)).
- Weitere neue Hexagons gibt es über die **Hilfen** des Lauf-Modus: **5 Steine nachfüllen** (ab 100 Münzen, mit jedem Kauf teurer); **Steine tauschen** und **Stein ersetzen** ändern nur Buchstaben (siehe [run-mode.md](run-mode.md)).
- **Feld voll:** Ist nicht genug Platz frei, kommen nur so viele Hexagons, wie hineinpassen. Ist gar kein Platz frei, ist Auffüllen gesperrt.
- Alle Zahlen sind Spielwerte (tunebar), nicht fest im Code.

### Buchstabenwahl
- Grundlage: Zufall, **gewichtet nach Buchstabenhäufigkeit** der Sprache (viel E, N, I, S, R; selten Q, X, Y).
- **Vokal-Ausgleich:** Es wird darauf geachtet, dass nie zu wenige Vokale im Feld liegen. Die genaue Regel ist Teil der Umsetzung und wird getunt.
- **Wort-Hilfe (Vorausschau):** Bevor ein neues Hexagon erscheint, steht sein Platz fest. Das Spiel bewertet für diesen Platz jeden möglichen Buchstaben danach, wie viele **geläufige Wörter** er zusammen mit den Nachbarn möglich macht, und bevorzugt gute Buchstaben – gewichtet, nicht immer (sonst zu vorhersehbar).
- **Auf den Auftrag ausgerichtet:** Gezählt werden nur Wörter in den **Längen der noch freien Zeilen** (z. B. bei ▢▢▢▢▢ nur Wörter mit 5 Buchstaben, bis 8 Buchstaben). So legt die Hilfe gezielt Bausteine für die gesuchten Wörter ins Feld, statt viele kurze Wörter zu ermöglichen.
- **Mindestens X Wörter:** Das Spiel zählt, wie viele geläufige Wörter (in den gesuchten Längen) gerade im Feld möglich sind. Sind es weniger als die Stufe verlangt, hilft es stärker nach (wählt den Buchstaben mit den meisten Wörtern).
- **Geläufige Wörter** für die Hilfe: die **Vorschlags-Wörter** (siehe unten). **Gültig** bleiben weiterhin alle Wörter des Wörterbuchs.
- Wie stark geholfen wird, bestimmt die **Hilfe-Stufe**, und die ergibt sich aus dem **Level** des Laufs.

### Hilfe-Stufen
- **5 Stufen** für die Wort-Hilfe. Der Spieler wählt sie **nicht** selbst; das **Level** des Laufs legt sie fest (am Anfang stark, später schwächer, siehe Kurve in [run-mode.md](run-mode.md)).

  | Stufe | Name | Hilfe | Mindestens möglich im Feld |
  |---|---|---|---|
  | 1 | Sehr leicht | stark | 8 Wörter |
  | 2 | Leicht | stark | 5 Wörter |
  | 3 | Mittel | mittel | 3 Wörter |
  | 4 | Schwer | schwach | 1 Wort |
  | 5 | Profi | keine (Zufall mit Vokal-Ausgleich) | – |

- Alle Zahlen sind Spielwerte (tunebar), nicht fest im Code.

### Wörter bilden
- Der Spieler **wischt** mit dem Finger über die Buchstaben, die ein Wort ergeben.
- **Zurückwischen** auf einen schon gewählten Buchstaben bewirkt **nichts**. Zum Korrigieren loslassen und neu beginnen.
- Ob das Wort gültig ist, zeigt sich **erst beim Loslassen**, nicht schon während des Wischens.
- Aufeinanderfolgende Buchstaben müssen **Nachbarn** sein (ein Hexagon hat 6 Nachbarn). Buchstaben **überspringen geht nicht**.
- Jedes Hexagon darf in einem Wort **nur einmal** vorkommen.
- **Mindestlänge:** immer **3 Buchstaben**.
- Angenommen wird nur ein Wort, das **genau so lang** ist wie eine noch freie Block-Zeile des Auftrags. Ein echtes, aber nicht passendes Wort wird **abgelehnt**; die Steine bleiben liegen (siehe [run-mode.md](run-mode.md)).
- Ein gültiges Wort **verschwindet**, also alle seine Hexagons. Zurück bleiben Löcher.
  - **Zerspringen (v8.2):** Gleichzeitig fliegt jeder Buchstabe nach oben in seinen Block, und der übrig gebliebene Stein zerspringt in feine, durchsichtige **Glas-Splitter** (v8.3; additiv leuchtend, der Hintergrund scheint durch) – jedes Mal zufällig: 5 bis 8 Splitter, Bruchpunkt nicht genau in der Mitte, unregelmäßige Schnitte, zufällige Flugrichtung und Drehung. Die Splitter fliegen nach außen und leicht nach oben, fallen dann, werden kleiner und verglimmen (ca. 0,8 s); dazu ein kurzer Lichtblitz. Die Steine eines Worts zerspringen leicht versetzt nacheinander.
- Bei einem **ungültigen** oder **nicht passenden** Wort bleibt das Feld unverändert; die Steine **wackeln**. Kein Text.

### Gültige Wörter
- **Alle Wortformen** gelten, auch gebeugte (z. B. STERNE, RANNTE, GROSSEN).
- **Eigennamen gelten** (v8): Vornamen, Orte, Länder, Flüsse, Marken, Personen, **samt Formen** (LEO, LEOS, ANNA, OLGAS, BERLIN, BERLINS). Sie werden aber **nie vom Spiel gelegt** (nicht in den schönen Wörtern, siehe unten), nur beim Wischen akzeptiert.
  - Bisher (v6.6 bis v7.13) galten Eigennamen nicht, außer handverlesene aus den Story-Listen. Anlass war OLGAS als Lösung; mit der Trennung „schöne Wörter“ / „gültige Wörter“ kann das nicht mehr passieren.
- **Abkürzungen** (z. B. USA, KFZ, NASA) gelten weiterhin **nicht**. Abkürzungen aus den Story-Listen (NASA, BMW, AFK …) zählen nur im Story-Kapitel.
- **Akronyme** wie DEA, CIA, CPU, AfD gelten ebenfalls nicht (in der Trennmuster-Liste als „Abk.“ markiert oder ganz großgeschrieben), außer Wiktionary kennt sie als normal geschriebenes Wort (z. B. Aids, Ufo, Abc).
- Ebenso Wörter, deren Wiktionary-Eintrag **Großbuchstaben mitten im Wort** hat (z. B. „UGs“ als Mehrzahl von UG = Untergeschoss, „CEOs“, „NASA“, „iPod“), außer es gibt sie auch normal geschrieben. Wörter mit Bindestrich oder Leerzeichen (z. B. „Armee-Einheit“) sind davon nicht betroffen.
- **Veraltete Schreibweisen** gelten nicht (im Wiktionary als veraltet markierte Formen, z. B. THEE für Tee, CITAT, CONCERT, TELEPHON), außer es gibt das Wort auch in heutiger Schreibung. Alte Formen mit ß bleiben unberührt (aus „hinuntergoß“ wird HINUNTERGOSS, und das ist heute richtig).
- **Römische Zahlen** (z. B. LIII, XII) gelten nicht, außer sie sind auch ein normales Wort (z. B. MIX).
- Buchstaben A–Z und Ä, Ö, Ü (siehe „Sprache“).

### Schöne Wörter (Vorschlags-Wörter)
- Zwei Listen mit getrennten Aufgaben:
  - **Alle gültigen Wörter** (ganzes Wörterbuch, siehe oben): entscheiden, ob ein gewischtes Wort zählt. Auch gebeugte Formen (HAUSES, ABIRRTE), Namen (LEO) und seltene Wörter (SHUKA) zählen.
  - **Schöne Wörter** (eigene kleine Liste): nur diese Wörter bringt das Spiel **selbst** ins Spiel, also bei Wort-Hilfe, Auffüllen, Magnet, Tipp, Scan, Lösen und der Lösung beim Aufgeben. Im Feld liegen damit **mehrheitlich schöne Wörter** (zufällig können auch andere gültige Wörter entstehen).
- **Neu in v8 (nach Testspielen: die gelegten Wörter wirkten oft fremd oder hässlich):**
  - **Nur Grundformen:** Hauptwort im Nominativ **Einzahl** (TISCH, BLUME), Verb im Infinitiv (LAUFEN), Adjektiv in der Grundform (WILD). **Keine Mehrzahl** mehr, keine Beugungen (TISCHE, HAUSES, LIEF, WILDEN).
  - **Alltagsnah statt zeitungsnah:** Häufigkeit zu 75 % aus allgemeinen Texten (`deu_mixed-typical`), zu 25 % aus Nachrichten; die Wörter der Alltags-Kapitel (Tiere, Gemüse, Früchte, Kleidung, Berufe, Sportarten, Instrumente) werden bevorzugt. Wörter, deren Bedeutungen im Wiktionary alle als veraltet, selten, abwertend, regional o. ä. markiert sind, fallen raus.
  - **Ohne gesperrte Wörter:** Sperrliste (`blocklist-suggestions.txt`) erweitert um Schimpf- und Vulgärwörter, Gewalt, Krankheit, Politik, belastete Begriffe.
  - **Ohne Namen** und ohne Abkürzungen.
  - **Größe:** **5.000** Wörter (3 Buchstaben: ca. 120, 4: 540, 5: 880, 6–8: je ca. 1.150).
  - **Durchsicht durch Adrian:** Die Liste wird in Portionen (nach Länge) vorgelegt; was nicht gefällt, kommt auf die Sperrliste.
- **Stimmig ohne schönes Wort (v8.4):** „Steckt man fest?“ heißt jetzt: kein **schönes** Wort im Feld – dann füllt das Spiel seit v8.5 selbst auf (vorher: Feld abgedunkelt und großer Auffüllen-Knopf; seltene gültige Wörter darf man trotzdem wischen). **Lösen** ohne schönes Wort im Feld lässt Steine sich umdrehen und ein schönes Wort bilden (wie Magnet, bei zu wenig Steinen vorher auffüllen); dieses fliegt dann aus dem Feld in die Zeile – kein Wort mehr aus dem Nichts. Ploppen direkt in die Zeile nur noch, wenn auch das nicht geht.
- **Nur schöne Wörter zeigen (v8.1):** Tipp, Scan, Lösen und die Lösung beim Aufgeben suchen **nur** in den schönen Wörtern, nie mehr ersatzweise im ganzen Wörterbuch (vorher konnte so z. B. ISCH als Lösung kommen). Liegt kein schönes Wort im Feld: Lösen und die Lösung beim Aufgeben lassen ein schönes Wort direkt in die Zeile ploppen; Tipp und Scan kosten nichts und wackeln. Ausnahme: Vervollständigen (Anfang vom Spieler) greift zuletzt auch auf alle gültigen Wörter zurück.
- **Weiterhin:** ohne Artikel und Pronomen (DER, DIE, ICH, WIR …; Ausnahme SEIN), ohne Akronyme, nur Wörter, die auch gültig sind.
- **Häufigkeit (Quelle):** **Leipzig Corpora Collection** (Uni Leipzig, Wortschatz), Korpora `deu_news_2023_1M` und `deu_mixed-typical_2011_1M`, Lizenz **CC BY** (vor Veröffentlichung auf der Quellseite prüfen). Nicht geeignet: DeReKo (nur nicht-kommerziell); Untertitel-Listen und wordfreq (CC BY-SA, eher heikel).
- **Bisher (v7.7 bis v7.13):** 10.000 häufigste Grundformen plus Mehrzahl, Häufigkeit aus beiden Korpora gemittelt.

### Wörterbuch (Deutsch)
- **Quellen:**
  - **Basis:** Trennmuster-Wortliste (DANTE / Werner Lemberg, `repo.or.cz/wortliste.git`), Lizenz **MIT**.
  - **Ergänzung:** Wiktionary (Auszug über kaikki.org) für fehlende Formen und zum Erkennen von Eigennamen und Abkürzungen, Lizenz **CC BY-SA 3.0 / GFDL**.
- **Aufbereitung** (einmalig, als eigene Wortliste fürs Spiel):
  - Großbuchstaben A–Z und Ä, Ö, Ü; **ß → SS**; Wörter mit anderen Sonderzeichen (Bindestrich, Apostroph, Ziffern, andere Akzente) entfallen.
  - **Mindestens 3 Buchstaben.**
  - Nur **neue Rechtschreibung**.
- **Lizenzpflichten:** Namensnennung beider Quellen (z. B. im Store-Text oder einem Lizenz-Hinweis in der App). Die aus Wiktionary abgeleitete Wortliste bleibt unter **CC BY-SA**; der Spielcode ist davon nicht betroffen.
- Lizenztexte vor der Veröffentlichung selbst prüfen.

### Punkte
- **Entfallen.** An ihre Stelle treten Münzen und Level (siehe [run-mode.md](run-mode.md)).

### Ende eines Laufs
- Der Lauf endet, wenn der Spieler **aufgibt** (Knopf „Aufgeben“ mit Nachfrage).
- Danach zeigt ein **Bilanz-Screen** das erreichte Level und den Rekord (siehe [screens.md](screens.md)).
- **Rekord** = höchstes erreichtes Level (ein Rekord, keine Stufen).

### Sprache
- **Zuerst Deutsch.**
- **Umlaute Ä, Ö, Ü** sind eigene Steine (seit v7.12), mit eigener Häufigkeit (Ä 0,54 %, Ö 0,30 %, Ü 0,65 %). Wörter mit Umlauten gelten (SCHÖN, GRÜN, MÖHRE). **ß wird als SS** geschrieben.
- Von Anfang an so bauen, dass **weitere Sprachen** möglich sind: Wörterbuch, Alphabet und Buchstabenverteilung austauschbar, keine fest verdrahtete Sprache im Spielcode.

## Später festlegen

- **Vorschlags-Wörter:** Größe und Sperrliste an Testspielen nachjustieren.
- **Feintuning** von Hilfe-Stufen, Auftrags-Kurve und Münz-Preisen anhand von Testspielen.
- **Wörterbuch:** Abdeckung und Größe der aufbereiteten Liste prüfen (Quellen siehe oben).
- **Effekte und Feedback:** Einblenden, 3D-Drehung, Sound, Wischen, gültige und ungültige Wörter.

## Verlauf

- **v1:** Grundidee mit fallenden Buchstaben, Wischen, Mindestlänge 3, Nachrutschen, Spielende, Sprache.
- **v1.1:** Nachbarschaft beim Wischen, keine Mehrfachnutzung, ungültige Wörter, A–Z mit ß als SS, Hexagons unten flach.
- **v1.2:** Wörter mit Umlauten vorerst weglassen.
- **v2:** Buchstaben fallen nicht mehr, sondern erscheinen mit 3D-Drehung an freien Plätzen (von unten nach oben). Kein Nachrutschen; Löcher werden neu gefüllt. Spielende, wenn kein Platz frei ist. Spielfeld geschlossen mit Zickzack-Innenkante. Entfällt: seitliches Nachrutschen mit Physik.
- **v3:** Kernspiel für Version 1: Start mit 2 Reihen, Platzwahl, Takt (3 s, −10 % alle 30 s, min. 0,8 s), Buchstabenwahl mit Vokal-Ausgleich, Wischen ohne Zurück und ohne Live-Prüfung, gültige Wörter (alle Formen, Eigennamen, Abkürzungen), Punkte 5 · n · (n − 1).
- **v3.1:** Wörterbuch-Quellen: Trennmuster-Wortliste (MIT) + Wiktionary (CC BY-SA), Aufbereitung und Lizenzpflichten.
- **v4:** Wort-Hilfe per Vorausschau, „mindestens X Wörter“, 5 Schwierigkeitsstufen (nur Hilfe), Rekord pro Stufe, geläufige Wörter = Trennmuster-Liste.
- **v5:** Ruhiger Level-Modus: kein Takt; Start mit 15 Hexagons; Level-Up bei wachsenden Punktschwellen bringt 10 Hexagons; Mindestlänge 3/4/5 je Level; Knopf „Neue Buchstaben“ (3 für 20 Punkte); endlos, Rundenende mit Bilanz. Entfällt: Takt, Tempo-Stufe, Verlieren bei vollem Feld.
- **v6:** Lauf-Modus (siehe [run-mode.md](run-mode.md)): Start mit 20 Hexagons und 0 Münzen; Feld bleibt zwischen Levels; Nachschub nur über gekaufte Hilfen; Mindestlänge immer 3, jedes gültige Wort zählt als Zug; Hilfe-Stufe folgt dem Level; Ende nur durch Aufgeben; Rekord = höchstes Level. Entfällt: Punkte, Punkt-Schwellen, +10 Hexagons pro Level, Knopf „Neue Buchstaben“, wählbare Schwierigkeitsstufen.
- **v6.1:** Raster 5 × 9 (45 Plätze).
- **v6.2:** Lauf endet auch, wenn ein Zuglimit verfehlt wird.
- **v6.3:** Preise der Hilfen siehe run-mode.md v2.5.
- **v6.4:** Nur zum Auftrag passende Wörter werden angenommen; jeder Versuch ab 3 Buchstaben ist ein Zug.
- **v6.5:** Automatisches Auffüllen nach gefundenen Wörtern (Wortlänge − 1).
- **v6.6:** Eigennamen und Abkürzungen gelten nicht mehr (außer sie sind auch normale Wörter).
- **v7:** Aufträge als Block-Zeilen (genaue Länge), Ablehnung nur durch Wackeln, Lauf endet nur durch Aufgeben. Entfallen: Zug, Zuglimit, „ohne Nachziehen“, gezieltes Säen.
- **v7.1:** Wort-Hilfe zählt nur Wörter in den Längen der freien Auftrags-Zeilen (bis 8 Buchstaben).
- **v7.2:** Römische Zahlen gelten nicht (außer sie sind auch ein normales Wort).
- **v7.3:** Start mit 10 Hexagons.
- **v7.4:** Akronyme und als „Abk.“ markierte Trennmuster-Einträge gelten nicht (außer normal geschriebene Wörter wie Aids, Ufo).
- **v7.5:** Als Name vermerkte Trennmuster-Einträge (POE, ARMSTRONG, AADORF …) gelten nicht.
- **v7.6:** Raster 5 × 6 (größere Hexagons, Feld fast so breit wie das Handy).
- **v7.7:** Vorschlags-Wörter: eigene Liste für alles, was das Spiel selbst anbietet (Grundformen plus Mehrzahl, ohne Artikel und Pronomen, ca. 15.000 häufigste, Häufigkeit aus Leipzig Corpora). Gültig bleiben alle Wörter.
- **v7.8:** Vorschlags-Wörter umgesetzt: 10.000 häufigste, nur 3 bis 8 Buchstaben, Sperrliste, ohne Akronyme.
- **v7.9:** Raster 5 × 5 (25 Plätze), damit unten mehr Platz für die Hilfe-Knöpfe ist.
- **v7.10:** Wörter mit Großbuchstaben mitten im Wiktionary-Stichwort (UGS, CEOS, NASA, IPOD …) gelten nicht (160 Wörter).
- **v7.11:** Veraltete Schreibweisen (THEE, CITAT, CONCERT …) gelten nicht (rund 1.670 Wörter).
- **v7.12:** Umlaute Ä, Ö, Ü als eigene Steine; Wörterbuch rund 1,02 Mio. Wörter.
- **v7.13:** Eigennamen aus den Story-Listen gelten auch im normalen Lauf (ohne Abkürzungen, nicht als Tipp/Lösung).
- **v8 (Entwurf):** Eigennamen gelten wieder (samt Formen, nie vom Spiel gelegt), Abkürzungen weiterhin nicht. Neue Liste „schöne Wörter“: nur Grundformen ohne Mehrzahl, alltagsnah, ohne gesperrte Wörter und Namen, ca. 4.000–6.000, Durchsicht durch Adrian.
- **v8.1:** Tipp, Scan, Lösen und Aufgeben-Lösung nur noch aus den schönen Wörtern (kein Rückgriff aufs ganze Wörterbuch); ohne schönes Wort im Feld ploppt eines direkt in die Zeile.
- **v8.2:** Gefundene Steine zerspringen zufällig in Kristall-Splitter, während der Buchstabe nach oben fliegt.
- **v8.3:** Weniger, feinere Splitter (5–8) aus durchsichtigem, leicht leuchtendem Glas.
- **v8.4:** Feststecken = kein schönes Wort im Feld (Auffüllen-Angebot); Lösen dreht Steine zu einem schönen Wort um statt es aus dem Nichts in die Zeile zu setzen.
- **v8.5:** Feststecken löst automatisches Auffüllen aus (gratis, bis ein schönes Wort passt oder das Feld voll ist); kein Dialog mehr (siehe [run-mode.md](run-mode.md) v3.38).
