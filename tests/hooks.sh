#!/bin/sh
# devpath — the hook blocks that speak to somebody, run rather than read.
#
# Blocks 6 and 7 warn or deny at the end of a turn, block 4 warns after a write,
# and block 8 warns after a dispatch. All four reach their reader through a
# wrapper the harness parses, and whether a wrapper is well formed is the one
# thing reading README cannot tell.
#
# Six checks. That README still ships exactly two of the Learn blocks to extract
# and that neither reads `## Outcome checks`, that each one is silent on every
# state where Learn is not owed, that each one fires on a pull request out of
# draft with no lessons pull request open, that blocks 6 and 7 emit the JSON the
# harness reads, that block 4 does too and exits 0 either way, and that block 8
# fires on a built slice no critic has read and is silent everywhere else. Every
# run of a Learn block also counts the `gh` calls, because a second draft read is
# paid at the end of every turn rather than once.
#
# Blocks 6 and 7 are Stop hooks, so they run at the end of every turn on the
# branch.
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

# Blocks 4 and 6 build their message with `jq -n`, so jq is the thing under
# test's dependency rather than this file's. Without it check 3 still passes on
# jq's own error text and checks 4 and 5 report no JSON, which reads as a README
# defect. Check 5 puts a deliberately broken jq in front of this one, and it
# needs a working jq behind it to exec.
if ! command -v jq >/dev/null 2>&1; then
  echo "FAIL subject: jq is not on PATH, and blocks 4 and 6 build their message with it"
  exit 1
fi

W=$(mktemp -d) || exit 1
trap 'rm -rf "$W"' EXIT

