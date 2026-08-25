---
description: Propose codebase lessons from a finished devpath spec. Use at the end of Integrate, or point it at a pull request to capture something review turned up.
---

# Learn

**`devpath:learn` is the only skill with two modes.**

- **Inside `devpath:integrate`, at step 7**, before it marks the pull request ready and arms auto-merge.
  It is not a step somebody can decline by doing nothing: it sits inside a command they have to run in
  order to ship.
- **Human-invoked, pointed at a pull request** via `$ARGUMENTS`, naming what they want captured. This is
  what covers everything the automatic run cannot see.

**Say what the wiring is and is not, because the difference is a rule.** The wiring is an instruction in
`skills/integrate/SKILL.md` naming this skill, and **skill-to-skill invocation is model-driven** — Claude
reads the instruction and normally follows it. There is no call syntax, no subroutine form and no event
that fires on a skill finishing, so nothing in the harness makes it certain. **Do not write *cannot be
forgotten*.** A repo that wants a guarantee adds a `Stop` hook of its own; `devpath` ships none and
depends on none.

**No credential is stored anywhere and there is no precondition.**

## Refuse first

- **Invoked with `$ARGUMENTS`** — the argument is the pull request. Use it, and do not do branch
  discovery.
- **Invoked without an argument**, from Integrate: discover the spec with `git branch --show-current`. On
  `main`, on `<base>`, or on a branch with no matching spec directory → **stop.** On empty output → **stop
  and say *you are not on a branch***, which is what an empty return with exit code 0 actually means under
  a detached HEAD; the fix is one `git checkout -b <slug>`.
- **`gh` is unavailable** → **propose nothing and say so.** Do not write lessons directly — that is the
  one thing forbidden outright — and do not hold them anywhere. The findings are in `## Critique findings`
  and `## Deviations`, which is where they already were, and the human-invoked re-run is how they get
  proposed later.
- **The working tree is dirty** — `git status --porcelain` prints anything → **stop, name what is
  uncommitted, and do not cut the branch.** See *cutting the branch* below for why this is a refusal and
  not something to work around.

**This skill has no gate.** It reads a pull request and proposes; nothing gates it and it adds no field.

**Prefix every message this skill prints when it stops with `devpath: `.** Suggested.

## What can actually be read here

| Source | Available at Integrate |
| --- | --- |
| Critique's findings | **always** — `devpath`'s own file |
| The recorded deviations | **always** — `devpath`'s own file |
| The spec's traps | **always** — `devpath`'s own file |
| CI bot findings | **never** |
| Human review comments | **never** |

**Two of the five are never available, and it is the same reason both times: this runs while the pull
request is still a draft.** CI does not run on draft pull requests, and the spec's pull request is a draft
for its whole life until Integrate marks it ready — which happens *after* this step. So there has never
been a CI run on this pull request to read, and no reviewer has seen it either.

**That is a real hole, stated rather than promised away.** The human-invoked re-run covers both empty rows
by the same mechanism: once the pull request is ready, CI has run and a reviewer has commented, and an
engineer runs `devpath:learn` again pointed at it.

**A trap arrives pre-sorted:** `## Traps` is already the generalisation this skill would otherwise have to
make, written by the pass that was there while it was there. It enters the routing below as a candidate
like any other.

## What this produces

> **A pull request proposing lessons. Learn never writes them directly.**

An unattended job that *writes* to a file auto-loading in every future session is a compounding-error
machine, and **a wrong lesson is worse than no lesson because it loads forever.** Proposing means a human
catches it by reading a small diff, using the review gate that already exists. **The pull request *is* the
staging area** — there is no inbox and no raw lessons file underneath.

Every two-tier design measured is dead at the step where an entry is meant to move up a tier: a recurrence
counter that never exceeds 1 anywhere including its author's own repo; a hook-enforced *cite the original
incident* rule with zero citations across two repos; the best-designed inbox mechanism found anywhere,
verified live at two files and five days old. **The one alive in-band loop found has no second tier at
all.**

## Where lessons live

**`.claude/rules/<topic>.md` in the repo.** Codebase lessons only — things true about *that repo's code*.
**Nothing about `devpath` itself, ever.**

