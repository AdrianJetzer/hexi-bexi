"""Remove excluded words (e.g. proper names, abbreviations) from a word list.

Usage: python3 -I filter_words.py <words.txt> <excluded.txt> <out.txt>
"""
import sys


def main(src, excluded_path, dst):
    with open(excluded_path, encoding="utf-8") as f:
        excluded = {line.strip() for line in f if line.strip()}
    kept = removed = 0
    with open(src, encoding="utf-8") as f, open(dst, "w", encoding="utf-8") as out:
        for line in f:
            w = line.strip()
            if not w:
                continue
            if w in excluded:
                removed += 1
                continue
            out.write(w + "\n")
            kept += 1
    print(f"{src}: kept={kept} removed={removed}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
