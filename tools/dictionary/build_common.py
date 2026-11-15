"""Build the list of suggestion words ("Vorschlags-Wörter", spec/game-rules.md).

Usage: python3 -I build_common.py <dewiktionary.jsonl.gz> <de-words.txt> <blocklist.txt>
                                  <out.txt> <count> <leipzig-words.txt> [<leipzig-words.txt> ...]

Suggestion words are the words the game itself puts on the board or shows (hint, scan,
solve, swap, magnet, refill). They should be nice, everyday words:
- Only base forms (Wiktionary headwords that are not just a form of another word) plus the
  nominative plural of nouns (TISCH, TISCHE). No genitives, no inflected verbs/adjectives.
- No articles and pronouns (DER, EINE, ICH, IHM) and none of their forms, even if the same
  spelling is also a rare noun or verb (ICH as noun, EINEN as verb). Exception: KEEP_ANYWAY.
- Only lengths MIN_LEN..MAX_LEN (the lengths the game asks for).
- Only valid game words (must be in <de-words.txt>).
- Not in <blocklist.txt> (offensive words, names and abbreviations that slip through), and not
  written mostly in capitals in the corpora (acronyms like UNRWA).
- Ranked by frequency in the Leipzig Corpora Collection word lists (each corpus normalized to
  relative frequency, then averaged); the <count> most frequent are kept.
"""
import collections
import gzip
import json
import re
import sys

ALLOWED = re.compile(r"^[A-Z]{3,}$")

# Wortarten, deren Grundformen vorgeschlagen werden dürfen.
KEEP_POS = {"noun", "verb", "adj", "adv", "prep", "conj", "num", "intj", "particle", "postp"}
# Artikel und Pronomen: nie vorschlagen (samt ihren Formen).
DROP_POS = {"pron", "det"}
# Trotz Pronomen-Gleichklang behalten (SEIN ist vor allem ein Verb).
KEEP_ANYWAY = {"SEIN"}
# Formen-Einträge, deren Erklärung so beginnt, gehören zu Artikeln/Pronomen (oft Wortart „unknown“).
FUNCTION_HINTS = ("pronomen", "artikel")
MIN_LEN = 3
MAX_LEN = 8


def normalize(word):
    if not word or " " in word or "-" in word:
        return None
    w = word.replace("ß", "SS").replace("ẞ", "SS").upper()
    return w if ALLOWED.match(w) else None


def _is_form_of(e):
    senses = e.get("senses") or []
    return bool(senses) and all("form-of" in (s.get("tags") or []) for s in senses)


def read_wiktionary(src):
    """Return (candidates, function_words)."""
    candidates = set()
    function = set()
    with gzip.open(src, "rt", encoding="utf-8") as f:
        for line in f:
            try:
                e = json.loads(line)
            except ValueError:
                continue
            if e.get("lang_code") != "de":
                continue
            pos = e.get("pos")
            n = normalize(e.get("word"))
            if pos in DROP_POS:
                if n:
                    function.add(n)
                for fm in e.get("forms") or []:
                    fn = normalize(fm.get("form"))
                    if fn:
                        function.add(fn)
                continue
            if _is_form_of(e):
                glosses = " ".join(g for s in e.get("senses") or [] for g in s.get("glosses") or [])
                if n and any(h in glosses.lower() for h in FUNCTION_HINTS):
                    function.add(n)
                continue
            if pos not in KEEP_POS or not n:
                continue
            candidates.add(n)
            if pos == "noun":
                for fm in e.get("forms") or []:
                    tags = fm.get("tags") or []
                    if "nominative" in tags and "plural" in tags:
                        fn = normalize(fm.get("form"))
                        if fn:
                            candidates.add(fn)
    return candidates, function


def read_frequencies(paths):
    """Return (average relative frequency per normalized word, words mostly written in capitals)."""
    total = collections.Counter()
    caps = collections.Counter()
    seen = collections.Counter()
    for p in paths:
        counts = collections.Counter()
        with open(p, encoding="utf-8") as f:
            for line in f:
                parts = line.rstrip("\n").split("\t")
                if len(parts) < 3:
                    continue
                n = normalize(parts[1])
                if n:
                    c = int(parts[2])
                    counts[n] += c
                    seen[n] += c
                    if parts[1].isupper():
                        caps[n] += c
        s = sum(counts.values()) or 1
        for w, c in counts.items():
            total[w] += c / s
    mostly_caps = {w for w, c in caps.items() if c * 2 > seen[w]}
    return {w: v / len(paths) for w, v in total.items()}, mostly_caps


def read_blocklist(path):
    with open(path, encoding="utf-8") as f:
        return {line.strip() for line in f if line.strip() and not line.startswith("#")}


def main(wikt, valid_path, block_path, dst, count, corpora):
    with open(valid_path, encoding="utf-8") as f:
        valid = {line.strip() for line in f if line.strip()}
    candidates, function = read_wiktionary(wikt)
    drop = function - KEEP_ANYWAY
    pool = {w for w in (candidates & valid) - drop if MIN_LEN <= len(w) <= MAX_LEN}
    freq, mostly_caps = read_frequencies(corpora)
    pool -= read_blocklist(block_path) | mostly_caps
    ranked = sorted((w for w in pool if freq.get(w, 0) > 0), key=lambda w: (-freq[w], w))
    chosen = ranked[:count]
    with open(dst, "w", encoding="utf-8") as out:
        for w in sorted(chosen):
            out.write(w + "\n")
    with open(dst.replace(".txt", "-ranked.txt"), "w", encoding="utf-8") as out:
        for i, w in enumerate(chosen, 1):
            out.write(f"{i}\t{w}\n")
    lengths = collections.Counter(len(w) for w in chosen)
    print(f"candidates={len(candidates)} valid_pool={len(pool)} with_freq={len(ranked)} chosen={len(chosen)}")
    print("by length:", ", ".join(f"{k}={lengths[k]}" for k in sorted(lengths)))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5]), sys.argv[6:])
