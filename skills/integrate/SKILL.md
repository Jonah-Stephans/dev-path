---
description: Check a built dev-path spec against its Outcomes and release it to merge. Use when every slice of a spec is done and the work is ready to ship.
---

# Integrate

> **Integrate produces a verdict, never work.** It touches no code, cuts nothing, writes no slice file.

## Refuse first

**This block runs before step 1**, and *refuse first* means **before the first write**. Step 1 writes to
`spec.md` and step 2 runs a script, so a gate refusal arriving at step 3 would already have rewritten
`## Outcome checks` on an ungated spec.

- **`git branch --show-current` returns `main`, `<base>`, or a branch with no matching spec directory**
  → **stop.** Do not guess which spec this is. Say the next act: `git checkout <slug>`.
- **The command returns empty** → **stop, and say what is actually wrong:** it returns empty with exit
  code 0 under a detached HEAD, so the truth is *you are not on a branch*, never *no spec on this
  branch*. The fix is one `git checkout -b <slug>`, and it is a human's.
- **`intent_accepted` is not `true`, or `design_approved` is not `true`** → **stop, naming which.**
  Integrate sits behind **both** gates, and unlike the standalone stage skills it is a command, so
  **nothing has checked either field before it.** The route being closed is a human typing
  `/dev-path:integrate` on a spec that never passed the design gate.
- **The front-matter block does not parse, or a field carries the wrong shape** → **stop and name the
  exact field.**

**Nothing about the work is refused here.** No slice count, no `done` test, no box test, no `fix_cycles`
test — all of those are step 3's, and step 3 is a verdict on the work rather than a check on the route.

**Prefix every message a gate or refusal prints with `dev-path: `.** Suggested.

## The eight steps, in order

**The arming is last because it is the one irreversible act on this list.**

1. Run the Outcomes pass; write `## Outcome checks`.
2. Run the contention script again.
3. **Refuse on an open `- [ ]`, and on a slice carrying `done: true` with no `fix_cycles:` line.**
   Name all three exits on an unmet Outcome.
4. Carry `## Critique findings` and `## Deviations` into the pull request body — **plus every
   `- [x] won't fix` and `- [ ] unmet` line from anywhere in the spec directory.**
5. Offer to file `## dev-path feedback` as an issue. **If it is empty, say the heading exists and file
   nothing.**
6. Name a signal back to the engineer, if anything written down shows one. **If step 5 is also filing, it
   is one issue, not two.**
7. Run `dev-path:learn`.
8. Mark the draft pull request ready and arm auto-merge.

---

## 1 · The Outcomes pass

**One subagent per Outcome. Write `## Outcome checks` on `spec.md`, one line per Outcome, always
written.**

**Dispatch the checkers on the cheapest tier that reliably reads a diff and judges it against a written
statement; the orchestrator stays where it is.** Suggested, with its reason. **Named by the property
first, because a tier name is a model property and this one will move** — Sonnet is the current instance,
and **Haiku is excluded by decision.**

**The reason is this stage's own, and not the one `dev-path:survey` gives for its researchers.** A
checker's job is bounded — one diff against one written statement — which is the cheapest kind of judgment
to get right, where a researcher's is an open-ended read. **What a cheap tier must not be handed here is
breadth, and one checker per Outcome is what leaves it none.** The stakes cut the other way and are why
the tier is suggested rather than mandated: an unmet verdict stops step 3 and reaches the reviewer in the
pull-request body, and a wrong `met` reaches nobody.

**It is the one deliberate exception to *nothing writes a placeholder*** — always written, because
otherwise *nothing was wrong* and *the pass never ran* are indistinguishable. It is not a placeholder:
every line is a real per-Outcome verdict.

```markdown
## Outcome checks
- [x] met — Tolerances configurable per quantity, unit price and total
- [ ] unmet — Bulk update over 200 rows completes without error
```

**`- [ ] unmet` is not a sixth state.** It is a bare `- [ ]` with the shortfall spelled out, so every
check that greps `^- \[ \]` matches it.

**Why one checker per Outcome, where Survey groups.** An Integrate checker reads a known diff against a
known statement, so it is cheap per agent — it has no breadth problem to bound. And grouping here would
concentrate *judgment*: one checker holding four Outcomes writes four verdicts from one reading, at the one
stage where a wrong verdict merges code. Survey's findings feed a human conversation that catches a weak
one; `## Outcome checks` is the last gate.

**Why the pass runs here and not per slice.** On slice 1 of 5 nearly every Outcome is unmet. And it
cannot key on *the last slice done* either: slices can be built in any order and in more than one
session, so two concurrent finishers both observe *everything is done*, both run the pass, and both write
`spec.md`. Integrate runs exactly once per spec by construction — one spec, one pull request — so there
is nothing to count and no condition.

