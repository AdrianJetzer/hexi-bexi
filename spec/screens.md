# Screens und Ablauf

Status: **Entwurf v4**. Angepasst an Lauf-Modus v3 mit Block-Zeilen ([run-mode.md](run-mode.md)); Optik offen.

## Übersicht

```
                ┌──────────────────┐
   App-Start ──▶│  Startbildschirm │◀───────────────┐
                └───┬─────────┬────┘                │
          Spielen   │         │ Einstellungen       │
                    ▼         ▼                     │
             ┌──────────┐  ┌───────────────┐        │
             │  Spiel   │  │ Einstellungen │──zurück┘
             └────┬─────┘  └───────────────┘
   „Aufgeben?“    │ Ja
                  ▼
           ┌─────────────┐
           │   Bilanz    │── Menü ──▶ Startbildschirm
           └──────┬──────┘
                  │ Nochmal
                  ▼
           neuer Lauf (Spiel, Level 1)
```

## Screens in Version 1

Vier Screens: **Startbildschirm, Spiel, Bilanz, Einstellungen.** Dazu ein kurzes **Tutorial** beim ersten Start (v4.38, siehe unten).

### Startbildschirm
- **Titel/Logo**, schön inszeniert.
- **Spielen-Knopf:** startet einen neuen Lauf.
- **Rekord:** höchstes erreichtes Level.
- **Einstellungen-Knopf:** öffnet die Einstellungen.

### Spiel
- Aufbau siehe [screen-layout.md](screen-layout.md), Regeln siehe [game-rules.md](game-rules.md).
- **Kein Zeitdruck**, daher auch **keine Pause-Funktion** nötig.
- **Auftrag:** Block-Zeilen über dem Spielfeld (siehe [run-mode.md](run-mode.md)); gefundene Wörter fliegen hinein. Kein Text, kein gewischtes Wort.
- **Anzeige:** über dem Spielfeld links die **Leiter** (20 Quadrate, eins je Level, liegend wie eine Leiter; jedes Quadrat hat seine feste Farbe im Verlauf grün → orange → rot; geschaffte Level leuchten, das laufende ist farbig umrandet, offene sind dunkel), rechts die **Münzen**. Kein Text „Level · Rekord“ mehr. Screenshot: [Leiter](images/ladder-v1.png).
- **Wisch-Vorschau (v4.35):** Beim Wischen füllt sich in der kürzesten freien Block-Zeile, in die das Wort noch passt, je verbundenem Buchstaben ein Block (von links): türkis wie ein gelöster Block, nur leicht durchsichtig, mit dem gewischten Buchstaben in Weiß; der Rand bleibt gleich. Jeder neue Block blitzt kurz heller auf und ploppt leicht größer (ca. 0,05 s), dann steht er ruhig. Sind es mehr Buchstaben, als die längste freie Zeile hat, blitzen deren Blöcke kurz zweimal auf und ploppen leicht („zu viele“). Beim Loslassen blenden Füllung und Buchstaben mit einem letzten Puls aus; ist das Wort richtig, fliegen die echten Buchstaben wie bisher in die Blöcke.
- **Power-up-Auswahl** (nach Level 4, 8, 12, 16; Upgrades nur im endlosen Test-Betrieb): halbtransparenter Bildschirm über dem Spiel mit großem, goldenem Titel („Wähle eine Hilfe“ bzw. „Welche Hilfe wird günstiger?“) und Karten im Stil der Hilfe-Knöpfe: oben Name · Münze · Preis (beim Upgrade „alt → neu“), darunter die Erklärung (Power-up: 2 zufällige der Stufe) (Name, Preis, kurze Erklärung; beim Upgrade „alt → neu“). Antippen wählt, dann geht es weiter (siehe [run-mode.md](run-mode.md)). Screenshots: [Start](images/draft-start-v1.png), [Power-up](images/draft-powerup-v1.png), [Upgrade](images/draft-upgrade-v1.png).
- **Power-up-Anzeige** links unter dem Spielfeld, **ohne Text** (v4.22): je Level bis zum nächsten Power-up ein Quadrat (4 Stück, etwas größer als die Leiter, eigene Farben Cyan, Violett, Pink, Gold). Geschaffte Level leuchten, das laufende ist umrandet; im Level vor dem Power-up pulsiert die Anzeige. **Animation (v4.24):** Ist ein Level geschafft, dreht sich sein Quadrat kurz danach mit Perspektive um die senkrechte Achse (hebt sich leicht an), wechselt in der Mitte von dunkel auf seine Farbe mit Glanzstreifen und versprüht Funken (ohne Rauch, v4.26); danach leuchtet das nächste Quadrat sanft als „ready“ auf. Nach dem goldenen bleiben alle vier gefüllt, bis die Power-up-Auswahl erledigt ist. Keine Vibration. Nach dem letzten Power-up und im Story-Modus gibt es keine Anzeige (den Weg zum Ziel zeigt die Leiter). Screenshot: [Power-up-Quadrate](images/powerup-squares-v1.png).
- **Hilfe-Knöpfe** mit Preis, sortiert **von gratis bis teuer**: **Auffüllen** (5 Steine, gratis); **50:** Tipp (je Buchstabe); **100:** Mischen, Joker, Kürzen; **150:** Aufräumen, Teilen, Magnet (Stein antippen); **200:** Scan, Zeile streichen, Vervollständigen (Wortanfang anwischen); **Lösen** (ganzer Auftrag, 500). Gesperrt, wenn das Geld nicht reicht; Auffüllen auch bei vollem Feld.
- **Oben links / oben rechts (v4.25):** etwas Abstand zum oberen Rand (runde Display-Ecken), schmale Glas-Knöpfe **nur mit Symbol**, dezenter als die Hilfe-Knöpfe (schwacher Rand, leuchtet beim Antippen): **Kreuz** = Aufgeben, **Haus** = Home-Screen (v4.40, vorher drei Striche = Einstellungen). Symbole selbst gezeichnet (Linien), kein Text.
- **Knopf „Aufgeben“:**
  - Tippen öffnet die Nachfrage **„Aufgeben?“** mit Ja / Nein.
  - **Ja:** Lauf endet, es folgt der **Bilanz-Screen**. **Nein:** weiterspielen.

