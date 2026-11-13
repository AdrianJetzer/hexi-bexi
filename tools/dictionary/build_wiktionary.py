"""Extract German game words from the kaikki.org German Wiktionary dump.

Usage: python3 -I build_wiktionary.py <dewiktionary.jsonl.gz> <out.txt>
Takes headwords of German entries (lang_code == "de") plus single-word inflected forms.
"""
import collections
import gzip
import json
import re
import sys

ALLOWED = re.compile(r"^[A-Z]{3,}$")


def normalize(word):
    if not word or " " in word or "-" in word:
        return None
    w = word.replace("ß", "SS").replace("ẞ", "SS").upper()
    return w if ALLOWED.match(w) else None


def main(src, dst):
    words = set()
    pos_count = collections.Counter()
    entries = 0
    with gzip.open(src, "rt", encoding="utf-8") as f:
        for line in f:
            try:
                e = json.loads(line)
            except ValueError:
                continue
            if e.get("lang_code") != "de":
                continue
            entries += 1
            pos = e.get("pos", "?")
            n = normalize(e.get("word"))
            if n:
                words.add(n)
                pos_count[pos] += 1
            for fm in e.get("forms", []) or []:
                n = normalize(fm.get("form"))
                if n:
                    words.add(n)
    with open(dst, "w", encoding="utf-8") as out:
        for w in sorted(words):
            out.write(w + "\n")
    print(f"german_entries={entries} words={len(words)}")
    print("headwords by pos:", ", ".join(f"{k}={v}" for k, v in pos_count.most_common(15)))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
