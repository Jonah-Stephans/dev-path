#!/bin/sh
# devpath — hook blocks 6 and 7, run rather than read.
#
# Four checks. That README still ships exactly two of them to extract and that
# neither reads `## Outcome checks`, that each one is silent on every state where
# Learn is not owed, that each one fires on a pull request out of draft with no
# lessons pull request open, and that block 6 emits the JSON the harness reads.
#
# Both blocks are Stop hooks, so they run at the end of every turn on the branch.
# Detecting Integrate's completion by anything written into `spec.md` puts that
# detection six steps and one hard exit too early: `## Outcome checks` is written
# at step 1, Learn runs at step 7, and step 3 in between is a refusal that ends
# the run. A block reading it denies the end of every turn on a spec Integrate
# legitimately refused, and the escape is deleting the block. The draft state is
# the reading that survives, because Initiate opens the pull request as a draft
# and step 8 marks it ready.
#
# `gh` is stubbed. The draft read, the enumeration, the scoping and the release
# are what run here; the live API is not, and README says so.
#
# Exit code is the build's.

cd "$(dirname "$0")/.." || exit 1

FAIL=0

fail() {  # fail <rule> <subject> [detail]
  echo "FAIL [$1] $2"
  [ -n "$3" ] && printf '%s\n' "$3" | sed 's/^/      /'
  FAIL=1
}

if ! command -v python3 >/dev/null 2>&1; then
  echo "FAIL subject: python3 is not on PATH, and the extraction needs it"
  exit 1
fi

W=$(mktemp -d) || exit 1
trap 'rm -rf "$W"' EXIT

# --------------------------------------- 1. README still ships the two blocks
#
# Selected by content rather than by position: the scoped `devpath/lessons/`
# enumeration is what makes a command one of these two, so a block that moves
# still gets tested and a block deleted fails here rather than leaving the
# checks below testing nothing.
ERR=$(python3 - "$W" <<'PY' 2>&1
import json, re, sys

out = sys.argv[1]
blocks = re.findall(r"^```json\n(.*?)^```", open("README.md").read(), re.S | re.M)
cmds = []

def walk(o):
    if isinstance(o, dict):
        c = o.get("command")
        if isinstance(c, str) and "devpath/lessons/" in c:
            cmds.append(c)
        for v in o.values():
            walk(v)
    elif isinstance(o, list):
        for v in o:
            walk(v)

for b in blocks:
    walk(json.loads(b))

if len(cmds) != 2:
    sys.exit("README ships %d command(s) enumerating devpath/lessons/, not 2" % len(cmds))
for i, c in enumerate(cmds, 6):
    if "Outcome checks" in c:
        sys.exit("block %d detects Integrate by reading ## Outcome checks, which is true from step 1" % i)
    if "isDraft" not in c:
        sys.exit("block %d reads no draft state, so it cannot tell Integrate finished from Integrate refused" % i)
    open("%s/b%d.sh" % (out, i), "w").write(c + "\n")
PY
)
if [ -n "$ERR" ]; then
  fail 'hook blocks' README.md "$ERR"
  exit 1
fi

# ------------------------------------------ 2 & 3. run them against a stub gh
#
# One stub per command, logging every call, so the count is checkable: both are
# Stop hooks and a block that reads the draft state twice pays it on every turn.
BIN=$W/bin
mkdir -p "$BIN"

cat > "$BIN/git" <<'EOS'
#!/bin/sh
[ "$1 $2" = "branch --show-current" ] && { printf '%s\n' "$SLUG_STUB"; exit 0; }
exit 1
EOS

# Order matters: the lessons enumeration is also a `pr list --head`, so it is
# matched first. $LESSONS_PRS is deliberately unquoted, to print one per line.
cat > "$BIN/gh" <<'EOS'
#!/bin/sh
echo "gh $*" >> "$GH_LOG"
case "$*" in
  *"--head devpath/lessons/"*)  printf '%s\n' $LESSONS_PRS; exit 0;;
  "pr list --head "*)           printf '%s\n' "$DRAFT_STUB"; exit 0;;
  "pr diff "*"--name-only")     printf '%s\n' "$DIFF_STUB"; exit 0;;
