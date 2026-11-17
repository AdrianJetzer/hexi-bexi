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
python3 -I "$HERE/build_trennmuster.py" "$SRC/wortliste/wortliste" "$OUT/trennmuster-all.txt" "$OUT/trennmuster-abbrevs.txt"
python3 -I "$HERE/build_wiktionary.py"  "$SRC/dewiktionary.jsonl.gz" "$OUT/wiktionary-all.txt" "$OUT/excluded.txt"
# Abkürzungen/Akronyme laut Trennmuster dazunehmen (außer normal geschriebene Wörter wie Aids)
python3 -I "$HERE/combine_exclusions.py" "$OUT/excluded.txt" "$OUT/trennmuster-abbrevs.txt" "$OUT/excluded-normalcase.txt" "$OUT/excluded-all.txt"
# Eigennamen und Abkürzungen (laut Wiktionary nur Name/Abkürzung) sowie römische Zahlen
# auch aus Trennmuster entfernen
python3 -I "$HERE/filter_words.py" "$OUT/trennmuster-all.txt" "$OUT/excluded-all.txt" "$OUT/trennmuster.txt" "$OUT/excluded-roman-keep.txt"
python3 -I "$HERE/filter_words.py" "$OUT/wiktionary-all.txt" "$OUT/excluded-all.txt" "$OUT/wiktionary.txt" "$OUT/excluded-roman-keep.txt"
LC_ALL=C sort -u "$OUT/trennmuster.txt" "$OUT/wiktionary.txt" > "$OUT/de-words.txt"

wc -l "$OUT/trennmuster.txt" "$OUT/wiktionary.txt" "$OUT/de-words.txt"
ls -la "$OUT/de-words.txt"

# 4) Ins kompakte Spielformat packen und ins Godot-Projekt legen, dazu die Themenwörter der
#    Story-Kapitel (handverlesene Eigennamen).  (Wortlänge begrenzen mit z. B.:  MAX_LEN=15 …)
"$HERE/add_story.sh"

# 5) Vorschlags-Wörter (geläufige Wörter für Wort-Hilfe, Tipp, Scan, Lösen …):
#    Grundformen plus Mehrzahl, nach Häufigkeit in der Leipzig Corpora Collection (CC BY 4.0).
#    Anzahl ändern mit z. B.:  COMMON_COUNT=12000 tools/dictionary/build.sh
LEIPZIG="$SRC/leipzig"
mkdir -p "$LEIPZIG"
for c in deu_news_2023_1M deu_mixed-typical_2011_1M; do
  if [ ! -f "$LEIPZIG/$c/$c-words.txt" ]; then
    [ -f "$LEIPZIG/$c.tar.gz" ] || curl -L --fail -o "$LEIPZIG/$c.tar.gz" "https://downloads.wortschatz-leipzig.de/corpora/$c.tar.gz"
    tar -xzf "$LEIPZIG/$c.tar.gz" -C "$LEIPZIG" "$c/$c-words.txt"
  fi
done
python3 -I "$HERE/build_common.py" "$SRC/dewiktionary.jsonl.gz" "$OUT/de-words.txt" \
  "$HERE/blocklist-suggestions.txt" "$OUT/common.txt" "${COMMON_COUNT:-10000}" "$LEIPZIG"/*/*-words.txt
python3 -I "$HERE/pack_words.py" "$OUT/common.txt" "$HERE/../../letter-tetris/data/languages/de/common.bin"

# 6) Kinder-Wortliste für „Deutsch einfach“ (gültige Wörter UND Vorschläge in diesem Modus):
#    3000 häufigste Inhaltswörter mit 3–5 Buchstaben, ohne englische Lehnwörter, mit Kinder-Sperrliste.
python3 -I "$HERE/build_common.py" "$SRC/dewiktionary.jsonl.gz" "$OUT/de-words.txt" \
  "$HERE/blocklist-suggestions.txt" "$OUT/easy.txt" "${EASY_COUNT:-3000}" "$LEIPZIG"/*/*-words.txt \
  --len=3-5 --kids --block="$HERE/blocklist-kids.txt" --extra-valid="${EASY_EXTRA_VALID:-1200}"
cut -f2 "$OUT/easy-ranked.txt" > "$HERE/kids-words-ranked.txt"
python3 -I "$HERE/pack_words.py" "$OUT/easy.txt" "$HERE/../../letter-tetris/data/languages/de/easy.bin"
python3 -I "$HERE/pack_words.py" "$OUT/easy-valid.txt" "$HERE/../../letter-tetris/data/languages/de/easy_valid.bin"
