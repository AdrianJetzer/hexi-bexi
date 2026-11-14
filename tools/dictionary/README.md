# Wörterbuch-Aufbereitung (Deutsch)

Baut die Wortliste für das Spiel aus zwei freien Quellen. Regeln und Lizenzen siehe [spec/game-rules.md](../../spec/game-rules.md) (Abschnitt „Wörterbuch“).

## Quellen

| Quelle | Lizenz | Herkunft |
|---|---|---|
| Trennmuster-Wortliste (DANTE / W. Lemberg u. a.) | MIT | `https://repo.or.cz/wortliste.git` |
| Deutscher Wiktionary (Auszug via kaikki.org / wiktextract) | CC BY-SA 3.0 / GFDL | `https://kaikki.org/dewiktionary/raw-wiktextract-data.jsonl.gz` |

## Benutzung

```bash
tools/dictionary/build.sh
```

- Lädt beide Quellen nach `tools/dictionary/src/` (ca. 340 MB, wird beim nächsten Lauf wiederverwendet).
- Schreibt die Textliste nach `tools/dictionary/out/de-words.txt`.
- Packt sie ins Spielformat **LTW1** und legt sie nach `letter-tetris/data/languages/de/words.bin` (ca. 10 MB).
- Wortlänge begrenzen (optional): `MAX_LEN=15 tools/dictionary/build.sh`.
- Legt außerdem die **geläufigen Wörter** für die Wort-Hilfe nach `letter-tetris/data/languages/de/common.bin` (vorerst die Trennmuster-Liste, ca. 390.000 Wörter).
- `src/` und `out/` gehören **nicht** in die Versionsverwaltung.
- Benötigt: `git`, `curl`, `python3` (keine Zusatzpakete).

## Aufbereitung

- Großbuchstaben A–Z; ß → SS.
- Wörter mit Umlauten oder anderen Sonderzeichen (Bindestrich, Leerzeichen, Ziffern …) entfallen.
- Mindestens 3 Buchstaben.
- Trennmuster: nur Einträge, die in der **reformierten Rechtschreibung** gelten.
- Wiktionary: Stichwörter deutscher Einträge plus alle einteiligen Beugungsformen.
- **Eigennamen und Abkürzungen entfallen** (siehe spec/game-rules.md): Ein Wort fliegt raus, wenn Wiktionary es nur als Eigenname (`name`) oder Abkürzung (`abbrev`, inkl. als Abkürzung markierter Formen und der Formen solcher Wörter) kennt. Ausnahmen: Zusammenziehungen wie „zum“, „beim“, „sowas“ (bei Wiktionary auch `abbrev`) und längere kleingeschriebene Kurzformen wie „rausreißen“. Die entfernten Wörter stehen in `out/excluded.txt` und werden auch aus der Trennmuster-Liste gefiltert (`filter_words.py`).
- **Akronyme und markierte Namen entfallen:** Trennmuster-Einträge mit Vermerk „# Abk.“ oder „Name“ im Kommentar (z. B. „engl. Name“, „geogr. Name“) oder ganz in Großbuchstaben (z. B. DEA, CPU) werden aus beiden Listen entfernt (`out/trennmuster-abbrevs.txt`, zusammengeführt mit `combine_exclusions.py` zu `out/excluded-all.txt`). Ausnahme: Wiktionary kennt das Wort in normaler Schreibweise (ganz klein oder nur erster Buchstabe groß) und es enthält einen Vokal, z. B. Aids, Ufo, Abc (`out/excluded-normalcase.txt`).
- **Römische Zahlen entfallen** (z. B. LIII, XII; die Trennmuster-Liste enthält rund 2.400 davon), außer sie sind auch ein normales Wiktionary-Stichwort (z. B. MIX; Liste in `out/excluded-roman-keep.txt`).

## Stand (13.11.2026)

| Liste | Wörter |
|---|---|
| Trennmuster (ohne Namen/Abkürzungen/Akronyme/römische Zahlen) | 381.852 (vorher 390.374) |
| Wiktionary (ohne Namen/Abkürzungen/Akronyme/römische Zahlen) | 652.750 |
| Entfernt (Namen/Abkürzungen) | 42.599 |
| Kombiniert | 804.367 (vorher 850.724) |

## Offen

- Evtl. Begrenzung der Wortlänge (z. B. max. 15 Buchstaben).

## Dateien

- `build.sh`: alles in einem Schritt.
- `build_trennmuster.py`: Trennmuster-Wortliste → Wörter.
- `build_wiktionary.py`: Wiktionary-Auszug → Wörter.
- `combine_exclusions.py`: führt Namen/Abkürzungen (Wiktionary) und Akronyme (Trennmuster) zu einer Ausschlussliste zusammen.
- `filter_words.py`: entfernt Wörter einer Liste (z. B. Namen/Abkürzungen) aus einer Wortliste.
- `pack_words.py`: Textliste → kompaktes Spielformat LTW1 (Formatbeschreibung im Skript).
