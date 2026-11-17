#!/usr/bin/env bash
# Spiel-Wortliste (words.bin) = Wörterbuch (out/de-words.txt) + alle Themenwörter der Story-Kapitel
# (letter-tetris/data/story/*.txt, Spalte vor „;“). So gelten handverlesene Eigennamen wie Länder,
# Hauptstädte, Flüsse, Marken und berühmte Personen auch im normalen Lauf (spec/game-rules.md).
# Die Vorschlags-Wörter (common.bin, easy*.bin) bleiben unberührt: Namen erscheinen nie als Tipp,
# Lösung oder gesuchtes Wort im normalen Lauf.
# Aufruf:  tools/dictionary/add_story.sh   (auch Schritt 4 von build.sh)
set -euo pipefail
export LC_ALL=en_US.UTF-8  # für die Umlaute in grep; sort läuft mit LC_ALL=C
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/out"
STORY="$HERE/../../letter-tetris/data/story"
DEST="$HERE/../../letter-tetris/data/languages/de/words.bin"
# Abkürzungen (story-abbrevs.txt) bleiben draußen, sie zählen nur im Story-Kapitel.
grep -hv '^#' "$STORY"/*.txt | cut -d';' -f1 | tr -d ' \r' | grep -E '^[A-ZÄÖÜ]{3,}$' \
  | grep -vxFf <(grep -v '^#' "$HERE/story-abbrevs.txt") | LC_ALL=C sort -u > "$OUT/story-words.txt"
LC_ALL=C sort -u "$OUT/de-words.txt" "$OUT/story-words.txt" > "$OUT/de-words-play.txt"
echo "Story-Wörter: $(wc -l < "$OUT/story-words.txt"), davon neu: $(( $(wc -l < "$OUT/de-words-play.txt") - $(wc -l < "$OUT/de-words.txt") ))"
if [ -n "${MAX_LEN:-}" ]; then
  python3 -I "$HERE/pack_words.py" "$OUT/de-words-play.txt" "$DEST" --max-len "$MAX_LEN"
else
  python3 -I "$HERE/pack_words.py" "$OUT/de-words-play.txt" "$DEST"
fi
