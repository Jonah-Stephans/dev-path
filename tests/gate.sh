#!/bin/sh
# devpath — the open-box gate, run rather than read.
#
# Five checks. That README still ships exactly one gate and that the whole of it
# is extracted, that the gate sweeps what the pull request touched rather than
# what the branch is called, that it is red on an open box — indented or flat —
# and green on a closed one, that it is loud rather than quiet when it cannot
# work out what to sweep, and that no copy of the pattern has been narrowed back
# to a bare ^.
#
# The gate is a scope derivation and one anchored grep, written in README's
# recommended default, in the two hook blocks a repo pastes, in Integrate's step
# 3 test 1, and in the prose that quotes the pattern. Under a bare ^ it is a
# check that passes on the thing it exists to catch. A formatter that renests a
# list indents the box, the grep finds nothing, the job goes green, and Integrate
# arms a merge on a spec holding an open box. There is no second check that would
# notice, by design.
#
# The scope half has the mirrored failure. Derived from the head ref alone, the
# gate is red on every branch with no directory of that name — a lessons branch,
# a ci/ branch, a docs fix — for a reason that has nothing to do with a box.
# Derived from the diff alone, a spec branch that edited only code is swept for
# nothing. Both halves are asserted below, each in a case the other half cannot
# carry.
#
# The grep has a third failure that is neither of those. grep -r exits 2 on a
# path that is not there and the leading ! turns that into a pass — for the whole
# run, so a box it matched and printed in a live directory goes green beside the
# missing one. git diff --name-only names files a pull request deleted, so the
# diff half can put a directory in the sweep that the tree no longer holds. The
# [ -d ] filter is what closes that, and a case below pairs a retired spec with
# an open box in a live one to hold the filter there.
#
# Two things about the fixture, both load-bearing:
#
# It is a real git repository with a real base commit, because the gate diffs.
# Running the gate against a bare directory tests the grep and nothing else.
#
# Every case runs with a neighbouring spec directory on disk holding an open box
# that the branch under test never touches. That is what makes a green case
# assert something: a gate that swept all of devpath/, or one this file only
# half-extracted, finds that box and goes red. The single-line extraction this
# file used to do degrades exactly that way — pull the grep out of a multi-line
# gate and $SPECS is unset, so grep -rn takes no path operand and recurses the
# working directory, which is the fixture. Every box case still passes and the
# suite prints clean having asserted nothing about the scope at all.
#
# The fixture boxes carry no tag word. tests/lint.sh holds that nothing
# mechanical reads a tag, and it reads this file too.
#
# Exit code is the build's.

cd "$(dirname "$0")/.." || exit 1

FAIL=0

fail() {  # fail <rule> <subject> [detail]
  echo "FAIL [$1] $2"
  [ -n "$3" ] && printf '%s\n' "$3" | sed 's/^/      /'
  FAIL=1
}

# ------------------------------------ 1. README ships one gate, extracted whole
#
# The whole fence, selected by content rather than by position: the sh or bash
# block that greps for a box. A gate moved to another fence still gets tested,
# and a gate deleted fails here rather than leaving the rest of the file testing
# nothing.
#
# Whole, because the gate is more than its grep. A fragment of it runs — that is
# the failure this extraction exists to prevent — so the awk reports how the
# extraction ended rather than only what it found.
GATE=$(awk '
  /^```(sh|bash)$/ && !f { f = 1; body = ""; has = 0; next }
  f && /^```$/           { f = 0; if (has) { n++; printf "%s", body } next }
  f                      { body = body $0 "\n"
                           if (index($0, "- \\[ \\]")) has = 1
                           next }
  END { if (f) exit 3; if (n == 0) exit 1; if (n > 1) exit 2; exit 0 }
' README.md)

case $? in
  0) ;;
  1) fail gate README.md "no fenced sh or bash block greps for a box, so there is no
recommended gate to run"; exit 1 ;;
  2) fail gate README.md "more than one fenced sh or bash block greps for a box, so which
one is the recommended gate is ambiguous"; exit 1 ;;
  3) fail gate README.md "a fenced block opened and never closed, so the extraction ran
past the gate and picked up whatever follows it"; exit 1 ;;
esac

# ------------------------------------------------ 2, 3 & 4. run it on a fixture
#
# One git repository, one base commit, and a branch per case committed on top of
# it. The gate reads $BASE for the pull request's base and $GITHUB_HEAD_REF for
# the branch name, so a case is a tree plus those two values — the head ref is
# set independently of what the fixture's own branch is called, which is what
# lets one repository stand in for eleven pull requests.
FIX=$(mktemp -d) || exit 1

