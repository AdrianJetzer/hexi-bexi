# Lauf-Modus (Roguelike)

Status: **Entwurf v2**. Offene Fragen geklärt, Umfang für Version 1 festgelegt.

Markierungen: **[v1]** = kommt in Version 1 · **[später]** = gute Idee, nach Version 1 · **[offen]** = noch nicht entschieden.

Abschnitte ohne Markierung gehören zum Grundgerüst und sind **[v1]**.

## Idee in einem Satz

Ein **Lauf** besteht aus Levels, jedes Level ist ein **Auftrag** („Finde ein Wort mit 5 Buchstaben“). Erfüllte Aufträge bringen **Münzen**, mit denen man sich **Hilfen** kauft. Wer kein Geld mehr hat oder nicht weiterkommt, scheitert, und der nächste Lauf beginnt **wieder bei Level 1**.

Ersetzt den ruhigen Level-Modus aus [game-rules.md](game-rules.md) (Punkte-Schwellen, +10 Hexagons). Das Grundspiel bleibt: Raster, Wischen, Wörterbuch, Wort-Hilfe.

## Ablauf eines Laufs

1. **Start:** Level 1, **0 Münzen**, Spielfeld mit **20 Hexagons** (Platzwahl wie bisher). Das erste Level muss ohne Hilfe klappen.
2. **Level:** Der Spieler bekommt einen Auftrag und versucht ihn mit Wörtern im Feld zu erfüllen.
3. **Erfüllt:** Münzen gutschreiben, weiter zum nächsten, schwereren Level.
4. **Gescheitert:** Der Lauf endet, wenn
   - der Spieler nicht weiterkommt (z. B. kein Geld mehr für Hilfen) und **„Aufgeben“** tippt (mit Nachfrage), oder
   - bei einem Auftrag mit **Zuglimit** die Züge aufgebraucht sind, ohne dass er erfüllt ist (automatisch).
5. **Ende:** Bilanz (erreichtes Level, Münzen, gefundene Wörter). Danach neuer Lauf ab Level 1.
6. **Rekord:** nur das **höchste erreichte Level**.

## Aufträge

### Arten (Beispiele)
- **Länge:** „Finde ein Wort mit 3 Buchstaben“, später „… mit 5 Buchstaben“. Gemeint ist **mindestens** diese Länge; längere Wörter zählen auch (Anzeige z. B. „mind. 5 Buchstaben“). Beim bestimmten Wort zählt nur genau das Zielwort.
- **Bestimmtes Wort:** „Finde HIMMEL“. Das Zielwort kommt aus der Liste geläufiger Wörter.
  - **Säen durch Verwandeln:** Beim Start des Auftrags legt das Spiel das Wort als **zusammenhängende Kette** ins Feld. Die betroffenen Steine **drehen sich um** und zeigen dabei ihre neuen Buchstaben. Reichen die Steine nicht, werden freie Plätze mitbenutzt; dort erscheinen neue Steine (Füllen von unten nach oben bleibt gültig).
  - Das Wort ist damit **garantiert lösbar**, auch bei vollem Feld. Man muss es nur finden.
  - Die Kette soll nicht auffallen (z. B. nicht immer gerade, gemischt mit vorhandenen Steinen). Details bei der Umsetzung.
- **Anzahl:** „Finde 3 Wörter mit 3 Buchstaben“.
- **Mit Bedingung:**
  - „… ohne Nachziehen“ (im Level ist „Nachfüllen“ gesperrt)
  - „… in höchstens 5 Zügen“ (Züge aufgebraucht, Auftrag nicht erfüllt → **Lauf endet**)
  - „… mit dem Buchstaben X“
  - „… Wort endet auf -EN“

### Schwierigkeit
Die Levels werden schwerer. Stellschrauben pro Level:
- Wortlänge (3 → 5 → 6 …)
- Anzahl der Wörter
- Bedingungen (ohne Nachziehen, Zuglimit, bestimmte Buchstaben)
- schwächere Wort-Hilfe (schwierigere Buchstaben): **Das Level steuert die Hilfe**, am Anfang stark, später schwächer. Die 5 wählbaren Schwierigkeitsstufen entfallen; damit gibt es nur einen Rekord.
- weniger Steine im Feld oder weniger Nachschub
- Hindernisse [später] (siehe Abschnitt „Besondere Steine“)

### Kurve (Startwerte)
Pro Level zwei Auftragskarten: A sicher, B riskant. Zahlen sind Startwerte für das Feintuning.

