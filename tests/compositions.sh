#!/bin/sh
# dev-path — one assertion per skill-to-skill composition, asserting the call is
# still written as an imperative naming the skill.
#
# The reason this file exists is a shipped failure. Three of the four
# compositions were imperatives and were followed; the fourth, dev-path:build
# reaching dev-path:critique, was described and never called, and the first real
# spec built seven slices with no critic having read any of them. Nothing in the
# plugin noticed, because the only thing asserting a composition existed was the
# prose that failed to hold one.
#
# Skill-to-skill invocation is model-driven and stays model-driven — this asserts
# that the instruction is present, never that a session followed it. What a
# session did is visible in the artifact, which is the other half and is not a
# test's to make.
#
# Two assertions per file, not one. The imperative alone can ship without the
# softness callout that every call site carries, which is how a reader learns the
# call is not guaranteed at the place they act on it. Counting them against each
# other holds the pairing without naming line numbers that move.
#
# Exit code is the build's.

cd "$(dirname "$0")/.." || exit 1

FAIL=0

# The four compositions: <file> <called skill>. Survey and Slice are both
# technical-design's, which is why the file appears twice.
COMPOSITIONS='skills/technical-design/SKILL.md:survey
skills/technical-design/SKILL.md:slice
skills/build/SKILL.md:critique
skills/integrate/SKILL.md:learn'

for c in $COMPOSITIONS; do
  f=${c%:*}
  skill=${c##*:}
  if [ ! -f "$f" ]; then
    echo "FAIL [$skill] $f does not exist"
    FAIL=1
    continue
  fi
  # The imperative, in either voice: "run the skill" mid-sentence, "Run the
  # skill" opening one. Anything softer than a verb is not a call.
  if ! grep -qE "[Rr]un the skill \`dev-path:$skill\`" "$f"; then
    echo "FAIL [$skill] $f holds no imperative naming dev-path:$skill"
    echo "      expected a line matching: [Rr]un the skill \`dev-path:$skill\`"
    FAIL=1
  fi
done

# Every call site carries the softness callout, so per file the two counts match.
for f in skills/technical-design/SKILL.md skills/build/SKILL.md skills/integrate/SKILL.md; do
  [ -f "$f" ] || continue
  CALLS=$(grep -cE '[Rr]un the skill `dev-path:' "$f")
  SOFT=$(grep -c 'model-driven and is not guaranteed' "$f")
  if [ "$CALLS" -ne "$SOFT" ]; then
    echo "FAIL [callout] $f: $CALLS call site(s), $SOFT softness callout(s)"
    FAIL=1
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "compositions: four calls written as imperatives, each paired with its callout — clean"
fi
exit "$FAIL"