git init -q "$FIX" >/dev/null 2>&1 || { fail fixture "$FIX" "git init failed"; exit 1; }
git -C "$FIX" config user.email devpath@example.invalid
git -C "$FIX" config user.name devpath
git -C "$FIX" config commit.gpgsign false

mkspec() {  # mkspec <slug> <the boxes, as a heredoc on stdin>
  mkdir -p "$FIX/devpath/$1"
  {
    printf -- '---\ntype: bug\nintent_accepted: true\ndesign_approved: true\n---\n'
    printf '# %s\n\n## Critique findings\n' "$1"
    cat
  } > "$FIX/devpath/$1/spec.md"
}

commit() {  # commit <message>
  git -C "$FIX" add -A >/dev/null 2>&1
  git -C "$FIX" commit -q --no-verify -m "$1" >/dev/null 2>&1
}

# The base every case branches from: some code, a neighbouring spec that is
# mid-build, and the spec under test with its boxes closed. Nothing below ever
# touches the neighbour, so any case that reports its box has swept something it
# was not asked to.
#
# The spec under test is in the base rather than added by each case, and that is
# load-bearing for one case rather than tidiness. git pairs a delete with an add
# as a rename and reports only the new path, and every spec.md here comes off one
# template, so a case that retires one spec and adds another gets them collapsed
# into a rename at around half similarity — leaving the retired path out of the
# diff and out of the sweep, which is the whole of what that case exists to put
# there. A delete never pairs with a modify. Cases go on calling mkspec freely;
# it overwrites.
mkdir -p "$FIX/src"
echo 'echo hello' > "$FIX/src/app.sh"
mkspec neighbour-spec <<'EOF'
- [ ] the neighbouring spec is mid-build, and this box is open
EOF
mkspec fixture-spec <<'EOF'
- [x] fixed — the spec under test starts with its boxes closed
EOF
commit base
BASE=$(git -C "$FIX" rev-parse HEAD 2>/dev/null)
[ -n "$BASE" ] || { fail fixture "$FIX" "no base commit, so every case below would test the guard"; exit 1; }

reset() {  # back to the base commit, working tree clean
  git -C "$FIX" reset -q --hard "$BASE" >/dev/null 2>&1
  git -C "$FIX" clean -qfd >/dev/null 2>&1
}

touch_code() { echo "echo $1" > "$FIX/src/app.sh"; }

rungate() {  # rungate <base> <head ref> — the gate's stdout, its status as the caller's
  ( cd "$FIX" && BASE="$1" GITHUB_HEAD_REF="$2" sh -c "$GATE" ) 2>/dev/null
}

# Status alone does not say why a run was red. A gate that never derived a scope
# is red too, and so is one that swept a directory it had no business in. So a
# red read from the status alone is a red a broken fixture can fake, and the case
# passes having tested nothing, which is this file committing the bug it exists
# to catch. grep prints what it matched, so the printed box is the proof — and
# the slug in it says which spec was swept.
catches() {  # catches <case> <base> <head ref> <detail> — red, on the box it matched
  OUT=$(rungate "$2" "$3") && { fail gate "$1" "$4
$GATE"; return; }
  case $OUT in
    *"devpath/fixture-spec/"*"- [ ]"*) ;;
    *"- [ ]"*) fail gate "$1" "the gate was red on a box outside the spec under test, so it
swept wider than the pull request touched:
$OUT" ;;
    *) fail gate "$1" "the gate was red without matching a box, so this case asserted
nothing. A run that never derived a scope is red the same way:
$GATE" ;;
  esac
}

passes() {  # passes <case> <base> <head ref> <detail> — green, with nothing to catch
  rungate "$2" "$3" >/dev/null || fail gate "$1" "$4
$GATE"
}

refuses() {  # refuses <case> <base> <head ref> <detail> — red, having swept nothing
  OUT=$(rungate "$2" "$3") && { fail gate "$1" "$4
$GATE"; return; }
  case $OUT in
    *"- [ ]"*) fail gate "$1" "the gate swept and reported a box instead of refusing to run,
so a misconfigured job is red for the wrong reason:
$OUT" ;;
  esac
}

# --- red on an open box in the spec the pull request touched

