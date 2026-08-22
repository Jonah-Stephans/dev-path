---
description: Build the slices of an approved dev-path spec into code and tests. Use once a design is approved and its slices are cut.
---

# Build

`dev-path:build` loops Build ↔ Critique over the spec's slice list in `depends_on` order. This body has
two halves: **the orchestrator's instructions**, which is what the main session does, and **the worker
prompt**, which is what each dispatched subagent is told.

## Refuse first

Read the front matter of `dev-path/<slug>/spec.md`, then of every slice file. That read is the validation
— there is no separate front-matter check anywhere in `dev-path`, because a read the router needs in order
to route cannot be disconnected.

- **`git branch --show-current` returns `main`, `<base>`, or a branch with no matching spec directory**
  → **stop.** Do not guess which spec this is. Say the next act: `git checkout <slug>`.
- **The command returns empty** → **stop, and say what is actually wrong:** it returns empty with exit
  code 0 under a detached HEAD, so the truth is *you are not on a branch*, never *no spec on this
  branch*. The fix is one `git checkout -b <slug>`, and it is a human's.
- **`design_approved` is not `true`** → **stop.** Build runs behind gate 2. Say the next act: run
  `dev-path:technical-design` and take the design through its gate.
- **Zero slice files** → **stop.** Say the next act: run `dev-path:slice` against the approved design.
- **A slice's `depends_on` does not parse, or the front-matter block does not parse, or a field carries
  the wrong shape** → **stop and name the exact field and the slice.** *Malformed* stops the stage;
  *absent* is a legal state meaning *not yet*, and `done` and `fix_cycles` are legitimately absent on a
  new slice.
- **A slice's `depends_on` holds a slice that is not `done`** → **refuse and name the slice.** A
  structural check on a field that already exists, not a gate.
- **A `touches` path that does not resolve** → **record a deviation and carry on.** Do not refuse: a
  sibling spec may legitimately have moved or deleted the file since Slice ran, and refusing here would
  fail this spec for a condition its author did not cause and cannot meaningfully fix.

**Prefix every message a gate or refusal prints with `dev-path: `.** Suggested — two enforcement layers
with overlapping symptoms are otherwise indistinguishable, and a human reading a stop should know which
plugin stopped them.

---

# The orchestrator

**The main session is the orchestrator, and it re-derives its place from the spec directory, never from
its own conversation. One subagent per slice built, one per fix pass, one per review pass — a subagent
*is* a fresh context, and it is the only kind a running skill can produce, since a session cannot reset
its own context. Every worker is fresh and none is ever resumed, including one whose pause a human
cleared.**

**Why re-derive from disk.** The measured failure of conversation-held orchestrator state is specific and
expensive: controllers that lost their place have re-dispatched entire completed sequences of work.
`dev-path` already holds the right things — `done` per slice, `fix_cycles`, `## Critique findings`,
`## Deviations` — in a committed directory.

## Worker lifecycle

| Agent | Lifecycle |
| --- | --- |
| Build, per slice | fresh subagent |
| **Build, per fix pass** | **fresh** |
| **Critique, per pass** | **fresh, always** |
| Build, after a human clears a pause | **fresh. No worker is ever resumed.** |

**Suggested, with its reason**, because this line is a model property that has already moved once.

**The reason is context rot, and it is not the thing newer models fixed.** *Context anxiety* — models
wrapping up prematurely near a perceived limit — is fixed. Context rot is not going away: recall
**decreases** as tokens rise against an attention budget, performance **degrades as the window fills**,
and context windows of all sizes are subject to context pollution. **A bigger window is explicitly not
the answer, which is what would retire this line.**

**The trade-off, stated: resume buys the *reasoning* and pays for the *tool output*, and the two arrive
welded together.** On Salesforce the tool output — file reads, deploy logs, test runs — is the expensive
half. **And compaction discards the valuable half first:** specific instructions from early in the
conversation may not be preserved, and the slice brief is earliest in the transcript. So past the first
compaction a resumed Build holds the expensive half, has lost the valuable one, and has an auto-generated
lossy summary where a fresh Build would read the curated statement on disk.

