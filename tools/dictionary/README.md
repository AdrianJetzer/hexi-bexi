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
- `src/` und `out/` gehören **nicht** in die Versionsverwaltung.
- Benötigt: `git`, `curl`, `python3` (keine Zusatzpakete).

## Aufbereitung

- Großbuchstaben A–Z; ß → SS.
- Wörter mit Umlauten oder anderen Sonderzeichen (Bindestrich, Leerzeichen, Ziffern …) entfallen.
- Mindestens 3 Buchstaben.
- Trennmuster: nur Einträge, die in der **reformierten Rechtschreibung** gelten.
- Wiktionary: Stichwörter deutscher Einträge plus alle einteiligen Beugungsformen.

## Stand (Testlauf 13.11.2026)

| Liste | Wörter |
|---|---|
| Trennmuster | 390.374 |
| Wiktionary | 695.460 |
| Kombiniert | 850.724 (11 MB Text, 2,3 MB gzip) |

## Offen

- Evtl. Begrenzung der Wortlänge (z. B. max. 15 Buchstaben).

## Dateien

- `build.sh`: alles in einem Schritt.
- `build_trennmuster.py`: Trennmuster-Wortliste → Wörter.
- `build_wiktionary.py`: Wiktionary-Auszug → Wörter.
- `pack_words.py`: Textliste → kompaktes Spielformat LTW1 (Formatbeschreibung im Skript).
