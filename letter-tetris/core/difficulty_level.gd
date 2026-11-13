class_name DifficultyLevel
extends Resource
## Eine Schwierigkeitsstufe. Verändert nur die Wort-Hilfe (siehe spec/game-rules.md).

## Anzeigename, z. B. „Mittel“.
@export var display_name: String = ""
## Wie stark gute Buchstaben bevorzugt werden (0 = keine Hilfe).
@export var help_strength: float = 0.0
## Sind weniger geläufige Wörter im Feld möglich, wird gezielt nachgeholfen.
@export var min_words: int = 0
