# Lauf-Modus (Roguelike)

Status: **Entwurf v1**. Konzept gesammelt; Umfang für Version 1 und viele Details noch **offen**.

Markierungen: **[v1]** = kommt in Version 1 · **[später]** = gute Idee, nach Version 1 · **[offen]** = noch nicht entschieden.

Bis zur Entscheidung sind alle Ideen **[offen]**; die Markierungen werden beim Klären der offenen Fragen gesetzt.

## Idee in einem Satz

Ein **Lauf** besteht aus Levels, jedes Level ist ein **Auftrag** („Finde ein Wort mit 5 Buchstaben“). Erfüllte Aufträge bringen **Münzen**, mit denen man sich **Hilfen** kauft. Wer kein Geld mehr hat oder nicht weiterkommt, scheitert, und der nächste Lauf beginnt **wieder bei Level 1**.

Ersetzt den ruhigen Level-Modus aus [game-rules.md](game-rules.md) (Punkte-Schwellen, +10 Hexagons). Das Grundspiel bleibt: Raster, Wischen, Wörterbuch, Wort-Hilfe.

## Ablauf eines Laufs

1. **Start:** Level 1, ein Startbetrag an Münzen, Spielfeld mit Start-Hexagons. [offen: Startbetrag, Anzahl Start-Hexagons]
2. **Level:** Der Spieler bekommt einen Auftrag und versucht ihn mit Wörtern im Feld zu erfüllen.
3. **Erfüllt:** Münzen gutschreiben, weiter zum nächsten, schwereren Level.
4. **Gescheitert:** kein Geld mehr und kein Weiterkommen, oder der Spieler gibt auf. Der Lauf endet.
5. **Ende:** Bilanz (erreichtes Level, Münzen, gefundene Wörter). Danach neuer Lauf ab Level 1.
6. **Rekord:** höchstes erreichtes Level. [offen: zusätzlich Münzen oder Punkte als Rekord?]

## Aufträge

### Arten (Beispiele)
- **Länge:** „Finde ein Wort mit 3 Buchstaben“, später „… mit 5 Buchstaben“.
- **Bestimmtes Wort:** „Finde HIMMEL“. Das Spiel muss die nötigen Buchstaben ins Feld bringen, verteilt statt nebeneinander.
- **Anzahl:** „Finde 3 Wörter mit 3 Buchstaben“.
- **Mit Bedingung:**
  - „… ohne Nachziehen“
  - „… in höchstens 5 Zügen“
  - „… mit dem Buchstaben X“
  - „… Wort endet auf -EN“