Why the repo and not the plugin, in order of weight: the lesson is about that repo; a cross-repo pull
request would need a token with write access to a personal repo held as a secret in someone else's CI; and
per-engineer installation with no auto-update means a plugin-hosted lesson banked today does not reach a
colleague until they update.

**`.claude/rules/` is a native Claude Code mechanism, not any plugin's invention.** Rules without `paths:`
load in full every session; rules with `paths:` load when the agent touches a matching file.

**`.claude/lessons.md` is the one path to keep clear of** — other tooling in this estate reads it whole and
uncapped on startup, resume, clear and compact. **And avoid the `rstk-` prefix on a rule file's name.**

**A per-feature `.claude/rules/<feature>.md` is forbidden.** It is the deleted level above a spec returning
by the back door in a different directory — it has a location and its name is the body of work above the
spec. It also fails mechanically: an unscoped rule earns *unscoped* because a standard is universally
applicable, and feature-scoped content inverts that — auto-loaded into every session, relevant to almost
none, growing linearly with feature areas. **A feature's object model and its rationale belong in the
spec**, which is what Survey writes.

## Scoping

> **Never create an unscoped rule file.** Every lesson proposed is one of three things: a
> `paths:`-scoped rule, a **check**, or a **proposed edit to the repo's existing unscoped standards
> rule.**

This is stricter than *an unscoped lesson must justify itself* and stricter than *does the agent need it
while writing?* — both make this skill the judge of what is universal, and it will be generous. Routing
the universal case into an artifact already bounded by a human classification pass keeps the always-on set
bounded by something other than an agent's judgment.

**The load-bearing argument is a multiplier.** An unscoped rule loads into every session **and every
non-fork subagent**. Build spawns a fresh worker per slice and per fix pass; Critique spawns fresh every
pass. So the always-on set is paid **per worker**, not per session.

**And unscoped-always is removed from consideration by a single fact:** the 200-line limit everyone quotes
applies only to auto-memory. Instruction files are loaded in full regardless of length. **A rules file has
no cap, no truncation and no brake.**

**Authoring line, and it is a mistake already made five times nearby: to mean *always on*, omit the
`paths:` key. Never write `paths: ["*"]`.** A `paths: ["*"]` rule matches any path at any depth and any
extension, **but it is still read-gated and does not load at launch**, so it is not equivalent to unscoped
and is absent for the opening stretch of every session.

**The cost of scoping, stated in its narrow form rather than a stronger one.** `paths:` fires on `Read` and
on `Edit` of an existing file. It does not fire on `Write` of a new file, on `Grep`, or on Bash `cat`, and
it is dropped at compaction and not re-injected until another matching read. So:

> The standard is absent only when a file is **created** before any read or edit in that slice. Every
> `Edit` delivers it, every `Read` delivers it, and Critique always has it.

**The residual cost is permanent, not one fix cycle** — a lesson Build never sees is re-learned at review
every time. Two things soften it and neither removes it: Build reads existing code to orient, so any
matching file it opens loads the scoped set; and coverage improves as the repo fills up, which means **the
hole is worst on a young greenfield repo and closes as code accumulates** — the opposite of where
`devpath` aims.

## Routing: not everything found becomes a rule

| What was learned | Where it goes |
| --- | --- |
| A coding convention | `.claude/rules/<topic>.md`, `paths:`-scoped. The bulk |
| Something a machine can check | **a check** — below |
| A cross-feature convention found inside one feature | a proposed edit to the repo's unscoped standards rule |
| Something about `devpath` | **an issue on the plugin's own repo** — never in this repo. Integrate runs that channel; this skill never touches it |
| A one-off | **dropped** |
| Already covered by an existing rule | **dropped. Read the existing rules first.** Never copy the same rule into a rule, a skill and a document |

**Read the existing rules before proposing anything.** The third row is what a cross-feature convention
becomes, and it follows *that* file's shape rather than the grammar below — imposing `devpath`'s grammar
on an artifact the repo owns is the line rule 2 draws.

## The entry grammar

**A repo-side hook is expected to parse this**, so the shape is fixed rather than left to taste.

```markdown
---
paths:
  - "force-app/main/default/classes/**"
---

# Tolerance checks

Anything writing to `ToleranceService` needs this.

- Tolerance comparisons run in the currency of the invoice, never the order https://github.com/acme/erp/pull/418
- A tolerance of zero means exact match, not "no check" https://github.com/acme/erp/pull/431
  The two were confused twice; the second time it shipped.
```

