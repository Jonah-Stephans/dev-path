---
description: Cut an approved dev-path design into slice files. Use to run the slice stage on its own, or to re-cut a layout that was rejected.
---

# Slice

Slice cuts an approved design into N ≥ 1 slice files under `dev-path/<slug>/slices/`. It runs inside
`dev-path:technical-design`, in the same session that just wrote the design, and it runs alone against an
approved design.

**Slice is never a subagent.** It would have to be handed the spec file, which recreates the problem that
reading the repo while cutting exists to solve — and it must be able to be conversational, which a
subagent cannot be. A `Skill` call loads these instructions into the calling session, which is exactly
what leaves Slice in the session that can talk.

## Refuse first

Read the front matter of `dev-path/<slug>/spec.md`. That read is the validation; there is no separate
front-matter check anywhere in `dev-path`.

- **`git branch --show-current` returns `main`, `<base>`, or a branch with no matching spec directory**
  → **stop.** Do not guess which spec this is. Say the next act: `git checkout <slug>`, or run
  `dev-path:initiate` if the spec does not exist yet.
- **The command returns empty** → **stop, and say what is actually wrong:** it returns empty with exit
  code 0 under a detached HEAD, so the truth is *you are not on a branch*, never *no spec on this
  branch*. The fix is one `git checkout -b <slug>`, and it is a human's.
- **`design_approved` is not `true`** → **stop and say so.** Do not slice. Say the next act: run
  `dev-path:technical-design` and take the design through its gate.
- **`## Design` is empty** → **stop.** There is nothing to cut.
- **The front-matter block does not parse, or a field carries the wrong shape** → **stop and name the
  exact field.** *Malformed* stops the stage; *absent* is a legal state meaning *not yet*.

**Prefix every message this skill prints when it stops with `dev-path: `.** Suggested.

**Reaching this skill from `dev-path:technical-design` satisfies the gate by route rather than by
exception.** The command writes `design_approved: true` when the human approves, and only then calls
Slice — so the field is there and this refusal never fires. It fires on the route that needs it: a human
typing `/dev-path:slice` on a spec whose design was never approved.

## Read

`## Design`, `## Outcomes`, `## Out of scope`. Then read the repo while deciding how to cut.

**Reading the code while cutting is the point, not diligence.** It is what surfaces work that reshapes
the code so the change becomes easy — a slicing insight, not a design one, and a Slice that read only the
spec cannot have it.

## How to cut

Three rules, three different jobs.

| Rule | Governs |
| --- | --- |
| Split **only** where a reviewer could meaningfully reject one slice while approving its neighbour | **How many** — a floor. Do not split finer than reviewability |
| Cut **a narrow but complete route through every layer the change requires, verifiable on its own; never a horizontal slice of one layer** | **Which direction** |
| Sized so **the real (`-w`) diff fits one fresh context**, and edits into oversized shared files are surgical and generated | **Artifact count** |

**All three are adopted, they can disagree, and the disagreement resolves rather than being a defect.**
Splitting for reviewability yields independent slices. Splitting for size yields **dependent** slices —
unless the pieces share no references at all, as in a version bump cut by metadata type, in which case
they are independent. **`depends_on` is exactly what records the difference.**

**The third rule measures the *real* diff.** In an SFDX repo the file set is decoupled from the work by
three to five orders of magnitude — 325 real lines can sit inside 26.4 MB of files — so *sized to one
context* must never be read as *the file set fits one context*.

### The direction rule is a cutting instruction, never a self-test

**Use the direction rule above to decide how to cut. Do not turn it around and apply it as a test to the
layout you just produced.**

As a test it is self-referential: nothing fixes what *the change* is, so *the layers the change requires*
are whatever the slice ended up touching, and completeness is satisfied by construction. The chain that
actually holds is different — **you cut and write the behaviour line, the human sees the layout and can
change it, the gate stores the approval, and nothing else checks.** What the behaviour line buys is not
self-grading: it is **a claim a different party can check.** You can require that a behaviour sentence
exists; you can never require that it is complete.

**A change complete in one layer is vertical.** A recurring permission-set-only change is in bounds — it
is not a *piece* of anything. That case is exactly where the second clause misfires if it is read as a
test.

### The worked pair

- **In bounds:** *users in the Warehouse role can see Lot Number on the item record.*
- **Out of bounds:** *adds a method to `ToleranceService`.*

**Honest weakness, stated: a fluent behaviour line can dress a bad slice.** *"Tolerance checking is
available to the invoice matcher"* reads like behaviour and names no user. The template narrows the lie;
only the person at the gate kills it.

### Slice partitions; it never invents

The decision *to* reshape the code first belongs to Design. A slice that does the reshaping is a
legitimate slice and sorts first in dependency order.

**If the design cannot be sliced as written, refuse and say why**, sending the work back to Design. That
is cheap and fixable on the spot — say which part of `## Design` cannot be cut and what would make it
cuttable.

### Wide refactors

For one mechanical change whose blast radius fans across the codebase, use expand–migrate–contract.
**Expand** — add the new form beside the old; nothing breaks. **Migrate** — move references in batches
sized by blast radius, each batch its own slice, each safe because the old form still exists.
**Contract** — delete the old form last, blocked by every batch. `type: refactor` is where it lands.

**A mass rename is one slice, not many dependent ones** — the N = 1 case.

A once-per-repo format conversion is repo work rather than a spec: it fits no context at any cut.

## Write

**One file per slice at `dev-path/<slug>/slices/<nn>-<name>.md`, zero-padded.** Zero-padding is not
decoration — `ls` sorts `10-` before `2-`. **The number is authoring order, never execution order;**
`depends_on` owns execution order, and a reader who takes the number as an ordering claim has two sources
of truth for one fact.