### Bilanz (ersetzt „Game-Over“)
- **Geschafft** (Level 20 gelöst): „Geschafft!“, **Sterne**, **übrige Münzen** und **Rekord** (meiste übrige Münzen), mit Hinweis bei **neuem Rekord**. Screenshot: [Geschafft](images/goal-done-v1.png).
- **Aufgegeben:** Vorher zeigt das Spiel die **Lösung** (Steine blinken, Buchstaben fliegen in die Zeile); der Knopf **„Weiter“** öffnet die Bilanz „Nicht geschafft“ mit **Level n von 20** und dem Rekord.
- Knöpfe:
  - **Nochmal:** startet sofort einen neuen Lauf ab Level 1.
  - **Menü:** zurück zum Startbildschirm.

### Home-Screen (früher „Einstellungen“)
- **Home-Knopf** oben rechts im Spiel und auf dem Kapitel-Brett: Glas-Knopf mit gezeichnetem **Haus** (v4.40, vorher drei Striche). Öffnet den Home-Screen als Ebene über dem Spiel. Siehe [Screenshot](images/home-screen-v1.png).
- **Aufbau (v4.40):** kein Titel oben. Zuerst die Überschrift **„Modus“** (groß, Größe wie früher der Titel) mit den vier Modus-Karten, darunter die Überschrift **„Einstellungen“** (gleich groß) mit Vibration, Tutorial, Schließen.
- **Wann er erscheint (v4.40):**
  - App war nur im Hintergrund: Sie geht dort weiter, wo man war (kein Home-Screen).
  - Allererster Start: Tutorial, danach direkt ins Spiel.
  - **Kalter Start** (App beendet, Handy neu gestartet) nach dem Tutorial: **Home-Screen**. Darunter läuft schon ein neuer Lauf im gespeicherten Modus (Läufe werden nicht gespeichert). Den aktuellen Modus antippen oder „Schließen“ = ins Spiel; ein anderer Modus wechselt **ohne Nachfrage**, weil noch nichts gespielt ist. Ebenso startet „Tutorial“ dann ohne Nachfrage.
