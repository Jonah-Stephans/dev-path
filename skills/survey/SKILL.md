---
description: Find what already exists in a repo that bears on a devpath spec's Outcomes. Use when a spec is accepted and its current state is not yet known.
---

# Survey

Survey answers one question: **what exists today that bears on this?** It writes `## Current state` on
`devpath/<slug>/spec.md`.

**It has no gate, it narrows nothing, and it adds no field.** Where Survey finds that a requirement spans
two unrelated subsystems it writes the finding down and Design reaches the gate one stage later with a
stronger case. Survey has no gate, so letting it narrow scope would be an agent silently shrinking
accepted intent.

## Refuse first

Read the front matter of `devpath/<slug>/spec.md`. **That read is the validation** — there is no separate
front-matter check anywhere in `devpath`, because a read the router needs in order to route cannot be
disconnected, and that is the only structural immunity available.

- **`git branch --show-current` returns `main`, `<base>`, or a branch with no matching spec directory**
  → **stop.** Do not guess which spec this is. Say the next act: `git checkout <slug>` for the spec you
  meant, or run `devpath:initiate` if it does not exist yet.
- **The command returns empty** → **stop, and say what is actually wrong.** `git branch --show-current`
  returns empty with exit code 0 under a detached HEAD, so the honest message is *you are not on a
  branch*, never *no spec on this branch*. The fix is one `git checkout -b <slug>`, and it is a human's:
  a pull-request job is supposed to be detached and nobody is going to check out a branch inside it.
- **`intent_accepted` is not `true`** → **stop.** Survey runs behind gate 1. Say the next act: run
  `devpath:initiate` on this spec and take it through the intent gate.
- **The front-matter block does not parse as YAML, or a field carries the wrong shape** → **stop and name
  the exact field.** A human is sitting here and the file is already open, so the fix is one line.
  *Malformed* and *absent* are two different failures: absence is a legal state for every field and means
  *not yet*, so route on it rather than refusing.

**Prefix every message this skill prints when it stops with `devpath: `.** Suggested.

## Read

`## Outcomes`, and `## Intent` for context. `## Outcomes` always exists — the intent gate requires it
non-empty — so there is no empty-seed case.

## Fan out, one researcher per area

**Mandated. Cluster the Outcomes into the distinct areas they touch, dispatch one subagent per area, each
asked *what exists today that bears on these?*, each discarded. The session ends holding conclusions, not
files.**

**Cluster before anything reads the repo**, from `## Intent` and `## Outcomes` alone — that is the whole
material at this point and it is enough, because an Outcome names the area it concerns. **Why the area and
not the Outcome:** a spec's Outcomes usually concern one or two subsystems, so N researchers keyed on N
Outcomes re-read the same files N times with no view of each other.

> **At most four researchers on the first pass, and at most one further dispatch to chase what an answer
> named. Five for the whole of Survey.**

**Four is the exception and never the target.** A three-Outcome spec about one subsystem gets **one**
researcher, and that is the normal case rather than a shortfall — the failure this ceiling is written
against is an agent reading *up to four* as *four*.

**The ceiling covers the whole stage, because one covering the first pass is not a ceiling.** An open
extension clause is what put thirteen researchers on a thirteen-Outcome spec, and every single decision to
dispatch one more was locally reasonable.

**The fifth slot cannot be spent on the first pass, so nothing needs holding back.** An orchestrator that
expects to chase something already has its slot; one that finds nothing to chase never dispatches a fifth.
**Four plus one, and never four plus two** — *at most one further dispatch* is the half of this ceiling
that binds the mechanism thirteen came from, where every extra was justified one at a time.

**Extend the list as you go, and record what you dispatched. Seeded, never cold.** An answer routinely
names the next thing worth asking about; dispatch that too — that is what the fifth slot is for. The
dispatch list is prose in `## Current state` and nothing checks it — **no new field.**

**When two answers each name something and only one slot is left, chase the one the design will rest on**
— not the one that reads as most interesting. The other one is not dropped; it is written down, below.

**Where the Outcomes do not cluster meaningfully, chunk them in order.** A mis-grouped Outcome gets a less
focused answer, never a missing one — so messy Outcomes are no reason to stall, and no reason to talk
past the ceiling.

**Say in `## Current state` when the ceiling shaped the answer** — unrelated areas chunked together to fit
four, or a thread named and not chased. A shallower finding Design knows is shallow is usable; one Design
reads as complete is not, and Survey is the only stage that can still tell the difference.

**Findings stay per-Outcome.** A dispatch and a finding do not have to share a shape: one researcher
handed four related Outcomes hands back four separate answers.

**Why the Outcome keys the finding.** The per-item question is Survey's actual job, and it is the same key
at both ends of `devpath`: Survey asks *what exists that bears on this Outcome*, and the Outcomes pass at
Integrate asks *did we achieve it*.

**The discard is the load-bearing half, and here is why it must not be edited into something tidier:
Design runs in the same session as Survey because it wants the findings.** That only works if Survey ends
holding conclusions rather than open files. A fan-out that wrote its findings to files, or that left the
subagents alive, would end with the findings somewhere the design conversation cannot reach. A running
session cannot reset its own context, so a subagent is the only fresh context this skill can produce —
and handing back conclusions is what makes the fresh context free.