**Six rules, and that is the whole grammar:**

1. **The file is `.claude/rules/<topic>.md`.** One topic per file. Front matter carries `paths:`, or omits
   it to mean always-on, and **never** `paths: ["*"]`.
2. **One `# <Topic>` heading, and prose after it is allowed.** A file may explain itself.
3. **An entry is one line beginning `- ` at column zero.** Nothing else is an entry — not a heading, not a
   nested bullet, not a paragraph.
4. **The line's last whitespace-delimited token is the pull request link.** Bare URL, no brackets, no link
   text, nothing after it.
5. **A continuation line is indented two spaces and carries no link.** It belongs to the entry above it.
6. **No `- [ ]` ever appears in a rules file.** The disposition grammar is the spec's, and a checkbox here
   would be an open box nothing dispositions.

**Why a line rather than a heading or a section per entry.** *Presence and resolution* has to be checkable
without judgment, and a line makes it a per-line grep:

```sh
grep -rn '^- ' .claude/rules/ | grep -v 'https://github.com/[^ ]*/pull/[0-9]*$' && exit 1
```

A heading-per-entry loses the one property that makes this work — with a heading, prose sitting between
two entries has no unambiguous owner, so *which entry is this link on* becomes a judgment call, and the
check that was one grep becomes a parser.

**Why the link is the last token and carries no markdown.** It makes *does it resolve* a `gh` call on a
token already isolated, with nothing to strip. **And it means the grammar needs no separator at all**,
which removes a whole hazard class: a separator would be a punctuation character to pin.

### The link, and why it is the one field on an entry

**Every lesson entry links the pull request that taught it, and the link must resolve.** Checked on
**presence and resolution, never truth.**

**Nobody, anywhere, removes a wrong entry** — measured four independent ways, unanimous, with zero
deletion events found in any rolling store. The cause is legible: appending is always cheap, but once an
entry's rationale is gone, deciding whether to delete it means reasoning about every interaction it might
have had.

**A rationale per entry is the one intervention anyone has measured, and it is large: excess growth from
+211.3% to +1.4%, a 99.3% reduction.** An entry carrying its own *why* can be judged obsolete **locally** —
open the link, look, decide.

> **Say "the pull request link". Do not coin a noun for it.**

**Correctness is explicitly not the retention test.** Three decay mechanisms fire without any entry
becoming wrong: model upgrade; the repo becoming self-describing; and rationale loss.

**Validate your own entries before opening the pull request** — the router-is-the-checker rule applied to
this skill's output. You are formatting the entry anyway, so the check has no independent existence to
lose. **The weakness is stated:** the 99.3% figure was measured with an **independent** program doing the
checking, and *the thing that writes the entry also checks the entry* keeps the intervention's form and
not the conditions it was measured under. A repo may harden it with a hook on writes under
`.claude/rules/`.

**Resolution is a `gh` call, not `curl`** — on a private repository `curl` returns 404 for a link that
resolves perfectly well for the engineer, which is a false negative on the one property being checked. You
are already running `gh` as the engineer, so the credential is right by construction.

**On a network or authentication failure, report resolution as not attempted and open the pull request
anyway.** Presence has already passed. **A lesson lost to a flaky network is worse than a lesson whose
link nobody verified**, and the human reading the diff can click it.

## A check, and what a check is

**A proposed check evaluates only the lines changed in that pull request.** Consequences, all of them
simplifying: pre-existing violations elsewhere are never examined, so a new check cannot light up hundreds
of legacy findings and stop everyone's work — **therefore it blocks from day one.** No warning tier, no
second tier, no counting. **Therefore this skill computes and tracks nothing.**

**Changed *lines*, not changed *files*** — file-level would fail an engineer on someone else's pre-existing
violation in a file they touched for an unrelated reason, which is the friction that gets checks disabled.

**Two conditions:**

1. **A proposed check ships with the pull request that taught it as its test case.** This satisfies the
   link requirement for free — **the link *is* the test**, so there is no entry line to carry a URL.
2. **A check that goes red on the base branch is an alarm, not something to wait out.**