**Two more reasons native to this design.** A fix pass is not an exploration — its input is a named list
of confirmed findings, so the thing resume buys is worth least exactly where its cost is highest. And a
fresh Build is what keeps the spec honest: the quality bar for the spec is *could a fresh session pick
this up from the spec alone?*, and if Build resumes, nothing on the hot route ever exercises that.

**Never resume an agent into a role that judges its own prior output.** Critique always judges; Build
never does. That governs the critic. **What governs the builder is context rot, not contamination** — two
rules, two reasons, and neither is the other's corollary. The measured failure of a resumed judge is
silent: one fix round shipped a correctness defect plus the test blessing it, and the resumed session
passed both with zero findings.

**And say it once: nothing depends on worker lifecycle for correctness, only for cost.** The ladder is
resume → return early and respawn → the human re-runs the command, and the engineer's seat is identical
at every rung.

**No named agent definitions.** Workers are the generic subagent with an inline prompt. A definition buys
nothing a prompt does not, and it is the one surface a local `.claude/agents/` file silently outranks.

## The order walk

**Mandated. Before dispatching anything, sort the spec's slices into `depends_on` order. If no order
exists, refuse, name every slice in the cycle, and stop. The next act is `dev-path:slice`.**

`depends_on` is written by a model and nothing validates that the graph is acyclic, and **a two-slice
cycle is an unbounded loop in the busiest skill.** This is cheap rather than machinery: the graph is small
— N is single digits in practice — Slice wrote every slice file in one pass so the whole graph exists at
the moment the check runs, and the refusal is fixable on the spot.

**It is a refusal and not a deviation to work around**, because there is no correct order to pick.
Choosing one would be Build deciding which dependency the model did not mean.

**No new field.** A cycle is a property of `depends_on`, computed from `depends_on`.

## Read `fix_cycles` before opening a fix pass

**At `fix_cycles >= 2` on that slice, do not open another fix pass unasked.** Ask the engineer already in
this session — **no new human, no third gate.** The answers are the disposition grammar, plus *keep
going*.

> **The cap does not stop the work. It stops the work being unattended.**

`fix_cycles` is Critique's field and Critique's write. **Never write it here.** Build's field is `done`.

## The dispatch

**Mandated. A dispatch prompt opens with a literal first line naming the slice file:**

```
dev-path slice: dev-path/tolerance-config/slices/01-schema.md
```

**The prefix `dev-path slice: ` is fixed and the remainder of the line is the slice file's full path.**
The rest of the dispatch follows on the lines after it and the convention says nothing about those.

**Changing this is a breaking change, not a wording tweak.** It is contract surface: a repo may gate on
it, and blocks a repo pastes parse it.

**Three properties, and they are why it is a first line rather than a token anywhere in the prompt.** It
is positional, so a guard needs no search and cannot match a slice path the dispatch merely mentions in
passing — and a slice's prose routinely names other slice files, as do `depends_on` values. It survives
paraphrase, because everything after line 1 is prose a model composes and line 1 is a string it copies.
And a missing convention **fails visibly**, where a token somewhere fails by finding nothing, which is
indistinguishable from a compliant dispatch with nothing to flag.

**What else a dispatch carries — paths, not contents.** Name the slice file and the spec file and instruct
the worker to read them; **do not paste either.** That is *re-derive from disk* one level down: a pasted
spec is a copy that is stale the moment Critique appends a finding, and it is how a 42k-character dispatch
happens, of which one real session's was 99% pasted history.

**So a dispatch carries, and carries nothing else:** the fixed first line; the spec's path; what the
worker is being asked to do this pass — build the slice, fix these named findings, or critique — and the
findings themselves when it is a fix pass, because those are what Critique already wrote down and what the
pass is *for*. **No conversation history, no prior worker's output, no file contents.**

## Any stop that needs a human stops the whole run

