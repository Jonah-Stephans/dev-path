---
description: Critique the code of a built dev-path slice. Use after a slice is built, or when a reviewer has requested changes on the spec's pull request.
---

# Critique

Critique has **three passes with three subjects. Do not merge them.**

| Pass | Subject | Runs | Writes |
| --- | --- | --- | --- |
| **The slice pass** | that slice's code | when a slice is built, inside `dev-path:build`, or `dev-path:critique` alone | `## Critique findings` on **that slice file** |
| **The Outcomes pass** | the spec's Outcomes | **once, at the start of `dev-path:integrate`** | `## Outcome checks` on **`spec.md`** |
| **The change-request pass** | a human reviewer's comments on the pull request | when a reviewer requests changes and the engineer re-runs `dev-path:critique` | as the slice pass — triaged findings into the fix loop |

## Refuse first

Read the front matter of `dev-path/<slug>/spec.md`. That read is the validation.

- **`git branch --show-current` returns `main`, `<base>`, or a branch with no matching spec directory**
  → **stop.** Do not guess which spec this is. Say the next act: `git checkout <slug>`.
- **The command returns empty** → **stop, and say what is actually wrong:** it returns empty with exit
  code 0 under a detached HEAD, so the truth is *you are not on a branch*, never *no spec on this
  branch*. The fix is one `git checkout -b <slug>`, and it is a human's.
- **`design_approved` is not `true`** → **stop.** This stage runs behind gate 2. Say the next act: run
  `dev-path:technical-design` and take the design through its gate.
- **The front-matter block does not parse, or a field carries the wrong shape** → **stop and name the
  exact field.** *Malformed* stops the stage; *absent* is a legal state meaning *not yet*.

**Prefix every message this skill prints when it stops with `dev-path: `.** Suggested.

## Which pass is this?

**Work it out from the invocation, not from a field.** There is no field for this and there should not be.

| Invocation | Which pass |
| --- | --- |
| dispatched by `dev-path:build` | **the slice pass**, on the slice the dispatch names |
| `dev-path:integrate` | **the Outcomes pass.** This skill never runs it — it belongs to Integrate's first step |
| typed by a human, and the spec's pull request carries a review requesting changes | **the change-request pass.** Show the triage list and wait |
| typed by a human, and it does not | **the slice pass**, over the slices that carry code |

**Resolve the pull request with `gh pr list --head <slug>`** — one branch and one draft pull request per
spec means the number is derivable, and there is no `pr:` field to read. **If `gh` is unavailable the
change-request pass is unavailable**: say so, and run the slice pass. Do not guess.

## The slice pass

**A fresh subagent every pass.** Two independent supports: a resumed judge that had prescribed the fix
reported *"passed both with zero findings"* on work containing a real defect, and separating the agent
doing the work from the agent judging it is a strong lever. **Priced at about 3% of the cost of the build
it critiques**, so a fresh critic every pass costs effectively nothing. **If a dispatch is refused, or this
session is under an instruction not to dispatch, the slice pass is unavailable**: say so, write nothing, and
hand back — the next act is re-running this skill where a subagent can be had. **Do not critique inline
instead.** No exception for a session that did not build the slice, because the session that cannot dispatch
is usually the one that did, and asking it to sort those two apart hands the judgment to the agent this rule
exists to distrust. **`fix_cycles` staying absent is the right outcome and not a gap** — Integrate refuses on
an absent line on a slice carrying code, and on the finding a Build that cannot dispatch leaves open rather
than fixing, so an uncritiqued slice cannot reach a merge unseen.

**Read the changed files, not only the diff.** Mandated. A diff without the surrounding file is a worse
review on quality grounds alone — **and without this, scoped rules do nothing**, because a review
conducted through `git diff` in Bash loads no scoped rule at all.

**Check the diff against the repo's standards rule and emit a finding per violation.** That is the whole
instruction. **The instruction, never the list** — this skill carries the instruction to read the repo's
standard, and never a copy of the standard itself. A copy would stop working on a repo in another
language, would need a plugin release to change, and would be the copy that rots.