- **Modus** (siehe [run-mode.md](run-mode.md), „Modi“): **Einfach**, **Mittel**, **Schwer**, **Story** (siehe [story-mode.md](story-mode.md); Beschriftung der Knöpfe seit v4.32). Der aktuelle ist markiert. Neu installiert: **Einfach** (v4.38, vorher mittel).
  - Auf den Knöpfen steht **nur der Name**, ohne Beschreibung; darunter bei einfach / mittel / schwierig die **besten Sterne** (☆☆☆ … ★★★). Story zeigt keine Sterne (die stehen je Kapitel auf dem Pfad). Screenshot: [Einstellungen](images/settings-stars-v1.png).
  - Wechsel mitten im Lauf: Nachfrage **„Modus wechseln und neu starten?“** (Ja / Nein). Ja startet einen neuen Lauf im neuen Modus.
  - **Denselben Modus nochmal wählen** (v4.23): dieselbe Nachfrage; Ja startet den Lauf neu (einfach / mittel / schwierig) bzw. führt in der Story zurück aufs **Kapitel-Brett** (das Kapitel ist abgebrochen). Auf dem Kapitel-Brett selbst schließt „Story“ nur die Einstellungen.
  - Der Modus wird gespeichert und gilt beim nächsten Start.
- **Kein Ton, keine Musik** (v4.37): Das Spiel ist stumm, deshalb gibt es keine Schalter dafür. Rückmeldung nur über Optik und Vibration.
- **Knöpfe unter „Einstellungen“** (v4.39): **„Vibration: an/aus“**, **„Tutorial“**, **„Schließen“** – gleich groß wie die Modus-Karten, aber dezenter: dunkelgrau, dünner grauer Rand ohne Leuchten, graue Schrift. Innerhalb eines Abschnitts gleicher Abstand (22 px), zwischen Überschrift und Knöpfen 40 px. So ordnen sie sich den Modi unter.
- **Vibration** an/aus (Knopf „Vibration: an/aus“; neu installiert: an). Beim Wischen gibt **jeder neu verbundene Buchstabe einen kurzen, leichten Tick** (ca. 15 ms); Zurückwischen und fertige Wörter vibrieren nicht.
- **Testmodus** an/aus (Knopf „Testmodus: an/aus“ unter Vibration; neu installiert: aus). **Zurzeit ausgeblendet** (v4.21, Schalter `TEST_MODE_MENU` im Code); solange ist der Testmodus wirkungslos. Ist er an, kostet **Lösen 0 Münzen** (alle Modi), zum schnellen Durchspielen beim Testen.
- **Rekord zurücksetzen** (mit Nachfrage).
- Einstellungen werden lokal gespeichert.

## Rekord

- **Ein Rekord je Modus:** die meisten **übrigen Münzen** eines geschafften Laufs (Level 20) im jeweiligen Modus, dazu die besten **Sterne**. Die Bilanz zeigt den Rekord des aktuellen Modus.
- Der Rekord zählt nur bei einem **geschafften** Lauf, nicht beim Aufgeben. Alte Rekorde (höchstes Level) gelten nicht mehr.
- Wird **lokal auf dem Gerät** gespeichert.
- Architektur so anlegen, dass **später Online-Ranglisten** möglich sind (Google Play Games, Game Center).

## Tutorial (v4.38)

Ohne Text, nur mit einem gezeichneten Finger. Screenshot: [Finger](images/tutorial-finger-v1.png).

- **Wann:** automatisch beim **ersten Start** (auch einmal nach einem Update, wenn es noch nicht gesehen wurde) und jederzeit über **Einstellungen → „Tutorial“**. Läuft gerade ein Lauf, fragt das Spiel erst **„Tutorial starten? Der Lauf wird beendet.“** (Ja / Nein).
- **Ablauf:** Es läuft im Modus **Einfach**, mit zwei festen Runden auf dem normalen Feld:
  1. **DAS:** eine Zeile mit 3 Kästchen; in der untersten Reihe liegt D–A–S als Kette, dazu 7 andere Steine.
  2. **BAUM:** eine Zeile mit 4 Kästchen; B–A–U–M in der untersten Reihe, dazu 6 andere Steine.