| Level | Karte A (sicher) | Karte B (riskant) | Wort-Hilfe |
|---|---|---|---|
| 1 | Wort mit 3 Buchstaben, +100 | Wort mit 4, +150 | sehr stark |
| 2 | Wort mit 4, +100 | Wort mit 5, +200 | sehr stark |
| 3 | 2 Wörter mit 4, +100 | Wort mit 5, +200 | stark |
| 4 | Wort mit 5, +100 | bestimmtes Wort mit 4 (z. B. HAUS), +200 | stark |
| 5 | Wort mit 5 ohne Nachfüllen, +150 | Wort mit 6, +250 | mittel |
| 6–7 | 3 Wörter mit 4 in höchstens 4 Zügen, +150 | bestimmtes Wort mit 5, +250 | mittel |
| 8–10 | Wort mit 6, +150 | bestimmtes Wort mit 6 (z. B. HIMMEL), +300 | schwach |
| ab 11 | nach Regeln erzeugt, immer etwas schwerer | | ohne Hilfe |

- Sichere Karten reichen für 2–3 Nachfüllungen; riskante bringen etwa das Doppelte als Polster.
- Die Wort-Hilfe nutzt die bisherigen 5 Stufen (sehr stark = „Sehr leicht“ … ohne Hilfe = „Profi“), jetzt automatisch nach Level.

**Ab Level 11 (Mischen + steigern):**
- Beide Karten werden **zufällig** aus allen Auftragsarten von Level 6–10 gezogen (eine sicher, eine riskant).
- **Alle 5 Levels** (11, 16, 21 …) wird eine Stellschraube verschärft, reihum:
  1. Wortlänge **+1** (höchstens 8 Buchstaben),
  2. Anzahl Wörter **+1**,
  3. Zuglimit **−1** (mindestens so viele Züge wie Wörter).
- Die **Belohnung** steigt je Verschärfung um **+50**.
- Wort-Hilfe: keine. Alle Werte sind Startwerte für das Feintuning.

### Zug
- **Nur passende Wörter werden angenommen** und verschwinden. Ein echtes Wort, das nicht zum Auftrag passt (z. B. zu kurz), wird **abgelehnt** wie ein ungültiges: Die Steine wackeln und bleiben liegen, oben steht der Grund.
- Ein **Zug** ist **jeder Versuch** ab 3 Buchstaben: angenommene Wörter, nicht passende und auch Unsinn-Wörter. Kürzere Wische (z. B. versehentliches Antippen) und gekaufte Hilfen zählen nicht. Wichtig ist das nur bei Aufträgen mit Zuglimit.

### Auftrag wählen [v1]
Vor jedem Level gibt es **2 Auftragskarten** zur Wahl, z. B. „4 Buchstaben, +100“ oder „6 Buchstaben, +250“. Sicher oder riskant?

### Zufall [v1]
Aufträge werden pro Lauf **zufällig** gezogen, passend zur Schwierigkeit des Levels. Jeder Lauf ist anders.

### Bosse [später]
Alle **5 Levels** ein schwerer Auftrag mit großer Belohnung, z. B. „Finde HIMMEL in 8 Zügen“.

## Münzen

| Ereignis | Münzen |
|---|---|
| Auftrag erfüllt | **+100** (je nach Auftrag mehr, siehe Auftragskarten) |
| Bonus: Auftrag mit wenigen Zügen [später] | +50 |
| Langes Wort nebenbei, ab 6 Buchstaben [später] | +5 |
| **5 Steine nachfüllen** | **−100**, jeder weitere Kauf im Lauf **+25** (100, 125, 150 …) |
| **5 Steine tauschen** | **−50** |
| **Tipp: Anfangsbuchstabe zeigen** | **−100** |
| **Stein ersetzen** | **−100** |

- Münzen sind die **Währung** des Laufs. **Punkte entfallen**; es gibt nur noch Münzen und Level.
- Ohne Münzen gibt es keine Hilfen mehr; findet man dann nichts, ist der Lauf vorbei.

## Hilfen

- **Nachfüllen:** 5 neue Steine an freie Plätze (Platzwahl wie bisher). Kostet 100 und wird mit jedem Kauf im selben Lauf um 25 teurer; ein neuer Lauf beginnt wieder bei 100. Ist das Feld voll, ist Nachfüllen gesperrt; dann bleiben Tauschen, Stein ersetzen, Tipp oder Aufgeben.
- **Tauschen:** 5 zufällige Steine im Feld drehen sich um und bekommen neue Buchstaben, gewählt von der **Wort-Hilfe**. Fester Preis 50. Das Feld wird nicht voller; deshalb auch bei vollem Feld und bei „ohne Nachziehen“ erlaubt. Liegen weniger als 5 Steine im Feld, werden alle getauscht.
- **Tipp, Anfangsbuchstabe:** Der erste Stein eines passenden Wortes leuchtet auf. Das gilt bei gesuchten Wörtern („HIMMEL“) und bei allgemeinen Aufträgen („Wort mit 5 Buchstaben“), denn die Wortsuche kennt die möglichen Wörter im Feld.
- **Stein ersetzen:** Stein antippen, er bekommt einen neuen Buchstaben. Den wählt die **Wort-Hilfe**, also möglichst passend zu Wörtern im Feld. Kein Wunschbuchstabe.

## Laden und Vorteile [später]