Stated once for **any** mid-run stop rather than once per trigger, because two rules with the same reason
behind them drift apart later.

> **Any stop that needs a human stops the whole `dev-path:build` run. The engineer may hold the stopped
> slice and continue another on request only, guarded by a `touches` set intersection — disjoint goes,
> overlapping is refused.**

**The mechanical reason:** a fix pass takes *branch state plus open findings* as its input, and those
findings were verified against *this* branch state. Building another slice while the human decides means
the pass they then grant runs against a branch that moved underneath the thing it was asked to fix. The
same hazard applies to a pause, which is why this is stated once.

**The honest gap in the guard:** `touches` holds pre-existing paths only, so a brand-new file in the other
slice is invisible to the intersection. It cannot invalidate a finding about code that already existed.

**The backstop holds however far you run** — Integrate refuses on the open box, so the worst case is more
code and the same stuck slice, never a bad merge.

## Committing

**The worker writes code and reports. The orchestrator commits and pushes.**

Four reasons, in order of weight. **Parallelise reads, serialise writes** — git's index and branch pointer
are a shared write, and slice parallelism is a deliberately open upgrade, so worker-commits is a design
that breaks precisely when that upgrade is taken. **A failed commit needs a human, and a worker cannot
reach one.** It agrees with how the adjacent tooling in this estate already reasons about commits. And it
is immune to how a foreign guard identifies the caller.

**Nothing observable changes: one commit per slice, none for a pause.** The worker writes `done: true` and
returns; commit on that return; an open box means no commit.

**Stage with `git add -A`**, and **any commit excess against the slice's declared scope is recorded as
one `- [ ]` under `## Deviations`.**

**Why the audit beat a filter**, because it looks like the lazier choice and is not. Both need the *same*
comparison — what git reports changed, versus `touches` plus `dev-path/` plus created files — so the
machinery cost is identical and the only difference is exclude-it versus include-and-note-it. A filter's
risk is dropping a file Build legitimately created, which shows up later as a failed deploy somebody has
to debug. The audit's risk is committing something out of scope, **and it is flagged.** And `git add -A`
cannot lose work, which takes Build's memory out of the loop.

**Who closes that box, and it is not a skill.** It is written *after* `done: true`, so the frozen test
below does not catch it and no later `dev-path` run is looking for it — **a done slice with an open box
under `## Deviations` is not a pause and must not be read as one.** **It is the human's, at review**, in
the grammar: `- [x] false positive` if the files were in scope and `touches` was simply incomplete, or
`- [x] won't fix — <reason>` if they were not. What puts it in front of them is Integrate's step 3, which
refuses while any box is open and names the exits.

**The audit is also a backstop, and that is a rule rather than a side effect.**

> **A precondition on the repo comes with a backstop, never alone** — and the reason is that another
> plugin's presence depends on the **engineer**, not the repo, so it is not observable from the repo at
> all. A precondition that cannot be checked needs one.

`dev-path:fit-check` asks a repo to gitignore the directories other tooling writes into. If that ignore is
missing, or a new tool starts writing somewhere nobody anticipated, `git add -A` commits the file and the
audit writes it down as excess. **`dev-path` benefits from the ignore without depending on it.**

**Two costs, stated.** Under concurrent slices `git add -A` would sweep a sibling's half-finished work. It
cannot fire today and, when parallelism arrives, it fires **loudly** — slice 02's commit records slice 03's
files as excess. And the engineer's own stray edits in a shared working directory get committed into a
slice; also recorded, also visible at review.

### The commit message

**Suggested, with its reason. The subject line is the slice's title; the body names the slice file's path.
Nothing else. Where the repo's standards rule says otherwise, the repo's rule wins and this line retires
for that repo.**

```
Tolerance comparison in the invoice's currency

dev-path/tolerance-config/slices/02-validation.md
```

