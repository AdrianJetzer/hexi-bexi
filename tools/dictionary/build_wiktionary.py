"""Extract German game words from the kaikki.org German Wiktionary dump.

Usage: python3 -I build_wiktionary.py <dewiktionary.jsonl.gz> <out.txt> [<excluded.txt>]
Takes headwords of German entries (lang_code == "de") plus single-word inflected forms.
Obsolete spellings (forms tagged "obsolete", e.g. "Thee" for Tee) are left out unless the word
also exists as a normal entry or form. Proper names and abbreviations are left out: a word is excluded if it only occurs in
entries with pos "name" or "abbrev", or with capitals inside the headword (e.g. "UGs", "NASA",
"iPod"), with their forms, and in no other entry.
The excluded words are written to <excluded.txt> (to filter other word lists).
"""
import collections
import gzip
import json
import re
import sys

ALLOWED = re.compile(r"^[A-Z]{3,}$")
# Gültige römische Zahlen (z. B. LIII); gelten nicht als Spielwörter, außer sie sind auch ein
# normales Stichwort (z. B. MIX).
ROMAN = re.compile(r"^M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$")

# Wortarten, die nicht als Spielwörter gelten (Eigennamen, Abkürzungen).
EXCLUDED_POS = {"name", "abbrev"}


def normalize(word):
    if not word or " " in word or "-" in word:
        return None
    w = word.replace("ß", "SS").replace("ẞ", "SS").upper()
    return w if ALLOWED.match(w) else None


def _is_form_of(e):
    """Eintrag besteht nur aus Formen eines anderen Worts (z. B. „Kfzs“ → Kfz)."""
    senses = e.get("senses") or []
    return bool(senses) and all("form-of" in (s.get("tags") or []) for s in senses)


def _bases(e):
    result = set()
    for s in e.get("senses") or []:
        for fo in s.get("form_of") or []:
            n = normalize(fo.get("word"))
            if n:
                result.add(n)
    return result


def _mixed_case(e):
    """Stichwort mit Großbuchstaben mitten im Wort (z. B. „UGs“, „CEOs“, „NASA“, „iPod“):
    Abkürzungen, Akronyme und Markennamen. Gelten nicht als Spielwörter, außer es gibt sie
    auch normal geschrieben (z. B. „Ufo“ neben „UFO“)."""
    w = e.get("word") or ""
    # Nur einteilige Wörter aus Buchstaben: „Armee-Einheit“ oder „Corned Beef“ sind normale Wörter.
    return w.isalpha() and any(c.isupper() for c in w[1:])


ABBREV_HINTS = ("abkürzung", "akronym", "kurzwort", "initialwort", "zeichen für", "symbol")


def _is_contraction(e):
    """Wiktionary führt Zusammenziehungen wie „zum“, „beim“, „ins“, „sowas“ als „abbrev“.
    Die sind normale Wörter: kleingeschrieben und ohne Hinweis auf eine Abkürzung."""
    if e.get("pos") != "abbrev":
        return False
    w = e.get("word") or ""
    if not w.islower():
        return False
    for s in e.get("senses") or []:
        for g in s.get("glosses") or []:
            if any(h in g.lower() for h in ABBREV_HINTS):
                return False
    return True