reset
mkspec fixture-spec <<'EOF'
- [x] fixed — the null guard the critic wanted
  - [ ] bulk path still throws above 200 rows
EOF
commit 'an indented open box'
catches 'an indented open box' "$BASE" fixture-spec \
  "the recommended gate passed on a box a formatter had indented:"

reset
mkspec fixture-spec <<'EOF'
- [x] fixed — the null guard the critic wanted
- [ ] bulk path still throws above 200 rows
EOF
commit 'a flat open box'
catches 'a flat open box' "$BASE" fixture-spec \
  "the recommended gate passed on an ordinary open box, so it now catches nothing:"

reset
mkspec fixture-spec <<'EOF'
- [x] fixed — the null guard the critic wanted
  - [x] false positive — the caller guarantees non-null
EOF
commit 'a clean spec directory'
passes 'a clean spec directory' "$BASE" fixture-spec \
  "the recommended gate failed on a directory whose boxes are all closed, so it
fails every spec rather than the open ones:"

# --- each half of the derivation, in a case the other half cannot carry
#
# The head ref names no directory here, so only the diff can have found the spec.
# Drop the diff half back to reading the branch name and this case goes green on
# an open box.
reset
mkspec fixture-spec <<'EOF'
- [ ] bulk path still throws above 200 rows
EOF
commit 'a spec the branch is not named for'
catches 'a branch not named for the spec it touches' "$BASE" hotfix-nulls \
  "the recommended gate swept nothing on a pull request that touched a spec
directory, because the branch was not named for it:"

# And here the diff touches no spec file at all, so only the branch-name fallback
# can have found it. Drop the fallback and a spec branch that edited only code
# ships unswept.
reset
mkspec fixture-spec <<'EOF'
- [ ] bulk path still throws above 200 rows
EOF
commit 'the spec directory'
CODEBASE=$(git -C "$FIX" rev-parse HEAD 2>/dev/null)
touch_code goodbye
commit 'code only'
catches 'a spec branch that edited only code' "$CODEBASE" fixture-spec \
  "the recommended gate swept nothing on a spec branch whose diff touched no file
under its own spec directory:"

# --- green on a branch that is not a spec's
#
# Three shapes of the bug this gate was rewritten for: a branch with no matching
# directory under devpath/ was red on the open box it had nothing to do with.
# devpath creates the first of them itself, and a repo pasting the gate gets the
# other two on ordinary work.
reset
touch_code goodbye
commit 'a lessons branch'
passes 'a lessons branch' "$BASE" devpath/lessons/fixture-spec \
  "the recommended gate was red on the lessons pull request devpath opens itself,
which touches no spec directory:"

reset
touch_code goodbye
commit 'a ci branch'
passes 'a ci branch' "$BASE" ci/bump-actions \
  "the recommended gate was red on an ordinary CI branch, which touches no spec
directory:"

reset
touch_code goodbye
commit 'a flat branch with no spec directory'
passes 'a flat branch with no spec directory' "$BASE" readme-typo \
  "the recommended gate was red on a docs fix, which touches no spec directory:"

# --- a directory the diff names that the tree no longer holds
#
# The [ -d ] filter, in the case that tells it from no filter at all. This pull
# request retires the neighbouring spec and opens a box in the spec under test, so
# one sweep holds a path that is gone and a box that is really there. grep -r
# exits 2 for the missing one having already printed the box, and the leading !
# turns that into a pass. Drop the filter and this case is green with the box it
# should have failed on sitting in its own output.
#
# The retirement is a delete against a spec the base already held, never a delete
# paired with an add — see the base above for why that distinction is the case
# rather than incidental to it.
reset
git -C "$FIX" rm -rq devpath/neighbour-spec >/dev/null 2>&1
mkspec fixture-spec <<'EOF'
- [ ] bulk path still throws above 200 rows
EOF
commit 'retire one spec, open a box in another'
catches 'a spec retired alongside an open box' "$BASE" fixture-spec \
  "the recommended gate passed on an open box it had already printed, because the
same pull request retired another spec directory and grep -r exits 2 on a path
that is gone:"

# Retiring a spec on its own stays green, which is the answer this job wants for
# it. Both halves name the retired directory here — the diff because it was
# touched, the fallback because the branch is named for it — so green has to come
# from having nothing left to sweep.
reset
git -C "$FIX" rm -rq devpath/neighbour-spec >/dev/null 2>&1
commit 'retire a spec'
passes 'a pull request that only retires a spec' "$BASE" neighbour-spec \
  "the recommended gate was red on a pull request whose only spec directory is the