- **Finger:** Eine gezeichnete, leuchtend umrandete Hand setzt auf den ersten Buchstaben, zieht mit leuchtender Spur über das Wort, hebt ab und beginnt nach kurzer Pause von vorn, bis der Spieler das Wort **selbst wischt**. Während man wischt, verschwindet der Finger; nach einem Fehlversuch kommt er wieder. Er erscheint erst, wenn das Feld fertig aufgebaut ist (alle Steine gedreht), auch beim Start. Nach dem richtigen Wort verschwindet er sofort und kommt erst wieder, wenn die Buchstaben oben angekommen sind und die neuen Steine liegen (dann mit dem Weg des neuen Worts).
- **Nur das Zielwort zählt** (auch andere echte Wörter werden abgelehnt). Kein Nachfüllen, keine Münzen, keine Hilfen, keine Leiter, kein Aufgeben-Knopf; nur der Menü-Knopf bleibt.
- **Danach:** ein normaler Lauf im **vorher gewählten Modus** (Level 1). Beim ersten Start ist das **Einfach** (neue Installationen starten in Einfach). Wer im Tutorial über das Menü einen Modus wählt, verlässt es; es gilt dann als gesehen.

## Leistung (v4.36)

Gemessen auf einem Mittelklasse-Handy (Redmi Note 10 Pro, Android 14, 1080 × 2400): ohne Anpassung nur ca. 22 Bilder/s, der Grafikchip ist der Engpass (Prozessor kaum ausgelastet). Glow und Schatten kosten kaum etwas; teuer sind die Bildschirm-Auflösung und der Nebel-Hintergrund.

- **Nebel vorberechnet:** Das Rauschen des Nebel-Hintergrunds wird einmal beim Start als kachelbare Textur erzeugt und im Spiel nur noch nachgeschlagen (vorher 2 × 6 Rausch-Schichten je Pixel und Bild). Optik gleich, Redmi von ca. 22 auf ca. 36 Bilder/s.
- **Automatische 3D-Auflösung:** Nach dem Start misst das Spiel 2 s Einschwingen + 3 s die Bildrate. Unter 50 Bilder/s rechnet die 3D-Welt (Steine, Hintergrund, Kapitel-Brett) mit **75 %** Auflösung, liegt es danach noch unter 40, mit **60 %**. Schrift, Knöpfe und Kästchen bleiben scharf. Schnelle Handys (z. B. Pixel 10 Pro) bleiben bei 100 %. Redmi: 75 %, ca. 53 Bilder/s.



- Optik und Übergänge zwischen den Screens (Animationen).
- Gestaltung von Logo und Titel.
- Verhalten der Android-Zurück-Geste auf den einzelnen Screens.

## Verlauf

