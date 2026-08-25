#!/bin/sh
# devpath — three assertions on the pair of green warnings: that both instances
# sit under the deploy-tick-done heading, that they are two different failures
# rather than one written twice, and that README's honesty list carries the
# second one too.
#
# The reason this file exists is that the pair looks like a defect. Two
# blockquotes reading `> **Green is provably not done.**`, one after the other,
# is the shape a pruning pass deletes as duplication, and the deletion would be
# invisible, because either instance alone still reads as a whole warning. They
# are two mechanisms. The first is the platform's check not checking your
# feature, measured at 86.7% coverage over a query on a field that did not
# exist. The second is your own test not checking it, and it is the one that
# cost a real run a correctness bug: a jest suite asserted what the client sent
# and never what the server did with it, while the running org overwrote a
# layout instead of adding one.
#
# Assertion 2 is what makes assertion 1 mean anything. Two instances is a count
# a copy-paste satisfies; two named mechanisms is not. Each is anchored on the
# phrase that carries its own lesson, matched against the section flattened to
# one line. Both the line number and the line break are the wrong subject for
# an assertion about prose, and flatten() is what rules the second one out.
#
# Assertion 3 is the mirror. README's honesty list restates Build's warnings for
# a reader who never opens the skill, and a restatement drifts silently in
# exactly one direction: the skill gains a warning the list never hears about.
# It pins both instances, not only the newer one. Pinning the new instance alone
# would leave the older one available to the same pruning pass this file exists
# to stop, in the one file where nothing else is asserting it.
#
# What no assertion here does is check the wording of either instance beyond its
# anchor. The prose is the author's; the structure is the test's.
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

# The deploy-tick-done section, from its own heading to the next heading of its
# own level or higher. Ranged on headings rather than line numbers so the span
# survives the section growing, and closed on `# ` as well as `## ` because a
# span that runs past a top-level boundary is a looser assertion wearing a
# strict one's message: the anchors below would start matching prose that is not
# in this section at all.
SECTION=$(awk '
  /^## Deploy, then tick/ { on = 1; next }
  on && (/^# / || /^## /) { exit }
  on
' "$B")

# A renamed heading arrives here as an empty span, and an empty span answers
# every assertion below with the same message a deletion gets. Exit rather than
# accumulate, for the reason tests/deviation-tags.sh gives for an unscannable
# subject: the prose may be untouched and sitting under a new heading, and a
# message naming the prose sends a reader to the wrong thing.
if [ -z "$SECTION" ]; then
  echo "FAIL subject: $B carries no '## Deploy, then tick' section to read"
  exit 1
fi

# --- 1. Two instances, both inside that section. Anchored on the whole line so
#        a mention of the phrase in running prose does not count as an instance.
N=$(printf '%s\n' "$SECTION" | grep -cE '^> \*\*Green is provably not done\.\*\*$')
if [ "$N" -ne 2 ]; then
  echo "FAIL [pair] $B carries $N green warnings under the deploy-tick-done heading, expected 2"
  echo '      expected two lines of their own reading: > **Green is provably not done.**'
  FAIL=1
fi

# --- 2. The two mechanisms, each by its own anchor. The first is measured and
#        its number is the anchor. The second is the teachable sentence.
#
#        Matched against the section flattened to one line, because both anchors
#        are sentence fragments and a sentence rewraps. Anchored on a line, a
#        reflow that landed its break mid-phrase would fail a file that had lost
#        nothing — the assertion would be reporting the wrap width rather than
#        the content. flatten() is what makes the phrase the subject.
flatten() { tr '\n' ' ' | tr -s ' '; }

if ! printf '%s\n' "$SECTION" | flatten | grep -q 'scored 86.7% coverage'; then
  echo "FAIL [platform] $B has lost the measured deploy-green instance"
  echo '      expected the 86.7% coverage evidence under the deploy-tick-done heading'
  FAIL=1
fi

if ! printf '%s\n' "$SECTION" | flatten | grep -q 'asserted what the client sent'; then
  echo "FAIL [own test] $B has lost the own-test green instance"
  echo '      expected the jest suite that asserted what the client sent'
  FAIL=1
fi

# --- 3. README's honesty list carries both cases, by the same two anchors.
#
#        Closed on `## ` as well as `### `, so a new section opening above the
#        next sub-heading ends the span instead of being swallowed by it. Not on
#        `# `: README carries `# <Title>` inside fenced artifact templates, and a
#        terminator that matched one would end the span on an example rather than
#        a heading. The two levels that close it here have no fenced instances.
HONESTY=$(awk '
  /^### What verification does and does not reach/ { on = 1; next }
  on && (/^## / || /^### /) { exit }
  on
' "$R")

if [ -z "$HONESTY" ]; then
  echo "FAIL subject: $R carries no '### What verification does and does not reach' section"
  exit 1
fi

if ! printf '%s\n' "$HONESTY" | flatten | grep -q 'scored 86.7% coverage'; then
  echo "FAIL [mirror] $R's verification list has lost the deploy-green case"
  echo '      expected the 86.7% coverage evidence under: ### What verification does and does not reach'
  FAIL=1
fi

if ! printf '%s\n' "$HONESTY" | flatten | grep -q 'asserted what the client sent'; then
  echo "FAIL [mirror] $R's verification list does not name the own-test case"
  echo '      expected a condensed instance under: ### What verification does and does not reach'
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "green-instances: two warnings, two mechanisms, mirrored in README — clean"
fi
exit "$FAIL"
