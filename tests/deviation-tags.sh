#!/bin/sh
# dev-path — three assertions on the commit-excess tag: that Build writes it, as
# an instruction and as a shape a run can copy, that README's grammar table
# defines it, and that nothing mechanical reads it.
#
# The reason this file exists is an ambiguity the first real spec produced. Two
# slices on one branch each carried an open `- [ ]` under `## Deviations`. On
# slice 07 it meant *this slice does not proceed until a human answers*; on slice
# 01, written after `done: true`, it meant *this commit swept in a lockfile,
# somebody should say whether that was fine*. Same section, same three
# characters, opposite urgency, and both open on the same draft pull request.
# Telling them apart meant joining the box to `done` in the front matter — which
# every check does correctly and no human skimming seven slice files does at all.
#
# The tag is the fix, and it is worth a test because it is prose in one file
# defined by prose in another: Build can stop writing `excess` while README still
# advertises it, and neither file's own reader would notice.
#
# The third assertion is the one that keeps the fix cheap. `- [ ] excess` is the
# same open box with its shortfall named, exactly as `- [ ] unmet` is, so every
# existing check still matches it and no new check exists. The moment something
# mechanical reads the tag word, the tag has become a sixth state and the frozen
# test has two answers.
#
# What no test here does is run the freeze hook against a slice carrying the tag.
# That hook is untouched by this design and the tag gives it nothing to read,
# which is the whole claim assertion 3 holds.
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

# --- 1. Build writes the tag, in both halves of the slot. Build owns the audit,
#        so Build is the only place the tag can be mandated, and the two halves
#        fail independently: the mandating sentence is what a run acts on, the
#        worked example is the shape it copies. Held apart so the message names
#        which one went — the mandate can revert to a bare box while the example
#        under it still reads correctly, and it is the mandate that is the rule.
#
#        The example is anchored at line start, which is also the half that
#        proves `^- \[ \]` still matches the box — a tag that pushed the box off
#        the line start would silence every check in the plugin at once. A fenced
#        line does not rewrap, so it can be anchored; the mandate is prose, so it
#        is matched on its opening words instead.
if ! grep -qE '^- \[ \] excess — ' "$B"; then
  echo "FAIL [writer] $B carries no worked example of the tagged box"
  echo "      expected a line of its own opening with: - [ ] excess — "
  FAIL=1
fi

if ! grep -qF 'one `- [ ] excess — ' "$B"; then
  echo "FAIL [writer] $B does not mandate the tag at the audit slot"
  echo '      expected the instruction to read: one `- [ ] excess — <...>`'
  FAIL=1
fi

# --- 2. README's marker table defines it. The table is where a human reading a
#        slice file looks the marker up, and a tag nobody can look up is noise in
#        the diff rather than a distinction. Asserted as a table row rather than a
#        mention, because the mention already exists in prose.
if ! grep -qE '^\|[^|]*`- \[ \] excess`[^|]*\|' "$R"; then
  echo "FAIL [grammar] $R carries no marker-table row for the tag"
  echo '      expected a table row whose marker cell holds: `- [ ] excess`'
  FAIL=1
fi

# --- 3. Nothing mechanical reads it, over both places a reader could live.
#
#        In the prose files a check is always inside a fence — the hook menu's
#        json blocks and the sh blocks Integrate and CI run — so the scan is
#        fence-aware and skips prose entirely. That is deliberate: README's own
#        table says "every check greps `^- \[ \]`" on the same line as the tag,
#        and a scan that read prose would fail on the sentence stating the rule
#        it is enforcing. Inside a fence it flags only code-shaped lines, so the
#        worked example of the artifact passes and a grep over it does not.
#        Code-shaped names the tools this plugin's checks are actually written in
#        rather than the two that were easiest to think of: the hook menu alone
#        runs on jq, sed and case, so a filter naming only grep and awk would let
#        a reader written in any of them through the one assertion that exists to
#        stop exactly that.
#
#        In the executable files every line is code except a comment, and the
#        comments are skipped. A comment mentioning the tag is explanation rather
#        than a reader, and these files run a quarter to a half comment by line,
#        so a whole-file scan would fail on the next header that explains the
#        rule. This file is the one whole exclusion and the reason is the same
#        one tests/retired-words.sh gives for excluding itself: it carries the
#        tag as a literal, and a test that cannot pass against a compliant
#        plugin gets deleted.
#
#        Both subject lists are counted, because a glob that matched nothing
#        would otherwise pass this assertion silently — but counted as a floor
#        rather than an exact number. `tests/*.sh` is one of the globs and this
#        repo adds a test per change, so an equality here fails the next
#        unrelated test file with a message about counts and nothing about the
#        tag. This guard exits rather than accumulating into FAIL, as the
#        subject-existence check above it does: a list this cannot scan makes
#        every assertion under it meaningless, and an empty one would leave the
#        grep below reading stdin, which hangs a CI job instead of failing it.
PROSE=$(ls "$R" skills/*/SKILL.md 2>/dev/null)
CODE=$(ls scripts/*.sh .github/workflows/ci.yml tests/*.sh 2>/dev/null | grep -v '^tests/deviation-tags\.sh$')
PN=$(printf '%s\n' "$PROSE" | grep -c .)
CN=$(printf '%s\n' "$CODE" | grep -c .)

if [ "$PN" -lt 11 ] || [ "$CN" -lt 4 ]; then
  echo "FAIL subject: expected at least 11 prose and 4 executable files, found $PN and $CN"
  exit 1
fi

READERS=$(
  awk '
    FNR == 1 { fence = 0 }
    /^```/   { fence = !fence; next }
    fence && /excess([^a-z]|$)/ && /grep|awk|sed|jq|case|rg|"command"/ { print FILENAME ": " $0 }
  ' $PROSE
  grep -nE 'excess([^a-z]|$)' $CODE | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#'
)

if [ -n "$READERS" ]; then
  echo "FAIL [no new state] something mechanical reads the tag word"
  echo "      every check matches '^- [ ]' and none reads a tag"
  printf '%s\n' "$READERS" | sed 's/^/      /'
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "deviation-tags: Build writes the tag, README defines it, no check reads it — clean"
fi
exit "$FAIL"