***Isn't that late?* No.** You cannot check whether an Outcome was achieved before the code exists. This
is the earliest possible moment.

> **Integrate rewrites every line of `## Outcome checks` except one marked `won't fix`, which it carries
> forward verbatim and does not re-check.**

Same principle as never writing `false` on a gate field: **the machine does not relitigate a human's
decision.** It is a string check, not a judgment.

## 2 · The contention checkpoint

```sh
sh "${CLAUDE_PLUGIN_ROOT}/scripts/contention.sh"
```

**Show its output verbatim if it printed anything.** It stores nothing, stops nothing, and always exits
0. `${CLAUDE_PLUGIN_ROOT}` is required — a bare relative path resolves against the target repository,
where nothing of the plugin's exists.

## 3 · The refusal, and its three exits

**Step 3 holds two mechanical tests against a fixed grammar, and neither is a model judging.** One is a
grep; the other is a walk over the slice files.

**Test 1 — refuse while any `- [ ]` remains anywhere in the spec directory.** Same test as *Critique
clean* — one grep, section-blind, zero judgment.

**Test 2 — refuse while any slice carrying `done: true` has no `fix_cycles:` line.** Slice writes no such
line at creation and Critique writes `fix_cycles: 0` on its first pass over a slice that has none, so the
line's presence is the slice pass's own trace: **absent on a built slice, the pass never ran on it.**
**`done: true` is the mechanical form of *carries code*** — a slice holding code and no `done: true` holds
an open box, which test 1 already refuses on, so nothing here judges whether a slice built anything.

```sh
for f in dev-path/<slug>/slices/*.md; do
  grep -q '^done:[[:space:]]*true' "$f" && ! grep -q '^fix_cycles:' "$f" && echo "$f"
done
```

**Both patterns are anchored at line start, and that is the whole precision here.** Front matter sits at
byte zero and its fields start their lines, so an anchored match reads the field and never the same string
in a slice's prose — a slice that discusses `fix_cycles:` in its notes must not pass this test on the
mention.

**The next act on test 2 is `dev-path:critique` over the slices this test named.** Its invocation table
routes a human-typed run with no change request on the pull request to exactly that, so a spec that missed
the pass has a specified mode waiting rather than a workaround — and that pass writes the line that clears
this refusal.

**Name the slice pass when the pull request carries a review requesting changes**, because the same table
then routes a human-typed run to the change-request pass instead. That pass triages a reviewer's comments
and need not open the slices named here, so it does not clear this refusal. **Print the slice paths either
way** — they are what the next run is for.

**Why a second test earns its place at a step that was one grep.** An empty `## Critique findings` holds no
box, so test 1 passes a spec no critic ever read and step 4 then carries the empty section into the pull
request body — *nothing was wrong* and *the pass never ran* are otherwise indistinguishable at every check
downstream of Build. Shipping unreviewed slices is exactly the state a human at merge wants named. **And
Build reaching Critique is model-driven**: the imperative is in `dev-path:build` and nothing in the harness
makes it certain, so what catches a skip is the trace, not a louder instruction.

**The cost, said rather than smoothed: step 3 is no longer one grep.** It is a grep and a walk, and *one
grep, zero judgment* is now a claim about `- [ ]` alone.

**What to *do* about a box is section-dependent, and that is not the same as the test.** Under
`## Critique findings` an open box means *fix this*; under `## Deviations` it means *do not proceed until
a human clears it* — **a pause box is never ground on as a fix item.** An unticked `## Acceptance
criteria` box holds Integrate exactly as an open finding does, and **that is intended behaviour rather
than a false positive.**

**A tagged box under `## Deviations` holds this refusal exactly as a pause does**, and the tag names the
decision rather than whether one is owed. `- [ ] excess` is the commit audit's note on files a commit
swept in, closed by hand at merge: `- [x] false positive` where the files were in scope and `touches` was
incomplete, or `- [x] won't fix — <reason>` where they were not.

**On an unmet Outcome, name all three exits.** The question that separates them is **did we fall short of
the target, or was the target wrong?**

| Exit | Means | Where it lands |
| --- | --- | --- |
| **Run `dev-path:build`** | there is work left | Build **cuts a new slice** for the unmet Outcome, builds it, and the deviation is written down |
| **`- [x] won't fix`** | **the Outcome was right. We are shipping without it.** | the ledger — `grep -rn "won't fix" dev-path/`, forever |
| **Rework** | **the Outcome was never what we wanted.** | nowhere. Nothing was shipped short |

**Naming all three is load-bearing:** without it, the way to ship something knowingly unresolved is
invisible to anyone who has not read the design. **And the third exit exists to protect the ledger** —
without it a wrong Outcome walks out through `won't fix` and files a false admission. The ledger's entire
value is that a hit means something.

