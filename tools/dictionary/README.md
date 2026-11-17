# Wörterbuch-Aufbereitung (Deutsch)

Baut die Wortliste für das Spiel aus zwei freien Quellen. Regeln und Lizenzen siehe [spec/game-rules.md](../../spec/game-rules.md) (Abschnitt „Wörterbuch“).

## Quellen

| Quelle | Lizenz | Herkunft |
|---|---|---|
| Trennmuster-Wortliste (DANTE / W. Lemberg u. a.) | MIT | `https://repo.or.cz/wortliste.git` |
| Deutscher Wiktionary (Auszug via kaikki.org / wiktextract) | CC BY-SA 3.0 / GFDL | `https://kaikki.org/dewiktionary/raw-wiktextract-data.jsonl.gz` |
| Leipzig Corpora Collection (Wortschatz, Uni Leipzig): `deu_news_2023_1M`, `deu_mixed-typical_2011_1M` (nur Worthäufigkeit) | CC BY | `https://downloads.wortschatz-leipzig.de/corpora/` |

## Benutzung

```bash
tools/dictionary/build.sh
```

- Lädt beide Quellen nach `tools/dictionary/src/` (ca. 340 MB, wird beim nächsten Lauf wiederverwendet).
- Schreibt die Textliste nach `tools/dictionary/out/de-words.txt`.
- Packt sie ins Spielformat **LTW1** und legt sie nach `letter-tetris/data/languages/de/words.bin` (ca. 10 MB).
- Wortlänge begrenzen (optional): `MAX_LEN=15 tools/dictionary/build.sh`.
- Legt außerdem die **Vorschlags-Wörter** (geläufige Wörter für Wort-Hilfe, Tipp, Scan, Lösen …) nach `letter-tetris/data/languages/de/common.bin` (10.000 Wörter, ca. 63 KB; Anzahl ändern mit `COMMON_COUNT=12000 tools/dictionary/build.sh`).
- Lädt dafür zwei Leipzig-Korpora (zusammen ca. 330 MB) nach `src/leipzig/`.
- `src/` und `out/` gehören **nicht** in die Versionsverwaltung.
- Benötigt: `git`, `curl`, `python3` (keine Zusatzpakete).

## Aufbereitung