esac
echo "gh: the blocks called something this stub does not answer: $*" >&2
exit 1
EOS

chmod +x "$BIN/git" "$BIN/gh"
PATH="$BIN:$PATH"
export PATH GH_LOG SLUG_STUB DRAFT_STUB LESSONS_PRS DIFF_STUB

mkdir -p "$W/repo/devpath/a-spec"
: > "$W/repo/devpath/a-spec/spec.md"
cd "$W/repo" || exit 1

SLUG_STUB=a-spec
LESSONS_PRS=
DIFF_STUB=

run() {  # run <block> <fires: yes|no> <gh calls> <what state this is>
  GH_LOG=$W/log
  : > "$GH_LOG"
  OUT=$(sh "$W/b$1.sh" 2>&1)
  N=$(grep -c . "$GH_LOG")
  GOT=no
  [ -n "$OUT" ] && GOT=yes
  if [ "$GOT" != "$2" ]; then
    fail 'hook blocks' "block $1 on $4" "it ${GOT}s, and on this state it should ${2}: ${OUT:-(silent)}"
  elif [ "$N" != "$3" ]; then
    fail 'hook blocks' "block $1 on $4" "$N gh call(s), not $3:
$(cat "$GH_LOG")"
  fi
}

# A branch that is not a spec: no gh at all, because $S guards ahead of it.
SLUG_STUB=elsewhere run 6 no 0 "a branch carrying no spec.md"
SLUG_STUB=a-spec

# Every state where Learn is not owed leaves on the draft read, one call in.
DRAFT_STUB=true run 6 no 1 "a draft, which is Integrate refused at step 3"
DRAFT_STUB=true run 7 no 1 "a draft, which is Integrate refused at step 3"
DRAFT_STUB=null run 6 no 1 "a branch with no pull request"
DRAFT_STUB=     run 6 no 1 "a gh that answered with nothing"

# Out of draft is Integrate past step 8, so Learn is owed and nothing is open.
DRAFT_STUB=false run 6 yes 2 "a pull request out of draft, no lessons pull request"
DRAFT_STUB=false run 7 yes 2 "a pull request out of draft, no lessons pull request"

# A lessons pull request touching a rules file releases both.
DRAFT_STUB=false LESSONS_PRS=77 DIFF_STUB=.claude/rules/things.md \
  run 6 no 3 "a lessons pull request touching .claude/rules/"
DRAFT_STUB=false LESSONS_PRS=77 DIFF_STUB=.claude/rules/things.md \
  run 7 no 3 "a lessons pull request touching .claude/rules/"

# A neighbouring spec's lessons pull request does not, because of the scoping.
DRAFT_STUB=false LESSONS_PRS= DIFF_STUB=.claude/rules/things.md \
  run 6 yes 2 "a rules pull request that is not this spec's"

LESSONS_PRS=
DIFF_STUB=

# ------------------------------------------ 4. block 6 denies the way it says
#
# The wrapper is what the harness reads. A block emitting prose where the Stop
# event wants `{"decision":"block"}` is a block that prints and never denies,
# and nothing else here would tell the two apart.
GH_LOG=$W/log DRAFT_STUB=false sh "$W/b6.sh" > "$W/payload" 2>&1
ERR=$(python3 -c 'import json, sys
try: d = json.load(open(sys.argv[1]))
except Exception as e: sys.exit("block 6 emitted no JSON to deny with: %s" % e)
if d.get("decision") != "block": sys.exit("block 6 emitted decision=%r, not block" % d.get("decision"))
if not d.get("reason"): sys.exit("block 6 denies with no reason, so the engineer is told nothing")' "$W/payload" 2>&1)
[ -n "$ERR" ] && fail 'hook blocks' 'README.md block 6' "$ERR"

if [ "$FAIL" -eq 0 ]; then
  echo "hooks: blocks 6 and 7 are silent on a draft and on no pull request, fire out of draft, and scope to this spec — clean"
fi
exit "$FAIL"