**Why the path in the body rather than a prefix or a trailer.** `git log -- dev-path/<slug>/` already finds
a spec's commits, so the path is for the human reading one commit in isolation and asking *which slice was
this*. A prefix convention would be `dev-path` deciding the shape of the repo's history, which is
overreach; a trailer would be a string to pin.

**No issue key, because there is no tracker.** `upstream` holds what was read and a commit is not where it
belongs.

**The push is per commit, not per run.** You cannot have a draft pull request on an unpushed branch, and
the pull request is what makes the work visible while it is in flight — a run that pushed once at the end
would leave the spec's own pull request stale for the whole build, which is the condition the draft pull
request exists to prevent. **A pause commits nothing and therefore pushes nothing.**

## Dispatch a critic on that same return

**Mandated. A worker that returned having written `done: true` gets a critic before the walk moves on: run
the skill `dev-path:critique` against that slice.** This is the Build ↔ Critique loop this skill opened by
claiming, and it is the orchestrator's act — a worker cannot dispatch anything.

**The condition is the `done: true` return and not merely a return.** A pause returns too, and a pause
stops the whole run: no commit, no critic, no walk. It is the same event that already means no commit.

**A fresh critic, every pass.** *Fresh, always*, in the lifecycle table above, and the rule behind it is
that nothing is ever resumed into a role that judges its own prior output. Dispatch one; do not continue
anything into it.

**Nothing new carries it.** The dispatch above already names *critique* as one of the three things a
dispatch asks for, and its fixed first line already carries the slice's path.

**The critic writes and returns; you commit its write.** Same division as the builder's. Then `fix_cycles`
and the findings decide the next act: a finding open on this slice is a fix pass, under the cap above;
nothing open walks to the next slice.

**And this is why a session skipping the dispatch is visible.** `fix_cycles` is absent until Critique's
first pass over a slice writes it, so its absence on a slice carrying `done: true` is the slice pass never
having run — which Integrate's step 3 refuses on.

## Serial, for now

**One commit per slice on the one spec branch, walked in `depends_on` order across fresh contexts. No
slice branches.** With commits there is no merge step to own; slice branches would build an unprotected
integration branch that CI is contractually forbidden to run on, because every spec carries a draft pull
request from Initiate and CI must skip drafts; and attribution is already paid twice, in one file and one
commit per slice.

> **Say so plainly: serial execution is a starting posture, not a ceiling.** Presenting it as a principle
> would be dishonest.

Slices run in series first because the engineers are new to this way of working, not because parallelism
is worthless. Moving to slice branches later is **purely additive** — Build cuts a branch instead of a
commit and nothing else in the design changes.

**Worktrees are the engineer's business and `dev-path` mandates nothing about them.**

---

# The worker prompt

What follows is what each dispatched subagent is told. Dispatch it after the fixed first line.

## Read before you write

**Mandated: use the file tools — `Read`, `Write` and `Edit` — for `dev-path`'s own artifacts, and use
`Read` explicitly.** This is measured. Across 15 runs with loading instrumented by a hook rather than by
the model's own account:

| How a file was touched | Scoped rule delivered |
| --- | --- |
| `Read` | **3/3** |
| `Edit` on an existing file | **3/3** |
| `Write` on a new file | 0/2 |
| `Grep` | 0/2 |
| Bash `cat` | 0/3 |
| Bash `sed` | 0/2 |

**The read is where rule delivery happens**, so a slice worked through `cat` and `sed` is a slice worked
with the repo's scoped rules absent. This holds even if no other plugin is installed.

**Suggested, with its reason: read a neighbouring file of the kind you are about to write, before writing
it.** It was never only a rule-loading trick — house style, naming and structure were always part of it,
and that half stands on its own. It cannot be rephrased as *ensure the standard is loaded*, because an
agent cannot self-report whether a rule loaded.

**The slice's `touches` is not a work list.**

> **`touches` is what this slice will collide with, not where to work.**