def main(src, dst, excluded_dst=None):
    words = set()          # normale Wörter (inkl. Formen)
    names = set()          # Eigennamen / Abkürzungen (inkl. Formen)
    head_normal = set()    # Stichwörter mit normaler Wortart
    head_name = set()      # Stichwörter mit Wortart Name/Abkürzung
    normalcase = set()     # normale Wörter, deren Stichwort nicht ganz großgeschrieben ist (z. B. Aids)
    form_of = []           # (Wörter des Eintrags, Grundwörter) für reine Formen-Einträge
    obsolete = set()       # veraltete Schreibweisen (Formen mit Tag „obsolete“, z. B. „Thee“ zu Tee)
    real = set()           # Stichwörter echter Einträge und ihre nicht veralteten Formen
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
            is_name = (pos in EXCLUDED_POS and not _is_contraction(e)) or _mixed_case(e)
            own = set()
            n = normalize(e.get("word"))
            is_real = pos != "unknown" and not _is_form_of(e)
            if n and is_real:
                real.add(n)
            if n:
                own.add(n)
                pos_count[pos] += 1
            for fm in e.get("forms", []) or []:
                fn = normalize(fm.get("form"))
                if not fn:
                    continue
                # Veraltete Schreibweise (z. B. „Thee“, „Citat“, „Telephon“). Formen mit ß nicht:
                # „hinuntergoß“ wird zu HINUNTERGOSS und ist in neuer Schreibung ein gültiges Wort.
                raw = fm.get("form") or ""
                if "obsolete" in (fm.get("tags") or []) and "ß" not in raw:
                    obsolete.add(fn)
                    if is_name:
                        names.add(fn)  # alte Schreibweise eines Namens bleibt ein Name
                    continue
                if is_real:
                    real.add(fn)
                # Als Form angegebene Abkürzungen (z. B. „Kfz“ bei Kraftfahrzeug) sind keine Spielwörter.
                # Längere kleingeschriebene Kurzformen wie „rausreißen“ (zu herausreißen) bleiben
                # Wörter; kurze (z. B. Sprachcodes wie „tmh“) und solche mit Großbuchstaben nicht.
                form = fm.get("form") or ""
                is_abbrev = "abbreviation" in (fm.get("tags") or [])
                if is_abbrev and (form != form.lower() or len(form) < 5 or fm.get("raw_tags")):
                    names.add(fn)
                else:
                    own.add(fn)
            if is_name:
                names |= own
                if n:
                    head_name.add(n)
            elif _is_form_of(e):
                # Erst am Ende zuordnen: Formen von Namen/Abkürzungen gelten als Namen.
                form_of.append((own, _bases(e)))
            else:
                words |= own
                if n:
                    head_normal.add(n)
                    hw = e.get("word") or ""
                    # Normale Schreibweise: ganz klein oder nur der erste Buchstabe groß (nicht „AfD“, „GmbH“).
                    if hw == hw.lower() or hw == hw[:1].upper() + hw[1:].lower():
                        normalcase.add(n)
    name_only = head_name - head_normal
    for own, bases in form_of:
        if bases and bases <= name_only:
            names |= own
        else:
            words |= own
    # Veraltete Schreibweisen: raus, wenn es sie nicht auch als echtes Wort gibt.
    old_only = obsolete - real
    words -= old_only
    # Römische Zahlen: nur behalten, wenn sie auch ein normales Stichwort sind.
    roman_keep = {w for w in head_normal if ROMAN.match(w)}
    for w in [w for w in words if ROMAN.match(w) and w not in roman_keep]:
        words.discard(w)
    # Nur ausschließen, was nirgends sonst (als normales Wort) vorkommt.
    excluded = names - words
    with open(dst, "w", encoding="utf-8") as out:
        for w in sorted(words):
            out.write(w + "\n")
    if excluded_dst:
        with open(excluded_dst.replace(".txt", "-normalcase.txt"), "w", encoding="utf-8") as out:
            for w in sorted(normalcase):
                out.write(w + "\n")
        with open(excluded_dst.replace(".txt", "-roman-keep.txt"), "w", encoding="utf-8") as out:
            for w in sorted(roman_keep):
                out.write(w + "\n")
        with open(excluded_dst, "w", encoding="utf-8") as out:
            for w in sorted(excluded):
                out.write(w + "\n")
    print(f"german_entries={entries} words={len(words)} excluded_names_abbrevs={len(excluded)} "
          f"obsolete_spellings={len(old_only)}")
    print("headwords by pos:", ", ".join(f"{k}={v}" for k, v in pos_count.most_common(15)))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
