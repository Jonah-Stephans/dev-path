#!/bin/sh
# devpath — six assertions on the commit audit when the commit is a pause's:
# that the audit slot is still unconditional, that no statement of the retired
# `done: true` precondition survives in any prose file, that the tag alone now
# carries the distinction at each site that used to name it, that the shape a
# human meets first — two open boxes on one paused slice — is drawn, that the
# window a cleared pause leaves behind is stated wherever a run could walk into
# it, and that the two sentences pointing at `done` were left pointing there.
#
# The reason this file exists is that #28 permitted a pause to commit and left
# staging alone, so `git add -A` on a pause can sweep a stray file and the audit
# writes its box on a slice carrying no `done: true`. Eight sentences in five
# files said that could not happen, two of them by naming a mechanism: that the
# frozen test does not catch the box *because* the box is written after
# `done: true`. On a pause commit the frozen test does catch it and still answers
# *frozen*, because the untagged pause box is open beside it — the right answer
# for a reason those sentences no longer give. A rule whose stated mechanism is
# false is one edit from being applied where it does not hold, which is what
# assertion 2 is for and what the other four are protecting.
#
# The precondition was never doing the work. `excess` names the shortfall in the
# box itself, and the sentence that leaned hardest on `done` said so three words
# later: *which a human reads off the tag*. What the precondition described was
# the only case that existed before #28.
#
# Assertion 1 is the guard on the two routes this fix rejected. Conditioning the
# audit on a `done: true` return would make all eight sentences true again, at
# the cost of the guarantee the audit exists for — `git add -A` cannot lose work,
# and a pause commit that swept a sibling's file would then say nothing. Skipping
# the audit while keeping `git add -A` is worse: the files are committed and
# nothing records that they were out of scope. Either shows up in the one
# sentence that must not carry a `done`.
#
# What no assertion here reads is the tag word, in either direction. Assertion 4
# reads that a box carries *a* tag — one lowercase word before the em dash —
# which is the shape, not the word. tests/deviation-tags.sh owns the word, and
# its third assertion is that nothing mechanical reads it; a second test reading
# it would be that assertion's counterexample rather than a check.
#
# That file's header is deliberately not a subject here. Its `:9` and `:12` state
# the precondition in the past tense, about the two slices that produced the tag,
# and on that run `done` did separate the two boxes. It is history, and history
# is what a header comment is for — the same reading #31 arrived at before this
# was implemented.
#
# Exit code is the build's.

cd "$(dirname "$0")/.." || exit 1

B=skills/build/SKILL.md
R=README.md
T=skills/technical-design/SKILL.md
C=skills/critique/SKILL.md
I=skills/integrate/SKILL.md

# POSIX ERE has no \b. These bracket the word with a non-word character or an
# anchor, which is portable where \b and [[:<:]] are not — the same pair, for the
# same reason, as tests/retired-words.sh.
L='(^|[^[:alnum:]_])'
Rx='([^[:alnum:]_]|$)'

FAIL=0

for f in "$B" "$R" "$T" "$C" "$I"; do
  if [ ! -f "$f" ]; then
    echo "FAIL subject: $f does not exist"
    exit 1
  fi
done

# Every anchor below is a sentence fragment, and a sentence rewraps. Matched
# against the file flattened to one line so the assertion is about the prose
# rather than the wrap width — the same reason tests/pause-commits.sh gives.
flatten() { tr '\n' ' ' | tr -s ' '; }

BUILD=$(flatten < "$B")