Zwischen den Levels ein **Laden**: dauerhafte Vorteile für den laufenden Lauf, bezahlt mit Münzen. Beispiele:
- **Vokal-Magnet:** mehr Vokale
- **+20 % Münzen**
- **Erster Tipp gratis** (pro Level)
- **Goldener Stein:** doppelte Münzen, wenn er im Wort ist

## Besondere Steine [später]

- **Goldener Stein:** doppelte Belohnung.
- **Kristallstein:** bringt einen Zug zurück.
- **Rissiger Stein:** zerfällt nach X Zügen und blockiert dann oder kostet Münzen.
- **Steinblock:** ganz unten, ohne Buchstabe; bricht, wenn daneben ein Wort gebildet wird. Möglicher Auftrag: „Räume alle Blöcke ab“.

## Spielfeld zwischen den Levels

**Das Feld bleibt liegen.** Übrige Steine gehen ins nächste Level mit. Der Lauf ist ein durchgehendes Spiel; ein gutes oder schlechtes Feld wirkt nach.

## Fortschritt über Läufe (Meta) [später]

Über viele Läufe neue Vorteile oder besondere Steine freischalten, die dann in Läufen auftauchen können.

## Ausblick: Münzen kaufen [später]

Münzen bieten sich für **In-App-Käufe** an. Falls das kommt, muss das Spiel **ohne Kauf fair** bleiben. Entscheidung gesondert, nicht Teil dieser Spec.

## Offene Fragen

1. ~~**Spielfeld** zwischen den Levels~~ → bleibt liegen.
2. ~~**Start**~~ → 0 Münzen, 20 Hexagons.
3. ~~**Umfang Version 1**~~ → Grundgerüst + Auftrag wählen + Zufall; Bosse, Laden, besondere Steine, Meta, Münzkauf später.
4. ~~**Was ist ein „Zug“?**~~ → jeder Versuch ab 3 Buchstaben (seit v2.6); Hilfen zählen nicht.
5. ~~**Punkte**~~ → fallen weg.
6. ~~**Aufgeben**~~ → Knopf „Aufgeben“ mit Nachfrage beendet den Lauf; kein automatisches Ende.
7. ~~**„Ohne Nachziehen“**~~ → Knopf „Nachfüllen“ ist im Level gesperrt.
8. ~~**Wort-Hilfe und Schwierigkeitsstufen**~~ → Level steuert die Hilfe; die 5 Stufen entfallen.
9. ~~**Stein ersetzen**~~ → neuer Buchstabe von der Wort-Hilfe, kein Wunschbuchstabe.
10. ~~**Feld voll**~~ → Nachfüllen gesperrt; Tauschen, Stein ersetzen, Tipp oder Aufgeben.
11. ~~**Schwierigkeitskurve**~~ → Startwerte siehe „Kurve“; ab Level 11 Mischen + steigern.
12. ~~**Rekord**~~ → nur das höchste Level.

## Verlauf

- **v1:** Konzept gesammelt: Lauf mit Aufträgen als Levels, Münzen (+100 pro Auftrag; Nachfüllen 5 Steine −50, Tipp −100, Stein ersetzen −100), Neustart bei Level 1 nach Scheitern (Roguelike). Ideen: Auftragswahl, Zufall, Bosse, Laden, besondere Steine, Meta-Fortschritt. Umfang und Details offen.
- **v2:** Offene Fragen geklärt: Feld bleibt zwischen Levels liegen; Start mit 0 Münzen und 20 Hexagons; Zug = angenommenes Wort; Punkte entfallen; Knopf „Aufgeben“ (kein automatisches Ende); „ohne Nachziehen“ sperrt den Knopf; Level steuert die Wort-Hilfe, die 5 Stufen entfallen; Stein ersetzen über Wort-Hilfe; volles Feld sperrt Nachfüllen; Rekord = höchstes Level; Kurve für Level 1–10. Umfang v1: Grundgerüst + Auftrag wählen + Zufall; später: Bosse, Laden, besondere Steine, Bonus-Münzen, Meta, Münzkauf.
- **v2.1:** Zuglimit verfehlt → Lauf endet automatisch.
- **v2.2:** Ab Level 11: Aufträge aus Level 6–10 gemischt, alle 5 Levels eine Verschärfung (Länge, Anzahl, Zuglimit reihum), Belohnung +50 je Verschärfung.
- **v2.3:** Bestimmtes Wort wird gesät, indem Steine sich zu einer zusammenhängenden Kette verwandeln (garantiert lösbar).
- **v2.4:** Längen-Aufträge zählen Wörter mit mindestens der verlangten Länge.
- **v2.5:** Nachfüllen kostet 100, +25 je weiterem Kauf im Lauf. Neue Hilfe „5 Steine tauschen“ für 50 (Wort-Hilfe, auch bei vollem Feld und „ohne Nachziehen“).
- **v2.6:** Nur passende Wörter werden angenommen; nicht passende werden abgelehnt (Steine bleiben). Zug = jeder Versuch ab 3 Buchstaben, auch abgelehnte.
