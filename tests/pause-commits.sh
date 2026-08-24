#!/bin/sh
# dev-path — five assertions on the pause commit: that Build mandates it, that it
# claims nothing about the slice working at either site that ties committing to
# deploying, that it stops short of a push and README's hook block still denies
# that push, that none of the six retired forms of the old rule has come back,
# and that the two checks this fix was not allowed to touch are still intact.
#
# The reason this file exists is that the rule it replaces was stated six times
# in five passages, twice within a single sentence in two of them. "A pause
# commits nothing" is the kind of line a reader restores from memory while
# editing something adjacent, and any one of the six restores the whole rule:
# each reads as a complete instruction on its own, and a run following any one of
# them discards the work the pause is holding. Assertion 4 is therefore the point
# of the file and the other three are what it is protecting.
#
# The defect was measured. `Jonah-Stephans/salesforce-navigator@5998b02` is a
# pause that held a linter, a lockfile and a real correctness fix to a CSS custom
# property that did not exist. Under the old rule that commit was a deviation
# from this skill; the alternative was leaving four files uncommitted on a branch
# carrying a draft pull request, one `git checkout` from gone.
#
# Assertion 5 is the guard on the blast radius rather than on the change. This
# fix works precisely because no check anywhere reads git: the frozen test joins
# the absence of `done` to a section heading, and the critic dispatch turns on
# what the worker wrote. Both had to survive untouched, so both are pinned here —
# the second one negatively as well, because the clause that had to lose "no
# commit" still has to keep "no critic, no walk".
#
# Subject is skills/build/SKILL.md, which owns the rule, plus README.md for the
# hook block alone. No other file states it, then or now, so a wider ban would be
# asserting other files' silence about something they never said.
#
# Exit code is the build's.

cd "$(dirname "$0")/.." || exit 1

B=skills/build/SKILL.md
R=README.md
FAIL=0

for f in "$B" "$R"; do
  if [ ! -f "$f" ]; then
    echo "FAIL subject: $f does not exist"
    exit 1
  fi
done

# Every anchor below is a sentence fragment, and a sentence rewraps. Matched
# against the file flattened to one line so the assertion is about the prose
# rather than the wrap width — the same reason tests/green-instances.sh gives.
flatten() { tr '\n' ' ' | tr -s ' '; }

BUILD=$(flatten < "$B")

# --- 1. Build mandates the commit, in both halves of the rule. The two halves
#        fail independently and mean different things: the first is the count a
#        reader takes away, the second is the act a run performs on a return that
#        paused. A file keeping only the first states an arithmetic nobody
#        executes; keeping only the second leaves the count contradicting it.
if ! printf '%s' "$BUILD" | grep -qF 'plus one for a pause'; then
  echo "FAIL [count] $B does not count the pause commit"
  echo '      expected the commit count to read: one code commit per slice, plus one for a pause'
  FAIL=1
fi

if ! printf '%s' "$BUILD" | grep -qF 'you commit on that return as well'; then
  echo "FAIL [act] $B does not say when the pause commit happens, or who does it"
  echo '      expected: a pause returns too, and you commit on that return as well'
  echo '      the actor is the orchestrator — a worker commits nothing, paused or not'
  FAIL=1
fi

# --- 2. The commit claims nothing. This is the sentence the change had to add
#        rather than merely edit: before it, the skill tied committing to
#        deploying, so permitting the commit without this would make every pause
#        commit read as a working slice.
if ! printf '%s' "$BUILD" | grep -qF 'not a claim that the slice works'; then
  echo "FAIL [claim] $B does not disclaim the pause commit"
  echo '      expected: a pause commit is not a claim that the slice works'
  FAIL=1
fi