# --- 1. The audit slot mandates the box on any commit excess, and names no
#        `done`. Both halves are the assertion: a slot that still stands but
#        gated is route 1, a slot that has gone quiet is route 3, and the second
#        half is only meaningful while the first holds.
#
#        Scoped to the slot rather than to the file, because Build says
#        `done: true` a dozen times for good reasons and a file-wide ban would
#        fail on all of them. The slot is the one sentence that sets the box's
#        shape, so a route that gated the audit has to edit it.
#
#        The span opens a paragraph *before* the slot, at the sentence arguing
#        what the commit buys. A span opening on the slot's own first words is
#        escapable by the route it exists to stop: `The audit runs only where the
#        worker returned `done: true`. Stage with `git add -A`, and any commit
#        excess...` gates the audit without putting a `done` inside the slot, and
#        reads clean. That paragraph carries no `done` today and has no reason
#        to, and it is where a gate would have to go to still read as prose.
#
#        Cut with index() rather than a greedy `sed`, and required to be
#        non-empty. `sed 's/.*A//; s/B.*//'` reads *last* A to *first* B, so a
#        second copy of either phrase silently relocates the span, and anchors in
#        the wrong order hand the whole file tail to a check for one word. The
#        empty guard exits rather than accumulating, as the subject check above
#        it does: a span this cannot cut makes the assertion under it meaningless.
if ! printf '%s' "$BUILD" | grep -qF 'Stage with `git add -A`'; then
  echo "FAIL subject: $B no longer stages with git add -A at the audit slot"
  exit 1
fi

if ! printf '%s' "$BUILD" | grep -qF "against the slice's declared scope is recorded as one"; then
  echo "FAIL [unconditional] $B no longer mandates the box on any commit past the slice's scope"
  echo '      a pause commits, and a pause that swept a sibling file must say so'
  FAIL=1
fi

