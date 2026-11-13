"""Remove excluded words (proper names, abbreviations) and Roman numerals from a word list.

Usage: python3 -I filter_words.py <words.txt> <excluded.txt> <out.txt> [<roman-keep.txt>]
Roman numerals (e.g. LIII) are removed unless listed in <roman-keep.txt> (e.g. MIX).
"""
import re
import sys

ROMAN = re.compile(r"^M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$")


def _read(path):
    with open(path, encoding="utf-8") as f:
        return {line.strip() for line in f if line.strip()}


def main(src, excluded_path, dst, roman_keep_path=None):
    excluded = _read(excluded_path)
    roman_keep = _read(roman_keep_path) if roman_keep_path else set()
    kept = removed = romans = 0
    with open(src, encoding="utf-8") as f, open(dst, "w", encoding="utf-8") as out:
        for line in f:
            w = line.strip()
            if not w:
                continue
            if w in excluded:
                removed += 1
                continue
            if ROMAN.match(w) and w not in roman_keep:
                romans += 1
                continue
            out.write(w + "\n")
            kept += 1
    print(f"{src}: kept={kept} removed_names_abbrevs={removed} removed_roman={romans}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else None)