- Großbuchstaben A–Z und Ä, Ö, Ü; ß → SS.
- Wörter mit anderen Sonderzeichen (Bindestrich, Leerzeichen, Ziffern, Akzente …) entfallen.
- Im Spielformat stehen Umlaute als je ein Byte direkt hinter Z (Ä → `[`, Ö → `\`, Ü → `]`); `WordDictionary` übersetzt hin und zurück.
- Mindestens 3 Buchstaben.
- Trennmuster: nur Einträge, die in der **reformierten Rechtschreibung** gelten.
- Wiktionary: Stichwörter deutscher Einträge plus alle einteiligen Beugungsformen.
- **Eigennamen und Abkürzungen entfallen** (siehe spec/game-rules.md): Ein Wort fliegt raus, wenn Wiktionary es nur als Eigenname (`name`) oder Abkürzung (`abbrev`, inkl. als Abkürzung markierter Formen und der Formen solcher Wörter) kennt. Ausnahmen: Zusammenziehungen wie „zum“, „beim“, „sowas“ (bei Wiktionary auch `abbrev`) und längere kleingeschriebene Kurzformen wie „rausreißen“. Die entfernten Wörter stehen in `out/excluded.txt` und werden auch aus der Trennmuster-Liste gefiltert (`filter_words.py`).
- **Akronyme und markierte Namen entfallen:** Trennmuster-Einträge mit Vermerk „# Abk.“ oder „Name“ im Kommentar (z. B. „engl. Name“, „geogr. Name“) oder ganz in Großbuchstaben (z. B. DEA, CPU) werden aus beiden Listen entfernt (`out/trennmuster-abbrevs.txt`, zusammengeführt mit `combine_exclusions.py` zu `out/excluded-all.txt`). Ausnahme: Wiktionary kennt das Wort in normaler Schreibweise (ganz klein oder nur erster Buchstabe groß) und es enthält einen Vokal, z. B. Aids, Ufo, Abc (`out/excluded-normalcase.txt`).
- **Story-Wörter kommen dazu** (`add_story.sh`, Schritt 4 von `build.sh`): alle Themenwörter aus `letter-tetris/data/story/*.txt` werden in `words.bin` aufgenommen, damit handverlesene Eigennamen (Länder, Städte, Marken, Personen) auch im normalen Lauf gelten. Ausnahme: Abkürzungen aus `story-abbrevs.txt`. Die Vorschlags-Listen (`common.bin`, `easy*.bin`) bleiben ohne sie. Nach Änderungen an den Story-Listen genügt `LC_ALL=C tools/dictionary/add_story.sh`.
- **Großbuchstaben mitten im Wort entfallen:** Wiktionary-Stichwörter aus einem Stück mit Großbuchstaben nach dem ersten Buchstaben (z. B. „UGs“, „CEOs“, „NASA“, „iPod“) gelten samt Formen als Abkürzung/Marke, außer es gibt sie auch normal geschrieben (z. B. „Ufo“ neben „UFO“). Wörter mit Bindestrich oder Leerzeichen sind nicht betroffen.
- **Veraltete Schreibweisen entfallen:** Wiktionary-Formen mit Tag „obsolete“ (z. B. „Thee“ bei Tee, „Citat“, „Concert“) kommen nicht ins Wörterbuch, außer das Wort gibt es auch als normalen Eintrag oder normale Form. Formen mit ß bleiben unberührt (ß → SS ergibt oft die heutige Schreibung). Alte Schreibweisen von Namen zählen weiter als Namen.
- **Römische Zahlen entfallen** (z. B. LIII, XII; die Trennmuster-Liste enthält rund 2.400 davon), außer sie sind auch ein normales Wiktionary-Stichwort (z. B. MIX; Liste in `out/excluded-roman-keep.txt`).

## Vorschlags-Wörter (`build_common.py`)

- Nur **Grundformen** laut Wiktionary (Stichwort, kein reiner Formen-Eintrag) plus **Mehrzahl (Nominativ)** von Hauptwörtern: TISCH, TISCHE, LAUFEN, WILD. Keine Genitive oder gebeugten Formen.
- Wortarten: Hauptwort, Verb, Adjektiv, Adverb, Präposition, Bindewort, Zahlwort, Ausruf, Partikel.
- **Ohne Artikel und Pronomen** samt ihrer Formen (auch Formen-Einträge, deren Erklärung „Pronomen“ oder „Artikel“ nennt), außer SEIN.
- Nur gültige Spielwörter (aus `de-words.txt`), nur **3 bis 8 Buchstaben**.
- Ohne Wörter der **Sperrliste** `blocklist-suggestions.txt` (versioniert) und ohne Wörter, die in den Korpora meist ganz großgeschrieben stehen (Akronyme).
- Rangfolge nach Häufigkeit in beiden Leipzig-Korpora (je relativ, gemittelt); die häufigsten kommen in die Liste. Rangliste zum Ansehen: `out/common-ranked.txt`.

## Kinder-Wortliste (`easy.bin`, Modus „Deutsch einfach“)

- Gleiches Skript wie die Vorschlags-Wörter (`build_common.py`) mit `--len=3-5 --kids`: nur Hauptwörter, Verben, Adjektive und Zahlwörter (Grundformen plus Mehrzahl), **ohne englische Lehnwörter** (laut Wiktionary-Herkunft), 3–5 Buchstaben, die 3.000 häufigsten.
- Zusätzliche Sperrliste `blocklist-kids.txt` (für Kinder Unpassendes, Heikles, Abwertendes).
- In diesem Modus sind das **die Vorschläge**. **Gültig** sind zusätzlich die 1.200 häufigsten kurzen Wörter in jeder Form (ICH, SIE, DER, UND, IST, GEHT …) → `easy_valid.bin` (rund 3.400 Wörter), damit Kinder auch kleine Wörter legen können.
- Zum Durchsehen: `kids-words-ranked.txt` (versioniert, nach Häufigkeit sortiert).

## Stand (13.11.2026)

| Liste | Wörter |
|---|---|
| Trennmuster (ohne Namen/Abkürzungen/Akronyme/römische Zahlen) | 381.852 (vorher 390.374) |
| Wiktionary (ohne Namen/Abkürzungen/Akronyme/römische Zahlen) | 652.750 |
| Entfernt (Namen/Abkürzungen) | 42.599 |
| Kombiniert | 1.016.262 (mit Umlauten; vorher 802.530 ohne) |

## Offen

- Evtl. Begrenzung der Wortlänge (z. B. max. 15 Buchstaben).

## Dateien

- `build.sh`: alles in einem Schritt.
- `build_trennmuster.py`: Trennmuster-Wortliste → Wörter.
- `build_wiktionary.py`: Wiktionary-Auszug → Wörter.
- `combine_exclusions.py`: führt Namen/Abkürzungen (Wiktionary) und Akronyme (Trennmuster) zu einer Ausschlussliste zusammen.
- `filter_words.py`: entfernt Wörter einer Liste (z. B. Namen/Abkürzungen) aus einer Wortliste.
- `build_common.py`: Vorschlags-Wörter (siehe oben).
- `blocklist-suggestions.txt`: Sperrliste für Vorschlags-Wörter.
- `blocklist-kids.txt`: zusätzliche Sperrliste für die Kinder-Wortliste.
- `kids-words-ranked.txt`: Kinder-Wortliste zum Durchsehen.
- `pack_words.py`: Textliste → kompaktes Spielformat LTW1 (Formatbeschreibung im Skript).
