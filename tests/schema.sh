#!/bin/sh
# devpath — the structural checks: the things that break for somebody who
# installed this plugin, none of which any prose assertion can see.
#
# Six checks. That every skill still loads, that the hook blocks a repo pastes
# are valid JSON and valid shell, that the three places the spec and slice
# schemas are written still agree, that no schema heading has escaped its fence
# into a skill's own outline, that the two human-invoked skills are the two, and
# that the manifests parse and name the same plugin.
#
# Needs python3, which is what the JSON work runs on. Exit code is the build's.

cd "$(dirname "$0")/.." || exit 1

FAIL=0

if ! command -v python3 >/dev/null 2>&1; then
  echo "FAIL subject: python3 is not on PATH, and the JSON checks need it"
  exit 1
fi

fail() {  # fail <rule> <subject> [detail]
  echo "FAIL [$1] $2"
  [ -n "$3" ] && printf '%s\n' "$3" | sed 's/^/      /'
  FAIL=1
}

SKILLS=$(ls skills/*/SKILL.md 2>/dev/null)
if [ "$(printf '%s\n' "$SKILLS" | grep -c .)" -lt 8 ]; then
  echo "FAIL subject: found fewer than 8 skills, which is a collapsed glob rather than a repo"
  exit 1
fi

# ------------------------------------------------------- 1. every skill loads
#
# Front matter is what makes a SKILL.md a skill. A missing closing --- swallows
# the whole body into the front matter and the skill silently does not load —
# nothing else here would notice, because every word is still on the page.
for f in $SKILLS; do
  [ "$(head -1 "$f")" = "---" ] || { fail frontmatter "$f" "line 1 is not ---, so the front matter does not start at byte zero"; continue; }
  CLOSE=$(awk 'NR>1 && /^---$/ { print NR; exit }' "$f")
  [ -n "$CLOSE" ] || { fail frontmatter "$f" "the front matter has no closing ---"; continue; }
  head -n "$CLOSE" "$f" | grep -qE '^description: .+' \
    || fail frontmatter "$f" "the front matter carries no non-empty description:"
done

# ----------------------------------- 2. the hook blocks a repo pastes are valid
#
# README ships seven json blocks as copy-paste into a repo's settings.json, each
# carrying shell inside a JSON string. Both halves are hand-edited — the rename
# in #44 moved 150 lines of this file — and a repo that pastes a broken one gets
# a settings file that does not parse, or a hook that never fires.
BLK=$(mktemp -d) || exit 1
awk -v d="$BLK" '
  /^```json$/ { n++; f = 1; next }
  /^```$/     { f = 0; next }
  f           { print > (d "/" n ".json") }
' README.md

N=$(ls "$BLK" 2>/dev/null | wc -l | tr -d ' ')
if [ "$N" -lt 1 ]; then
  fail 'hook blocks' README.md "no fenced json blocks found, so this check tested nothing"
else
  for b in "$BLK"/*.json; do
    ERR=$(python3 -c 'import json,sys
try: json.load(open(sys.argv[1]))
except Exception as e: print(e)' "$b" 2>&1)
    if [ -n "$ERR" ]; then
      fail 'hook blocks' "README.md block $(basename "$b" .json)" "is not valid JSON: $ERR"
      continue
    fi
    # Every command string in the block has to be shell somebody can run.
    python3 -c 'import json,sys
def walk(o):
    if isinstance(o, dict):
        c = o.get("command")
        if isinstance(c, str): print(c)
        for v in o.values(): walk(v)
    elif isinstance(o, list):
        for v in o: walk(v)
walk(json.load(open(sys.argv[1])))' "$b" > "$BLK/cmds"
    while IFS= read -r cmd; do
      [ -n "$cmd" ] || continue
      printf '%s' "$cmd" | sh -n 2>/dev/null \
        || fail 'hook blocks' "README.md block $(basename "$b" .json)" \
             "a command does not parse as shell: $(printf '%s' "$cmd" | sh -n 2>&1 | head -1)"
    done < "$BLK/cmds"
  done
fi

# ------------------------------------------- 3. the schema agrees with itself
#
# The spec and slice heading schemas are written in three places: hook block 4,
# which a repo runs; README's two skeleton fences, which a human copies; and
# README's heading table, which says who writes each one. Drift between them is
# silent and lands on whoever pasted the hook — a section documented in prose but
# missing from the hook's list is born tripping the repo's own check, and the fix
# looks like deleting the section.
#
# chr(92) and chr(34) are a backslash and a quote: the list sits inside a
# JSON-escaped string, so the delimiter to find is a literal \" .
hooklist() {  # the P= list under the case label $1, one heading per line
  python3 -c 'import sys
marker = sys.argv[1]
s = open("README.md").read()
i = s.find(marker)
if i >= 0:
    rest = s[i + len(marker):]
    d = chr(92) + chr(34)
    if rest.startswith(d):
        rest = rest[len(d):]
        j = rest.find(d)
        if j >= 0:
            print(chr(10).join(rest[:j].split("|")))' "$1"
}

skeleton() {  # the ## headings of the $1'th markdown fence
  awk -v want="$1" '
    /^```markdown$/ { n++; if (n == want) f = 1; next }
    /^```$/         { if (f) exit; next }
    f && /^## /     { print }
  ' README.md | sed 's/^## //'
}

SPEC_HOOK=$(hooklist "spec.md) P=")
SPEC_SKEL=$(skeleton 1)
SLICE_HOOK=$(hooklist "slices/*.md) P=")
SLICE_SKEL=$(skeleton 2)
SPEC_TABLE=$(grep -oE '^\| `## [^`]+`' README.md | sed 's/^| `## //; s/`$//')

compare() {  # compare <what> <hook list> <skeleton list>
  if [ -z "$2" ]; then
    fail schema "README.md" "hook block 4 carries no $1 heading list to read"
  elif [ -z "$3" ]; then
    fail schema "README.md" "there is no $1 skeleton fence to read"
  elif [ "$2" != "$3" ]; then
    fail schema "README.md" "the $1 schema differs between hook block 4 and the skeleton:
  hook:     $(printf '%s' "$2" | tr '\n' ' ')
  skeleton: $(printf '%s' "$3" | tr '\n' ' ')"
  fi
}

compare spec  "$SPEC_HOOK"  "$SPEC_SKEL"
compare slice "$SLICE_HOOK" "$SLICE_SKEL"

# The heading table covers spec.md only, and it is the reader's map of who writes
# what — a section in the schema with no row is a section nobody owns.
if [ -n "$SPEC_HOOK" ] && [ "$SPEC_HOOK" != "$SPEC_TABLE" ]; then
  fail schema "README.md" "the spec schema differs between hook block 4 and the heading table:
  hook:  $(printf '%s' "$SPEC_HOOK" | tr '\n' ' ')
  table: $(printf '%s' "$SPEC_TABLE" | tr '\n' ' ')"
fi

# ------------------------------------- 4. no schema heading escapes its fence
#
# A skill printing `## Traps` or `## Technical design questions` as a literal
# shows it inside a fence. Written bare it is a real heading in that skill's own
# structure and splits the section it lives in. Three backticks earlier in the
# file are the only difference between the two, and grep cannot see a fence.
# Joined on | rather than newlines: awk -v takes no literal newline.
NAMES=$(printf '%s\n%s\nTechnical design questions\n' "$SPEC_HOOK" "$SLICE_HOOK" | grep . | tr '\n' '|')
if [ -n "$NAMES" ]; then
  ESCAPED=$(
    for f in $SKILLS; do
      awk -v F="$f" -v names="$NAMES" '
        BEGIN { n = split(names, a, "|"); for (i = 1; i <= n; i++) if (a[i] != "") bad[a[i]] = 1 }
        /^```/           { fence = !fence; next }
        !fence && /^## / { h = $0; sub(/^## /, "", h); if (h in bad) print F ":" NR ": " $0 }
      ' "$f"
    done
  )
  [ -n "$ESCAPED" ] && fail 'live heading' 'a skill carries a schema heading outside a fence' "$ESCAPED"
fi

# ------------------------------- 5. the human-invoked skills are the two
#
# devpath:sketch and devpath:fit-check are not stages and no model calls them.
# The flag is the whole of that, and a skill that gains or loses it changes who
# can start it without anything else in the repo changing.
DISABLED=$(grep -l 'disable-model-invocation: true' skills/*/SKILL.md 2>/dev/null | sort | tr '\n' ' ' | sed 's/ $//')
WANT='skills/fit-check/SKILL.md skills/sketch/SKILL.md'
if [ "$DISABLED" != "$WANT" ]; then
  fail 'human-invoked' 'the model-disabled set has changed' "expected: $WANT