**Dispatch the researchers on the cheapest tier that reliably reads code and summarises it; the
orchestrator stays where it is.** Suggested, with its reason.

**Named by the property first, because a tier name is a model property and this one will move.** Sonnet is
the current instance. **Haiku is excluded by decision** — the hallucination risk is not worth the saving
on a stage whose output a design conversation then builds on. On a harness with one tier the rule
degrades to a no-op, which is the other half of why it is written this way.

Mechanically available today: the `Agent` tool takes a per-dispatch `model` parameter, so an Opus
orchestrator dispatches Sonnet researchers and stays on Opus itself. **A `fork` subagent ignores that
override** — Survey's researchers are not forks, and a fork would defeat the fan-out anyway by inheriting
the context this stage spends a subagent to get out of. **And there is no per-dispatch effort knob on the
plain `Agent` tool**: the tier is the only dial this rule can reach, so *cheaper* has no finer setting than
*a cheaper model*.

## Bounded by the query, never a sweep

> **Bounded by the query, never a sweep — over the code as much as over the specs.**

**One rule over both, and each half carries its own reason, because a rule with one reason gets scoped
back to whichever half the reason fits.**

- **The specs, because the corpus accumulates without limit.** Specs are permanent, so grep-by-topic is
  fine at five hundred specs and a corpus sweep never is.
- **The code, because every read costs now.** *Code is replaced, so a codebase stays flat* is true and
  answers a different question: *the repo does not grow over years* is not *reading the repo is cheap in
  this run*. A four-hundred-file repo is flat forever and still costs a fortune read four times over —
  and clustered researchers must not re-pay for the same files.

## Ground sideways as well as down

**Suggested, with its reason** — a suggestion without its reason is a suggestion an agent drops.

**The reason, in one line: the code carries *what* was built and not *why*.** An agent reading
`RentalContractLine__c` learns the shape, not that Sales Order Line was rejected for having no time
interval — which is exactly the reasoning that stops a later spec refactoring back toward it.

So read the work around this spec, not only the code.

**Merged specs — grep `devpath/` the way you grep the codebase.** Bounded by the query, never a sweep:
this is the grep that rule was written for first, and the reason it scales at five hundred specs.

**In-flight specs — read the neighbour report from the contention checkpoint.** Grep sees only the working
tree; unmerged specs need `git show <branch>:<path>`, which `scripts/contention.sh` already does. Read
that report for the **names and intents** of the neighbours it found, not only for file collisions.

> **A neighbour whose Design has not run holds an intent, not a decision.**

That is a prompt to go and talk to the other engineer, never a decision to build on. Its `spec.md` has
Intent and Outcomes and no design, and an agent that reads a neighbour's intent as settled has built on
something nobody approved.

**Accepted cost, watched rather than solved: Survey gets more expensive as the corpus grows.** The
bounded-by-query rule is what keeps that curve survivable.

## Where a decision lives, by scope

Survey is the reader that makes the middle row real. Without Survey's instruction that row has no reader.

| Scope | Lives in | Found by |
| --- | --- | --- |
| **Feature-area** — a feature's object model **and its rationale** | **the spec**, attributed and dated, beside the reasoning that produced it | **Survey** |

So a feature's object model and the reasoning behind it belong in the spec Survey is writing, attributed
and dated — not in a rule file. A repo-wide standard is auto-loaded from `.claude/rules/` and there is
nothing for Survey to find; a cross-feature convention discovered inside one feature is what
`devpath:learn` proposes later.

## Write

**`## Current state`, on `spec.md`.** Survey is its only writer; Design prunes it later to the facts the
design rests on. **Survey done ⇔ `## Current state` is non-empty, or `## Refuse first` stopped the
run and named the condition.**

**Rewrite the section; do not append to it.** A stage that supersedes an earlier section rewrites it. The
file is the working set and git is the archive.

**What to write when nothing was found.** Mandated:

> **Write what you found, and *nothing bears on this, and here is what the repo does have* is something
> you found. Never the word `none`, and never a heading written to satisfy the check.**

`## Current state` is **not** a second exception to the placeholder rule and does not need to be. Survey's
question is *what exists today that bears on this?*, and **there is nothing here yet** is an answer: it is
what a subagent actually concluded, it is what Design needs to know, and it is the sentence that stops
Design assuming a service layer it would otherwise go looking for. This is the first spec in a greenfield
repo, which is the stated target, so it is not an edge case.

**The line the rule draws is between text with content and text without it.** *There is no billing code
in this repo; the closest thing is `InvoiceService`, which does not touch schedules* is content.
`## Current state` followed by `n/a` is the placeholder, and it is banned on a greenfield repo exactly as
it is banned everywhere else. Two sentences is short, not absent.

## Stop

**Commit the write.** One commit, on this branch, so the diff between the Survey commit and the Design
commit is what the design decided to stop carrying. **Do not push here** — the push belongs to the design
gate, where a human is about to read a diff, and pushing earlier would put this spec's slices on the
remote before the contention checkpoint reads it.

Then show what was found and stop. When Survey was reached by `devpath:technical-design`, the design
conversation continues in this session with the findings live.
