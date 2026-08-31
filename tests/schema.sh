#!/bin/sh
# devpath — the structural checks: the things that break for somebody who
# installed this plugin, none of which any prose assertion can see.
#
# Eight checks. That every skill still loads, that the hook blocks a repo pastes
# are valid JSON and valid shell, that the three places the spec and slice
# schemas are written still agree, that no schema heading has escaped its fence
# into a skill's own outline, that the two human-invoked skills are the two, that
# the manifests parse and name the same plugin, that both files stating the two
# triggers for a trap state both of them, and that fit-check's spelled counts
# agree with the entry tables under them.
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

# ------------------------------------- 7. both trap triggers, in both the files
#
# A trap has two triggers and two files state them: skills/critique/SKILL.md,
# which the critic acts on, and README's heading table, which is where everyone
# else learns who writes the section. This is check 3's kind of drift rather than
# a paragraph assertion. Two copies of one list, where a trigger lost from one
# copy is invisible in a diff of the other, and the reader left short is the one
# who read only that file.
#
# Literal phrases, one per trigger, chosen because nothing else in either file
# says them. Each has to survive on one line: a rewrap that splits one goes red
# while being correct, and the fix is to put the phrase back on one line.
T1='a test that passed while the code was wrong'
T2='still quotable from `## Design`'
for f in skills/critique/SKILL.md README.md; do
  if [ ! -f "$f" ]; then
    fail 'trap triggers' "$f" "does not exist, so this check read nothing"
    continue
  fi
  grep -qF "$T1" "$f" || fail 'trap triggers' "$f" "states no green-test trigger — expected: $T1"
  grep -qF "$T2" "$f" || fail 'trap triggers' "$f" "states no quotable-design trigger — expected: $T2"
done

