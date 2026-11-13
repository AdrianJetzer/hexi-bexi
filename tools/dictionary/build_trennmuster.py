"""Extract game words (reformed spelling) from the Trennmuster 'wortliste'.

Usage: python3 -I build_trennmuster.py <wortliste> <out.txt>
"""
import re
import sys

ALLOWED = re.compile(r"^[A-Z]{3,}$")


def normalize(word: str):
    w = word.replace("ß", "SS").replace("ẞ", "SS").upper()
    return w if ALLOWED.match(w) else None


def reformed_ok(fields):
    # 2 fields: identical for all spellings
    if len(fields) == 2:
        return True
    if fields[1] and not re.fullmatch(r"-2-", fields[1]):
        return True
    # field 4 = reformed spelling
    if len(fields) >= 4 and not re.fullmatch(r"-4-", fields[3]):
        return True
    # fields 5/7: Swiss/uppercase variants; field 7 = reformed
    if len(fields) >= 5 and fields[4] and not re.fullmatch(r"-5-", fields[4]) and len(fields) == 5:
        return True
    if len(fields) >= 7 and not re.fullmatch(r"-7-", fields[6]):
        return True
    return False


def main(src, dst):
    words = set()
    total = 0
    with open(src, encoding="utf-8") as f:
        for line in f:
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            total += 1
            fields = [x.strip() for x in line.split(";")]
            if not reformed_ok(fields):
                continue
            n = normalize(fields[0])
            if n:
                words.add(n)
    with open(dst, "w", encoding="utf-8") as out:
        for w in sorted(words):
            out.write(w + "\n")
    print(f"entries={total} words={len(words)}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
