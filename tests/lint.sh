#!/bin/sh
# devpath — repo-wide rules that hold no matter which file is edited next.
#
# Four checks, all of them rules rather than paragraphs: the retired vocabulary,
# the skill-to-skill call strings, the closed set of gate fields, and the
# commit-excess tag staying unread by anything mechanical. What this file does
# not do is assert that a given sentence is still on a given page — a deleted
# paragraph shows up in the diff, which is where it gets caught.
#
# Exit code is the build's.

cd "$(dirname "$0")/.." || exit 1

FAIL=0

# POSIX ERE has no \b. These bracket a word with a non-word character or an
# anchor, which is portable where \b and [[:<:]] are not.
L='(^|[^[:alnum:]_])'
R='([^[:alnum:]_]|$)'

# Every file carrying prose of devpath's authoring. Nothing under tests/ is a
# subject: this file names every retired word as a literal.
PROSE=$(ls skills/*/SKILL.md README.md scripts/contention.sh 2>/dev/null)
PN=$(printf '%s\n' "$PROSE" | grep -c .)

# A floor, not a census — it catches a glob that collapsed, and stays quiet when
# a skill is added. A count pinned to the exact number turns every new skill red.
if [ "$PN" -lt 10 ]; then
  echo "FAIL subject: expected at least 10 prose files, found $PN"
  printf '%s\n' "$PROSE" | sed 's/^/      /'
  exit 1
fi

report() {  # report <rule> <file> <hits>
  [ -z "$3" ] && return 0
  echo "FAIL [$1] $2"
  printf '%s\n' "$3" | sed 's/^/      /'
  FAIL=1
}

# ---------------------------------------------------------------- 1. vocabulary
#
# Ten rules over the prose files. Several retirements are scoped, and the
# scoped-out forms are mandated literals — ## Design, design_approved, the stage
# name Design, "Build records" under ## Deviations. A flat "this word does not
# appear" would fail against a compliant plugin, and a test that cannot pass gets
# deleted, which puts the list back to a wish.
#
# An allowlist is part of its rule rather than a convention around it, so adding
# to one is an edit visible in a diff.
for f in $PROSE; do
  [ -f "$f" ] || continue

  # enhancement — banned everywhere, any case. No permitted form.
  report enhancement "$f" "$(grep -niE 'enhancement' "$f")"

  # pipeline — banned everywhere, any case. Reads as CI to every engineer, and
  # an existing plugin already owns it.
  report pipeline "$f" "$(grep -niE 'pipeline' "$f")"

  # unit of work — banned everywhere. No permitted form.
  report 'unit of work' "$f" "$(grep -niE 'unit of work' "$f")"

  # unit — whole word, minus a named allowlist. The naive form fails on
  # "npm run test:unit", which fit-check looks for by name, and on "unit test",
  # which an Apex repo cannot avoid. Permitted compounds are stripped first so a
  # mixed line is still caught.
  report unit "$f" "$(
    sed -e 's/[Uu]nit tests*//g' -e 's/test:unit//g' -e 's/[Uu]nit price/PRICE/g' "$f" \
      | grep -niE "${L}unit${R}"
  )"

  # task — whole word, minus the one harness string this plugin ships: the hook
  # matcher Task|Agent in README item 5. Collides with the harness's Task tool.
  report task "$f" "$(
    sed -e 's/Task|Agent/MATCHER/g' "$f" | grep -niE "${L}task${R}"
  )"

  # record — whole word, which is the singular noun and the imperative, leaving
  # records, recorded and recording untouched so the mandated "Build records"
  # passes. The allowlist is four named phrases, each mandated elsewhere here.
  report record "$f" "$(
    sed -e 's/record what you dispatched/DISPATCHED/g' \
        -e 's/record a deviation/DEVIATION/g' \
        -e 's/record that a human said yes/CONSENT/g' \
        -e 's/on the item record/ITEM/g' "$f" \
      | grep -niE "${L}record${R}"
  )"

  # program — banned as a LEVEL in the work hierarchy: a directory, a field, a
  # slug prefix, a grouping key. Ordinary English for a body of work is
  # permitted, and so is program-agnostic. A ban on a position asserts positions.
  report 'program-as-level' "$f" "$(
    sed -e 's/program-agnostic/AGNOSTIC/g' "$f" \
      | grep -niE "(^[[:space:]]*programs?:|programs?/|devpath/programs?|program[_-]prefix|group(ing)? key.*program|program.*group(ing)? key)"
  )"

  # design — banned as a BARE SKILL NAME. In this ecosystem "design" means
  # visual design. Permitted: the stage name Design, the heading ## Design, the
  # field design_approved, and devpath:technical-design.
  report 'design-as-skill-name' "$f" "$(
    grep -nE "(devpath:design([^a-zA-Z0-9_-]|$)|skills/design/)" "$f"
  )"

  # Research — banned as a stage name, a heading or a field. Ordinary English,
  # lower case, is permitted; Survey is the stage name.
  report Research "$f" "$(
    grep -nE "(^##+[[:space:]]+Research|^[[:space:]]*research:|devpath:research|${L}Research${R})" "$f"
  )"

  # Review — same scope, same reason. Ordinary English, lower case, is
  # permitted: "one per review pass", "pull-request review". Critique is the
  # stage name.
  report Review "$f" "$(
    grep -nE "(^##+[[:space:]]+Review|^[[:space:]]*review:|devpath:review|${L}Review${R})" "$f"
  )"
