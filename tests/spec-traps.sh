#!/bin/sh
# dev-path — seven assertions on `## Traps`: that the section is in the schema at
# all three of README's sites and in neither slice schema, that Critique writes
# it on a trigger an agent can check, that both readers reach it by heading name
# rather than by file, that an entry is a plain bullet, that the grammar keeps an
# entry alive across a re-cut, that its load is bounded on the page, and that
# Integrate carries it to the reviewer.
#
# The reason this file exists is that the thing being fixed is a route, and a
# route has no artifact. What #39 observed was a generalisation over two slices —
# *the fixtures in this repo are uniform in a way that lets a passing test prove
# nothing* — reaching slice 06 through the orchestrator's conversation, which is
# the one carrier `skills/build/SKILL.md`'s dispatch contract forbids. `## Traps`
# moves that carriage to disk. Nothing downstream can observe whether it worked:
# a spec with no traps and a spec whose traps nobody read are the same seven
# green slices, and the failure shows up as a defect three slices later that
# looks like an ordinary miss. The instructions being on the page is the whole of
# what is enforceable, which is the bound tests/survey-ceiling.sh and
# tests/ux-branch-new-surface.sh both state about their own subjects.
#
# Assertion 1 is the only half of this change that any machine reads. Hook block
# 4 warns on a heading outside the schema, so a plugin that documents `## Traps`
# in prose and leaves it out of that `P=` list ships a section whose every write
# trips the repo's own hook — the section would be born non-compliant, and the
# fix would look like deleting it. The slice half of the same line is pinned
# unchanged in the same assertion, because `## Traps` is a spec-level section:
# permitted on a slice file it becomes a per-slice note, which is the thing that
# already exists and is called `## Critique findings`.
#
# Assertion 3 is the one the issue predicted would fail, and it is scoped to the
# two halves that have to carry it rather than to the files. *Read the spec file*
# is already mandated and is not the fix: a worker reading `spec.md` for Intent,
# Outcomes and Design passes over a heading it was never sent to, silently and
# indistinguishably from a spec that had no traps. This repo has shipped that
# exact shape once — tests/compositions.sh records Build reaching Critique being
# described and never called. So the anchor is the heading in an imperative, read
# off the worker prompt and off the slice pass separately: a mandate in Build's
# orchestrator half satisfies neither, and the orchestrator is not who reads.
#
# Assertion 4 is a guard on the blast radius rather than on the rule. Every
# `- [ ]` anywhere in a spec directory is *Critique clean*'s subject and
# Integrate's refusal, so a trap written as an open box is a spec that can never
# merge and a section that gets deleted rather than debugged. A checked box is no
# better: every checked box carries a disposition tag as its first word, and a
# trap has no disposition — nothing closes it, because nothing about it is open.
# The scan reads the lines under a `## Traps` heading in every prose file, so the
# shape is pinned wherever the plugin shows one.
#
# Assertion 5 pins the sentence that makes the two withdrawal tables true.
# `skills/initiate/SKILL.md` and `skills/technical-design/SKILL.md` both say
# everything else survives, and a re-cut renumbers the slices under it — so an
# entry naming a slice survives into a spec where it points at nothing. The
# grammar rule is what makes survival correct rather than merely stated, which is
# why it is pinned beside the two table rows it is holding up.
#
# What no assertion here does is check that an entry is any good, or that a run
# wrote one when the trigger fired. The trigger is checkable by the agent holding
# the finding and by nobody afterwards: a finding whose test was green is a fact
# about the moment it was confirmed, and the slice file does not keep it.
#
# Exit code is the build's.

cd "$(dirname "$0")/.." || exit 1

R=README.md
B=skills/build/SKILL.md
C=skills/critique/SKILL.md
I=skills/integrate/SKILL.md
N=skills/initiate/SKILL.md
D=skills/technical-design/SKILL.md
FAIL=0

for f in "$R" "$B" "$C" "$I" "$N" "$D"; do
  if [ ! -f "$f" ]; then
    echo "FAIL subject: $f does not exist"
    exit 1
  fi
done

