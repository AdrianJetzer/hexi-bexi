"""Packt eine Wortliste (ein Wort pro Zeile, A-Z) ins kompakte Spielformat.

Usage: python3 -I pack_words.py <words.txt> <out.bin> [--max-len N]

Format (alle Zahlen little-endian uint32):
  4 Bytes  Magic "LTW1"
  4 Bytes  max_len (L)
  L x 4    Anzahl Wörter je Länge 1..L
  Daten    Wörter gruppiert nach Länge (aufsteigend), je Gruppe sortiert,
           ASCII ohne Trennzeichen (feste Breite = Länge)
"""
import re
import struct
import sys

ALLOWED = re.compile(r"^[A-Z]+$")


def pack(words):
    by_len = {}
    for w in words:
        by_len.setdefault(len(w), set()).add(w)
    max_len = max(by_len) if by_len else 0
    out = bytearray(b"LTW1")
    out += struct.pack("<I", max_len)
    for n in range(1, max_len + 1):
        out += struct.pack("<I", len(by_len.get(n, ())))
    for n in range(1, max_len + 1):
        for w in sorted(by_len.get(n, ())):
            out += w.encode("ascii")
    return bytes(out)


def main(argv):
    src, dst = argv[0], argv[1]
    max_len = None
    if "--max-len" in argv:
        max_len = int(argv[argv.index("--max-len") + 1])
    words = []
    with open(src, encoding="utf-8") as f:
        for line in f:
            w = line.strip()
            if not w:
                continue
            if not ALLOWED.match(w):
                raise SystemExit(f"Ungültiges Wort: {w!r}")
            if max_len is None or len(w) <= max_len:
                words.append(w)
    data = pack(words)
    with open(dst, "wb") as f:
        f.write(data)
    print(f"words={len(set(words))} bytes={len(data)} -> {dst}")


if __name__ == "__main__":
    main(sys.argv[1:])