one it retired, so a spec cannot be retired without a red:"

# --- and loud, rather than quiet, when it cannot work out what to sweep
#
# An empty head ref is what a push event hands the gate. Unguarded, the fallback
# tests [ -d "devpath/" ], which is true, and the sweep collapses to every spec
# in the repo — so this case is green only while that guard is there.
reset
touch_code goodbye
commit 'no head ref'
passes 'an event with no head ref' "$BASE" '' \
  "the recommended gate swept a neighbouring spec on a run with no head ref, which
is the unscoped sweep the guard exists to prevent:"

# No base at all, and a base the clone does not hold. Both are misconfiguration,
# and both have to be visible: a gate that exits 0 having swept nothing reads
# exactly like a clean spec, and nothing downstream would notice.
reset
touch_code goodbye
commit 'no pull request'
refuses 'an event with no pull request' '' fixture-spec \
  "the recommended gate passed on a run with no base to diff against, so a
misconfigured trigger ships as a green gate:"

refuses 'a base the clone does not hold' 0000000000000000000000000000000000000000 fixture-spec \
  "the recommended gate passed on a base it could not resolve, so a shallow
checkout ships as a green gate:"

# Those two are different mistakes and must not print the same diagnosis. No base
# at all is a job running on an event that is not a pull request; a base the clone
# does not hold is a shallow checkout. Told the second when the first is true, the
# reader deepens the checkout on a job that was never going to have a base.
#
# This one case reads the wording rather than the status, because the wording is
# the whole of the difference — both runs are red either way. Drop the ${BASE:?}
# guard and the no-base run falls through to the merge-base message, which is a
# regression nothing else here can see.
NOBASE=$( ( cd "$FIX" && BASE='' GITHUB_HEAD_REF=fixture-spec sh -c "$GATE" ) 2>&1 )
case $NOBASE in
  *'merge base'*) fail gate 'an event with no pull request' \
    "the gate blamed the merge base on a run that had no base at all, so a
misconfigured trigger reads as a shallow checkout:
$NOBASE" ;;
esac

# And the same assertion the other way round, because red is not enough here
# either. A merge-base failure that prints nothing leaves a shallow checkout as an
# unexplained red, and the summary line below would go on calling this job loud
# about it. Delete the echo from the || branch and only this catches it.
BADBASE=$( ( cd "$FIX" && BASE=0000000000000000000000000000000000000000 \
  GITHUB_HEAD_REF=fixture-spec sh -c "$GATE" ) 2>&1 )
case $BADBASE in
  *'merge base'*) ;;
  *) fail gate 'a base the clone does not hold' \
    "the gate was red on a base it could not resolve without naming the merge base,
so a shallow checkout ships as a red with no reason on it:
$BADBASE" ;;
esac

rm -rf "$FIX"

# ------------------------------------------- 5. no copy has been narrowed back
#
# Every place the pattern is written, live or quoted, has to carry the leading
# whitespace. A bare ^ anywhere is the silent failure returning, and a widened
# gate sitting beside a narrow hook block is a gate that disagrees with itself.
# The backslashes are optional in both greps below because the pattern is
# written three ways: bare in prose, shell-escaped, and JSON-escaped inside a
# hook block. Requiring one would let the bare form through unread.
NARROW=$(grep -rnE '\^- \\*\[' README.md skills/*/SKILL.md 2>/dev/null)
[ -n "$NARROW" ] && fail narrowed 'the open-box pattern' \
  "anchored at a bare ^, which misses an indented box:
$NARROW"

# And the widened form is present in both of the places the gate is specified.
# README is the one a repo pastes, Integrate is the one that refuses on it at
# step 3. A floor rather than a census, because README carries several and a new
# check is not a failure.
for f in README.md skills/integrate/SKILL.md; do
  grep -qE '\^\[\[:space:\]\]\*- \\*\[' "$f" \
    || fail 'gate copy' "$f" "carries no open-box pattern, so this file no longer specifies the gate"
done

if [ "$FAIL" -eq 0 ]; then
  echo "gate: the recommended grep sweeps what the pull request touched and only what is still on disk, is red on an indented box, green on a branch with no spec, loud on a base it cannot resolve, and narrowed nowhere — clean"
fi
exit "$FAIL"