```markdown
# <Title>

---
depends_on:
touches:
---

> Watch a new test go red before you make it green.
> *Why: a test written before the code cannot be written to hit a coverage number — there is nothing to
> cover yet. Retires when Apex gets mutation testing.*

## What to build
## Acceptance criteria
## Deviations
## Critique findings
```

**Write the test-first block into every slice file.** It sits between the front matter and the first
heading, so it adds no `## ` heading and leaves a schema check that flags headings outside the schema
unaffected. It is one copy per slice file — a five-slice spec carries it five times — which is the cost of
a template that is generated rather than referenced. It is **Build's suggestion living in Slice's
output**: Slice writes it, and `dev-path:build` names it as the thing the slice file carries.

**`done` and `fix_cycles` are absent at creation.** Mandated. `done: true` is Build's, written when the
acceptance criteria are ticked; `fix_cycles` is Critique's, written on its first pass over the slice. A
slice created carrying `fix_cycles: 1` would put every new slice one lap from the two-cycle cap.

### `## What to build`

**The end-to-end behaviour this slice makes work, from the user's perspective — not a layer-by-layer
list.** One sentence. This is the load-bearing artifact of the whole file.

### `## Acceptance criteria`

**Mandated. One `- [ ]` per criterion, drawn from `## Design` and from the Outcomes this slice serves.**
Not from the code, which does not exist yet. **The floor is one criterion**, and one is legal, exactly as
a set of one slice is.

**A criterion is a claim a different party can check.** Same test as the behaviour line, one altitude
down. `- [ ] A Warehouse-role user sees Lot Number on the item's detail page` is one;
`- [ ] the service method is implemented` is not.

**They are not a second behaviour statement.** `## What to build` is the one sentence saying what the
slice makes work; the criteria are the checkable consequences of that sentence. Where the two would read
identically, write the criterion and let the overlap stand.

**Slice writes them and Build ticks them — never the other way round.** The session that just designed
the thing is the one that knows what *done* would look like, and the criteria are part of the layout the
human sees at the design gate. **Build writing its own acceptance criteria is Build grading itself**,
which is the failure the direction rule above already names.

This is not a second exception to *nothing writes a placeholder*: Slice always has something to put here,
because a slice with no checkable consequence is a slice with no behaviour statement either — and that is
the cut being wrong rather than the heading being empty.

### `depends_on` and `touches`

**`depends_on` holds full paths to other slice files**, of the form
`dev-path/<slug>/slices/<nn>-<name>.md`. Not ordinals, not slugs, and no flat form. It means *this slice
cannot start until that slice is done*, which is a statement about slices. Slice writes every slice file
in one pass, so they all exist and the cited-paths check genuinely validates the whole graph with no new
machinery.

**`touches` holds paths to pre-existing files the slice will modify.** Two readers: the cited-paths check
and the contention checkpoint.

> **`touches` is what this slice will collide with, not where to work.**

That clause is load-bearing and it is prose, which is the honest weakness: telling an agent the change
goes in a named file makes it edit that file even when the right change is elsewhere. Build is explicitly
not instructed to touch those paths and not limited to them.

**There is no `creates:` field.** `touches` is safe on every count — the files exist so the check really
works, and it describes code that already exists, so it does not decide Build's file layout. `creates:`
would name files that do not exist yet, so **it reads as checked while nothing checks it**, and it decides
Build's business. Every shared-file collision worth catching is a collision on a pre-existing file, and
the edge case resolves without it: if slice 2 modifies a file slice 1 *creates*, slice 2 already
`depends_on` slice 1.

**Two consequences of `touches` being pre-existing-only.** On a greenfield repo, whose dominant act is
creating metadata, `touches` is often empty — so any future trigger derived from it is blind exactly where
`dev-path` runs. And two specs inventing the same new object appear in no field anywhere.

**The cited-paths check runs here, as you write, and it refuses.** A `depends_on` path that does not
resolve is Slice's own error — Slice wrote every slice file in one pass — and is fixable in the same
breath. A `touches` path that does not resolve at the moment it is written is wrong by definition, because
`touches` holds pre-existing paths only. **Refuse on either, and name the slice and the path.**

## Checkpoint

Run the cross-spec contention script from the repository root and **show its output verbatim if it printed
anything.**

```sh
sh "${CLAUDE_PLUGIN_ROOT}/scripts/contention.sh"
```

`${CLAUDE_PLUGIN_ROOT}` is required — a bare relative path resolves against the target repository, where
nothing of the plugin's exists. It takes an optional remote and base branch, defaulting to `origin` and
`main`; pass the resolved base branch when it is not `main`.

**It stores nothing and stops nothing, and it always exits 0.** Empty output is the normal result. It
prints file collisions across specs, specs sharing an `upstream` entry, and the names and intents of the
in-flight neighbours it found.

**Do not summarise it.** Show it as printed. A collision is one value appearing under two or more distinct
slugs, and what a reader does about it is talk to the other engineer.

## Stop

**Show the layout and stop.** The slice list, each slice's one-sentence behaviour line, and the
`depends_on` edges between them.

**Commit the slice files.** When Slice was reached by `dev-path:technical-design`, that command pushes
once the layout settles, so the human sees the design and the layout together on the draft pull request.
Run alone, commit and push here.

**The human may reject the layout, and that does not withdraw the design approval.** One verdict sending
the whole thing back was rejected, and the design is not what was rejected. **Re-cut conversationally in
this same session**, with everything still in context. The cold fallback is `dev-path:slice` alone against
the approved design.

**A `dev-path:technical-design` run never ends with `design_approved: true` and zero slice files.** That
is a postcondition on the command, and it is why this skill is separately invocable: a session that dies
after the approval and before the cut leaves an approved design with no slices, and running
`dev-path:slice` recovers it.
