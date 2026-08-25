#!/bin/sh
# devpath — four assertions on Survey's dispatch ceiling: that the number is
# mirrored everywhere it is quoted, that the split it is made of still adds up
# to the number, that the cheaper-tier rule is stated at both stages that fan
# out, and that the no-sweep rule still carries a reason on each of its halves.
#
# The reason this file exists is that one number now lives in four files.
# skills/survey/SKILL.md sets it, skills/technical-design/SKILL.md quotes it
# describing the composition, skills/initiate/SKILL.md rests an accepted cost on
# it, and README.md lists it as prose nothing checks. A restatement drifts
# silently in exactly one direction: the rule is loosened where it is set, and
# the three quotations go on asserting the old bound to anyone who reads them
# instead. Every one of those readers is an agent about to dispatch.
#
# What this cannot do is check that a run honoured the ceiling. There is no
# field and no count — README says so under what is not bounded — so the subject
# here is the instruction, not the behaviour. That is the whole assertion: the
# instruction is the only thing carrying the bound, so it is worth a test that
# the four copies of it still say the same thing.
#
# Assertion 2 is what makes assertion 1 mean anything. "five" appearing in four
# files is a string four files happen to share; four-plus-one summing to five in
# the blockquote that mandates it is the rule. The split is the half that failed
# review once already: a ceiling written as four on the first pass and one chase
# had a sentence under it telling an orchestrator to cluster into three and hold
# a slot, which only makes sense if the five splits freely, and an agent reading
# both cannot tell whether it may chase once or twice.
#
# Assertion 3 rides along because it is the other claim mirrored between two
# files, and it is mirrored the fragile way: Survey and Integrate each dispatch
# a fan-out, each name the tier by its property rather than its name, and each
# exclude Haiku by decision. Integrate used to delegate its reason to Survey's
# file by name, and a delegated reason is a reason that silently stops being
# true. Both sites are pinned, so the pair stays a pair.
#
# Assertion 4 pins the retirement the ceiling was written alongside: bounded by
# the query is one rule over the code and the specs, and each half carries the
# reason that fits it. It had one reason before — the corpus grows forever —
# which is a reason about specs, and the rule got scoped back to the spec grep
# accordingly, leaving the code read exempt. Two halves, two reasons, or it
# happens again.
#
# What no assertion here does is check the wording of any site beyond its
# anchor. The prose is the author's; the structure is the test's.
#
# Exit code is the build's.

cd "$(dirname "$0")/.." || exit 1

S=skills/survey/SKILL.md
T=skills/technical-design/SKILL.md
I=skills/initiate/SKILL.md
G=skills/integrate/SKILL.md
R=README.md
FAIL=0

for f in "$S" "$T" "$I" "$G" "$R"; do
  if [ ! -f "$f" ]; then
    echo "FAIL subject: $f does not exist"
    exit 1
  fi
done

# Matched against each subject flattened to one line, because every anchor below
# is a sentence fragment and a sentence rewraps. Anchored on a line, a reflow
# that landed its break mid-phrase would fail a file that had lost nothing — the
# assertion would be reporting the wrap width rather than the content.
flatten() { tr '\n' ' ' | tr -s ' '; }

# want <label> <file> <phrase> <expectation>
want() {
  if ! flatten < "$2" | grep -qF "$3"; then
    echo "FAIL [$1] $2"
    echo "      expected: $4"
    FAIL=1
  fi
}

# --- 1. The number, at all four sites. Each anchored on the phrase that carries
#        that site's own job: Survey mandates it, technical-design describes the
#        composition, initiate prices a wasted Survey with it, README admits
#        nothing checks it.
want ceiling "$S" 'Five for the whole of Survey' \
  'the ceiling, mandated: five for the whole of Survey'
want mirror "$T" 'ceiling of five' \
  'the composition description quotes the ceiling of five'
want mirror "$I" 'at most five discarded subagent reads' \
  'the accepted cost priced at five discarded subagent reads'
want mirror "$R" 'five-dispatch ceiling' \
  "the five-dispatch ceiling named under README's not-bounded list"

# --- 2. The split, inside the blockquote that mandates it, and it must add up.
#        Ranged on the fan-out heading rather than the whole file so a number
#        quoted in running prose elsewhere cannot satisfy it.
SECTION=$(awk '
  /^## Fan out/ { on = 1; next }
  on && (/^# / || /^## /) { exit }
  on
' "$S")

if [ -z "$SECTION" ]; then
  echo "FAIL subject: $S carries no '## Fan out' section to read"
  exit 1
fi

QUOTE=$(printf '%s\n' "$SECTION" | grep '^> ' | flatten)

for pair in \
  'At most four researchers on the first pass|the first-pass half of the split' \
  'at most one further dispatch|the chase half of the split, which is what caps it at one' \
  'Five for the whole of Survey|the whole-stage total the two halves add up to'
do
  phrase=${pair%%|*}
  expect=${pair#*|}
  if ! printf '%s\n' "$QUOTE" | grep -qF "$phrase"; then
    echo "FAIL [split] $S's fan-out blockquote has lost $expect"
    echo "      expected in a '> ' line under ## Fan out: $phrase"
    FAIL=1
  fi
done

# --- 3. The cheaper-tier rule at both stages that fan out, each naming the tier
#        by its property and each excluding Haiku. Neither file is the other's
#        source of truth, which is the point.
for f in "$S" "$G"; do
  want tier "$f" 'cheapest tier that reliably' \
    'the tier named by the property it must have, not by a model name'
  want tier "$f" 'Haiku is excluded by decision' \
    'the exclusion, stated as a decision rather than left to a reader'
done

# --- 4. The no-sweep rule, one reason per half.
want no-sweep "$S" 'The specs, because the corpus accumulates' \
  'the specs half of bounded-by-query, with the reason that fits specs'
want no-sweep "$S" 'The code, because every read costs now' \
  'the code half of bounded-by-query, with the reason that fits code'

if [ "$FAIL" -eq 0 ]; then
  echo "survey-ceiling: one number at four sites, a split that adds up, a tier rule at both fan-outs — clean"
fi
exit "$FAIL"
