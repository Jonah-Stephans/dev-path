#!/bin/sh
# dev-path — three assertions on the commit-excess tag: that Build writes it in a
# shape a run can copy, that README's grammar table defines it, and that nothing
# mechanical reads it.
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

# --- 1. Build writes the tag, anchored at line start. Build owns the audit, so
#        Build is the only place the tag can be mandated. Anchored, and matched
#        against the worked example rather than the mandating sentence, for two
#        reasons: the example is the shape a run copies, and it is the half that
#        proves `^- \[ \]` still matches the box — a tag that pushed the box off
#        the line start would silence every check in the plugin at once. A
#        sentence rewraps; a fenced line does not.
if ! grep -qE '^- \[ \] excess — ' "$B"; then
  echo "FAIL [writer] $B carries no worked example of the tagged box"
  echo "      expected a line of its own opening with: - [ ] excess — "
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
#
#        In the executable files every line is code, so those are scanned whole.
#        This file is the one exclusion and the reason is the same one
#        tests/retired-words.sh gives for excluding itself: it carries the tag as
#        a literal, and a test that cannot pass against a compliant plugin gets
#        deleted. Both subject lists are counted, because a glob that matched
#        nothing would otherwise pass this assertion silently.
PROSE=$(ls "$R" skills/*/SKILL.md 2>/dev/null)
CODE=$(ls scripts/*.sh .github/workflows/ci.yml tests/*.sh 2>/dev/null | grep -v '^tests/deviation-tags\.sh$')
PN=$(printf '%s\n' "$PROSE" | grep -c .)
CN=$(printf '%s\n' "$CODE" | grep -c .)

if [ "$PN" -ne 11 ] || [ "$CN" -ne 5 ]; then
  echo "FAIL subject: expected 11 prose files and 5 executable files, found $PN and $CN"
  FAIL=1
fi

READERS=$(
  awk '
    FNR == 1 { fence = 0 }
    /^```/   { fence = !fence; next }
    fence && /excess([^a-z]|$)/ && /grep|awk|"command"/ { print FILENAME ": " $0 }
  ' $PROSE
  grep -nE 'excess([^a-z]|$)' $CODE
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