# Anchors are sentence fragments and a sentence rewraps, so every prose anchor is
# matched against its section flattened to one line. Same reason
# tests/green-instances.sh gives for its own flatten.
flatten() { tr '\n' ' ' | tr -s ' '; }

# Every section here shows the schema it writes, so `## ` at line start appears
# inside fenced examples as content rather than as structure. A range walk that
# does not track the fence stops at the first worked example and reads none of
# the prose under it. section <file> <start> <stop>
section() {
  awk -v start="$2" -v stop="$3" '
    /^```/ { fence = !fence; next }
    !fence && $0 ~ start { on = 1; next }
    on && !fence && $0 ~ stop { exit }
    on
  ' "$1"
}

# want <label> <haystack-name> <text> <phrase> <expectation>
want() {
  if ! printf '%s' "$3" | grep -qF "$4"; then
    echo "FAIL [$1] $2"
    echo "      expected: $5"
    FAIL=1
  fi
}

# --- 1. The schema, at all three of README's sites, and absent from the slice
#        half of the one that fires. The three fail independently and only the
#        third is mechanical: the skeleton is what a human copies, the table is
#        what names the writer and the readers, and the hook is what warns.
HOOK=$(grep -F 'dev-path/*/spec.md) P=' "$R")

if [ -z "$HOOK" ]; then
  echo "FAIL [schema] $R carries no hook block 4 heading list to read"
  FAIL=1
else
  want schema "$R's hook block 4, spec.md list" "$HOOK" 'Design|Traps|Outcome checks' \
    'Traps between Design and Outcome checks, so a write of the section does not trip the repo hook'
  want schema "$R's hook block 4, slices list" "$HOOK" \
    'P=\"What to build|Acceptance criteria|Deviations|Critique findings\"' \
    'the slice list unchanged — Traps is a spec-level section and a per-slice one already exists'
fi

# The skeleton, scoped to the spec.md subsection so a heading in the slice
# skeleton below it cannot satisfy this. Ranged on the two `### ` headings rather
# than on line numbers, so the span survives the section growing.
SKELETON=$(section "$R" '^### .dev-path/<slug>/spec.md.' '^### ')

if ! printf '%s\n' "$SKELETON" | grep -qx '## Traps'; then
  echo "FAIL [schema] $R's spec.md skeleton carries no ## Traps line"
  echo '      expected a line of its own reading: ## Traps'
  FAIL=1
fi

if ! printf '%s\n' "$SKELETON" | grep -qF '| `## Traps` |'; then
  echo "FAIL [schema] $R's heading table has no ## Traps row"
  echo '      expected a row naming who writes it and who reads it'
  FAIL=1
fi

# --- 2. One writer, on a trigger an agent can check. Both halves, because they
#        fail in opposite directions: the pass table is where a reader learns the
#        slice pass writes on spec.md at all, and the trigger is what stops
#        *when you learn something* — the shape #36 is already open on — being
#        the condition. The trigger phrase is anchored past the word `passed`,
#        because a fixture that fails while the code is wrong is the ordinary
#        case and writing a trap about it is the section filling with noise.
CFLAT=$(flatten < "$C")

want writer "$C's pass table" "$(grep -F '| **The slice pass** |' "$C")" '## Traps' \
  'the slice pass row naming ## Traps beside ## Critique findings, since it writes both'
want writer "$C" "$CFLAT" 'a test that passed while the code was wrong' \
  'the trigger stated as a fact about a confirmed finding, checkable by the pass holding it'
want writer "$C" "$CFLAT" 'must be able to fail on' \
  'the entry grammar as a positive target — the mutation to go and write, not a habit to avoid'

# --- 3. Both readers, by heading name, each read off the half that has to carry
#        it. Scoped because the orchestrator half of $B is where the clarifying
#        clause lives and it is not a reader: a worker prompt that never names
#        the heading sends a fresh agent to a file it was already reading.
WORKER=$(awk '/^# The worker prompt/ { on = 1 } on' "$B" | flatten)
SLICEPASS=$(section "$C" '^## The slice pass' '^## ' | flatten)

if [ -z "$WORKER" ]; then
  echo "FAIL [readers] $B carries no '# The worker prompt' half to read"
  FAIL=1
else
  want readers "$B's worker prompt" "$WORKER" 'read `## Traps` on `spec.md`' \
    'the worker sent to the heading by name, not to the file it already reads'
fi

if [ -z "$SLICEPASS" ]; then
  echo "FAIL [readers] $C carries no '## The slice pass' section to read"
  FAIL=1
else
  want readers "$C's slice pass" "$SLICEPASS" 'read `## Traps` on `spec.md`' \
    'the critic sent to the heading by name, so a test that cannot fail on an entry is visible'
fi

# --- 4. An entry is a plain bullet. Read off every prose file, wherever one
#        shows a `## Traps` heading with lines under it — the worked example is
#        what a run copies, so its shape is the rule in the form that gets used.
PROSE=$(ls skills/*/SKILL.md README.md 2>/dev/null)

BOXED=$(awk '
  /^## Traps$/ { blk = 1; next }
  blk {
    if ($0 ~ /^- \[/) { print FILENAME ":" FNR ": " $0; next }
    if ($0 !~ /^- / && $0 !~ /^[[:space:]]+[^[:space:]]/) { blk = 0 }
  }
' $PROSE)

if [ -n "$BOXED" ]; then
  echo 'FAIL [no box] a trap entry is written as a checkbox'
  echo '      every - [ ] in a spec directory is Integrate refusing; a trap has nothing to close'
  printf '%s\n' "$BOXED" | sed 's/^/      /'
  FAIL=1
fi

EXAMPLE=$(awk '
  /^## Traps$/ { blk = 1; next }
  blk && /^- / { print; exit }
  blk { blk = 0 }
' "$C")

if [ -z "$EXAMPLE" ]; then
  echo "FAIL [no box] $C shows no worked entry under a ## Traps heading"
  echo '      expected a plain bullet under the heading, as the shape a run copies'
  FAIL=1
fi

# --- 5. The entry outlives the slice numbering, and the two withdrawal tables
#        say so. The grammar rule is what makes the tables true: both already
#        promise everything else survives, and a re-cut renumbers the slices
#        underneath that promise.
want survives "$C" "$CFLAT" 'never names a slice' \
  'the grammar rule that keeps an entry meaningful after a re-cut renumbers the slices'
want survives "$N's withdrawal table" "$(grep -F '| `intent_accepted`' "$N")" '## Traps' \
  'Traps named in the survives-untouched column, beside the two sections it sits with'
want survives "$D's withdrawal table" "$(grep -F '| `design_approved` only |' "$D")" '## Traps' \
  'Traps named in the survives-untouched column, beside the two sections it sits with'

# --- 6. The load is bounded on the page, in both of the forms the argument
#        takes. Every entry loads into every later worker and every later critic,
#        which is the multiplier skills/learn/SKILL.md already argues about
#        unscoped rules — so the two bounds are the section's price of admission
#        and not a footnote to it.
want bounded "$C" "$CFLAT" 'dies with the spec' \
  'the per-spec bound: the section does not outlive the branch it was written on'
want bounded "$C" "$CFLAT" 'restates a default' \
  'the per-entry bound: an entry changing nothing still pays the per-worker cost'

# --- 7. Integrate carries it, in the step list and in the step itself. Both,
#        because the numbered list is what a run follows and the section is what
#        a builder wiring the step reads.
want carried "$I's step list" "$(grep -F '4. Carry' "$I")" '## Traps' \
  'step 4 naming Traps beside the two sections it already carries'

STEP4=$(section "$I" '^## 4 · ' '^## ' | flatten)

if [ -z "$STEP4" ]; then
  echo "FAIL [carried] $I carries no step 4 section to read"
  FAIL=1
else
  want carried "$I's step 4" "$STEP4" '## Traps' \
    'the step saying what a trap gives the reviewer, so the carry is not a bare list entry'
fi

if [ "$FAIL" -eq 0 ]; then
  echo "spec-traps: the section is in the schema, Critique writes it on a checkable trigger, both readers are sent to the heading — clean"
fi
exit "$FAIL"
