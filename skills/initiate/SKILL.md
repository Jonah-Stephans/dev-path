---
description: Turn an arriving requirement — a link, a paste, or one typed sentence — into a devpath spec. Use at the start of a piece of work, before any design or code.
---

# Initiate

Initiate creates the spec. It is the first stage of `devpath` and the only one that runs before a
spec exists.

**The contract is a postcondition on the spec, never a precondition on the arriving text.** There is no
bar a requirement must clear to be accepted here. *Ready* is not a property a requirement has; it is the
state after a human accepted a distillation. A precondition on the arriving text would be a check on
whether someone else's prose is good enough, held against the one party this workflow cannot bind.

**The primary experience is an engineer typing a sentence. A link is one way to supply one.** Read that
ordering as load-bearing: written the other way round `devpath` reads as tracker-shaped, and it is not.
**A spec with no upstream is the normal case, not a degraded one** — an engineer-originated refactor has
no requirements set, no requester and no link, `upstream` is an empty list, and nothing else moves.

Where the arriving text has internal structure, **the engineer points at one requirement.** That pointing
is a human act, so the requirements set's own shape — numbered, bulleted, or a wall of prose — is
something `devpath` **tolerates and never parses**.

## Refuse first

**`devpath:initiate` is excepted from the refuse-on-`main` rule, explicitly and by name.** Every other
stage skill discovers its spec with `git branch --show-current` and refuses on `main` or on a branch with
no matching spec directory. Initiate is the skill that *creates* the branch, so it has nothing to
discover, and the rule read literally would be an Initiate that can never create anything.

The exception is narrow, and the reason bounds it: **the rule exists so no stage ever guesses which spec
it is operating on.** Initiate is the only skill with no spec to guess about.

Two refusals are Initiate's own.

- **A branch that already holds a spec directory for a different slug** → **stop.** That is somebody
  else's spec branch, and creating a second spec on it would put two specs in one pull request, which
  one branch / one draft pull request / one approval forbids. Say the next act: `git checkout <base>`
  and run `devpath:initiate` again.
- **A colliding slug**, found by the sweep below → **stop, and propose a better, non-colliding slug.**
  Never a numeric suffix — not `decline-codes-2`. Being forced to say what is *different* about the
  second spec produces a better name than the first one had, so the proposal is a real name:
  `decline-code-retry-window`.

**Prefix every message this skill prints when it stops with `devpath: `.** Suggested — the same prefix
every pasteable block in the README echoes, so a human reading a stop meets one prefix rather than two.

### Re-entry on an accepted spec withdraws both gates, and says so

**Mandated.** `devpath:initiate` re-run on a spec directory that already carries `intent_accepted: true`
**announces that the intent gate is returning to unapproved** before it changes anything, then **deletes
`intent_accepted` and `design_approved`**, and carries on. Say it in substance: *this moves the intent back
to unapproved — you will accept the new version when we are done.*

**Withdrawal is a deletion of the field, never a `false`.** Nothing in `devpath` ever writes `false`, and
a guard written against `intent_accepted: false` could never fire.

**Taking `design_approved` with it is not overreach.** Initiate overwrites the five sections, so any design
rested on Outcomes that have just changed. Leaving `design_approved: true` in place would let
`devpath:build` proceed on a design approved against a superseded problem.

| Deleted | Survives untouched |
| --- | --- |
| `intent_accepted` **and** `design_approved` | the branch, the draft pull request, the slice files, `## Critique findings`, `## Deviations`, `## Traps` |

**The slices survive on purpose.** They are work, `design_approved` is absent so nothing acts on them, and
`devpath:technical-design` re-slices when the design settles. Deleting them would be this skill throwing
away an artifact the human never asked it to throw away. **The draft pull request survives, always** — one
per spec, for the spec's whole life, and nothing in a re-entry changes which spec this is.

**Announcing is the whole of what makes this acceptable.** The uncomfortable part of an automatic
withdrawal is *silence*, not the deletion — here the human is in the room, asked for the rework, and is
told. The decision is not being overturned; its **subject** is being replaced, at the human's own request,
and git keeps the old value regardless.

## Read

**Read the requirement. Read the epic's own text if there is one. Never walk its children.** Mandated.
Reading one more document is not parsing the requirements set's shape; walking its children is, and
`devpath` never does that.

**Snapshot once.** No later stage ever reads upstream again. That single decision is what collapses the
whole upstream dependency to one optional read at one moment, keeps every downstream stage pure to the
repo, and makes a cold session work offline.

**Say *no later stage* rather than *never*, because there is one route back:** a human re-runs
`devpath:initiate` on an existing spec directory when the requirement itself moved, and that run
re-reads upstream and updates the entry in place. That is Initiate running again on a human's request,
not a downstream stage reaching sideways — so there is still no drift check, and there cannot be one.

