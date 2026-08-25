#!/bin/sh
# dev-path — five assertions on the UX branch's new-surface default: that the
# section states it, that it names the overhead argument it preserves and that
# argument is still on the page, that it carries a stated limit for the case it
# does not cover, that the insertion left the section it was inserted into
# intact, and that it introduced no gate, no mandate and no model-invoked
# artifact.
#
# The reason this file exists is that nothing else can observe this rule. It is
# a recommendation inside a Suggested section that says in as many words
# **Nothing about this can block the gate** and **Suggest the route; never
# require the artifact** — so there is no field to check, no artifact whose
# absence means anything, and no run that can be called non-compliant for
# skipping it. The instruction being on the page, in the section a design
# conversation actually reaches, is the whole of what is enforceable, which is
# the same bound tests/survey-ceiling.sh states about its own subject.
#
# The deletion this guards against is a pruning pass, not a rewrite. The new
# paragraph reads as a qualifier on the trigger blockquote above it, and the
# blockquote alone still reads as a complete rule — an editor who removes the
# qualifier leaves a section that looks whole and answers *would two engineers
# picture the same screen* the way it did before #3, which is the failure the
# rule was written for. Same shape tests/green-instances.sh describes: the
# survivor of the deletion is what makes the deletion invisible.
#
# Assertion 2 is what makes assertion 1 safe rather than merely present. The
# default and the overhead argument are a pair and they fail in opposite
# directions: the default alone reopens the tension the issue fenced off — a
# section recommending an artifact by default beside a paragraph promising the
# branch cannot create overhead — and the overhead argument alone is the change
# reverted. Neither half is worth pinning without the other.
#
# Assertion 3 is anchored on the shape of the never-reached case rather than on
# the phrase *never reaches the branch*, which the overhead paragraph has said
# since 0.1.0. Anchored on the bare phrase this file would have passed against
# the tree before the change, and a test that passes against the defect is not
# a test of anything.
#
# Assertion 5 is the guard on the blast radius rather than on the change. The
# rule moves what the branch recommends, and the cheap way to make a
# recommendation land is to stop it being refusable — a mandate in the section,
# a field at the gate, or a model-invocable dev-path:sketch. All three are out
# of scope by name, and out of scope is not a thing a diff shows you later.
#
# Two calls, both raised in review and neither taken. **A mandate worded
# without the word.** *The artifact is required for a new surface* carries no
# `Mandated` and passes the ban below; what catches it is assertion 4, because
# the sentence it pins — **Suggest the route; never require the artifact** —
# would be sitting on the same page contradicting it, and a section that
# contradicts itself is the thing a reader reports. A grep over *must* and
# *required* would fail on prose that merely quotes the rule. **The literal ban
# is self-defeating in the tests/deviation-tags.sh sense:** a sentence in this
# section promising it adds no `design_approved` would fail the assertion
# enforcing that promise. Accepted — the section has no business naming the
# field either way, and the alternative is a fuzzier grep for a cheaper message.
#
# What no assertion here does is check the wording of any sentence beyond its
# anchor. The prose is the author's; the structure is the test's.
#
# Exit code is the build's.

cd "$(dirname "$0")/.." || exit 1

T=skills/technical-design/SKILL.md
S=skills/sketch/SKILL.md
FAIL=0

for f in "$T" "$S"; do
  if [ ! -f "$f" ]; then
    echo "FAIL subject: $f does not exist"
    exit 1
  fi
done

