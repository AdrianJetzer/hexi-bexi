class_name Scoring
extends RefCounted
## Punkte für ein Wort: factor · n · (n − 1), n = Anzahl Buchstaben.


static func word_points(length: int, factor: int = 5) -> int:
	if length <= 0:
		return 0
	return factor * length * (length - 1)