found:    ${DISABLED:-(none)}"
fi

# ---------------------------------------------------- 6. the manifests agree
#
# plugin.json is what `claude plugin install` reads and marketplace.json is what
# lists it. A name in one and not the other is an install that resolves to nothing.
for m in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  ERR=$(python3 -c 'import json,sys
try: json.load(open(sys.argv[1]))
except Exception as e: print(e)' "$m" 2>&1)
  [ -n "$ERR" ] && fail manifest "$m" "is not valid JSON: $ERR"
done
PNAME=$(python3 -c 'import json; print(json.load(open(".claude-plugin/plugin.json")).get("name",""))' 2>/dev/null)
MNAME=$(python3 -c 'import json; print(json.load(open(".claude-plugin/marketplace.json")).get("plugins",[{}])[0].get("name",""))' 2>/dev/null)
if [ -z "$PNAME" ] || [ "$PNAME" != "$MNAME" ]; then
  fail manifest '.claude-plugin/' "plugin.json names '$PNAME', marketplace.json names '$MNAME'"
fi

rm -rf "$BLK"

if [ "$FAIL" -eq 0 ]; then
  echo "schema: $(printf '%s\n' "$SKILLS" | grep -c .) skills load, $N hook blocks parse, three schema copies agree — clean"
fi
exit "$FAIL"