### Schwierigkeit
Die Levels werden schwerer. Stellschrauben pro Level:
- Wortlänge (3 → 5 → 6 …)
- Anzahl der Wörter
- Bedingungen (ohne Nachziehen, Zuglimit, bestimmte Buchstaben)
- schwächere Wort-Hilfe (schwierigere Buchstaben)
- weniger Steine im Feld oder weniger Nachschub
- Hindernisse (siehe [Besondere Steine](#besondere-steine))

[offen: konkrete Kurve, z. B. welche Aufträge in Level 1–10]

### Auftrag wählen
Vor jedem Level gibt es **2 Auftragskarten** zur Wahl, z. B. „4 Buchstaben, +100“ oder „6 Buchstaben, +250“. Sicher oder riskant?

### Zufall
Aufträge werden pro Lauf **zufällig** gezogen, passend zur Schwierigkeit des Levels. Jeder Lauf ist anders.

### Bosse
Alle **5 Levels** ein schwerer Auftrag mit großer Belohnung, z. B. „Finde HIMMEL in 8 Zügen“.

## Münzen

| Ereignis | Münzen |
|---|---|
| Auftrag erfüllt | **+100** (je nach Auftrag mehr, siehe Auftragskarten) |
| Bonus: Auftrag mit wenigen Zügen | +50 [offen] |
| Langes Wort nebenbei (ab 6 Buchstaben) | +5 [offen] |
| **5 Steine nachfüllen** | **−50** |
| **Tipp: Anfangsbuchstabe zeigen** | **−100** |
| **Stein ersetzen** | **−100** |

- Münzen sind die **Währung** des Laufs; die bisherigen Punkte entfallen oder sind nur noch Anzeige. [offen]
- Ohne Münzen gibt es keine Hilfen mehr; findet man dann nichts, ist der Lauf vorbei.

## Hilfen

- **Nachfüllen:** 5 neue Steine an freie Plätze (Platzwahl wie bisher).
- **Tipp, Anfangsbuchstabe:** Der erste Stein eines passenden Wortes leuchtet auf. Das gilt bei gesuchten Wörtern („HIMMEL“) und bei allgemeinen Aufträgen („Wort mit 5 Buchstaben“), denn die Wortsuche kennt die möglichen Wörter im Feld.
- **Stein ersetzen:** Stein antippen, er wird ersetzt. [offen: zufälliger Buchstabe oder Wunschbuchstabe, ggf. teurer]

## Laden und Vorteile

Zwischen den Levels ein **Laden**: dauerhafte Vorteile für den laufenden Lauf, bezahlt mit Münzen. Beispiele:
- **Vokal-Magnet:** mehr Vokale
- **+20 % Münzen**
- **Erster Tipp gratis** (pro Level)
- **Goldener Stein:** doppelte Münzen, wenn er im Wort ist

## Besondere Steine

- **Goldener Stein:** doppelte Belohnung.
- **Kristallstein:** bringt einen Zug zurück.
- **Rissiger Stein:** zerfällt nach X Zügen und blockiert dann oder kostet Münzen.
- **Steinblock:** ganz unten, ohne Buchstabe; bricht, wenn daneben ein Wort gebildet wird. Möglicher Auftrag: „Räume alle Blöcke ab“.

## Spielfeld zwischen den Levels

[offen] Zwei Möglichkeiten:
- **Liegen lassen:** Übrige Steine gehen ins nächste Level mit. Der Lauf ist ein durchgehendes Spiel, jede Entscheidung wirkt nach.
- **Neues Feld:** Jedes Level ist ein sauberes, einzelnes Rätsel.

## Fortschritt über Läufe (Meta)

Über viele Läufe neue Vorteile oder besondere Steine freischalten, die dann in Läufen auftauchen können.

## Ausblick: Münzen kaufen

Münzen bieten sich für **In-App-Käufe** an. Falls das kommt, muss das Spiel **ohne Kauf fair** bleiben. Entscheidung gesondert, nicht Teil dieser Spec.

## Offene Fragen

1. **Spielfeld** zwischen den Levels: liegen lassen oder neu?
2. **Start:** Münzen und Anzahl Hexagons zu Beginn.
3. **Umfang Version 1:** Welche Ideen sind [v1], welche [später]?
4. **Was ist ein „Zug“?** Ein gewischtes Wort? Zählen Hilfen mit?
5. **Punkte:** fallen sie weg, oder bleiben sie für Bonus/Rekord?
6. **Aufgeben:** Gibt es einen Knopf dafür, und kostet es etwas?
7. **„Ohne Nachziehen“:** Ist der Knopf im Level gesperrt, oder scheitert der Auftrag beim Drücken?
8. **Wort-Hilfe und Schwierigkeitsstufen:** Bleiben die 5 Stufen, oder steuert jetzt das Level die Hilfe?
9. **Stein ersetzen:** zufällig oder Wunschbuchstabe?
10. **Feld voll:** Was passiert, wenn kein Platz frei ist und der Auftrag nicht lösbar ist? (nur Stein ersetzen oder aufgeben?)
11. **Schwierigkeitskurve:** konkrete Aufträge pro Level.
12. **Rekord:** nur Level, oder auch Münzen/Wörter?

## Verlauf

- **v1:** Konzept gesammelt: Lauf mit Aufträgen als Levels, Münzen (+100 pro Auftrag; Nachfüllen 5 Steine −50, Tipp −100, Stein ersetzen −100), Neustart bei Level 1 nach Scheitern (Roguelike). Ideen: Auftragswahl, Zufall, Bosse, Laden, besondere Steine, Meta-Fortschritt. Umfang und Details offen.