**Build cuts the slice, never Integrate.** Nothing new is built to make this work: Build already holds
re-cut authority; the new slice is an ordinary slice with the next number, `depends_on` by the normal
rule and `done` absent, so Integrate then refuses for the reason it already refuses. This is not the
routing trap — routing a finding to one of five existing slices is attribution, with N destinations and
judgment about code the model did not write. **Cutting a new slice asks *is there work left*: one
destination, no attribution.**

### Exit 2's line is the human's, by hand

> **`- [x] won't fix — <reason>` on an unmet Outcome is written by the human, by hand, between the
> refused run and the next one. `dev-path` has no other route to it.**

**Say it, because a builder who does not read it will wire a step 3 that tries to write it.** A run admits
no mid-run human input, so a run must end where a human is needed — Integrate cannot name the three
exits, wait, and write the one the human picks, because the run is over at the naming. And re-running
`dev-path:integrate` cannot produce the line either, because step 1 rewrites `## Outcome checks` and
would write the same Outcome unmet again. **Step 1's carry-forward rule is the other half of the
mechanism**, and it only makes sense against a line something else wrote.

**Do not close this with a field.** The three exits are deliberately unstored: a stored exit would put
the ledger's loudest entry behind a flag rather than in front of the reviewer.

### This refusal is a hard exit

**Steps 4 to 8 do not run.** The pull request stays a draft, the feedback offer is not made, Learn does
not run, and nothing is armed. **Say that**, because a builder wiring step 3 as a return and a builder
wiring it as a warning produce two different plugins, and only one of them keeps *Integrate produces a
verdict, never work* true.

### Two nested bounds

A new slice's `fix_cycles` starts at zero while the spec has already been round the loop. **That is not a
bug**, and the reason is worth carrying because the first thing a reader does about it is "fix" it with a
field.

> **The inner loop — Build fixing Critique's findings — is bounded by the cap. The outer loop — Integrate
> refusing, Build cutting a new slice — is bounded by a human typing the command, every single lap.**

Runaway automation has nowhere to live. **No spec-level counter, no aggregation, no new field.**

## 4 · Carry the findings into the pull request body

So the human reviewer is not re-finding what was already caught. Carry `## Critique findings` and
`## Deviations`, **plus every `- [x] won't fix` and `- [ ] unmet` line from anywhere in the spec
directory.**

**Two extra lines by grammar, not two whole sections.** A criterion can close as `won't fix` under
`## Acceptance criteria`, and exit 2 puts one under `## Outcome checks` — but carrying
`## Acceptance criteria` wholesale would put every criterion of every slice in the body, which is the
noise this step exists to reduce. **`- [ ] unmet` rides with it because it is the same line's other
half:** the reviewer needs the shortfall next to the decision to ship without it. **`- [ ] excess` needs no
line of its own** — its sibling in the grammar sits under `## Deviations`, which rides whole.

## 5 · Offer to file `## dev-path feedback`

The engineer writes `## dev-path feedback` on `spec.md` at the moment of friction — optional, ungated,
absence normal. Read it, show a draft issue, and **on confirmation** run:

```sh
gh issue create --repo Jonah-Stephans/dev-path
```

**Using the engineer's own credentials.** No credential is stored anywhere.

**If the section is empty, name the heading in one sentence and file nothing.** That single sentence is
the only prompt this channel has, and it is the whole of it — **no draft, no suggested content, no second
ask**, because an agent proposing the engineer's own feedback turns a mirror into a critic.

> **Say why this is not the tracker returning.** The settled constraint is about the **context store**:
> nothing in the machinery reads or writes a tracker, and no gate is blocked on one. This channel is
> **write-only, off-workflow, human-initiated and human-confirmed.**

## 6 · Name the signal back

**Only when what is written down actually shows something.** Report the observation, never the diagnosis.

> *"Build re-cut 3 of 4 slices on this spec — that's a signal about the cutting rule. File it?"*

**Four bounds, and the fourth is the one that matters:**

1. **Fires only here**, once per spec. Never mid-run.
2. **Fires only when the written trace shows something.** No deviation, no fix cycles, no re-cut ⇒ **say
   nothing.** That is most specs, and silence in the common case is what stops this becoming noise the
   engineer learns to dismiss.
3. **Draft it; the human confirms and sends**, with their own `gh`. Never file unilaterally.
4. **Report the observation, never the diagnosis.** *"Build re-cut 3 of 4 slices"* is data; *"the cutting
   rule is wrong"* is a conclusion only the maintainer draws. **An agent editorialising about the design
   off a single spec is the actual failure mode**, and restricting this to naming what the fields already
   say makes it a mirror rather than a critic.

