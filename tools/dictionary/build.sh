#!/usr/bin/env bash
# Baut die deutsche Spiel-Wortliste aus Trennmuster-Wortliste (MIT) + Wiktionary via kaikki.org (CC BY-SA).
# Aufruf:  tools/dictionary/build.sh
# Ergebnis: tools/dictionary/out/de-words.txt (eine Zeile pro Wort, A-Z, sortiert)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/src"      # heruntergeladene Quellen (nicht versionieren)
OUT="$HERE/out"      # Ergebnisse (nicht versionieren)
mkdir -p "$SRC" "$OUT"

# 1) Trennmuster-Wortliste (Git, ca. 25 MB)
if [ -d "$SRC/wortliste/.git" ]; then
  git -C "$SRC/wortliste" pull --depth 1 --quiet || true
else
  git clone --depth 1 --quiet https://repo.or.cz/wortliste.git "$SRC/wortliste"
fi

# 2) Deutscher Wiktionary-Auszug von kaikki.org (ca. 310 MB, gzip)
if [ ! -f "$SRC/dewiktionary.jsonl.gz" ]; then
  curl -L --fail -o "$SRC/dewiktionary.jsonl.gz" https://kaikki.org/dewiktionary/raw-wiktextract-data.jsonl.gz
fi

# 3) Aufbereiten und zusammenführen
python3 -I "$HERE/build_trennmuster.py" "$SRC/wortliste/wortliste" "$OUT/trennmuster.txt"
python3 -I "$HERE/build_wiktionary.py"  "$SRC/dewiktionary.jsonl.gz" "$OUT/wiktionary.txt"
LC_ALL=C sort -u "$OUT/trennmuster.txt" "$OUT/wiktionary.txt" > "$OUT/de-words.txt"

wc -l "$OUT/trennmuster.txt" "$OUT/wiktionary.txt" "$OUT/de-words.txt"
ls -la "$OUT/de-words.txt"

# 4) Ins kompakte Spielformat packen und ins Godot-Projekt legen
#    (Wortlänge begrenzen mit z. B.:  MAX_LEN=15 tools/dictionary/build.sh)
DEST="$HERE/../../letter-tetris/data/languages/de/words.bin"
if [ -n "${MAX_LEN:-}" ]; then
  python3 -I "$HERE/pack_words.py" "$OUT/de-words.txt" "$DEST" --max-len "$MAX_LEN"
else
  python3 -I "$HERE/pack_words.py" "$OUT/de-words.txt" "$DEST"
fi