You are **not** instructed to touch those paths and **not** limited to them. Slice wrote them so the
contention checkpoint and the cited-paths check have something to read. This clause is prose mitigating a
real model-behaviour risk and the risk is live: tell an agent the change goes in a named file and it edits
that file even when the right change is elsewhere. On a greenfield repo `touches` is often empty anyway,
because it holds pre-existing paths only.

**You already have the repo's standard if it has one.** An unscoped `.claude/rules/` file auto-loads into
every session and every non-fork subagent and is re-injected after compaction. **A repo with no standards
rule builds against nothing, and that is the honest degradation** rather than a defect.

**The slice file carries a test-first line.** It reads:

> Watch a new test go red before you make it green.
> *Why: a test written before the code cannot be written to hit a coverage number — there is nothing to
> cover yet. Retires when Apex gets mutation testing.*

**It is a suggestion and not a mandate, and the reason is that a reviewer cannot verify it from a diff.**
This is not choosing to be lax; it is refusing to write a rule in a voice nothing can back. Both halves of
its rationale are statements about what is and is not possible: a test written first cannot be a coverage
artifact, and a test you never saw fail is a test you have not tested.

## Deploy, then tick, then `done: true`, then return

**Mandated, in that order.**

**Deploy the slice and run its tests against the engineer's own scratch org**, kept for the life of the
spec.

```sh
sf project deploy start
```

**No `--target-org`.** `sf` resolves a default target org per project folder. The plugin holds no org
name, no username and no credential.

**With no default set, this fails with the CLI's own error and the run stops there, and that is the right
failure.** The alternative is a plugin that holds an opinion about which org this repo deploys to. **Nor
does any stage create the org** — the engineer creates their own, and the repo's CI creates the fresh one
for the whole-spec deploy. A plugin that creates an org is a plugin that names one.

**Nothing is committed before it deploys**, which is what makes *one commit per slice* mean *one working
slice per commit*.

> **It does not prove verticality and must not claim to.**

**Verticality has no mechanical gate in this design.** One pull request per spec means a slice never
deploys alone to anything real, so **what ever gets deployed is a spec, never a slice** — a fresh org per
slice would test a property nothing downstream depends on, and would cost eleven orgs for a ten-slice
spec. **Two orgs per spec, not N+1.**

> **Green is provably not done.**

A slice whose feature was a dynamic query on a nonexistent field **passed validation, passed its test, and
scored 86.7% coverage.** Deploy-time integrity verifies the dependency graph, never the feature. The gate
is real and worth having — the same feature cut horizontally fails with 5 errors and 0 components
deployed — but do not read a green deploy as a finished slice.

**Then tick `## Acceptance criteria`.** **Mandated: tick each `- [ ]` as you satisfy it, and never
before.** The tag is `- [x] met` — a criterion is a statement about behaviour, so it closes the way an
Outcome does rather than the way a finding does. Ticking after the run rather than before is the same rule
as *never before it is satisfied*: a criterion ticked against code that has not deployed is a criterion
you graded rather than met.

**Do not write them and do not rewrite them.** Slice wrote them from the approved design. A criterion you
cannot satisfy is not edited into one you can: either resolving it changes only *how*, in which case
re-cut and note the deviation, or it changes *what*, in which case **pause**.

**`- [x] won't fix — <reason>` is written by the human, by hand, under any heading. `dev-path` writes
`fixed`, `met` and `false positive`; it never writes this one.** So it is never your unilateral way past a
criterion you could not meet.

**Then write `done: true`, then return.** A slice is done when its acceptance criteria are ticked — that is
the predicate the field carries. Value is always `true`; absence is how you say no; nothing ever writes
`false`.

**A failed deploy or a failing test is the slice not being finished, and you keep working.** It is **not**
a deviation and **not** a pause — nothing has diverged from the design and nothing needs a human yet.
**No retry count**: a cap on deploy attempts is a threshold that gets loosened, and the real bound is
already there in the fix cap.

## Deviations, and the pause test

**Build records; the recording is mandatory; the stopping is the engineer's call.**

