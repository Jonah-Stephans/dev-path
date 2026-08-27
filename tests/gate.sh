#!/bin/sh
# devpath — the open-box gate, run rather than read.
#
# Four checks. That README still ships exactly one gate to extract, that the
# gate it ships is red on an indented open box and on a flat one, that it stays
# green on a directory whose boxes are all closed, and that no copy of the
# pattern has been narrowed back to a bare ^.
#
# The gate is one anchored grep, written in README's recommended default, in the
# two hook blocks a repo pastes, in Integrate's step 3 test 1, and in the prose
# that quotes the pattern. Under a bare ^ it is a check that passes on the thing
# it exists to catch. A formatter that renests a list indents the box, the grep
# finds nothing, the job goes green, and Integrate arms a merge on a spec holding
# an open box. There is no second check that would notice, by design.
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

# --------------------------------------------- 1. README still ships the gate
#
# Selected by content rather than by position, the fenced bash line that greps
# for a box. A gate moved to another fence still gets tested, and a gate deleted
# fails here rather than leaving the next three checks testing nothing.
GATE=$(awk '
  /^```bash$/    { f = 1; next }
  /^```$/        { f = 0; next }
  f && index($0, "- \\[ \\]") { print }
' README.md)

if [ -z "$GATE" ]; then
  fail gate README.md "no fenced bash line greps for a box, so there is no recommended gate to run"
  exit 1
fi

# Exactly one, or the extraction is ambiguous rather than wrong. Two fences
# quoting the pattern get concatenated into one sh -c, where the last line's
# status becomes the whole run's and the three checks below silently assert
# against something other than the gate.
if [ "$(printf '%s\n' "$GATE" | grep -c .)" -ne 1 ]; then
  fail gate README.md "more than one fenced bash line greps for a box, so which one is the
recommended gate is ambiguous:
$GATE"
  exit 1
fi

# ------------------------------------------- 2 & 3. run it against a fixture
#
# One spec directory per case, laid out the way a real one is, and the gate run
# from the repo root above it with the slug in the environment variable the
# block reads.
FIX=$(mktemp -d) || exit 1
SLUG=fixture-spec

spec() {  # spec <the boxes, as a heredoc on stdin>
  rm -rf "${FIX:?}/devpath"
  mkdir -p "$FIX/devpath/$SLUG"
  {
    printf -- '---\ntype: bug\nintent_accepted: true\ndesign_approved: true\n---\n'
    printf '# %s\n\n## Critique findings\n' "$SLUG"
    cat
  } > "$FIX/devpath/$SLUG/spec.md"
}

rungate() {  # the gate's stdout, and its exit status as the caller's
  ( cd "$FIX" && GITHUB_HEAD_REF="$SLUG" sh -c "$GATE" ) 2>/dev/null
}

# Status alone does not say why a run was red. A gate that never found its
# directory is red too: test -d fails and the chain stops before the grep. So a
# red read from the status alone is a red a broken fixture can fake, and the
# case passes having tested nothing, which is this file committing the bug it
# exists to catch. grep prints what it matched, so the printed box is the proof.
catches() {  # catches <case> <detail> — red, with the box it matched as the proof
  OUT=$(rungate) && { fail gate "$1" "$2
$GATE"; return; }
  case $OUT in
    *'- [ ]'*) ;;
    *) fail gate "$1" "the gate was red without matching a box, so this case asserted nothing.
A fixture directory the gate never found is red the same way:
$GATE" ;;
  esac
}

passes() {  # passes <case> <detail> — green, on a directory with nothing to catch
  rungate >/dev/null || fail gate "$1" "$2
$GATE"
}

spec <<'EOF'
- [x] fixed — the null guard the critic wanted
  - [ ] bulk path still throws above 200 rows
EOF
catches 'an indented open box' \
  "the recommended gate passed on a box a formatter had indented:"

spec <<'EOF'
- [x] fixed — the null guard the critic wanted
- [ ] bulk path still throws above 200 rows
EOF
catches 'a flat open box' \
  "the recommended gate passed on an ordinary open box, so it now catches nothing:"

spec <<'EOF'
- [x] fixed — the null guard the critic wanted
  - [x] false positive — the caller guarantees non-null
EOF
passes 'a clean spec directory' \
  "the recommended gate failed on a directory whose boxes are all closed, so it
fails every spec rather than the open ones:"

rm -rf "$FIX"

# ------------------------------------------- 4. no copy has been narrowed back
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
  echo "gate: the recommended grep is red on an indented box, green on a closed one, and narrowed nowhere — clean"
fi
exit "$FAIL"
