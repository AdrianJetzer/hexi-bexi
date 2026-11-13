class_name LanguageData
extends Resource
## Alles Sprachabhängige an einem Ort (Alphabet, Buchstabenhäufigkeit, Vokale, Wortliste).
## Neue Sprache = neue LanguageData-Datei, kein Code.

## Sprachcode, z. B. "de".
@export var code: String = ""
## Anzeigename, z. B. "Deutsch".
@export var display_name: String = ""
## Buchstaben, die im Spiel vorkommen können.
@export var alphabet: PackedStringArray = PackedStringArray()
## Relative Häufigkeit je Buchstabe, gleiche Reihenfolge wie alphabet.
@export var weights: PackedFloat32Array = PackedFloat32Array()
## Welche Buchstaben als Vokale zählen (für den Vokal-Ausgleich).
@export var vowels: PackedStringArray = PackedStringArray()

@export_group("Vokal-Ausgleich")
## Liegt der Vokal-Anteil im Feld darunter, kommt sicher ein Vokal.
@export_range(0.0, 1.0) var min_vowel_ratio: float = 0.3
## Liegt der Vokal-Anteil im Feld darüber, kommt sicher ein Konsonant.
@export_range(0.0, 1.0) var max_vowel_ratio: float = 0.55
## Erst ab so vielen Buchstaben im Feld wird ausgeglichen.
@export var balance_min_letters: int = 4

@export_group("Wörterbuch")
## Pfad zur Wortliste (eine Zeile pro Wort, Großbuchstaben).
@export_file var words_path: String = ""


func is_valid() -> bool:
	return not alphabet.is_empty() and alphabet.size() == weights.size()


func is_vowel(letter: String) -> bool:
	return vowels.has(letter)