- **v1:** Screens für Version 1, Ablauf, Menü-Knopf statt Pause, Verhalten im Hintergrund, Game-Over mit Nochmal und Menü, Einstellungen, Rekord lokal.
- **v1.1:** Schwierigkeitsstufe in den Einstellungen, Rekord pro Stufe.
- **v2:** Ruhiger Level-Modus: Bilanz statt Game-Over (Rundenende durch den Spieler), Knopf „Neue Buchstaben“, keine Pause und kein Anhalten im Hintergrund nötig.
- **v3:** Lauf-Modus: Auftragswahl als Ebene über dem Spiel, Anzeige von Auftrag und Münzen, Hilfe-Knöpfe, „Aufgeben“ statt „Runde beenden“, Bilanz mit Level, ein Rekord (höchstes Level), Schwierigkeitsstufe aus den Einstellungen entfernt.
- **v4:** Auftragswahl entfällt; Auftrag als Block-Zeilen über dem Spielfeld; kein Text für Auftrag und gewischtes Wort; Bilanz nur nach Aufgeben.
- **v4.1:** Fünfter Hilfe-Knopf „Aufräumen“.
- **v4.2:** Sechster Hilfe-Knopf „Lösen“.
- **v4.3:** Hilfe-Knöpfe Joker, Mischen, Schwerkraft; zum Testen in zwei Reihen, gute Platzierung später.
- **v4.4:** Hilfe-Knöpfe Magnet und Säule (Antipp-Modus wie Ersetzen); zum Testen in drei Reihen.
- **v4.5:** Hilfe-Knöpfe Teilen und Scan.
- **v4.6:** Säule und Schwerkraft entfallen; Hilfe-Knöpfe nach Preis sortiert (gratis bis teuer).
- **v4.7:** Hilfe-Knopf Vervollständigen (Wisch-Modus).
- **v4.8:** Hilfe-Knopf Kürzen.
- **v4.9:** Preisstufen 50/100/150/200 (je drei Hilfen), Knopf Zeile streichen, Lösen 500.
- **v4.27:** Wisch-Vorschau in den Block-Zeilen (abdunkeln, Puls bei zu vielen Buchstaben).
- **v4.28:** Wisch-Vorschau als Lava-Glut statt Abdunkeln: pulsiert rein, beim Loslassen wieder raus.
- **v4.29:** Glut in Magenta (passt zu den Power-up-Farben), schnelles Aufflammen statt Einblenden. Cyan-Variante evtl. später testen.
- **v4.30:** Glut als Kristall-Plasma in Cyan (passt zu den Steinen); Magenta verworfen.
- **v4.31:** Modus-Knöpfe beschriftet mit EASY, MEDIUM, HARD, STORY.
- **v4.32:** Doch deutsch: Einfach, Mittel, Schwer, Story (passt zum Rest der Oberfläche).
- **v4.33:** Wisch-Vorschau zeigt die gewischten Buchstaben in den glühenden Blöcken.
- **v4.34:** Glut der Wisch-Vorschau gedämpft (ruhige Glut und Aufflammen schwächer).
- **v4.35:** Lava/Plasma verworfen: Vorschau-Blöcke sehen aus wie gelöste (türkis, weißer Buchstabe), nur leicht durchsichtig.
- **v4.36:** Leistung: Nebel-Rauschen vorberechnet, automatische 3D-Auflösung auf schwächeren Handys.
- **v4.37:** Kein Ton und keine Musik; Schalter dafür entfernt.
- **v4.38:** Tutorial beim ersten Start und über das Menü (DAS, BAUM, Finger); neu installiert startet Einfach.
- **v4.40:** Einstellungen werden zum Home-Screen: Haus-Symbol statt drei Striche, kein Titel oben, Überschrift „Modus“ groß, neue Überschrift „Einstellungen“ vor Vibration; nach kaltem Start erscheint der Home-Screen.
- **v4.39:** Einstellungen: Vibration, Tutorial und Schließen als dezente graue Knöpfe in Größe der Modus-Karten.
- **v4.26:** Symbol-Knöpfe tiefer (nicht mehr im Rand); Power-up-Drehung ohne Rauch.
- **v4.25:** Aufgeben und Einstellungen als Symbol-Knöpfe (Kreuz, Menü) statt Text.
- **v4.24:** Power-up-Quadrate drehen sich beim Level-Abschluss mit Funken und Rauch.
- **v4.23:** Denselben Modus nochmal wählen fragt „Modus wechseln und neu starten?“ (Neustart).
- **v4.22:** Kein Text unter dem Feld mehr: Power-up-Anzeige als 4 farbige Quadrate, Story ohne „bis zum Ziel“.
- **v4.21:** Menüeintrag Testmodus ausgeblendet.
- **v4.20:** Tipp 50; Ersetzen und Tauschen vorerst deaktiviert.
- **v4.19:** Story im Kapitel nochmal wählen: Nachfrage, dann Kapitel-Brett.
- **v4.18:** Testmodus (Lösen gratis) in den Einstellungen.
- **v4.17:** Vibration: Tick je verbundenem Buchstaben, Schalter in den Einstellungen.
- **v4.16:** Neue Preisstufen (Tauschen 50, Mischen 100, Aufräumen und Magnet 150, Vervollständigen 200).
- **v4.15:** Leiter (20 Quadrate) statt „Level · Rekord“; Bilanz „Geschafft!“ mit Sternen bei Level 20; Rekord = übrige Münzen; Modus-Knöpfe nur mit Namen und Sternen; Tipp in der 100er-Stufe.
- **v4.14:** Modus „Story“ in den Einstellungen, Pfad durchs All, Rätsel-Anzeige, Kapitel-Abschluss.
- **v4.13:** Auswahl-Bildschirm überarbeitet: ohne Zeile „Power-up“/„Upgrade“, Titel hervorgehoben, Karten als Glas-Knöpfe mit Münze und größerer Erklärung.
- **v4.12:** Knopf „Einstellungen“ oben rechts; Modus einfach / mittel / schwierig mit Neustart-Nachfrage; Rekord je Modus.
- **v4.11:** Münzen oben rechts mit goldener Münze statt Wort „Münzen“.
- **v4.10:** Auswahl-Bildschirm für Power-ups und Upgrades (Karten), Hinweis „Noch n Level bis zum Power-up“, Knöpfe nur für freigeschaltete Hilfen (2 × 3).