# ----------------- 8. fit-check's stated counts agree with its own entry tables
#
# skills/fit-check/SKILL.md spells how many preconditions it carries in four
# sentences, how many a non-Salesforce repo cannot be checked against in five
# more, and splits the entries three ways in a summary table. All of it is prose
# moved by hand, and a missed site reads perfectly well: a description saying
# twenty-six over a table of twenty-seven is the number a router is handed.
#
# The sites are compared against each other, never against a literal 26. A check
# pinning the number goes red on every correct edit; this one goes red only when
# the file contradicts itself, which is the defect.
#
# Two numbers, and they move independently. The total moves whenever an entry is
# added. The subtotal moves only when a Salesforce-only one is, and its source of
# truth is the enumerated not-applicable row rather than any sentence spelling it.
#
# The counts are spelled rather than written, so this carries a spelling map —
# the next entry turns the check red instead of waiting to be noticed.
#
# Document order does not ascend. Entry 26 was appended to ### Coexistence and
# entry 25 sits alone under ### Culture, because renumbering would break every
# citation already naming entry 25, so the numbers are sorted before gaps are
# looked for. And the row scan is scoped to the ### tables under the entry
# heading: the per-entry discussion below them holds a sub-property table
# numbered 1 to 4.
#
# The site phrases below are part of the assertion. A rewording that no longer
# matches goes red saying so, and the fix is to move the phrase into the list.
COUNTS=$(python3 - <<'PY'
import re

F = "skills/fit-check/SKILL.md"
out = []
def bad(rule, detail): out.append(rule + "|" + detail)

try:
    lines = open(F).read().split("\n")
except OSError as e:
    print("entry numbering|%s could not be read, so this check read nothing: %s" % (F, e))
    raise SystemExit

ONES = ("zero one two three four five six seven eight nine ten eleven twelve thirteen "
        "fourteen fifteen sixteen seventeen eighteen nineteen").split()
TENS = [None, None, "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]

def word(n):
    if 0 <= n < 20: return ONES[n]
    if 20 <= n < 100:
        t, u = divmod(n, 10)
        return TENS[t] if u == 0 else TENS[t] + "-" + ONES[u]
    return None

def cells(line):  # a markdown row's cells, with escaped pipes left inside them
    s = line.replace("\\|", "\x00").strip()
    if not s.startswith("|") or not s.endswith("|"): return None
    return [c.replace("\x00", "|").strip() for c in s[1:-1].split("|")]

def sites(specs, n, kind, source):
    stale = {}
    for pat, name in specs:
        hits = [(i + 1, m.group(1)) for i, l in enumerate(lines) for m in [re.search(pat, l)] if m]
        if not hits:
            bad("spelled " + kind, "%s no longer reads as this check expects, so the %s spelled there went unread — the phrase is part of the assertion and a rewording has to move it here too" % (name, kind))
            continue
        for ln, got in hits:
            if got != word(n):
                stale.setdefault(got, []).append("%s (line %d)" % (name, ln))
    for got in sorted(stale):
        bad("spelled " + kind, "%s, and %s is still spelled at %s" % (source, got, ", ".join(stale[got])))

hstart = None
for i, l in enumerate(lines):
    if re.match(r'^## The [a-z-]+, and how each is observed\s*$', l):
        hstart = i
        break

if hstart is None:
    bad("entry numbering", "no heading reads '## The <count>, and how each is observed', so the entry tables could not be found")
else:
    hend = len(lines)
    for i in range(hstart + 1, len(lines)):
        if lines[i].startswith("## "):
            hend = i
            break
    sub = None
    for i in range(hstart + 1, hend):
        if lines[i].startswith("### "):
            sub = i
            break

    entries = []  # (number, observability group, line)
    if sub is None:
        bad("entry numbering", "the entry-table section holds no ### group heading, so no group table could be read")
    else:
        for i in range(sub, hend):
            c = cells(lines[i])
            if not c or len(c) != 5 or not re.fullmatch(r'\d+', c[0]): continue
            entries.append((int(c[0]), c[2].replace("*", "").strip(), i + 1))

    nums = sorted(n for n, _, _ in entries)
    N = len(nums)
    dups = sorted(set(n for n in nums if nums.count(n) > 1))
    missing = [n for n in range(1, N + 1) if n not in set(nums)]
    over = sorted(set(n for n in nums if n > N))
    tail = " Nothing else in this check ran, because it has no trustworthy total to compare the spelled sites against."

    if not entries:
        bad("entry numbering", "the group tables hold no entry row, so this check read nothing." + tail)
    elif dups or missing or over:
        parts = []
        if missing: parts.append("no row is numbered " + ", ".join(str(n) for n in missing))
        if dups: parts.append("two rows are numbered " + ", ".join(str(n) for n in dups))
        if over: parts.append("a row is numbered above the total: " + ", ".join(str(n) for n in over))
        bad("entry numbering", "the group tables carry %d entry rows, so they should be numbered 1 to %d, and %s.%s" % (N, N, "; ".join(parts), tail))
    elif word(N) is None:
        bad("entry numbering", "the group tables carry %d entry rows, and this check spells numbers up to ninety-nine only — extend the spelling map." % N)
    else:
        sites([
            (r'^description: Check a repo against the ([a-z-]+) preconditions', "the front matter description"),
            (r'are the same ([a-z-]+) checks', "the two moments, one skill line"),
            (r'so [a-z-]+ of the ([a-z-]+) do not apply', "the not-applicable worked example"),
            (r'^## The ([a-z-]+), and how each is observed', "the entry-table heading"),
        ], N, "total", "the group tables carry %s entry rows" % word(N))

        # The summary table splits the entries by observability group. The six ###
        # tables partition them by topic instead — both sum to N, neither derives
        # from the other, and this compares the first against the Group column.
        summary = {}
        for i in range(hstart, sub):
            c = cells(lines[i])
            if not c or len(c) != 3: continue
            m = re.match(r'^\*{0,2}(\d+)\b', c[0])
            v = c[2].replace("*", "").strip()
            if m and re.fullmatch(r'\d+', v): summary[m.group(1)] = int(v)
        tally = {}
        for n, g, _ in entries: tally[g] = tally.get(g, 0) + 1
        if not summary:
            bad("observability split", "the group summary table above the first ### heading carries no readable counts, so the split went unchecked")
        elif summary != tally:
            for g in sorted(set(summary) | set(tally)):
                if summary.get(g) != tally.get(g):
                    bad("observability split", "the summary table puts %s entries in group %s and the Group column of the entry rows holds %s" % (summary.get(g, "no"), g, tally.get(g, "none")))
        if summary and sum(summary.values()) != N:
            bad("observability split", "the summary table's counts sum to %d and the group tables carry %d entry rows" % (sum(summary.values()), N))

        na = None
        for i, l in enumerate(lines):
            c = cells(l)
            if c and len(c) == 2 and c[0].startswith("**Not applicable**"):
                na = ([x.strip() for x in c[1].split("·")], i + 1)
                break
        if na is None:
            bad("not applicable", "no table row opens '**Not applicable**', so the enumerated list of entries a non-Salesforce repo cannot be checked against went unread")
        else:
            members, ln = na
            junk = [x for x in members if not re.fullmatch(r'\d+', x)]
            ms = [int(x) for x in members if re.fullmatch(r'\d+', x)]
            strays = sorted(set(x for x in ms if x < 1 or x > N))
            mdups = sorted(set(x for x in ms if ms.count(x) > 1))
            if junk:
                bad("not applicable", "the not-applicable list (line %d) holds something that is not an entry number: %s" % (ln, ", ".join(junk)))
            if strays:
                bad("not applicable", "the not-applicable list (line %d) names %s, and the entries run 1 to %d" % (ln, ", ".join(str(x) for x in strays), N))
            if mdups:
                bad("not applicable", "the not-applicable list (line %d) names %s twice" % (ln, ", ".join(str(x) for x in mdups)))
            M = len(set(ms))
            if junk or strays or mdups:
                pass  # a broken list implies no subtotal worth comparing
            elif word(M) is None:
                bad("not applicable", "the not-applicable list holds %d entries, and this check spells numbers up to ninety-nine only — extend the spelling map." % M)
            else:
                sites([
                    (r'Never report the ([a-z-]+) as \*absent\*', "the never-report-absent rule"),
                    (r'Reporting ([a-z-]+) absents', "the report-nobody-reads-twice line"),
                    (r'at the top, not ([a-z-]+) times', "the stated-once rule"),
                    (r'so ([a-z-]+) of the [a-z-]+ do not apply', "the not-applicable worked example"),
                    (r'repeating it ([a-z-]+) times', "the report layout's stated-once rule"),
                ], M, "subtotal", "the not-applicable list holds %s entries" % word(M))

        if not out:
            out.append("summary|%s fit-check entries agree with the counts stated over them" % word(N))

print("\n".join(out))
PY
)
FITSUM=''
while IFS= read -r p; do
  [ -n "$p" ] || continue
  case "$p" in
    'summary|'*) FITSUM=${p#summary|}; continue ;;
  esac
  fail "${p%%|*}" skills/fit-check/SKILL.md "${p#*|}"
done <<EOF
$COUNTS
EOF

rm -rf "$BLK"

if [ "$FAIL" -eq 0 ]; then
  echo "schema: $(printf '%s\n' "$SKILLS" | grep -c .) skills load, $N hook blocks parse, three schema copies agree, two trap triggers in two files, $FITSUM — clean"
fi
exit "$FAIL"