### Triage first

**Real / false positive / won't fix, each verified against the actual call path.** Hand only confirmed
items onward.

**Critique owns *false positive*** — a factual claim it can verify. ***Won't fix* needs the human** — a
judgment about what is worth doing.

> **`- [x] won't fix — <reason>` is written by the human, by hand, under any heading. `dev-path` writes
> `fixed`, `met` and `false positive`; it never writes this one.**

That is one rule rather than three. A run admits no mid-run human input, so a run must end where a human
is needed — and this disposition needs the human by definition, so **no running skill can be the one that
writes it.** It is a hand edit everywhere it appears.

**What that costs, said plainly: the one route past a real-but-not-done finding is a human opening the
file.** The alternative needs mid-run human input, which is ruled out, or a stored permission, which the
cap below refuses.

**Critique does not fix its own findings** — the reviewer becoming the author is the thing a fresh critic
exists to prevent. **And no per-finding fixer subagents:** each has no view of the whole change, and the
documented failure is fixing one finding and breaking a sibling route. The fix goes to a fresh Build
context whose input is the branch state plus the findings, **never the tail of the original build.**

### Write `## Critique findings` on the slice file

**It appends across cycles** — a `won't fix` from cycle 1 must reach Integrate. Nothing is ever deleted
from it.

```markdown
## Critique findings
- [x] fixed — `ToleranceService` swallowed the DML exception
- [x] false positive — null guard at line 42; the caller guarantees non-null
- [x] won't fix — hard-coded org id in the test; fixture is scratch-org-local
- [ ] bulk path still throws above 200 rows
```

**Every checked box carries its tag as the first word.** A bare checked box reads as *fixed in code* when
it may not have been, and **only `fixed` and `met` mean the code changed.** Pin that apostrophe in
`won't fix` as ASCII — a typographic one silently empties the standing ledger that
`grep -rn "won't fix" dev-path/` gives you on the base branch.

**Three writers, deliberately:** this skill writes `- [x] false positive`; **the fix-pass worker writes
`- [x] fixed` in the pass that fixes it**; and `- [x] won't fix` needs the human. *Fixed* is a claim about
work just done, so only the pass that did it can make it.

> ***Critique clean* ⇔ no `- [ ]` remains anywhere in the spec directory.**

One grep, zero judgment, every cycle. It names no heading, deliberately — a box put somewhere the design
never anticipated fails loudly rather than quietly.

**What is still section-dependent is what to *do* about a box, and that is not the same as the test.**
Under `## Critique findings` an open box means **fix this**. Under `## Deviations` it means **do not
proceed on this slice until a human clears it** — **a pause box is never ground on as a fix item.** Two
readings of one test: the grep answers *is anything open*, the section answers *what do I do about this
one*.

## The two-cycle cap

> **The cap does not stop the work. It stops the work being unattended.**

**A cycle is a fix and its re-review.** The initial pass is a review, not a cycle — nothing was fixed, so
there was no round trip. The sequence is build → review → **fix → review → fix → review** → stop: **two
fix attempts before it asks.** That also makes `fix_cycles: 0` mean something true — *reviewed once,
needed nothing.*

**`fix_cycles` is read by `dev-path:build`, at its start.** At `>= 2` on that slice, Build may not open
another fix pass unasked.

**The trigger is an undispositioned `- [ ]`**, identical to *Critique clean*. A finding already marked
`won't fix` or `false positive` does not hold the loop open.

### When to write `fix_cycles`, and what to write

**Mandated. `fix_cycles` is written here and by nothing else.** Build never touches it — Build's field is
`done`. Three cases, each observable from the slice file alone:

| The slice's state when Critique opens it | What to write |
| --- | --- |
| no `fix_cycles:` line at all | **`fix_cycles: 0`.** This is the review after the build, and a review is not a cycle |
| a `fix_cycles:` line, and `## Critique findings` holds at least one `- [x] fixed` | **one more than you read.** A fix happened and this pass is its re-review |
| a `fix_cycles:` line and nothing fixed since | **nothing.** Re-reading a slice no fix touched is not a cycle |

**The third row is what makes `dev-path:critique` safe to run alone.** Without it an engineer re-running
Critique to look again spends a lap of the cap on a pass in which nothing was fixed, and the cap starts
counting attention rather than fix attempts.

Slice writes no `fix_cycles:` line at creation, which is why the first row exists at all: the line is
absent until this skill's first pass writes it, and it is absent for exactly one pass.

### When the cap trips

**Ask the engineer already in that session. No new human, no third gate.** The answers are the disposition
grammar, plus *keep going*.

**The grant is spoken and never stored.** Default **one lap per "go"**, with an optional count — *cycle up
to three more times*. Storing it would be a new field and, worse, a standing permission sitting on disk
long after the conversation that granted it. It lives in the session and dies with it.

**Only *keep going* needs no write at all.** Every other answer is the human editing the line by hand,
between this run and the next one — and the next `dev-path:critique` run then opens a slice whose finding
is already dispositioned.

**`fix_cycles` keeps counting through granted laps**, so a slice that ends at 7 is honestly recorded as one
that fought. **Nothing caps how many times a human may grant** — any limit there would be the first thing
in this design constraining what a human may choose.

**A cap trip stops the whole `dev-path:build` run.** It is not a gate: a gate is three things at once —
the run stops, a stored field records that a human said yes, and the router refuses the next stage without
it. A cap trip is the first only.

## The change-request pass

**A reviewer requesting changes on the pull request re-enters as the same fix pass**, and it is
**engineer-initiated** rather than fired from a GitHub event. The output under discussion *is* the code
being reviewed, so a misread comment spends exactly the attention this design is trying to earn.

**The one difference from the internal loop: show a triage list first and wait.** The internal loop does
not, and the difference is entirely in the input. Findings from a bot or from Critique itself are
mechanical. A human comment may be **a defect, a nit, a wrong suggestion, or a question wanting an answer
rather than a code change** — four readings, and this skill cannot pick between them without asking.

> **The agent drafts replies; the human posts them.**

**That is a rule, not a preference, and its reason is social rather than technical.** It keeps an agent
from arguing in a pull-request thread with the senior engineer reviewing the team's first agent-written
code. It is also the line most likely to be dropped as friction by someone reading only the mechanics,
which is why it is written as a rule.

**Everything else applies unchanged**: a fresh critic, the disposition grammar, `fix_cycles` and the
two-cycle cap, and Build doing the fixing.

## What no check reaches

**A slice made only of custom metadata has no behavioural verification whatsoever.** No runner exists for
it and the deploy validates shape only. The same holds for permission sets, layouts and screen flows.

> **Say that outright rather than inventing a check.**

An invented check is the pattern this design has measured ten separate times — a check written and never
wired. If a slice's behaviour cannot be verified, the finding is *this cannot be verified here*, and the
verifiers that remain are the deploy gate for *will it deploy*, the human at the design gate for *is the
slice complete*, and the pull-request reviewer for *is the diff readable*.

## Stop

Write the findings, write `fix_cycles` if this pass is one of the three cases above, and return.

**Who commits that write is your role and never which skill called this one.** **A dispatched critic
writes and returns; the session that dispatched it commits on that return.** **The session holding this
skill commits** — whether `dev-path:build` loaded it here or a human typed it, that session is the one that
can.

**One rule and not two paths**, because a critic is a subagent in every pass above: *write and return* is
what a critic always does. Two writers on one branch pointer is the thing being avoided, and **a failed
commit needs a human a subagent cannot reach** — both are properties of the worker, not of the caller.

On a cap trip, stop the run and say which slice tripped it and what the answers are.

Do not fix anything here. Do not tick a box you did not verify.
