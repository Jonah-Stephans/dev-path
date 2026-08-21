---
description: Find what already exists in a repo that bears on a dev-path spec's Outcomes. Use when a spec is accepted and its current state is not yet known.
---

# Survey

Survey answers one question: **what exists today that bears on this?** It writes `## Current state` on
`dev-path/<slug>/spec.md`.

**It has no gate, it narrows nothing, and it adds no field.** Where Survey finds that a requirement spans
two unrelated subsystems it writes the finding down and Design reaches the gate one stage later with a
stronger case. Survey has no gate, so letting it narrow scope would be an agent silently shrinking
accepted intent.

## Refuse first

Read the front matter of `dev-path/<slug>/spec.md`. **That read is the validation** — there is no separate
front-matter check anywhere in `dev-path`, because a read the router needs in order to route cannot be
disconnected, and that is the only structural immunity available.

- **`git branch --show-current` returns `main`, `<base>`, or a branch with no matching spec directory**
  → **stop.** Do not guess which spec this is. Say the next act: `git checkout <slug>` for the spec you
  meant, or run `dev-path:initiate` if it does not exist yet.
- **The command returns empty** → **stop, and say what is actually wrong.** `git branch --show-current`
  returns empty with exit code 0 under a detached HEAD, so the honest message is *you are not on a
  branch*, never *no spec on this branch*. The fix is one `git checkout -b <slug>`, and it is a human's:
  a pull-request job is supposed to be detached and nobody is going to check out a branch inside it.
- **`intent_accepted` is not `true`** → **stop.** Survey runs behind gate 1. Say the next act: run
  `dev-path:initiate` on this spec and take it through the intent gate.
- **The front-matter block does not parse as YAML, or a field carries the wrong shape** → **stop and name
  the exact field.** A human is sitting here and the file is already open, so the fix is one line.
  *Malformed* and *absent* are two different failures: absence is a legal state for every field and means
  *not yet*, so route on it rather than refusing.

**Prefix every message this skill prints when it stops with `dev-path: `.** Suggested.

## Read

`## Outcomes`, and `## Intent` for context. `## Outcomes` always exists — the intent gate requires it
non-empty — so there is no empty-seed case.

## Fan out, one subagent per Outcome

**Mandated. One subagent per Outcome, each asked *what exists today that bears on this?*, each
discarded. The session ends holding conclusions, not files.**

**The discard is the load-bearing half, and here is why it must not be edited into something tidier:
Design runs in the same session as Survey because it wants the findings.** That only works if Survey ends
holding conclusions rather than open files. A fan-out that wrote its findings to files, or that left the
subagents alive, would end with the findings somewhere the design conversation cannot reach. A running
session cannot reset its own context, so a subagent is the only fresh context this skill can produce —
and handing back conclusions is what makes the fresh context free.

**Extend the list as you go, and record what you dispatched. Seeded, never cold.** An Outcome's answer
routinely names the next thing worth asking about; dispatch that too. The dispatch list is prose in
`## Current state` and nothing checks it — **no new field.**

**Why Outcomes and not something else.** The per-item question is Survey's actual job, and it is the same
key at both ends of `dev-path`: Survey asks *what exists that bears on this Outcome*, and the Outcomes
pass at Integrate asks *did we achieve it*.

## Ground sideways as well as down

**Suggested, with its reason** — a suggestion without its reason is a suggestion an agent drops.

**The reason, in one line: the code carries *what* was built and not *why*.** An agent reading
`RentalContractLine__c` learns the shape, not that Sales Order Line was rejected for having no time
interval — which is exactly the reasoning that stops a later spec refactoring back toward it.

So read the work around this spec, not only the code.

**Merged specs — grep `dev-path/` the way you grep the codebase.**

> **Bounded by the query, never a sweep.**

That distinction is the whole reason it scales. Code is *replaced*, so reading a codebase stays flat.
Specs are permanent and accumulate forever, so grep-by-topic is fine at five hundred specs and a corpus
sweep never is.

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
`dev-path:learn` proposes later.

## Write

**`## Current state`, on `spec.md`.** Survey is its only writer; Design prunes it later to the facts the
design rests on. **Survey done ⇔ `## Current state` is non-empty.**

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

Then show what was found and stop. When Survey was reached by `dev-path:technical-design`, the design
conversation continues in this session with the findings live.