# The UX branch, from its own heading to the next heading of its own level or
# higher. Ranged on headings rather than line numbers so the span survives the
# section growing, and closed on `# ` and `## ` as well so an assertion scoped
# to this section cannot be satisfied by prose from the next one.
SECTION=$(awk '
  /^### The UX branch/ { on = 1; next }
  on && (/^# / || /^## / || /^### /) { exit }
  on
' "$T")

if [ -z "$SECTION" ]; then
  echo "FAIL subject: $T carries no '### The UX branch' section to read"
  exit 1
fi

# Every anchor below is a sentence fragment, and a sentence rewraps. Matched
# against the section flattened to one line so the assertion is about the prose
# rather than the wrap width — the same reason tests/green-instances.sh gives.
flatten() { tr '\n' ' ' | tr -s ' '; }

# The blockquote markers come off before the flatten, because the trigger is a
# two-line blockquote and every wrap inside it leaves a `> ` sitting mid-
# sentence. Anchoring around the marker would pin the wrap width, which is the
# subject flatten() exists to stop being the subject.
FLAT=$(printf '%s\n' "$SECTION" | sed 's/^>[[:space:]]\{0,1\}//' | flatten)

# want <label> <phrase> <expectation>
want() {
  if ! printf '%s' "$FLAT" | grep -qF "$2"; then
    echo "FAIL [$1] $T's ### The UX branch"
    echo "      expected: $3"
    FAIL=1
  fi
}

# --- 1. The default is stated, in both halves. The two halves fail
#        independently and mean different things: the first is the case the rule
#        is about, the second is what the branch does when it lands on that
#        case. A section keeping only the first names a case and tells nobody
#        what to do with it; keeping only the second recommends the artifact
#        everywhere and is a different rule.
want default 'A new surface has no anchor' \
  'the case the rule is about: a surface that does not exist yet has no anchor'
want default 'so recommend the artifact' \
  'what the branch does on that case: it recommends the artifact rather than skipping it'

# --- 2. The defence it preserves, and the paragraph being preserved. One
#        assertion, because they are one claim in two places: the new sentence
#        says the overhead argument survives, and the overhead argument is what
#        has to be there for that to be true.
want defence 'never how often the branch is reached' \
  'the scope of the new default: it moves the recommendation, not the firing frequency'
want defence 'overhead argument' \
  'the defence named rather than gestured at, so a reader can go and check it'
want defence 'This cannot create overhead' \
  'the overhead argument itself, which the sentence above claims is left standing'

# --- 3. The stated limit, in the idiom the altitude stop above it already uses.
#        Anchored on the never-reached case as this rule states it, for the
#        reason the header gives. Both anchors here and the second one under
#        assertion 1 carry the word on the far side of the negation — `so
#        recommend`, `never reaches` — because an anchor that stops one word
#        short is satisfied by the sentence that says the opposite, and these
#        three sit exactly where a *not* fits.
want limit 'Stated limit' \
  'the limit stated as a limit, the way ### The altitude stop states its own'
want limit 'raises no question about the screen never reaches the branch' \
  'the case not covered: a Design that raises no question never reaches the branch at all'

# --- 4. What the insertion was not allowed to touch. Both halves of the
#        trigger, because a qualifier added under a trigger is one edit from
#        replacing it; both governing sentences, because they are what keeps the
#        recommendation refusable; the craft table's bottom row, which is the
#        row a question about arrangement lands on and so the row this rule
#        sends work to — the other two rows are pinned by nothing here; and the
#        sketch handoff,
#        because a recommendation with no plumbing behind it is advice.
want trigger 'would two competent engineers picture the same screen?' \
  'the trigger question, unchanged'
want trigger 'If yes, nothing physical is needed' \
  'the trigger yes-branch, unchanged — the default qualifies it, it does not replace it'
want governs 'Nothing about this can block the gate' \
  'the no-blocking rule, which the new default is explicitly not allowed to spend'
want governs 'Suggest the route; never require the artifact' \
  'the never-require rule, which keeps a recommendation refusable in one line'
want craft 'only the real runtime' \
  "the craft table's bottom row, which is where an arrangement question has to go"
want craft 'dev-path:sketch' \
  'the handoff to the skill that owns the plumbing'

# --- 5. No gate, no mandate, no model-invoked artifact. The first two are read
#        off the section, the third off the skill the section hands to — the
#        section cannot state that skill's front matter and the front matter is
#        what makes the artifact human-invoked.
if ! printf '%s' "$FLAT" | grep -qF '**Suggested.**'; then
  echo "FAIL [suggested] $T's ### The UX branch no longer opens Suggested"
  echo '      the whole section is Suggested; a default that recommends does not change that'
  FAIL=1
fi

for banned in 'Mandated' 'design_approved'; do
  if printf '%s' "$FLAT" | grep -qF "$banned"; then
    echo "FAIL [no new gate] $T's ### The UX branch has gained $banned"
    echo '      the new default moves a recommendation; it adds no mandate and no field'
    FAIL=1
  fi
done

# A field is the other way a recommendation stops being refusable, and it would
# not land in this section — it would land at the gate, which is a `## ` heading
# away and outside every span above. So the field half is read off the whole
# file: two gate fields exist in this plugin, and a third named anywhere here is
# a gate this change was not allowed to introduce.
FIELDS=$(grep -oE '[a-z_]+_(approved|accepted)' "$T" | sort -u | grep -vxE 'design_approved|intent_accepted')

if [ -n "$FIELDS" ]; then
  echo "FAIL [no new gate] $T names a gate field beyond the two that exist"
  echo '      design_approved and intent_accepted are the whole list; a third is a new gate'
  printf '%s\n' "$FIELDS" | sed 's/^/      found: /'
  FAIL=1
fi

if ! grep -qF 'disable-model-invocation: true' "$S"; then
  echo "FAIL [human-invoked] $S is no longer model-disabled"
  echo '      the artifact stays something a human asks for, however the branch recommends'
  FAIL=1
fi

if ! flatten < "$S" | grep -qF 'Human-invoked. Not a stage.'; then
  echo "FAIL [human-invoked] $S no longer says so in its prose"
  echo '      the front matter and the sentence are one rule in two places'
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "ux-branch-new-surface: a new surface gets the artifact recommended, the overhead argument stands, nothing blocks — clean"
fi
exit "$FAIL"