**`devpath` declares no MCP server.** Initiate accepts a link or pasted text and is agnostic about how
a link gets read. The degradation ladder is: an MCP server the engineer already has → whatever
direct-read tooling the engineer has → paste. `devpath` declares none of the three, because shipping a
server declaration forces it on repos that do not want one, and owning credentials is a route already
proven to rot.

**Initiate does not read code.** Mandated. An Initiate that reads code starts proposing implementations,
and the intent gate quietly becomes an early design gate resting on a shallow read.

**Initiate is not a conversation.** Command 1's only human moment is the gate. There is exactly one
conversation in `devpath` and it is at Design. Two shallow conversations cost more than one deep one,
because the human context-switches in, out and back in — and Initiate has nothing left to argue about:
every refusal is homed elsewhere, the gate's job is a *reading*, and the spec-boundary decision sits at
Design.

**Accepted cost, stated so it is not discovered later: a possibly-wasted Survey.** Survey clusters the
Outcomes into areas and reads against them, so unargued Outcomes can send it at the wrong areas, with
Design's conversation correcting the problem after Survey ran.

**What makes that acceptable is Survey's ceiling, and not a fan-out being free.** A wasted Survey costs at
most five discarded subagent reads inside one session — no human hour, no code, no pull request. **An
earlier form of this paragraph called the fan-out cheap outright, and that claim is withdrawn**: measured,
it was thirteen researchers on the session's own tier, and that sentence is why nothing ever bounded the
count.

## Derive the slug

**Mandated. Derive the slug from the accepted intent: two to four words, lower case, ASCII letters and
digits, hyphen-separated. Nothing else.**

| Rule | Why it is a rule and not a preference |
| --- | --- |
| **From the intent, never from the upstream text** | `upstream` is optional and the no-upstream case is the normal one. A slug derived from an issue key is the tracker's identifier wearing a directory's clothes |
| **Two to four words** | it is read in `ls devpath/` and in a branch listing. One word is almost never distinguishing on the second spec; five is a sentence |
| **Lower case, ASCII, `[a-z0-9-]` only** | it is simultaneously a directory name and a git branch name. **No slash** — a slash makes it a branch namespace rather than a slug, and it is what tells a lessons branch apart from a spec branch |
| **No leading or trailing hyphen, no dots, no consecutive hyphens** | `.` and `..` are git ref restrictions, and the rest is what keeps `ls` output readable |
| **No prefix and no number** — not `devpath-`, not `feat-`, not the `type` value, not a sequence | the directory it sits in already says `devpath`, `type` is a field, and sequential numbering does not survive this store: specs are created on branches that cannot see each other, so two engineers running Initiate the same morning both take `47-` and the collision surfaces at merge instead of here |
| **Name what is different about it** | the same standard the collision proposal uses. Applied at the first spec, the second one is cheaper |

**A directory level per requirements set, or its name as a slug prefix, is the deleted level returning by
the back door.** It has a location and its name is the ask above. There is no level above a spec: a spec
optionally carries `upstream`, a list of what Initiate read, and that is all. Anyone who proposes a
grouping directory or a shared prefix should be pointed at this paragraph.

**The human confirms the slug at the intent gate and nowhere else.** It is shown with the five sections;
accepting the intent accepts the slug. No separate confirmation — a checkpoint that acquired a stop would
be overhead, and the gate is already there, reading the thing the slug names.

## Sweep for a colliding slug

`devpath/` is flat and merged specs are never deleted, so the second `devpath/decline-codes/` is
refused by `mkdir` rather than by policy. Check `<base>` plus every branch, local and remote, in one
sweep — **before any work exists.**

```sh
git fetch --prune --quiet
git ls-tree -r --name-only <base> -- devpath/ | awk -F/ '{print $2}' | sort -u
git for-each-ref --format='%(refname:short)' refs/heads refs/remotes
```

**`<base>` is the repository's base branch, resolved rather than assumed:**

```sh
base=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
```

Sweeping the wrong ref reports clean and surfaces the collision at merge, which is the failure this
check exists to prevent. Where `gh` cannot answer, fall back to `main` and say which ref was swept.

**The fetch is not optional and the stated failure case is why.** *Two engineers running Initiate the
same morning* is only detectable if the sweep sees the other engineer's branch, and a local clone knows
only what it has fetched. `--prune` matters for the mirror-image reason: a stale remote-tracking ref for
a deleted branch reports a collision that no longer exists.

**With no remote configured the sweep covers `<base>` plus local branches and says so in one line.** It
does not fail — a repo with no remote has no second engineer to collide with yet, and refusing would be a
stop nobody can clear.

## Write

**`git checkout -b <slug>` from `<base>`**, then write `devpath/<slug>/spec.md`.

