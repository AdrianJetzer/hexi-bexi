#!/usr/bin/env bash
# Führt alle GUT-Tests des Godot-Projekts ohne Fenster aus.
# Aufruf:  tools/run-tests.sh
# Godot-Pfad über GODOT=/pfad/zu/Godot überschreibbar.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$HERE/../hexi-bexi"

if [ -z "${GODOT:-}" ]; then
  for c in /Applications/Godot.app/Contents/MacOS/Godot "$HOME/Downloads/Godot.app/Contents/MacOS/Godot" "$(command -v godot || true)"; do
    if [ -n "$c" ] && [ -x "$c" ]; then GODOT="$c"; break; fi
  done
fi
if [ -z "${GODOT:-}" ]; then
  echo "Godot nicht gefunden. Pfad mit GODOT=/pfad/zu/Godot angeben." >&2
  exit 1
fi

# Einmal importieren (Klassen-Cache, Ressourcen), dann Tests laufen lassen.
"$GODOT" --headless --path "$PROJECT" --import >/dev/null 2>&1 || true
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT
set +e
"$GODOT" --headless --path "$PROJECT" -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json 2>&1 | tee "$LOG"
STATUS=${PIPESTATUS[0]}
set -e

# GUT überspringt Testdateien mit Syntaxfehlern stillschweigend – das als Fehler werten.
if grep -qE "Parse Error|Ignoring script" "$LOG"; then
  echo "FEHLER: Mindestens eine Testdatei konnte nicht geladen werden (siehe oben)." >&2
  exit 1
fi
exit "$STATUS"
