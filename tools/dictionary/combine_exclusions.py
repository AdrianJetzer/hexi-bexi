"""Combine exclusion lists: proper names/abbreviations from Wiktionary plus acronyms and
abbreviations and names marked in the Trennmuster list ("# Abk.", "# … Name", all capitals),
except words that
Wiktionary knows as normal words in normal spelling (e.g. Aids, Abc).

Usage: python3 -I combine_exclusions.py <excluded.txt> <trennmuster-abbrevs.txt> <wiktionary-normalcase.txt> <out.txt>
"""
import sys


def _read(path):
    with open(path, encoding="utf-8") as f:
        return {line.strip() for line in f if line.strip()}


def main(excluded_path, abbrevs_path, normalcase_path, dst):
    excluded = _read(excluded_path)
    # Ausnahmen nur für aussprechbare Wörter (mit Vokal); „http“, „ccm“ usw. bleiben Abkürzungen.
    normal = {w for w in _read(normalcase_path) if any(v in w for v in "AEIOUY")}
    acronyms = _read(abbrevs_path) - normal
    result = excluded | acronyms
    with open(dst, "w", encoding="utf-8") as out:
        for w in sorted(result):
            out.write(w + "\n")
    print(f"excluded: names/abbrevs={len(excluded)} acronyms={len(acronyms)} total={len(result)}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