**`devpath/` sits at the repository root. Fixed, not configurable.** A setting means every skill
resolves it before doing anything and the router grows a branch. Every spec is a directory with
`spec.md` and N ≥ 1 slice files; there is no collapsed single-file form.

```markdown
---
type: feature
upstream:
  - url: https://example.atlassian.net/browse/ABC-123
    read_at: 2026-08-19
    source_updated: 2026-08-14
---

# <Title>

## Intent
## Outcomes
## Out of scope
## Open questions
## Evidence
```

**The front-matter block starts at byte zero and the title sits under it.** That is where every
front-matter parser already looks and, more to the point, where every markdown formatter already knows not
to reformat. A fence below the title is not front matter to a formatter — it is a thematic break followed
by an ordinary list, and prettier rewrites it into a nested one, which silently demotes `done` and the two
gate fields out of the top level. That is measured, not theorised: it corrupted four slice files on the
first real run.

**One consequence, because a reader will see it.** GitHub renders a real front-matter block as a table
above the body, so a merged `spec.md` shows its fields as a table and then its `# Title`.

**No gate field yet.** `intent_accepted` is written at the gate below and not before. Value is always
`true`; absence is how you say no; nothing ever writes `false`.

**`type` is one of `feature`, `bug`, `refactor`, `config`, `doc`.** Nothing in `devpath` branches on it
today — it is kept because a human reading a spec is a reader.

**Write only the sections you have something to put in.** A stage writes a section only when it has
content for it; absent and empty mean the same thing. Gating a section's presence yields the word `none`
typed to satisfy a check, which is worse than nothing.

### The five sections, each with a named reader

| Section | Read by |
| --- | --- |
| `## Intent` — the problem and the outcome, one paragraph | the human at the gate; every later stage |
| `## Outcomes` — the testable statements | the Outcomes pass, checking code against the requirement |
| `## Out of scope` | Design and Build, to refuse creep |
| `## Open questions`, with owners | Design |
| `## Evidence` — verbatim and attributed | Design and Build, when a question has no answer |

**`## Outcomes` is always the agent's translation, and there is no marker for it.** No field, no
convention distinguishes a quoted Outcome from an inferred one, because two axes pull opposite ways: a
user story is something a human said and nothing can check it; a technical translation is checkable and
no human said it. Marking the first as authoritative creates pressure to paste user stories in *as*
Outcomes so they can carry the mark, hardcoding the checkable artifact to non-technical prose. **The
translation is the valuable work.** The humans' verbatim words live in `## Evidence`, attributed.

**The snapshot is lossy by choice, and `## Evidence` is what survives**, because it pre-answers design
questions. A quote saying *"we'd probably be none at the company level… maybe down the road we'll relax
a bit"* **answers** the design question *what should the company-level default be?* Summarising that away
destroys the local answer store and forces a question that had already been answered, through the one
channel that costs a human conversation. Evidence bloat solves itself — Design prunes `## Evidence` to
what the design rests on, and git holds the rest.

**An ordering claim in the arriving text binds nothing.** Requirements often arrive already ordered —
*"this one is dependent on Step-3 ABC-123"*. **Mandated: capture it as prose in `## Evidence`, verbatim
and attributed, and nowhere else.** No field, no cross-spec `depends_on`.

The primary reason: that is priority order, authored by someone not positioned to know implementation
order. The arriving text is non-technical by construction, so importing it as a dependency would encode
a non-technical guess as a technical constraint. The secondary reason is mechanical: a cross-spec
`depends_on` cannot pass the cited-paths check while the sibling spec has not been initiated, so it
would be the one field in the design that dangles by construction. **Implementation order is decided at
Design and Slice**, where `depends_on` holds paths inside a single spec.

**An unanswered question can reach `main`.** `## Open questions` is written with its owner and read at
Design; nothing gates on it, and nothing stops a spec merging with one still open. That is deliberate —
gating it would yield the word `none` — but it is worth knowing rather than discovering.

### `upstream`, and how its `url` is normalised

**Mandated. Write `url` as: scheme and host lower-cased; no trailing slash; no query string and no
fragment; the path's case left exactly as it arrived.**

| Rule | Why |
| --- | --- |
| host lower-cased | hostnames are case-insensitive, and a paste from a browser bar and a paste from a chat client differ on it |
| trailing slash dropped | the commonest single difference between two links to one page |
| query string and fragment dropped | `?focusedCommentId=`, `#comment-4` and a tracking parameter all name the same document. A link whose query string is load-bearing is not an issue link, and if one ever is, it survives in `## Evidence` where the arriving text is kept verbatim |
| path case preserved | issue keys and slugs are case-sensitive on some hosts, and lower-casing the path would break the link rather than normalise it |

