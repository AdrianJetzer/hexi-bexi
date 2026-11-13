# Spielregeln

Status: **Entwurf v4**. Kernspiel für Version 1 abgestimmt; ausgefeilte Füll-Logik, Wörterbuch-Quelle und Effekte folgen später.

## Grundidee

Im Spielfeld erscheinen nach und nach Buchstaben in Hexagons und füllen es von unten nach oben. Der Spieler findet Wörter in den Buchstaben und räumt das Feld damit frei. Es ist ein Wettlauf: Wörter finden, bevor kein Platz mehr frei ist.

## Festgelegt

### Hexagons und Raster
- Jeder Buchstabe sitzt in einem **Hexagon**, **unten flach** (flache Unter- und Oberseite).
- Das Raster hat senkrechte Spalten; jede zweite Spalte ist um ein halbes Feld versetzt.
- Größe: **6 Spalten × 9 Reihen = 54 Plätze** (siehe [screen-layout.md](screen-layout.md)).
- Das Spielfeld ist **geschlossen**; seine Innenkante folgt dem Raster im Zickzack (siehe [screen-layout.md](screen-layout.md)).

### Spielstart
- Eine Runde beginnt mit **2 gefüllten Reihen** (12 Hexagons).

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

### Tempo
- Neue Hexagons erscheinen in einem **festen Takt**.
- Nach einem gefundenen Wort wird **nicht** zusätzlich nachgefüllt; Löcher füllt nur der Takt.
- **Startwerte für Version 1** (alle als Einstellungen, nicht fest im Code, später tunebar):
  - Start: **alle 3 Sekunden** ein Hexagon.
  - **Alle 30 Sekunden** wird der Takt **10 % kürzer**.
  - Kürzester Takt: **0,8 Sekunden**.
- **Tempo-Stufe** (Anzeige im Infobereich): beginnt bei **1** und steigt bei jeder Verkürzung des Takts um 1.

### Buchstabenwahl
- Grundlage: Zufall, **gewichtet nach Buchstabenhäufigkeit** der Sprache (viel E, N, I, S, R; selten Q, X, Y).
- **Vokal-Ausgleich:** Es wird darauf geachtet, dass nie zu wenige Vokale im Feld liegen. Die genaue Regel ist Teil der Umsetzung und wird getunt.
- **Wort-Hilfe (Vorausschau):** Bevor ein neues Hexagon erscheint, steht sein Platz fest. Das Spiel bewertet für diesen Platz jeden möglichen Buchstaben danach, wie viele **geläufige Wörter** er zusammen mit den Nachbarn möglich macht, und bevorzugt gute Buchstaben – gewichtet, nicht immer (sonst zu vorhersehbar).
- **Mindestens X Wörter:** Das Spiel zählt, wie viele geläufige Wörter gerade im Feld möglich sind. Sind es weniger als die Stufe verlangt, hilft es stärker nach (wählt den Buchstaben mit den meisten Wörtern).
- **Geläufige Wörter** für die Hilfe: vorerst die Einträge der Trennmuster-Wortliste. **Gültig** bleiben weiterhin alle Wörter des Wörterbuchs.
- Wie stark geholfen wird, bestimmt die **Schwierigkeitsstufe**.

### Schwierigkeitsstufen
- **5 Stufen**, die **nur die Wort-Hilfe** verändern. Tempo, Startreihen und Punkte sind auf allen Stufen gleich.
- Der Spieler stellt die Stufe in den **Einstellungen** ein; Standard beim ersten Start: **2 (Leicht)**.
- Jede Stufe hat ihren **eigenen Rekord**.

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
- **Mindestlänge: 3 Buchstaben.**
- Ein gültiges Wort **verschwindet**, also alle seine Hexagons. Zurück bleiben Löcher.
- Bei einem **ungültigen** Wort passiert **nichts**. Keine Strafe, das Feld bleibt unverändert.

### Gültige Wörter
- **Alle Wortformen** gelten, auch gebeugte (z. B. STERNE, RANNTE, GROSSEN).
- **Eigennamen** (z. B. BERLIN, ANNA) und **Abkürzungen** (z. B. USA, KFZ) gelten ebenfalls.
- Weiterhin: nur A–Z, Wörter mit Umlauten vorerst nicht (siehe „Sprache“).

### Wörterbuch (Deutsch)
- **Quellen:**
  - **Basis:** Trennmuster-Wortliste (DANTE / Werner Lemberg, `repo.or.cz/wortliste.git`), Lizenz **MIT**.
  - **Ergänzung:** Wiktionary (Auszug über kaikki.org) für Eigennamen, Abkürzungen und fehlende Formen, Lizenz **CC BY-SA 3.0 / GFDL**.
- **Aufbereitung** (einmalig, als eigene Wortliste fürs Spiel):
  - Großbuchstaben A–Z; **ß → SS**; Wörter mit **Umlauten entfallen**; Wörter mit anderen Sonderzeichen (Bindestrich, Apostroph, Ziffern) entfallen.
  - **Mindestens 3 Buchstaben.**
  - Nur **neue Rechtschreibung**.
- **Lizenzpflichten:** Namensnennung beider Quellen (z. B. im Store-Text oder einem Lizenz-Hinweis in der App). Die aus Wiktionary abgeleitete Wortliste bleibt unter **CC BY-SA**; der Spielcode ist davon nicht betroffen.
- Lizenztexte vor der Veröffentlichung selbst prüfen.

### Punkte
- Die Wortlänge zählt stark: **Punkte = 5 · n · (n − 1)**, n = Anzahl Buchstaben.

  | Buchstaben | 3 | 4 | 5 | 6 | 7 | 8 |
  |---|---|---|---|---|---|---|
  | Punkte | 30 | 60 | 100 | 150 | 210 | 280 |

### Spielende
- Das Spiel ist verloren, wenn **kein Platz mehr frei** ist.

### Sprache
- **Zuerst Deutsch.**
- Erste Version: **ohne Umlaute und Sonderzeichen**, nur die Buchstaben A–Z. **ß wird als SS** geschrieben. **Wörter mit Umlauten** (z. B. „Bär“) werden vorerst **weggelassen**.
- Von Anfang an so bauen, dass **weitere Sprachen** möglich sind: Wörterbuch, Alphabet und Buchstabenverteilung austauschbar, keine fest verdrahtete Sprache im Spielcode.

## Später festlegen

- **Wörter gezielt säen:** ein Ziel-Wort wählen und seine Buchstaben über die nächsten neuen Hexagons verteilen (Ausbaustufe nach der Vorausschau).
- **Bessere Liste geläufiger Wörter** (z. B. Häufigkeitsliste mit passender Lizenz).
- **Feintuning der Stufen** anhand von Testspielen.
- **Feintuning Tempo:** Werte anhand von Testspielen anpassen.
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