**You may re-cut the slice layout unattended, and it is recorded as a deviation.** *Stop and ask* was
rejected — it would make the slice layout more sacred than the design itself, and even the design gate
permits deviation-with-recording.

> **Build re-cuts but never redesigns. Does resolving it change *what* the slice builds, or only *how*?**
> *How* → decide it, and the change is recorded as a deviation. *What* → that is design, and you do not
> own it. **Pause.**

**Mandated: a pause writes an open box under `## Deviations` before stopping.**

```markdown
## Deviations
- [ ] The design assumes every billing schedule is monthly and derives the period from the
      contract start date. The second Outcome implies mid-cycle proration, needing a proration
      basis that is not in the design and not derivable from what exists. This changes what is
      built, not how — needs a decision before this slice continues.
```

**Why the box and not just prose.** Without it a paused slice is **indistinguishable from one nobody
started** — neither carries `done: true`, neither has a `fix_cycles` line yet, and nothing under
`## Deviations` distinguishes them. With it: **no `done: true` plus an open box under `## Deviations` =
frozen, needs you; no `done: true` and no open box there = not started.** No new field.

**Reason in the absence of `done: true`, never in the string `done: false`** — nothing ever writes
`false`, so a check phrased against that string is a check that can never fire.

**And the section matters, not merely the box.** Slice writes `## Acceptance criteria` as open boxes at
creation, so an unbuilt slice already carries open boxes and *any open box* no longer separates frozen
from not-started. **A pause is an open box under `## Deviations`.** Same grammar, different instruction:
under `## Critique findings` an open box means *fix this*; under `## Deviations` it means *do not proceed
on this slice until a human clears it*. **A pause box is never ground on as a fix item.**

**You do not close your own pause.** The `dev-path:technical-design` session that resolves it writes the
disposition, in that session, before it ends. A stage that could clear the box it wrote is not a stop.

## On a fix pass

**Mandated: write `- [x] fixed` on each finding you fixed, in the same pass that fixes it.** The dispatch
already names the findings and carries them, so you have the list you are dispositioning.

***Fixed* is a claim about work just done, which only the pass that did it can make** — the same rule as
ticking a criterion as you satisfy it and never before. Critique owns `false positive`; the human owns
`won't fix`.

## How you reach a human

> **A worker can reach the orchestrator. Only the orchestrator can reach the human.**

**`dev-path` names exactly one route: write it down, then return.** The artifact on disk is the question's
durable form; the return value is the signal. No live messaging, no elicitation, no prose question into
the void.

The harness prescribes this itself: *AskUserQuestion is not available inside subagents. Complete the work
with the tools provided and return findings to the orchestrator.* It is absent from a subagent and fails
synchronously.

**Say this, because the mirror image of *a check written and never wired* is *ruled out and never
checked*: live messaging is a declined available mechanism, not an assumed-absent one.** Sending a message
to the main conversation from a background subagent **works**, and returns *queued for the main
conversation's next turn* — **queued, not interrupting**, so it saves not one step over returning.

**Escalate on irreversibility, not uncertainty.** `dev-path` always has a controller, so the instruction
is rule and report, never stall. That does not weaken the pause: building the wrong thing is exactly the
irreversibility case.

## A foreign hook's refusal

> **Write the refusal verbatim into `## Deviations` and stop the run.**

**Mandated, and *verbatim* is the load-bearing word.** Paraphrasing another plugin's reasoning is where a
dependency re-enters — the plugin would then be holding an opinion about what that guard meant, and the
next version of the guard makes the opinion wrong. **Copy the message the harness handed over and stop.**

**Nothing new is needed to detect it.** A refusal from another plugin's hook that this stage cannot satisfy
**is** the case *any stop that needs a human stops the whole run* already covers, and the harness hands the
guard's message straight to whoever made the call. Do not build a catalogue of another plugin's hooks, and
do not route around a refusal.

**A deploy blocked by another plugin's hook is one of these.** A deploy that fails because no default org
is set is the CLI's own error, above. Neither is yours to fix.