DEPLOY=$(awk '
  /^## Deploy, then tick/ { on = 1; next }
  on && (/^# / || /^## /) { exit }
  on
' "$B" | flatten)

if [ -z "$DEPLOY" ]; then
  echo "FAIL subject: $B carries no '## Deploy, then tick' section to read"
  exit 1
fi

if ! printf '%s' "$DEPLOY" | grep -qF 'The claim is the field, not the commit'; then
  echo "FAIL [claim] $B does not disclaim it where deploying is tied to committing"
  echo '      expected, under ## Deploy, then tick: The claim is the field, not the commit'
  FAIL=1
fi

# --- 3. It stops short of a push, and the hook block that denies that push is
#        still in README. Held as one assertion because they are one rule in two
#        files: the skill instructs a run, the block is what a repo installs when
#        it wants the instruction enforced rather than followed. Either alone
#        going quiet is the pair disagreeing, and the disagreement would surface
#        as a denied push in the middle of somebody's build.
if ! printf '%s' "$BUILD" | grep -qF 'A pause commits and stops there'; then
  echo "FAIL [push] $B does not say a pause stops short of the push"
  echo '      expected: **A pause commits and stops there: no push.**'
  FAIL=1
fi

if ! flatten < "$R" | grep -qF 'Nothing pushes while a slice is stopped'; then
  echo "FAIL [push] $R has lost the hook block that denies the push during a pause"
  echo '      expected README item 1 to still read: Nothing pushes while a slice is stopped'
  FAIL=1
fi

# --- 4. None of the six retired forms is back. Named one per line rather than
#        matched by a pattern over the idea, because the message has to say which
#        one returned: they sit in four different sections and each was written
#        for a different reason, so the fix for each is local to it.
#
#        Two of them are sub-clauses of a sentence whose main clause survives the
#        change intact — "an open box means no commit" and "already means no
#        commit" — which is exactly how an edit to the bold claim above them
#        leaves the rule standing three words later.
#        One of the six doubles up with assertion 1 — "none for a pause" is the
#        exact negation of "plus one for a pause" in the same sentence, so
#        reverting that sentence prints two blocks for one edit. Kept anyway: the
#        list's claim is that all six are gone, and five would not be that claim.
RETIRED='none for a pause
an open box means no commit
A pause commits nothing
no commit, no critic
already means no commit
Nothing is committed before it deploys'

HITS=$(
  printf '%s\n' "$RETIRED" | while IFS= read -r form; do
    [ -n "$form" ] || continue
    printf '%s' "$BUILD" | grep -qF "$form" && printf '%s\n' "$form"
  done
)

if [ -n "$HITS" ]; then
  echo "FAIL [retired] $B has restored a retired form of the rule"
  echo '      a pause commits; it is the absence of `done: true` that says frozen'
  printf '%s\n' "$HITS" | sed 's/^/      found: /'
  FAIL=1
fi

# --- 5. What the change was not allowed to touch. The frozen test is pinned in
#        both halves, because a fix that permitted the commit and then read it
#        would have made the commit a sixth state; and the dispatch condition is
#        pinned positively, because the clause that had to lose "no commit" is
#        the same clause that still has to deny the critic and the walk.
if ! printf '%s' "$BUILD" | grep -qF 'no `done: true` plus an open box under `## Deviations` = frozen, needs you'; then
  echo "FAIL [frozen] $B has lost the frozen half of the pause test"
  FAIL=1
fi

if ! printf '%s' "$BUILD" | grep -qF 'no `done: true` and no open box there = not started'; then
  echo "FAIL [frozen] $B has lost the not-started half of the pause test"
  FAIL=1
fi

DISPATCH=$(awk '
  /^## Dispatch a critic/ { on = 1; next }
  on && (/^# / || /^## /) { exit }
  on
' "$B" | flatten)

if [ -z "$DISPATCH" ]; then
  echo "FAIL subject: $B carries no '## Dispatch a critic' section to read"
  exit 1
fi

if ! printf '%s' "$DISPATCH" | grep -qF 'no critic, no walk'; then
  echo "FAIL [dispatch] $B no longer says a pause dispatches no critic and moves no walk"
  echo '      expected, under ## Dispatch a critic: a pause stops the whole run: no critic, no walk'
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "pause-commits: a pause commits, claims nothing, pushes nothing — clean"
fi
exit "$FAIL"