**Zero new fields; every input already exists.** What is readable here is a re-cut written under
`## Deviations`, a slice that hit the cap in `fix_cycles`, and an accepted intent on a spec that died —
`intent_accepted: true` plus a closed-unmerged pull request. A recorded assumption that turned out wrong
is **not detectable here**: what is written down holds the assumption, and whether it was wrong is
learned weeks later.

**Steps 5 and 6 both file on the same repo, so when both fire it is one issue, not two.** **Keep the two
contributions separate inside the body** — the engineer's words as they wrote them, this step's
observation as data — because merging the voices breaks bound 4.

## 7 · Learn

**Run the skill `dev-path:learn` against this spec, before step 8 arms the merge.**

> **This is model-driven and is not guaranteed.** There is no call syntax and no event that fires on a
> skill finishing. Claude reads this instruction and normally follows it, and nothing in the harness makes
> it certain. **Do not write *cannot be forgotten*** — that is a guarantee this design does not have. A
> repo that wants it guaranteed adds a `Stop` hook of its own; `dev-path` ships none and depends on none.

**It runs before the arming, and the order is deliberate.** Arming auto-merge is irreversible: on a pull
request already carrying its approval, a required check that finishes fast can merge it while a later
step is still running. **Nothing is lost by running Learn first** — its two available inputs are
`dev-path`'s own files, `## Critique findings` and `## Deviations`, and both are complete before this
command started. Learn reads nothing the ready transition produces.

## 8 · Mark ready, then arm auto-merge

**Mandated. Two commands, and one this skill must never use.**

```sh
gh pr ready <number>
```

Then arm auto-merge. GraphQL identifies a pull request by node id rather than by number, so resolve the
id first:

```sh
pr_id=$(gh pr view <number> --json id -q .id)

gh api graphql -f query='
  mutation($pr: ID!) {
    enablePullRequestAutoMerge(input: {pullRequestId: $pr}) {
      pullRequest { number autoMergeRequest { enabledAt } }
    }
  }' -F pr="$pr_id"
```

**Read `autoMergeRequest.enabledAt` back and report it.** A non-null value is the only evidence the
setting took, and a silently ineffective arming is indistinguishable from a working one until a spec
merges without CI.

> **`dev-path` never runs `gh pr merge --auto`, anywhere, for any purpose.**

**Why, and it is the sharpest rule in this body.** `gh pr merge --auto` calls the auto-merge mutation only
when the pull request is *not already immediately mergeable* — so on a `CLEAN`, `HAS_HOOKS` or `UNSTABLE`
pull request **it performs a real merge.** On a repo whose base branch is unprotected, the pull request is
`CLEAN` the moment it leaves draft, and **step 8 is the first moment CI runs on this pull request at
all** — so `--auto` merges it immediately with no review and no CI. **The one deploy in a spec's life that
can fail on a dangling reference is skipped by the command meant to schedule it**, and a repo missing
branch protection would get a worse outcome from `dev-path` than from doing nothing.

**The mutation cannot merge.** It sets a setting; the merge happens later, when GitHub's own conditions
are met, or never. **Do not use a command that might do the thing to arrange for the thing.**

**`dev-path` passes no merge method and takes the repo's default.** The plugin holds no opinion about a
repo's history, the same posture as holding no org name. One consequence, so Build is not misread:
whether one code commit per slice survives to the base branch depends on that default, and Build's
per-slice argument is about attribution **on the branch and in the pull request**, never a requirement on
the base branch.

**Confirm both commands on first use rather than assume them.** They are documented GitHub behaviour that
this plugin has not yet exercised, and the confirmation costs one pull request on a scratch repo.

## What step 8 releases, and what Integrate does not own

**Marking the pull request ready is what releases the whole-spec deploy against a fresh org** — one fresh
org, the whole spec as one payload, an explicit test level. That is the **second** of the two orgs a spec
costs; the first is the engineer's own scratch org that Build deployed each slice into. This one is
different in the two ways that matter: it is the whole spec as one payload, and the org holds none of it
already, so references resolve against org state ∪ payload rather than against an org carrying an earlier
deploy of the same spec.

**`dev-path` does not run it.** It is the repo's own deploy gate, and CI not running on draft pull
requests is what puts it here rather than earlier. What `dev-path` contributes is the timing and the
precondition — never the workflow.

**Nobody owns integration order.** Arrival order: mark ready, arm auto-merge, a reviewer approves, GitHub
merges. **This body contains no ordering, no *Update branch* step and no merge-queue assumption.** Two
specs ready at once both merge, in whatever order they finished — and two specs each green alone can break
the base branch together with no textual conflict, which the repo's own post-merge workflow catches and
somebody fixes forward.

## Stop

Report what was written, what was filed, and that auto-merge is armed. **Human actions per spec from here:
one approval, which branch protection already required.** Nobody clicks Merge.
