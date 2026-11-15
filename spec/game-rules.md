# Spielregeln

Status: **Entwurf v7.7**. Lauf-Modus (Roguelike mit Aufträgen und Münzen) ersetzt den ruhigen Level-Modus; Details in [run-mode.md](run-mode.md).

## Grundidee

Ein **Denk-Spiel ohne Zeitdruck** als **Roguelike**: Im Spielfeld liegen Buchstaben in Hexagons. Jedes Level ist ein **Auftrag**: Zeilen leerer Blöcke über dem Spielfeld zeigen, welche Wortlängen gesucht sind. Gelöste Aufträge bringen **Münzen**, mit denen man Hilfen kauft (Steine nachfüllen, Steine tauschen, Tipp, Stein ersetzen). Wer nicht weiterkommt, gibt auf, und der nächste **Lauf** beginnt wieder bei Level 1. Alles zum Lauf steht in [run-mode.md](run-mode.md); hier stehen die Regeln des Grundspiels.

## Festgelegt

### Hexagons und Raster
- Jeder Buchstabe sitzt in einem **Hexagon**, **unten flach** (flache Unter- und Oberseite).
- Das Raster hat senkrechte Spalten; jede zweite Spalte ist um ein halbes Feld versetzt.
- Größe: **5 Spalten × 6 Reihen = 30 Plätze** (siehe [screen-layout.md](screen-layout.md)).
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
- Bei einem **ungültigen** oder **nicht passenden** Wort bleibt das Feld unverändert; die Steine **wackeln**. Kein Text.

### Gültige Wörter
- **Alle Wortformen** gelten, auch gebeugte (z. B. STERNE, RANNTE, GROSSEN).
- **Eigennamen** (z. B. BERLIN, ANNA, OLGAS) und **Abkürzungen** (z. B. USA, KFZ) gelten **nicht**.
  - Ausnahme: Ist ein Name **auch ein normales Wort** (z. B. ROSE, WOLF, BACH, ERNST, WINTER), gilt er.
  - Entfernt wird ein Wort, wenn Wiktionary es **nur** als Eigenname oder Abkürzung kennt (samt Formen), oder wenn die Trennmuster-Liste es im Kommentar als **Name** vermerkt (z. B. „engl. Name“, „geogr. Name“), außer Wiktionary kennt es als normales Wort (z. B. Newton, Dobermann). Seltene Namen, die Wiktionary nicht kennt, können durchrutschen; dafür später ggf. eine eigene Sperrliste.
- **Akronyme** wie DEA, CIA, CPU, AfD gelten ebenfalls nicht (in der Trennmuster-Liste als „Abk.“ markiert oder ganz großgeschrieben), außer Wiktionary kennt sie als normal geschriebenes Wort (z. B. Aids, Ufo, Abc).
- **Römische Zahlen** (z. B. LIII, XII) gelten nicht, außer sie sind auch ein normales Wort (z. B. MIX).
- Weiterhin: nur A–Z, Wörter mit Umlauten vorerst nicht (siehe „Sprache“).

### Vorschlags-Wörter (geläufige Wörter)
- Zwei Listen mit getrennten Aufgaben:
  - **Gültige Wörter** (ganzes Wörterbuch, siehe oben): entscheiden, ob ein gewischtes Wort zählt. Auch gebeugte Formen wie HAUSES oder ABIRRTE zählen weiter.
  - **Vorschlags-Wörter** (neu, eigene kleine Liste): nur diese Wörter bringt das Spiel **selbst** ins Spiel, also bei Wort-Hilfe, Nachfüllen, Tauschen, Magnet, Tipp, Scan, Lösen und der Lösung beim Aufgeben. Ziel: Die angebotenen Wörter sind **schön, bekannt und alltäglich**, nicht seltene Beugungsformen.
- **Formen:** nur **Grundformen plus Mehrzahl**: Hauptwort im Nominativ Einzahl und Mehrzahl (TISCH, TISCHE, BLUME, BLUMEN), Verb im Infinitiv (LAUFEN), Adjektiv in der Grundform (WILD). Keine Genitive, keine gebeugten Verb- oder Adjektivformen (HAUSES, LIEF, WILDEN).
  - Erkennung über Wiktionary: Stichwort oder nur Beugungsform; die Mehrzahl steht dort beim Hauptwort.
- **Ohne Artikel und Pronomen:** DER, DIE, DAS, EINE, ICH, WIR, IHM u. ä. werden nicht vorgeschlagen. Bindewörter, Adverbien und Präpositionen bleiben (ABER, ODER, OBEN, UNTER).
- **Häufigkeit:** nur die **rund 15.000 häufigsten** passenden Wörter (Zahl ist ein Spielwert und wird an der fertigen Liste nachjustiert).
  - Quelle der Häufigkeit (geplant): **Leipzig Corpora Collection** (Uni Leipzig, Wortschatz), laut Übersicht **CC BY 4.0**, also kommerziell nutzbar mit Namensnennung. Lizenz vor dem Einbau auf der Quellseite prüfen.
  - Nicht geeignet: DeReKo (nur nicht-kommerziell); Untertitel-Listen und wordfreq (CC BY-SA, eher heikel).
- Eventuell später eine kleine **Sperrliste** für Wörter, die gültig, aber als Vorschlag unschön oder unpassend sind.
- Nur Wörter, die auch **gültig** sind (Vorschlags-Wörter sind eine Teilmenge des Wörterbuchs).

### Wörterbuch (Deutsch)
- **Quellen:**
  - **Basis:** Trennmuster-Wortliste (DANTE / Werner Lemberg, `repo.or.cz/wortliste.git`), Lizenz **MIT**.
  - **Ergänzung:** Wiktionary (Auszug über kaikki.org) für fehlende Formen und zum Erkennen von Eigennamen und Abkürzungen, Lizenz **CC BY-SA 3.0 / GFDL**.
- **Aufbereitung** (einmalig, als eigene Wortliste fürs Spiel):
  - Großbuchstaben A–Z; **ß → SS**; Wörter mit **Umlauten entfallen**; Wörter mit anderen Sonderzeichen (Bindestrich, Apostroph, Ziffern) entfallen.
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
- Erste Version: **ohne Umlaute und Sonderzeichen**, nur die Buchstaben A–Z. **ß wird als SS** geschrieben. **Wörter mit Umlauten** (z. B. „Bär“) werden vorerst **weggelassen**.
- Von Anfang an so bauen, dass **weitere Sprachen** möglich sind: Wörterbuch, Alphabet und Buchstabenverteilung austauschbar, keine fest verdrahtete Sprache im Spielcode.

## Später festlegen

- **Vorschlags-Wörter umsetzen** (siehe oben); danach Größe und Sperrliste an Testspielen nachjustieren.
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
