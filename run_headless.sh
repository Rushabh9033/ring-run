#!/bin/bash
# Run a headless Godot script with a hard timeout, so a compile error or an
# infinite loop can never wedge the session.
set -u
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
SCRIPT="$1"
shift || true
LOG="${TMPDIR:-/tmp}/rr_headless_$$.log"
( "$GODOT" --headless --path "$(cd "$(dirname "$0")" && pwd)" --script "$SCRIPT" "$@" > "$LOG" 2>&1 ) &
PID=$!
for _ in $(seq 1 "${RR_TIMEOUT:-120}"); do
	if ! kill -0 "$PID" 2>/dev/null; then break; fi
	if grep -qE 'Parse Error|Compile Error|Failed to load script' "$LOG" 2>/dev/null; then
		echo "COMPILE ERROR:"; grep -E 'Parse Error|Compile Error|Failed to load script|at: GDScript' "$LOG" | head -10
		kill -9 "$PID" 2>/dev/null; wait "$PID" 2>/dev/null
		exit 2
	fi
	sleep 1
done
if kill -0 "$PID" 2>/dev/null; then
	echo "TIMEOUT after ${RR_TIMEOUT:-120}s — log:"; kill -9 "$PID" 2>/dev/null
	grep -vE '^\s*$' "$LOG" | tail -40
	exit 124
fi
wait "$PID"; CODE=$?
grep -vE 'WARNING: [0-9]+ (RIDs|ObjectDB)|ERROR: [0-9]+ resources still in use|^\s+at: _free_rids|^\s+at: cleanup|^\s+at: clear' "$LOG"
exit $CODE
