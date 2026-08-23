#!/bin/sh
# dev-path — one assertion per element of a printed design round: the question
# marker, the recommendation marker, and the round's header.
#
# The reason this file exists is the hole it closes. skills/technical-design
# mandated that questions be numbered and that each carry a recommended answer,
# and said nothing about what one looks like once printed. Every session invented
# a layout, and the observed run printed ten dense questions split under two
# sub-headings — two interrogations where the frontier is one. The fix is prose,
# and prose with nothing holding it is how the hole opened in the first place.
#
# The header assertion has two sides and the second is the one that earns the
# file. `## Technical design questions` is a literal the skill tells the agent to
# print, so it belongs in a fence; written bare it is a real heading in the
# skill's own structure and splits the section it lives in. No other test under
# tests/ is fence-aware, so nothing else would catch it.
#
# What a session actually printed is not a test's to see. This asserts the rule is
# on the page, which is the same bargain tests/compositions.sh strikes.
#
# Exit code is the build's.

cd "$(dirname "$0")/.." || exit 1

F=skills/technical-design/SKILL.md
FAIL=0

if [ ! -f "$F" ]; then
  echo "FAIL subject: $F does not exist"
  exit 1
fi

# --- 1. The question marker, paired with the number. Yellow is the question still
#        waiting on the human, and the number is what makes "I disagree with Q3"
#        land in a forty-exchange conversation.
if ! grep -qF '🟡 **Q1**' "$F"; then
  echo "FAIL [question marker] $F shows no 🟡 question block"
  echo "      expected a line holding: 🟡 **Q1**"
  FAIL=1
fi

# --- 2. The recommendation marker, opening its own line. Green is the answer
#        already on the table, and "on its own line beneath" is the half that
#        makes disagreement the cheap response instead of an essay. Anchored,
#        because a ❇️ buried mid-sentence is prose, not the block.
if ! grep -q '^❇️' "$F"; then
  echo "FAIL [recommendation marker] $F shows no ❇️ line of its own"
  echo "      expected a line opening with: ❇️"
  FAIL=1
fi

# --- 3. The round header, fenced and fenced only. awk tracks the fence because
#        grep cannot, and the distinction is the whole point: the same string is
#        right shown as a literal and wrong as a live heading, and three
#        backticks earlier in the file are the only difference between them.
FENCED=$(awk '
  /^```/ { fence = !fence; next }
  fence && /^## Technical design questions/ { n++ }
  END { print n+0 }
' "$F")

LIVE=$(awk '
  /^```/ { fence = !fence; next }
  !fence && /^## Technical design questions/ { print NR ": " $0 }
' "$F")

if [ "$FENCED" -lt 1 ]; then
  echo "FAIL [round header] $F shows no fenced '## Technical design questions'"
  FAIL=1
fi

if [ -n "$LIVE" ]; then
  echo "FAIL [round header] $F carries '## Technical design questions' as a live heading"
  printf '%s\n' "$LIVE" | sed 's/^/      /'
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "round-format: question marker, recommendation marker and a fenced header — clean"
fi
exit "$FAIL"