SLOT=$(printf '%s' "$BUILD" | awk -v a='What the commit buys is the work' -v b="place the box's shape is set" '
  {
    i = index($0, a)
    j = index($0, b)
    if (i > 0 && j > i + length(a)) print substr($0, i + length(a), j - i - length(a))
  }')

if [ -z "$SLOT" ]; then
  echo "FAIL subject: $B carries no audit slot to read — its two anchors are gone or out of order"
  exit 1
fi

if printf '%s' "$SLOT" | grep -qE "${L}done${Rx}"; then
  echo "FAIL [unconditional] $B has gated the commit audit on the slice's state"
  echo '      the audit runs on any commit, and a pause commits — a gate here is a'
  echo '      pause that sweeps a sibling file and records nothing'
  printf '      %s\n' "$SLOT"
  FAIL=1
fi

# --- 2. No statement of the retired precondition is left, over every prose file
#        rather than over the five that carried one. Four of the eight sites were
#        not named by the issue that filed this and one was not named by the
#        review that found those four, which is the argument for scanning the
#        whole estate: the sentence reads as background description, and any
#        file's author can restore it while editing something adjacent.
#
#        Named one literal per line rather than one pattern over the idea,
#        because the message has to say which file and which form: the eight
#        sites sit in five skills' worth of argument and the fix for each is
#        local to it. The subject list is counted as a floor for the reason
#        tests/deviation-tags.sh gives — a glob that matched nothing would
#        otherwise pass this silently, and this repo adds files.
RETIRED='written *after* `done: true`
on a slice that already carries `done: true`
on a slice that already finished
written after the slice finished'

# The four above are the forms that were actually here. These three are the same
# claim reworded, and they are here because the argument for scanning the whole
# estate is that the sentence reads as background description — and somebody
# restoring background description from memory paraphrases it. Neither list is a
# decision procedure for *is this the precondition*; together with assertion 3's
# positive anchors they are a net, and the net is what a check of prose can be.
#
# `on a finished slice` is deliberately not among them. README says it of a box
# under `## Critique findings`, where a finished slice is exactly the point. The
# two live `on a slice that carries code` sentences about `fix_cycles` are why
# the first pattern requires a completion token after `carries` rather than
# stopping at the verb.
RETIRED_RX='on a slice that (already )?(carries `?done|carried `?done|finished|completed|is done|was done|has finished)
written \*?after\*? [^.]{0,40}(done|slice (finished|completed))
after the slice (finished|completed|was done|is done)'

PROSE=$(ls "$R" skills/*/SKILL.md 2>/dev/null)
PN=$(printf '%s\n' "$PROSE" | grep -c .)

if [ "$PN" -lt 11 ]; then
  echo "FAIL subject: expected at least 11 prose files, found $PN"
  exit 1
fi

for f in $PROSE; do
  FLAT=$(flatten < "$f")
  HITS=$(
    printf '%s\n' "$RETIRED" | while IFS= read -r form; do
      [ -n "$form" ] || continue
      printf '%s' "$FLAT" | grep -qF "$form" && printf '%s\n' "$form"
    done
    printf '%s\n' "$RETIRED_RX" | while IFS= read -r rx; do
      [ -n "$rx" ] || continue
      printf '%s' "$FLAT" | grep -oE "$rx"
    done
  )
  if [ -n "$HITS" ]; then
    echo "FAIL [retired] $f has restored the precondition on the commit audit"
    echo '      a pause commits, and its audit writes the box on a slice with no `done: true`'
    printf '%s\n' "$HITS" | sed 's/^/      found: /'
    FAIL=1
  fi
done

# --- 3. The tag carries the distinction, at every site that used to name the
#        precondition. One anchor per site rather than per file: the three in
#        Build are the ambiguity argument, the closing rule and the pause test,
#        and they fail independently because a run acting on any one of them
#        never reads the other two. The three in the stage skills are the ones
#        with teeth — a `devpath:technical-design` session clearing a pause is
#        the actor that meets both boxes on one slice, a critic is the actor that
#        must leave the tagged one alone, and Integrate is what carries the
#        section onto the pull request.
#
#        Two of these anchors are worded narrowly on purpose. `done: true` does
#        settle one direction — a done slice's open box under `## Deviations` is
#        never a pause, which is the rule Build keeps and README's freeze block
#        implements — so what the fix retired is the claim that the *absence* of
#        `done` settles the other. An anchor reading "`done` does not separate
#        them" would pin the overshoot.
ANCHORS="$B|does not always tell you which
$B|the pause box is there beside it
$B|the tag tells them apart wherever they land
$R|A pause commit can write that box too
$T|The slice you are clearing can carry both
$C|review is exactly where it gets closed
$I|the commit audit's note on files a commit swept in"

MISSES=$(
  printf '%s\n' "$ANCHORS" | while IFS='|' read -r f frag; do
    [ -n "$frag" ] || continue
    flatten < "$f" | grep -qF "$frag" || printf '%s — %s\n' "$f" "$frag"
  done
)

if [ -n "$MISSES" ]; then
  echo "FAIL [tag carries it] a site that named the precondition says nothing in its place"
  echo '      the tag is what tells a pause box from the audit box; each line below is'
  echo '      the file and the fragment it no longer holds'
  printf '%s\n' "$MISSES" | sed 's/^/      /'
  FAIL=1
fi

# --- 4. The pair is drawn. Two open boxes under one `## Deviations`, one
#        untagged and one tagged, is the artifact a human meets before any prose
#        about it, and before this change it could not exist. Read as a fenced
#        block so it is the worked example that is asserted and not a sentence
#        describing one. A floor and not exactly one, for the reason the subject
#        counts above are floors: a second worked example is a thing this repo
#        might legitimately grow, and failing that with a message about counts
#        would say nothing about the pair.
#
#        A tagged box is a box whose first word is followed by an em dash; the
#        untagged one is any other open box. That reads the shape rather than the
#        word, which is the line tests/deviation-tags.sh draws. The fence cannot
#        show the absence of `done: true` — front matter is not in it — so what
#        carries *paused* here is the untagged box, which is what carries it in a
#        real slice file too.
#
#        The per-fence reset is load-bearing rather than general: Build draws
#        three separate `## Deviations` fences, and without it the tagged box in
#        the audit's example and the untagged box in the pause's would satisfy
#        this assertion between them while no file drew the pair. An unclosed
#        final fence is evaluated at END for the same reason — a missing back
#        fence is a broken file, and failing with *no pair drawn* when the pair is
#        there would send somebody to the wrong line.
if ! awk '
  /^```/ {
    if (fence && dev && bare && tagged) { found = 1 }
    if (fence) { dev = 0; bare = 0; tagged = 0 }
    fence = !fence
    next
  }
  !fence { next }
  /^## Deviations$/    { dev = 1; next }
  /^- \[ \] [a-z]+ — / { tagged = 1; next }
  /^- \[ \] /          { bare = 1 }
  END {
    if (fence && dev && bare && tagged) { found = 1 }
    exit !found
  }
' "$B"; then
  echo "FAIL [worked example] $B draws no paused slice carrying both boxes"
  echo '      expected one fenced ## Deviations block with an untagged open box'
  echo '      and a tagged one under it'
  FAIL=1
fi

# --- 5. The window a cleared pause leaves behind is stated at all three sites a
#        run could walk into it. Closing the pause box does not close the tagged
#        one — that disposition is the human's at merge — so from the clearing
#        until `done: true` the slice carries no `done` and an open box under
#        `## Deviations`. That is the frozen test's *frozen*, and it is hook
#        block 3's `is frozen and needs a human` on the dispatch of any sibling.
#
#        Nothing mechanical can tell that state from a real pause without reading
#        the tag, and reading the tag is the one thing tests/deviation-tags.sh
#        forbids. So what closes the window is a rule about order — the cleared
#        slice is built next, and block 3 never denies the slice it is being
#        asked to dispatch — and a rule about order is worth only the files that
#        state it. Build owns dispatch, technical-design is where the clearing
#        happens, and README's block 3 is the paste whose message is wrong for
#        as long as the window is open.
WINDOW="$B|the cleared slice is the next slice this run builds
$T|name the slice as the next one to build
$R|once a pause is cleared it is wider than the truth"

GAPS=$(
  printf '%s\n' "$WINDOW" | while IFS='|' read -r f frag; do
    [ -n "$frag" ] || continue
    flatten < "$f" | grep -qF "$frag" || printf '%s — %s\n' "$f" "$frag"
  done
)

if [ -n "$GAPS" ]; then
  echo "FAIL [cleared-pause window] a site is silent on the slice a cleared pause leaves"
  echo '      the tagged box outlives the pause, so the slice reads frozen until `done: true`;'
  echo '      each line below is the file and the fragment it no longer holds'
  printf '%s\n' "$GAPS" | sed 's/^/      /'
  FAIL=1
fi

# --- 6. What this change was not allowed to touch, pinned where nothing else
#        pins it. tests/pause-commits.sh holds the frozen test's two halves, so
#        what is held here is the joint: the sentence saying that test reads
#        `done` and not the tag. Dropping the precondition from the prose around
#        it and then letting the test read the tag would make the tag a sixth
#        state, which is the one outcome both files exist to prevent.
#
#        README's freeze block is pinned on the field it reads. The block itself
#        is correct as written — a paused slice carries no `done: true`, so
#        nothing is skipped and the push is denied, which is what a pause wants —
#        and this change is prose-only above it.
if ! printf '%s' "$BUILD" | grep -qF 'joins on `done` rather than reading the tag'; then
  echo "FAIL [reads done] $B no longer says the frozen test joins on \`done\`, not the tag"
  echo '      a tag is prose a run can forget; `done: true` is mechanical'
  FAIL=1
fi

if ! grep -qF "grep -q '^done: true\$'" "$R"; then
  echo "FAIL [reads done] $R's freeze block no longer reads the \`done: true\` field"
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "audit-on-pause: the audit is unconditional, the tag carries it, the pair is drawn, the window is named — clean"
fi
exit "$FAIL"