done

# --------------------------------------------------------------- 2. compositions
#
# The four skill-to-skill calls, asserted as imperatives naming the skill. These
# strings are a functional contract: the namespace in them is the plugin's own
# name, so a half-rename lands here.
#
# The reason this check exists is a shipped failure. Three of the four
# compositions were imperatives and were followed; the fourth, devpath:build
# reaching devpath:critique, was described and never called, and the first real
# spec built seven slices with no critic having read any of them. Nothing noticed,
# because the only thing asserting a composition existed was the prose that
# failed to hold one.
#
# Invocation is model-driven and stays model-driven — this asserts the instruction
# is present, never that a session followed it.
COMPOSITIONS='skills/technical-design/SKILL.md:survey
skills/technical-design/SKILL.md:slice
skills/build/SKILL.md:critique
skills/integrate/SKILL.md:learn'

for c in $COMPOSITIONS; do
  f=${c%:*}
  skill=${c##*:}
  if [ ! -f "$f" ]; then
    report "$skill" "$f" "file does not exist"
    continue
  fi
  # The imperative in either voice: "run the skill" mid-sentence, "Run the
  # skill" opening one. Anything softer than a verb is not a call.
  if ! grep -qE "[Rr]un the skill \`devpath:$skill\`" "$f"; then
    report "$skill" "$f" "holds no imperative naming devpath:$skill
expected a line matching: [Rr]un the skill \`devpath:$skill\`"
  fi
done

# Every call site carries the softness callout, so per file the two counts match.
# The imperative alone can ship without the callout that tells a reader, at the
# place they act on it, that the call is not guaranteed.
for f in skills/technical-design/SKILL.md skills/build/SKILL.md skills/integrate/SKILL.md; do
  [ -f "$f" ] || continue
  CALLS=$(grep -cE '[Rr]un the skill `devpath:' "$f")
  SOFT=$(grep -c 'model-driven and is not guaranteed' "$f")
  if [ "$CALLS" -ne "$SOFT" ]; then
    report callout "$f" "$CALLS call site(s), $SOFT softness callout(s)"
  fi
done

# --------------------------------------------------------------- 3. gate fields
#
# Two gates exist and the design turns on there being two. A third field named
# anywhere under skills/ or in README is a gate somebody added in prose.
FIELDS=$(grep -rhoE '[a-z_]+_(approved|accepted)' skills/ README.md 2>/dev/null \
  | sort -u | grep -vxE 'design_approved|intent_accepted')
if [ -n "$FIELDS" ]; then
  report 'gate fields' 'skills/ and README.md' "a gate field beyond the two that exist:
$FIELDS"
fi

# ----------------------------------------------------- 4. the excess tag is prose
#
# `- [ ] excess` is the same open box with its shortfall named, exactly as
# `- [ ] unmet` is, so every existing check matches it and no new check exists.
# The moment something mechanical reads the tag word, the tag has become a sixth
# state and the frozen test has two answers.
#
# Two subjects. The executable files, minus this one — README's fenced json and
# sh blocks are shipped code a repo pastes, so they count as mechanical, and the
# scan of them names the tools those blocks actually run on.
CODE=$(ls scripts/*.sh .github/workflows/ci.yml tests/*.sh 2>/dev/null | grep -vx 'tests/lint.sh')
MECH=$(
  awk '
    /^```(json|sh|bash)$/ { fence = 1; next }
    /^```$/               { fence = 0; next }
    fence && /excess([^a-z]|$)/ && /grep|awk|sed|jq|case|rg|"command"/ { print FILENAME ": " $0 }
  ' README.md
  [ -n "$CODE" ] && grep -nE 'excess([^a-z]|$)' $CODE | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#'
)
if [ -n "$MECH" ]; then
  report 'no new state' 'the excess tag' "something mechanical reads the tag word:
$MECH"
fi

# --------------------------------------------- 5. an Outcome is never numbered
#
# `devpath:integrate` states it where it prints an unmet Outcome: a positional
# index is a convention nothing in `devpath` defines, and #69 owns the question
# of what would. This scans devpath's own prose rather than a spec on disk, so
# what it catches is an illustration teaching the convention by example — which
# is how the last one survived a rule that already forbade it.
#
# Stable under #69. An ID line reads `- O2 — <statement>` and a reference reads
# `O2`, neither of which is the word Outcome followed by a digit, so the ban on
# positions outlives the arrival of handles.
for f in $PROSE; do
  [ -f "$f" ] || continue
  report 'never numbered' "$f" "$(grep -nE "${L}Outcome[[:space:]]+[0-9]" "$f")"
done

if [ "$FAIL" -eq 0 ]; then
  echo "lint: vocabulary over $PN prose files, four compositions, two gate fields, one unread tag, no numbered Outcome — clean"
fi
exit "$FAIL"
