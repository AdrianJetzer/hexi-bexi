class_name GameMode
extends Resource
## Spielmodus (siehe spec/run-mode.md, „Modi“): welche Wörter gelten, welche das Spiel vorschlägt
## und welche Auftrags-Kurve gilt. Hilfen, Preise und Münzen sind in allen Modi gleich.

## Kennung (für Einstellungen und Rekord), z. B. "de_medium".
@export var id: String = ""
## Name in den Einstellungen, z. B. „Deutsch mittel“.
@export var display_name: String = ""
## Kurze Beschreibung in den Einstellungen.
@export var description: String = ""
## Sprache (Alphabet, Buchstaben-Häufigkeit).
@export var language: LanguageData
## Gültige Wörter (leer = Wörterbuch der Sprache).
@export_file var words_path: String = ""
## Vorschlags-Wörter (leer = geläufige Wörter der Sprache).
@export_file var common_words_path: String = ""
## Auftrags-Kurve.
@export var curve: QuestCurve


func valid_words_path() -> String:
	return words_path if words_path != "" else language.words_path


func suggestion_words_path() -> String:
	return common_words_path if common_words_path != "" else language.common_words_path