**The risk a check actually carries is not that it is right about old code — it is that it is wrong about
new code.** A regex slightly too broad will not fire on the past; it will fire on every future pull request
writing something fine. Both conditions are aimed at that.

> **A check is a diff-scoped step in the repo's own CI. Nothing else.**

**Propose an edit to the repo's own CI configuration, at whatever path that repo already uses.**
`devpath` names no path of its own.

**Three things a check is not, and each is a plausible wrong answer:**

- **Not a hook.** A hook fires on a tool call and sees no diff, so it cannot evaluate changed *lines* —
  which is the whole of the scope above. It would also be a check the engineer's own session carries
  rather than one the pull request carries.
- **Not a `.claude/rules/` entry.** A rule is read by an agent; a check is run by a program. **A lesson
  that can be checked stops being a rule** — that is why the routing table has two rows and not one.
- **Not an artifact under `devpath/`.** The spec directory is what one piece of work left behind. A check
  outlives it.

## Cutting the branch and opening the pull request

| | |
| --- | --- |
| **Cut from** | the repo's **base branch**, never the spec branch. Cut from the spec branch, the lessons ride into the spec's own pull request and **there is no second pull request at all** |
| **Branch name** | `devpath/lessons/<slug>`. **It contains a slash, so it can never be mistaken for a slug** — a slug is a flat directory name — and any `devpath` skill run on it refuses, correctly, with *no spec on this branch* |
| **Title** | *Lessons from `<slug>`*. **Nothing parses it** |
| **Draft or ready** | **ready.** A draft would be slightly worse than pointless: CI does not run on drafts, and a proposed check's whole point is that its test case runs |
| **Author** | the engineer. Run `gh` with **their** credentials, so the pull request is theirs and the repo's own branch protection governs who reviews it |
| **Body** | one line per proposed entry with its link, plus one line naming each proposed check and the test case it ships with |
| **On a re-run** | **push to the same branch and add to the same pull request** if one is open for that slug. Only if it is closed or merged do you open another. **There is never a third** |

**The tree must be clean before you cut**, which is why a dirty tree is a refusal above. This skill runs at
Integrate's step 7, on the spec branch, and step 1 has already written `## Outcome checks` — a
`git checkout -b` from a dirty tree either fails or drags that section onto the lessons branch, where it
does not belong and where it would be lost. **Every stage that writes commits before it hands on**, so the
tree is normally clean here; if it is not, something upstream did not commit and that is worth surfacing
rather than working around. **A `git stash` dance is not the answer** — it is a mechanism nobody chose, and
its failure mode is losing the engineer's work silently.

```sh
git checkout -b "devpath/lessons/<slug>" "$base"
# write the rule files and any CI edit
git add .claude/rules/ && git commit && git push -u origin HEAD
gh pr create --base "$base" --head "devpath/lessons/<slug>" --title 'Lessons from <slug>' --body-file -
git checkout "<slug>"
```

Resolve `$base` rather than assuming it:

```sh
base=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
```

**Return to the spec branch before you finish**, so Integrate's step 8 runs where it expects to be.

**Why amending rather than opening a second.** The human's job here is *read a small diff*, and two open
pull requests proposing lessons for one spec is two small diffs plus the question of which one is current.
It is also the two-tier shape this design declines everywhere else.

**No topics are seeded.** `.claude/rules/` starts empty and the file set is whatever this skill earns.

**If the spec is later rejected**, a human closes the lessons pull request too. One human act, no
mechanism.

## What this skill must not claim

A repo's testing standard typically has three parts, and **two attach to `devpath` while the third does
not.** Gates are repo shape, which `devpath` requires and reimplements none of. Standards, the judgment
half, are what Build builds to and Critique checks. **The code-health metrics attach to nothing here** —
this skill sees one merged spec, those are a property of the whole repo's history, so it is not positioned
to move one and cannot observe whether it did.

> **The plugin must not claim the code-health metrics measure whether `devpath` works.**

**And the standard itself is a starting point to be challenged, not an adopted standard.** Its content is
provisional. **What is settled, and survives any change to its content, is where it attaches.**

## Stop

Report the pull request link, one line per proposed entry, and one line per proposed check. Then stop —
Integrate's step 8 follows.
