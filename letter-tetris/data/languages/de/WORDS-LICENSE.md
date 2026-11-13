# Lizenz der deutschen Wortlisten (`words.bin`, `common.bin`)

`words.bin` ist aus zwei Quellen erzeugt (siehe `tools/dictionary/`):

1. **Trennmuster-Wortliste**
   Copyright (c) 2013–2024 Stephan Hennig, Werner Lemberg, Günter Milde,
   Sander van Geloven, Georg Pfeiffer, Gisbert W. Selke, Tobias Wendorf, Keno Wehr.
   Lizenz: MIT. Quelle: https://repo.or.cz/wortliste.git

2. **Wiktionary (deutsch)**, maschinell ausgelesen über wiktextract / kaikki.org.
   Autorinnen und Autoren: die Mitwirkenden des deutschen Wiktionary.
   Lizenz: Creative Commons Attribution-ShareAlike 3.0 (CC BY-SA 3.0) und GFDL.
   Quellen: https://de.wiktionary.org, https://kaikki.org

Bearbeitung: Wörter in Großbuchstaben A–Z umgewandelt, ß → SS, Wörter mit Umlauten
oder Sonderzeichen entfernt, mindestens 3 Buchstaben, beide Listen zusammengeführt
und in ein kompaktes Binärformat gepackt.

Die Wortliste `words.bin` steht als abgeleitetes Werk unter **CC BY-SA 3.0**.
Der Programmcode des Spiels ist davon nicht betroffen.

`common.bin` (geläufige Wörter für die Wort-Hilfe) enthält nur die Trennmuster-Wortliste
(MIT, Copyright siehe oben), bearbeitet wie oben beschrieben.