This is what the cross-spec sibling report rests on: it compares `upstream` values as exact strings, so
two specs reading the same issue through differently-shaped links are silently not reported as siblings.
**No host aliases, no redirect following, no shortening rules** — each needs a table of hosts, which is
either somebody's local fact or a tracker's shape being parsed, and Initiate never does either. The rule
is syntactic and knows nothing about the systems it points at.

**Per-entry timestamps, not one pair for the whole read**, because the documents move on independent
cadences and one pair would say *something changed* and never *which*.

**At the bottom of the ladder the entry degrades, and never by guessing.** Mandated:

- **A link the engineer supplies, with pasted text** — the entry carries `url` and `read_at`, and
  **`source_updated` is omitted.** Absence is how you say no. Its reader is a human already looking at
  the link, and an absent key tells that human *this was never captured* rather than lying with a date.
- **Pasted text and no link at all** — **`upstream` is the empty list.** An entry whose only content is
  *something was read at some time* records nothing anyone can go back to.

**Never a fabricated or guessed value, and never `read_at` copied into `source_updated`.** That turns the
one line that makes drift *noticeable* into a line that always says *fresh* — worse than its absence, and
undetectable.

## The intent gate

**Report the one thing Initiate reports, then ask.**

Initiate has no refusal on content. Every candidate reason to refuse has a better home: *too big* is
narrowed at Design behind the design gate; *too thin* is the gate itself, where a human reads it;
*ambiguous* goes to `## Open questions`, read at Design. A refusal route with nothing left to refuse only
ever fires on a false positive, and it teaches people to route around Initiate.

**The one thing Initiate reports** is that it read structured input plainly describing more than one
change — **a sentence in its output, not a stop.**

**The gate checks exactly two things mechanically: `## Intent` non-empty, `## Outcomes` non-empty.** No
mechanical check on `## Out of scope`, `## Evidence` or `upstream` — a requirement legitimately has none
of them.

> **Say it plainly: the mechanical check at this gate is nearly worthless. The human reading is the whole
> gate.**

Pretending otherwise is how you get a check that goes green on a spec nobody read. The reading the gate
actually wants is **read the Outcomes and confirm the translation is faithful to the Evidence**, both
halves on the page. That reading is what converts a model's judgment into a human-accepted statement.

**How the yes is captured: plain prose, and then the turn ends.** `devpath` names no question tool at
either gate. A tool that presents options invites a click where this gate wants a read — and naming a
harness tool is a dependency `devpath` does not otherwise take, whereas a gate that works by ending the
turn works in every harness that can run a skill at all.

**So: state what was accepted, show the slug, ask for the go/no-go in one sentence, and stop.** The next
turn is the answer. A yes writes `intent_accepted: true`; anything else writes nothing.

**The gate's subject includes scope, not only content.** One spec is one design a human can approve in
one sitting — not a size test, because size is what slices are for. **When in doubt, make it one spec:**
narrowing later costs one branch and one draft pull request, while merging two later costs an abandoned
pull request, a re-scope, and two intent gates already burnt.

## Stop

**Commit, push, and open the draft pull request — one commit**, so the spec *is* the branch's first
commit whichever way the answer went.

```sh
gh pr create --draft --base <base> --head <slug> --title '<the spec title>' --body-file -
```

**The body is `## Intent`, verbatim.** It is the one section the gate requires non-empty and the one a
reader wants first, and `devpath:integrate` rewrites the body later anyway.

**This step runs on a no as well as a yes, and that is deliberate.** A spec whose intent was declined is
not a mistake to hide: `devpath:technical-design` refuses without the field, so nothing proceeds, and
**abandoned is a closed pull request whose file never reached `<base>`** — which requires the pull request
to exist. Initiate always writes a spec, and this is what that costs and buys.

**If `gh` is absent or unauthenticated the command fails with `gh`'s own error and Initiate stops there.**
The branch and the commit already exist, so nothing is lost, and the next act is named: authorise `gh`
and re-run `devpath:initiate` on the existing directory, which opens the pull request. The act that
needs the property is the check, and the tool's own error is the whole signal.

**What the draft pull request buys, so nobody removes it as ceremony.** A bare branch is genuinely
invisible: an unpushed branch is invisible to everyone, code search indexes the default branch only, and
nothing in the GitHub interface surfaces a branch-resident file without a pull request. A draft pull
request ends all of that and makes pushing **mechanical rather than disciplinary** — you cannot have a
draft pull request on an unpushed branch. It needs no approval, cannot be merged, and gives the design
gate a readable, inline-commentable diff at zero approval cost.

**One branch, one draft pull request, one approval.** `devpath:initiate` opens it; `devpath:integrate`
marks that same pull request ready and arms auto-merge.

Then show what was written and stop. The next act is `devpath:technical-design`.
