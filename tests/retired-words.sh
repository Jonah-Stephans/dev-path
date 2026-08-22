#!/bin/sh
# dev-path — one assertion per retired word, each asserting that word's own scope
# rather than the bare string. Several retirements are scoped, and the scoped-out
# forms are mandated literals: ## Design, design_approved, the stage name Design,
# and "Build records" under ## Deviations. A flat "this word does not appear"
# would fail on the plugin's own required text, and a test that cannot pass
# against a compliant plugin gets deleted — which puts the list back to a wish.
#
# Subject: the ten SKILL.md bodies, README.md and scripts/contention.sh — twelve
# of the eighteen files, and every file that carries prose. The six exclusions
# are deliberate: neither test under tests/ is a subject — this one carries every
# retired word as a literal, and compositions.sh carries the call strings it
# asserts — and ci.yml, the two manifests and LICENSE carry no prose of
# dev-path's authoring.
#
# Ten assertions, not seven: "unit of work", "unit" and "task" share a row on the
# retired list and do not share a scope, and neither do "Research" and "Review".
# Three absolute bans, three whole-word bans minus a named allowlist, and four
# bans on a position. A retirement is a ban on a job the word must not do.
#
# An allowlist is part of an assertion rather than a convention around it, so
# adding to one is an edit visible in a diff. Exit code is the build's.

cd "$(dirname "$0")/.." || exit 1

# POSIX ERE has no \b. These bracket the word with a non-word character or an
# anchor, which is portable where \b and [[:<:]] are not.
L='(^|[^[:alnum:]_])'
R='([^[:alnum:]_]|$)'

FAIL=0

FILES=$(ls skills/*/SKILL.md README.md scripts/contention.sh 2>/dev/null)
COUNT=$(printf '%s\n' "$FILES" | grep -c .)
if [ "$COUNT" -ne 12 ]; then
  echo "FAIL subject: expected 12 prose files, found $COUNT"
  printf '%s\n' "$FILES" | sed 's/^/      /'
  FAIL=1
fi

# report <word> <file> <hits>
report() {
  [ -z "$3" ] && return 0
  echo "FAIL [$1] $2"
  printf '%s\n' "$3" | sed 's/^/      /'
  FAIL=1
}

for f in $FILES; do
  [ -f "$f" ] || continue

  # --- 1. enhancement — banned everywhere, any case. No permitted form.
  report enhancement "$f" "$(grep -niE 'enhancement' "$f")"

  # --- 2. pipeline — banned everywhere, any case. Reads as CI to every
  #        engineer, and an existing plugin already owns it.
  report pipeline "$f" "$(grep -niE 'pipeline' "$f")"

  # --- 3. unit of work — banned everywhere. No permitted form.
  report 'unit of work' "$f" "$(grep -niE 'unit of work' "$f")"

  # --- 4. unit — whole word, minus a named allowlist. The naive form fails on
  #        "npm run test:unit", which fit-check looks for by name, and on
  #        "unit test", which an Apex repo cannot avoid. The permitted compounds
  #        are stripped first so a mixed line is still caught.
  #        Allowlist: unit test, unit tests, test:unit, unit price.
  report unit "$f" "$(
    sed -e 's/[Uu]nit tests*//g' -e 's/test:unit//g' -e 's/[Uu]nit price/PRICE/g' "$f" \
      | grep -niE "${L}unit${R}"
  )"

  # --- 5. task — whole word, minus a named allowlist. "task" collides with the
  #        harness's own Task tool. Counted from the plugin's own files: the one
  #        harness string it ships is the hook matcher Task|Agent in README item
  #        5. "Quoted vendor text" was a permission here and is withdrawn —
  #        nothing can decide what is a quotation of somebody else's docs.
  report task "$f" "$(
    sed -e 's/Task|Agent/MATCHER/g' "$f" | grep -niE "${L}task${R}"
  )"

  # --- 6. record — whole word, which is the singular noun and the imperative,
  #        and leaves records, recorded and recording untouched, so the mandated
  #        Deviations instruction "Build records" passes. "A Salesforce database
  #        row, where that is genuinely what is meant" was a permission here and
  #        is withdrawn: it has no mechanical form.
  #
  #        The allowlist is four named phrases rather than the bare word, and
  #        each is mandated elsewhere in this plugin:
  #          "record what you dispatched"      -> skills/survey/SKILL.md
  #          "record a deviation"              -> skills/build/SKILL.md
  #          "record that a human said yes"    -> README.md item 7, verbatim
  #          "on the item record"              -> skills/slice/SKILL.md, a
  #                                               worked example shipped as given
  #        The bare word stays banned everywhere else.
  report record "$f" "$(
    sed -e 's/record what you dispatched/DISPATCHED/g' \
        -e 's/record a deviation/DEVIATION/g' \
        -e 's/record that a human said yes/CONSENT/g' \
        -e 's/on the item record/ITEM/g' "$f" \
      | grep -niE "${L}record${R}"
  )"

  # --- 7. program — banned as a LEVEL in the work hierarchy: a directory, a
  #        field, a slug prefix, a grouping key. Ordinary English for a body of
  #        work is permitted, and so is the compound program-agnostic. This is a
  #        ban on a position, so it asserts the positions.
  report 'program-as-level' "$f" "$(
    sed -e 's/program-agnostic/AGNOSTIC/g' "$f" \
      | grep -niE "(^[[:space:]]*programs?:|programs?/|dev-path/programs?|program[_-]prefix|group(ing)? key.*program|program.*group(ing)? key)"
  )"

  # --- 8. design — banned as a BARE SKILL NAME. In this ecosystem "design"
  #        means visual design. Permitted: the stage name Design, the heading
  #        ## Design, the field design_approved, and dev-path:technical-design.
  report 'design-as-skill-name' "$f" "$(
    grep -nE "(dev-path:design([^a-zA-Z0-9_-]|$)|skills/design/)" "$f"
  )"

  # --- 9. Research — banned as a stage name, a heading or a field name. It
  #        collides several ways with skills that mean something else. Ordinary
  #        English, lower case, is permitted; Survey is the stage name.
  report Research "$f" "$(
    grep -nE "(^##+[[:space:]]+Research|^[[:space:]]*research:|dev-path:research|${L}Research${R})" "$f"
  )"

  # --- 10. Review — same scope, same reason. Ordinary English, lower case, is
  #         permitted: "one per review pass", "pull-request review". Critique is
  #         the stage name.
  report Review "$f" "$(
    grep -nE "(^##+[[:space:]]+Review|^[[:space:]]*review:|dev-path:review|${L}Review${R})" "$f"
  )"

done

if [ "$FAIL" -eq 0 ]; then
  echo "retired-words: ten assertions over $COUNT prose files — clean"
fi
exit "$FAIL"