# ---------------------------------------- 1. README still ships the four blocks
#
# Selected by content rather than by position: the scoped `devpath/lessons/`
# enumeration is what makes a command one of the Learn pair, a `P=` list under a
# `spec.md` case label is what makes one block 4, and reading `fix_cycles` is
# what makes one block 8 — so a block that moves still gets tested and a block
# deleted fails here rather than leaving the checks below testing nothing.
#
# Block 4's fixtures are cut from its own `P=` lists rather than typed out, so no
# fourth copy of the spec and slice schemas is born in this file for
# tests/schema.sh to then have to police.
ERR=$(python3 - "$W" <<'PY' 2>&1
import json, re, sys

out = sys.argv[1]
blocks = re.findall(r"^```json\n(.*?)^```", open("README.md").read(), re.S | re.M)
cmds = []

def walk(o):
    if isinstance(o, dict):
        c = o.get("command")
        if isinstance(c, str):
            cmds.append(c)
        for v in o.values():
            walk(v)
    elif isinstance(o, list):
        for v in o:
            walk(v)

for b in blocks:
    walk(json.loads(b))

learn = [c for c in cmds if "devpath/lessons/" in c]
if len(learn) != 2:
    sys.exit("README ships %d command(s) enumerating devpath/lessons/, not 2" % len(learn))
for i, c in enumerate(learn, 6):
    if "Outcome checks" in c:
        sys.exit("block %d detects Integrate by reading ## Outcome checks, which is true from step 1" % i)
    if "isDraft" not in c:
        sys.exit("block %d reads no draft state, so it cannot tell Integrate finished from Integrate refused" % i)
    open("%s/b%d.sh" % (out, i), "w").write(c + "\n")

critic = [c for c in cmds if "fix_cycles" in c]
if len(critic) != 1:
    sys.exit("README ships %d command(s) reading fix_cycles, not 1" % len(critic))
if "devpath slice: " not in critic[0]:
    sys.exit("block 8 parses no dispatch first line, so it reads the prompt of every dispatch")
open("%s/b8.sh" % out, "w").write(critic[0] + "\n")

schema = [c for c in cmds if 'spec.md) P="' in c]
if len(schema) != 1:
    sys.exit("README ships %d command(s) casing on a spec.md heading list, not 1" % len(schema))
open("%s/b4.sh" % out, "w").write(schema[0] + "\n")

for label, name in (("spec.md", "spec"), ("slices/*.md", "slice")):
    m = re.search(re.escape(label) + r'\) P="([^"]+)"', schema[0])
    if not m:
        sys.exit("block 4 carries no %s heading list to cut fixtures from" % name)
    open("%s/%s-headings" % (out, name), "w").write(m.group(1).replace("|", "\n") + "\n")

BAD = "Notes"
if BAD in schema[0]:
    sys.exit("## %s is in block 4's own lists, so it cannot be the fixture's offending heading" % BAD)
open("%s/bad-heading" % out, "w").write(BAD + "\n")
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
    if [ "$2" = yes ]; then WANT="fire here"; else WANT="stay silent here"; fi
    fail 'hook blocks' "block $1 on $4" "it should $WANT, and it did not: ${OUT:-(silent)}"
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

# Nor does a lessons pull request touching no rules file. This is the limit
# README states about what a lessons pull request contains: Learn proposing
# only a check reads here as Learn never having run.
DRAFT_STUB=false LESSONS_PRS=77 DIFF_STUB=.github/workflows/tests.yml \
  run 6 yes 3 "a lessons pull request touching only CI configuration"

LESSONS_PRS=
DIFF_STUB=

# --------------------------- 4. blocks 6 and 7 speak the way each of them says
#
# The wrapper is what the harness reads. A block emitting prose where the Stop
# event wants `{"decision":"block"}` is a block that prints and never denies,
# and nothing else here would tell the two apart.
#
# Block 7 is here and not only block 6 because its warning is JSON too. Check 3
# reads output as non-empty, and malformed JSON is non-empty — so one unescaped
# quote in a reworded message emits a payload the harness cannot parse, the
# engineer is told nothing, and every check above this line stays green.
GH_LOG=$W/log DRAFT_STUB=false sh "$W/b6.sh" > "$W/payload" 2>"$W/payload.err"
[ -s "$W/payload.err" ] && fail 'hook blocks' 'README.md block 6' \
  "block 6 wrote to stderr, which is not where the harness reads:
$(cat "$W/payload.err")"
ERR=$(python3 -c 'import json, sys
try: d = json.load(open(sys.argv[1]))
except Exception as e: sys.exit("block 6 emitted no JSON to deny with: %s" % e)
if d.get("decision") != "block": sys.exit("block 6 emitted decision=%r, not block" % d.get("decision"))
if not d.get("reason"): sys.exit("block 6 denies with no reason, so the engineer is told nothing")' "$W/payload" 2>&1)
[ -n "$ERR" ] && fail 'hook blocks' 'README.md block 6' "$ERR"

GH_LOG=$W/log DRAFT_STUB=false sh "$W/b7.sh" > "$W/payload7" 2>"$W/payload7.err"
[ -s "$W/payload7.err" ] && fail 'hook blocks' 'README.md block 7' \
  "block 7 wrote to stderr, which at exit 0 reaches nobody at all:
$(cat "$W/payload7.err")"
ERR=$(python3 -c 'import json, sys
try: d = json.load(open(sys.argv[1]))
except Exception as e: sys.exit("block 7 emitted no JSON to warn with: %s" % e)
if not d.get("systemMessage"): sys.exit("block 7 emitted the key(s) %r, and systemMessage is its one route to the engineer" % sorted(d))' "$W/payload7" 2>&1)
[ -n "$ERR" ] && fail 'hook blocks' 'README.md block 7' "$ERR"

# --------------------------- 5. block 4 reaches the model, and never does worse
#
# Block 4 is the block nothing else on this build runs: check 1's other selector
# is `devpath/lessons/`, which block 4 does not carry, and tests/schema.sh reads
# its `P=` lists as text rather than running them. Before this check, a jq
# program error in block 4 shipped green.
#
# Its reader is the model that made the write and its route is
# `hookSpecificOutput.additionalContext` on exit 0, so the event name is part of
# the assertion: the harness routes the context by that name.
mkdir -p "$W/repo/devpath/b-spec/slices" "$W/repo/devpath/c-spec/slices"
BAD="## $(cat "$W/bad-heading")"
sed 's/^/## /' "$W/spec-headings"  > "$W/repo/devpath/c-spec/spec.md"
sed 's/^/## /' "$W/slice-headings" > "$W/repo/devpath/c-spec/slices/01.md"
{ sed 's/^/## /' "$W/spec-headings";  printf '%s\n' "$BAD"; } > "$W/repo/devpath/b-spec/spec.md"
{ sed 's/^/## /' "$W/slice-headings"; printf '%s\n' "$BAD"; } > "$W/repo/devpath/b-spec/slices/01.md"

run4() {  # run4 <file_path> <fires: yes|no> <what that path is>
  OUT=$(printf '{"tool_input":{"file_path":"%s"}}' "$1" | sh "$W/b4.sh" 2>"$W/b4.err")
  RC=$?
  GOT=no
  [ -n "$OUT" ] && GOT=yes
  if [ "$RC" -ne 0 ]; then
    fail 'hook blocks' "block 4 on $3" \
      "it exited $RC, and anything but 0 at PostToolUse is an error rather than a warning"
  elif [ -s "$W/b4.err" ]; then
    fail 'hook blocks' "block 4 on $3" "it wrote to stderr, which is not where the harness reads:
$(cat "$W/b4.err")"
  elif [ "$GOT" != "$2" ]; then
    if [ "$2" = yes ]; then WANT="fire here"; else WANT="stay silent here"; fi
    fail 'hook blocks' "block 4 on $3" "it should $WANT, and it did not: ${OUT:-(silent)}"
  fi
}

run4 devpath/b-spec/spec.md      yes "a spec carrying a heading outside the schema"
ERR=$(printf '%s' "$OUT" | python3 -c 'import json, sys
try: d = json.load(sys.stdin)
except Exception as e: sys.exit("block 4 emitted no JSON to reach the model with: %s" % e)
h = d.get("hookSpecificOutput") or {}
if h.get("hookEventName") != "PostToolUse":
    sys.exit("block 4 named the event %r, and the harness routes the context by that name" % h.get("hookEventName"))
c = h.get("additionalContext") or ""
if not c:
    sys.exit("block 4 emitted the key(s) %r, and additionalContext is its one route to the model" % sorted(h))
if sys.argv[1] not in c:
    sys.exit("block 4 named no offending heading, which is the part the model can act on: %r" % c)' \
  "$(cat "$W/bad-heading")" 2>&1)
[ -n "$ERR" ] && fail 'hook blocks' 'README.md block 4' "$ERR"

run4 devpath/b-spec/slices/01.md yes "a slice carrying a heading outside the schema"
run4 devpath/c-spec/spec.md      no  "a spec wholly inside the schema"
run4 devpath/c-spec/slices/01.md no  "a slice wholly inside the schema"
run4 docs/notes.md               no  "a path that is neither, and does not exist"

# The `exit 0` the command ends on, tested by breaking the jq underneath it.
# Without it the block's status is jq's, and jq exits 2 on a usage error and 3 on
# a compile error — 2 being the code PostToolUse reads as a blocking error fed to
# the model. A block README says cannot deny would acquire the ability by typo,
# and the repo that hits it is the one that reworded the message.
REALJQ=$(command -v jq)
mkdir -p "$W/badjq"
cat > "$W/badjq/jq" <<EOJ
#!/bin/sh
# The block's first clause reads the event with \`jq -r\`, which has to keep
# working, or it leaves before it ever builds a message. \`jq -n\` builds it.
for a in "\$@"; do
  [ "\$a" = "-n" ] && { echo 'jq: error: syntax error at <top-level>' >&2; exit 3; }
done
exec "$REALJQ" "\$@"
EOJ
chmod +x "$W/badjq/jq"
OUT=$(printf '{"tool_input":{"file_path":"devpath/b-spec/spec.md"}}' \
  | PATH="$W/badjq:$PATH" sh "$W/b4.sh" 2>/dev/null)
RC=$?
[ "$RC" -ne 0 ] && fail 'hook blocks' 'README.md block 4' \
  "with a jq that errors the block exited $RC rather than 0, so a typo in its message denies the write"

# ------------------- 6. block 8 fires on a built slice no critic has read, only
#
# Block 8 is the second `jq -n` message on this menu that nothing else runs, and
# it fires far more often than block 4 does — on every ordinary builder return —
# so a malformed wrapper here is a sentence the orchestrator never sees on the
# one edge with a demonstrated failure history.
#
# Its condition is Integrate's step 3 test 2. Two of the silent fixtures are
# states a session actually produces — a slice a critic has already read, and a
# slice not built yet. The other two are the shapes where reading the prompt any
# further would be wrong: a first line naming a path that is not there, and a
# dispatch that is not a slice dispatch at all.
mkdir -p "$W/repo/devpath/d-spec/slices"

mkslice() {  # mkslice <file> <done line> [fix_cycles line]
  { printf -- '---\n'; printf '%s\n' "$2"; [ -n "$3" ] && printf '%s\n' "$3"
    printf -- '---\n\n## Critique findings\n'; } > "$1"
}
mkslice "$W/repo/devpath/d-spec/slices/01.md" "done: true"
mkslice "$W/repo/devpath/d-spec/slices/02.md" "done: true" "fix_cycles: 0"
mkslice "$W/repo/devpath/d-spec/slices/03.md" "depends_on: 01"

run8() {  # run8 <prompt first line> <fires: yes|no> <what state this is>
  OUT=$(printf '{"tool_input":{"prompt":"%s\\nbuild it"}}' "$1" | sh "$W/b8.sh" 2>"$W/b8.err")
  RC=$?
  GOT=no
  [ -n "$OUT" ] && GOT=yes
  if [ "$RC" -ne 0 ]; then
    fail 'hook blocks' "block 8 on $3" \
      "it exited $RC, and anything but 0 at PostToolUse is an error rather than a warning"
  elif [ -s "$W/b8.err" ]; then
    fail 'hook blocks' "block 8 on $3" "it wrote to stderr, which is not where the harness reads:
$(cat "$W/b8.err")"
  elif [ "$GOT" != "$2" ]; then
    if [ "$2" = yes ]; then WANT="fire here"; else WANT="stay silent here"; fi
    fail 'hook blocks' "block 8 on $3" "it should $WANT, and it did not: ${OUT:-(silent)}"
  fi
}

run8 "devpath slice: devpath/d-spec/slices/01.md" yes "a builder returning on a slice no critic has read"
ERR=$(printf '%s' "$OUT" | python3 -c 'import json, sys
try: d = json.load(sys.stdin)
except Exception as e: sys.exit("block 8 emitted no JSON to reach the orchestrator with: %s" % e)
h = d.get("hookSpecificOutput") or {}
if h.get("hookEventName") != "PostToolUse":
    sys.exit("block 8 named the event %r, and the harness routes the context by that name" % h.get("hookEventName"))
c = h.get("additionalContext") or ""
if not c:
    sys.exit("block 8 emitted the key(s) %r, and additionalContext is its one route to the orchestrator" % sorted(h))
if sys.argv[1] not in c:
    sys.exit("block 8 named no slice, which is the part the orchestrator dispatches on: %r" % c)' \
  devpath/d-spec/slices/01.md 2>&1)
[ -n "$ERR" ] && fail 'hook blocks' 'README.md block 8' "$ERR"

run8 "devpath slice: devpath/d-spec/slices/02.md" no "a slice a critic has already read"
run8 "devpath slice: devpath/d-spec/slices/03.md" no "a slice not built yet"
run8 "devpath slice: devpath/d-spec/slices/99.md" no "a first line naming a slice that is not there"
run8 "go and read the codebase"                   no "a dispatch that is not a slice dispatch"

if [ "$FAIL" -eq 0 ]; then
  echo "hooks: blocks 6 and 7 are silent on a draft and on no pull request, fire out of draft, and scope to this spec; blocks 4, 6, 7 and 8 each emit the wrapper their event reads, block 4 exits 0 even where jq does not, and block 8 fires only on a built slice no critic has read — clean"
fi
exit "$FAIL"
