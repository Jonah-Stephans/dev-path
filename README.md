# dev-path

One engineering workflow, from a non-technical requirement through to merged code. Eight stages, two
human gates, ten skills. Salesforce-shaped and program-agnostic.

## Install

```
claude plugin marketplace add Jonah-Stephans/dev-path
claude plugin install dev-path@jonah-stephans
```

## Check it worked

> Type `/dev-path:` and confirm the skills appear.

**A plugin that failed to install cannot detect that it failed to install.** Any preflight or self-check
shipped *inside* a plugin is unreachable in exactly the case it exists for. This line works because it
reaches only people who are already installing.

## First use

> Run `dev-path:initiate` on a real requirement. Stop at the intent gate.

One command, a real requirement, and you have a spec file, a branch and a draft pull request in minutes.
It needs no CI, no scratch org and no branch protection working yet — Initiate touches none of them.

Every stage is individually invocable, so a one-stage first use is the design working as specified. A
full end-to-end run on a small real change is the right *second* use.

## Is this repo ready?

> Run `dev-path:fit-check` when the repo is new, and again if `dev-path` stops feeling like it buys
> anything.

## What you can gate on

**`dev-path` ships no enforcement and never depends on any.** A repo that enforces nothing gets identical
behaviour from `dev-path`, just less attended. Everything below is a repo's own choice, pasted into the
repo's `.claude/settings.json`.

**The recommended default is one check, not a suite** — the open-box grep, as a job on the pull request:

```bash
SPEC="dev-path/${GITHUB_HEAD_REF:?not a pull request build}"; test -d "$SPEC" && ! grep -rn '^- \[ \]' "$SPEC/"
```

**The slug comes from the pull request's head ref, never from `git branch --show-current`** — this job
runs on a detached HEAD, where that command returns empty and the path collapses to `dev-path/`, an
unscoped sweep that fails this spec on a neighbouring spec's open boxes. `GITHUB_HEAD_REF` is GitHub
Actions' name for the source branch; substitute the one your CI sets. **`test -d` is what makes a wrong
slug red:** `grep -r` on a missing directory exits 2, the leading `!` turns that into 0, and the job
passes having tested nothing.

<details>
<summary><b>The menu — seven blocks over six properties</b></summary>

**What a repo can make hard, and what it cannot.** Nine properties; seven have a block below.

| Rule | Repo-enforceable? | Mechanism |
| --- | --- | --- |
| No undispositioned `- [ ]` reaches the base branch | **hard** | the open-box grep above, as a job on the pull request, scoped to the spec's directory by the pull request's head ref. **Not section-blind at push time** — `## Acceptance criteria` boxes are open by design mid-build, so block 1 is narrower |
| `fix_cycles >= 2` opens no unattended fix pass | **the rule holds; no block ships** | the grant is *spoken and never stored*, so a hook reading the field cannot tell a capped slice from a granted lap. A repo can only buy this by giving up the granted lap |
| A gate field is `true` before the next stage runs | **hard** | block 2 |
| Spec and slice files match the schema | **hard** | block 4 |
| A mid-run stop stops the whole run | **hard** | block 3 |
| A missed `fix_cycles` increment is caught | **withdrawn — there is nothing to catch** | a slice carrying `- [x] fixed` with the field at `0` is the **legal mid-cycle state**, and a missed increment is byte-identical to it on disk. **A missing line is a different thing and is caught** — Integrate's step 3 refuses on a built slice that has none |
| A lesson entry carries a resolving link | **hard** | block 5 |
| Learn runs before the merge | **hard** | blocks 6 and 7 |
| **A per-worker token budget** | **NOT AVAILABLE** | no hook input carries token counts |

**Three of those nine rows ship no block**, and the README says so rather than leaving you to notice the
table is longer than the menu: the `fix_cycles` cap has no honest hook, the missed-increment row is not a
rule any more, and the token budget is unavailable.

**One markdown trap: the matcher is `Task|Agent`.** Where you see a backslash before the pipe in prose,
it is markdown escaping a table column separator — it is not part of the string. The blocks below carry
`"matcher": "Task|Agent"`, and that is the form that goes into `settings.json`.

**Three facts make every block readable.** A hook receives its input as **JSON on stdin**. A `PreToolUse`
hook **denies by exiting 2**, and its message goes to whoever made the call. A `PostToolUse` hook **cannot
deny**, because the write it is reacting to has already happened.

**Merge the blocks rather than repeating the `hooks` key.** Two of the seven parse the dispatch first line
`dev-path slice: <path>` and are silently inert on any other dispatch.

**Blocks 1, 6 and 7 find the spec with `git branch --show-current`, which is empty under a detached
HEAD** — they go inert rather than wrong. They are hooks, running in a session where a branch is normally
checked out; the grep above is a CI job, where one normally is not.

---

**1 — Nothing pushes while a slice is stopped.** `if` is a real hook key — a permission-rule filter,
honoured on tool events, so the command runs only on a `git push`. **One over-fire, documented rather than
a surprise:** a pattern naming more than the command also runs on a call containing `$()`, backticks or
`$VAR`. The cost is bounded because the command exits 0 whenever no stop box is open — but while one *is*
open, an unrelated Bash call carrying a variable is denied too.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "if": "Bash(git push*)",
        "hooks": [
          {
            "type": "command",
            "command": "SLUG=$(git branch --show-current); [ -d \"dev-path/$SLUG/slices\" ] || exit 0; for f in \"dev-path/$SLUG\"/slices/*.md; do [ -f \"$f\" ] || continue; grep -q '^done: true$' \"$f\" && D=0 || D=1; H=$(awk -v d=\"$D\" '/^## Deviations/{s=(d+0);h=\"## Deviations\";next} /^## Critique findings/{s=1;h=\"## Critique findings\";next} /^## /{s=0} s&&/^- \\[ \\]/{print h;n=1;exit} END{exit !n}' \"$f\") && { echo \"dev-path: $f carries an open - [ ] under $H\"; exit 2; }; done; exit 0",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

**This is not the recommended grep with a hook wrapper, and the difference is the whole of the block.**
That grep runs on the pull request, where *Critique clean* — section-blind, whole spec directory — is the
right test. This one runs on **every push during a build**, and Slice writes `## Acceptance criteria` as
open boxes at creation, so section-blind here would deny the first push of every ordinary run. It is
scoped to the two sections that mean stop, and to the spec on this branch rather than all of `dev-path/`.

**A third scoping, and it is Build's rule rather than this menu's.** The commit-excess box is written
*after* `done: true`, and **a done slice with an open box under `## Deviations` is not a pause and must not
be read as one** — that box lands inside the slice's own commit, so without this the block would deny the
push of the commit that created it. The block skips `## Deviations` on a slice carrying `done: true`, and
**never skips `## Critique findings`** — a finding left open on a finished slice is a real stop. The
message names which of the two headings it found, because the two mean different things.

---

**2 — A gate field is `true` before a slice is built.**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Task|Agent",
        "hooks": [
          {
            "type": "command",
            "command": "SLICE=$(jq -r '.tool_input.prompt // \"\"' | head -1 | sed -n 's|^dev-path slice: ||p'); [ -n \"$SLICE\" ] || exit 0; SPEC=\"${SLICE%/slices/*}/spec.md\"; grep -q '^design_approved: true$' \"$SPEC\" || { echo \"dev-path: $SPEC does not carry design_approved: true\"; exit 2; }",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

---

**3 — A mid-run stop stops the whole run.**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Task|Agent",
        "hooks": [
          {
            "type": "command",
            "command": "SLICE=$(jq -r '.tool_input.prompt // \"\"' | head -1 | sed -n 's|^dev-path slice: ||p'); [ -n \"$SLICE\" ] || exit 0; for f in \"${SLICE%/*}\"/*.md; do [ \"$f\" = \"$SLICE\" ] && continue; grep -q '^done: true$' \"$f\" && continue; awk '/^## Deviations/{d=1;next} /^## /{d=0} d&&/^- \\[ \\]/{n++} END{exit !n}' \"$f\" && { echo \"dev-path: $f is frozen and needs a human\"; exit 2; }; done; exit 0",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

**Two things about this block are corrections, and both are the kind that ships inert if got wrong.**

**It tests for the absence of `done: true`, never for `done: false`.** Value is always `true`, absence is
how you say no, and nothing ever writes `false` — so a block greping `^done: false` can never fire.

**And the open-box test is scoped to `## Deviations`.** Slice writes `## Acceptance criteria` as open boxes
at creation, so **every slice not yet built carries open boxes** — an unscoped grep would deny the second
dispatch of every ordinary run. What this block looks for is a *pause*, and a pause is an open box under
`## Deviations`.

This is the strict form: it denies while **any** other slice in the spec is frozen. Build's
disjoint-`touches` exception is deliberately not in the paste — a repo that wants it compares the two
`touches` lists in the same script, and the strict form is the one that fails safe.

---

**4 — Spec and slice files stay inside the schema.** It warns rather than denies, because `PostToolUse`
cannot deny. The blocking variant is the same script on `PreToolUse` reading `.tool_input.content`.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "F=$(jq -r '.tool_input.file_path // \"\"'); case \"$F\" in *dev-path/*/spec.md) P=\"Intent|Outcomes|Out of scope|Open questions|Evidence|Current state|Design|Outcome checks|dev-path feedback\";; *dev-path/*/slices/*.md) P=\"What to build|Acceptance criteria|Deviations|Critique findings\";; *) exit 0;; esac; grep -n '^## ' \"$F\" | grep -Ev \"^[0-9]+:## ($P)$\" && echo \"dev-path: $F carries a heading outside the schema\"; exit 0",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

It checks for headings **outside** the schema and never for missing ones, because *absent and empty mean
the same thing* makes a missing heading legal.

---

**5 — A lesson entry carries a resolving link.** Presence only. Resolution is a second call and belongs in
CI, where a network failure does not stop an engineer's edit.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "IN=$(cat); F=$(printf '%s' \"$IN\" | jq -r '.tool_input.file_path // \"\"'); case \"$F\" in *.claude/rules/*.md) ;; *) exit 0;; esac; B=$(printf '%s' \"$IN\" | jq -r '.tool_input.content // .tool_input.new_string // \"\"' | grep '^- ' | grep -cv 'https://github.com/[^ ]*/pull/[0-9]*$'); [ \"$B\" -eq 0 ] || { echo \"dev-path: $B lesson entry line(s) in $F end in no pull request link\"; exit 2; }",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

---

**6 — Learn runs before the merge.** This is the one item that turns a model-driven instruction into a
guarantee, and the one with a cost: **Learn proposing nothing is a legal outcome**, and this block cannot
tell that from Learn never running. Take it only if the repo accepts *Learn always opens a pull request*.

**The detection is scoped to `dev-path/lessons/$SLUG`.** Unscoped, `gh pr list --state open` enumerates
every open pull request in the repository and passes if any of them touches `.claude/rules/` — so a
neighbouring spec's lessons pull request releases this spec's guard, silently.

**A second limit, stated rather than mechanised.** The condition becomes true at Integrate **step 1** and
Learn runs at **step 7** — and between them sits step 3, which is a hard exit. **After a legitimate
refusal at step 3 this block blocks the end of every turn on the branch**, demanding a Learn run that must
not happen. It cannot tell *Integrate finished* from *Integrate refused*, because those exits are
deliberately unstored. **A repo that takes block 6 accepts that an unmet Outcome means removing the block
or clearing the Outcome before the turn can end.** Block 7 costs nothing here, because it only prints.

**One more limit, and it is about what a lessons pull request contains.** Blocks 6 and 7 detect one by
`gh pr diff --name-only | grep '^\.claude/rules/'`. **A lessons pull request proposing only a check
touches the repo's CI configuration and no rules file, so these blocks do not see it** — they read as
*Learn never ran* when Learn ran and proposed a check.

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "SLUG=$(git branch --show-current); S=\"dev-path/$SLUG/spec.md\"; [ -f \"$S\" ] || exit 0; awk '/^## Outcome checks/{f=1;next} /^## /{f=0} f&&NF{n++} END{exit !n}' \"$S\" || exit 0; for n in $(gh pr list --state open --head \"dev-path/lessons/$SLUG\" --json number --jq '.[].number'); do gh pr diff \"$n\" --name-only | grep -q '^\\.claude/rules/' && exit 0; done; jq -n '{decision:\"block\",reason:\"dev-path: the Outcomes pass has run on this spec and no lessons pull request is open. Run dev-path:learn before the merge.\"}'",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

---

**7 — the same thing as a warning**, for a repo that does not accept that trade. Identical condition, no
denial: it puts the sentence in front of the engineer and stops there.

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "SLUG=$(git branch --show-current); S=\"dev-path/$SLUG/spec.md\"; [ -f \"$S\" ] || exit 0; awk '/^## Outcome checks/{f=1;next} /^## /{f=0} f&&NF{n++} END{exit !n}' \"$S\" || exit 0; for n in $(gh pr list --state open --head \"dev-path/lessons/$SLUG\" --json number --jq '.[].number'); do gh pr diff \"$n\" --name-only | grep -q '^\\.claude/rules/' && exit 0; done; echo 'dev-path: the Outcomes pass has run on this spec and no lessons pull request is open.'",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

---

**Two things are unverified, and which rather than a count.** Running shell cannot test whether the
harness honours a block's wrapper: the `if` key is settled against the official hooks reference, the
`Stop` event's `{"decision":"block"}` shape is not. And blocks 6 and 7 were exercised against a **stubbed**
`gh` — the enumeration, the scoping and the release were tested, the live API was not.

**The post-merge Learn runner is not on this menu.** A workflow file plus a stored credential plus a
decision to run an agent in CI is a procedure, not a paste. It is named here and not specified.

</details>

## What is on disk

<details>
<summary><b>The on-disk contract, complete</b></summary>

**This is the plugin's one complete statement of its own file format.** Each skill body states only the
fields and headings it reads or writes; this states all of them, once.

> **Where a skill body and this section disagree, this section is right.**

### Where a spec lives

**`dev-path/` at the repository root. Fixed, not configurable.** Every spec is a directory holding
`spec.md` and N ≥ 1 slice files. There is no collapsed single-file form: a one-slice spec gets a directory
and two files, and that uniformity is what makes *has this been sliced?* into `ls slices/` in every case.

```
dev-path/tolerance-config/
├── spec.md
├── slices/
│   ├── 01-schema.md
│   └── 02-validation.md
└── sketches/
    ├── config-panel.png
    └── config-panel-decision.md
```

**How you refer to a spec: by the draft pull request's number or its title.** The pull request is opened at
Initiate and lives exactly as long as the spec, and unlike anything `dev-path` could invent it is centrally
allocated. `gh pr list --head <slug>` maps a number to a slug. **There is no `pr:` field** — it is
derivable from the branch, and a field nothing reads is a field to delete.

**The ref is the status.** In flight means the spec exists only on a branch; merged means it is on the base
branch, where it stays in `dev-path/` with no move and no delete; abandoned means a closed pull request
whose file never got there. There is no `status:` field.

### `dev-path/<slug>/spec.md`

```markdown
---
type: feature
upstream:
  - url: https://example.atlassian.net/browse/ABC-123
    read_at: 2026-08-19
    source_updated: 2026-08-14
intent_accepted: true
design_approved: true
---

# <Title>

## Intent
## Outcomes
## Out of scope
## Open questions
## Evidence
## Current state
## Design
## Outcome checks
## dev-path feedback
```

| Heading | Written by | Read by |
| --- | --- | --- |
| `## Intent` | Initiate; **Design rewrites it when its conversation revises the problem, and narrows it when one spec turns out to be two** | the intent gate — **must be non-empty**; every later stage |
| `## Outcomes` | Initiate; Design rewrites it when its conversation revises the problem | the intent gate — **must be non-empty**; Survey's dispatch key; the Outcomes pass |
| `## Out of scope` | Initiate; **Design narrows it to one design** | Design, Build, to refuse creep. **Never gated** |
| `## Open questions` | Initiate, verbatim with its owner; the Design conversation adds | Design; `dev-path:sketch`; a resumed Design |
| `## Evidence` | Initiate; Design may add, verbatim and attributed | the human at the intent gate; Design; Build |
| `## Current state` | Survey; Design prunes it | Design. **Survey done ⇔ non-empty** |
| `## Design` | Design | Slice, Build. **Design done ⇔ non-empty** |
| `## Outcome checks` | the Outcomes pass, run by `dev-path:integrate` | Integrate's refusal; the human at merge |
| `## dev-path feedback` | the engineer, **optional** | Integrate, which offers to file it |

### `dev-path/<slug>/slices/<nn>-<name>.md`

```markdown
---
depends_on:
  - dev-path/tolerance-config/slices/01-schema.md
touches:
  - force-app/main/default/classes/ToleranceService.cls
done: true
fix_cycles: 1
---

# <Title>

## What to build
## Acceptance criteria
## Deviations
## Critique findings
```

**That skeleton is a mid-life slice, not a new one.** `depends_on` and `touches` are Slice's, written when
the file is created. **`done` and `fix_cycles` are absent at creation** and appear when their writers first
write them.

- **`## What to build`** — the end-to-end behaviour this slice makes work, from the user's perspective, not
  a layer-by-layer list.
- **`## Acceptance criteria`** — Slice writes them from the design; Build ticks each one as it satisfies
  it. One `- [ ]` per criterion, closed as `- [x] met`. They count toward *Critique clean* like every other
  box in the directory.
- **`## Deviations`** — Build records; Integrate carries into the pull request body; the human sees it at
  merge. Recording is mandatory; whether to stop is the engineer's call.
- **`## Critique findings`** — Critique's slice pass. Appends across cycles.

**Zero-padding is not decoration** — `ls` sorts `10-` before `2-`. **The number is authoring order, never
execution order;** `depends_on` owns execution order. **`depends_on` values are full paths** of the form
`dev-path/<slug>/slices/<nn>-<name>.md`; any flat form is wrong.

**`dev-path/<slug>/sketches/`** holds an artifact a later stage reads, plus its decision note. **This is
the only place a non-text file exists anywhere in `dev-path`.**

### The front-matter block starts at byte zero

**The block is the first thing in the file and the title sits under it.** That is where every front-matter
parser already looks, and where every markdown formatter already knows not to reformat. Below the title it
is not front matter at all — it is a thematic break and a list, and prettier renests the list, which
demotes `done`, `intent_accepted` and `design_approved` out of the top level without touching the file's
validity as YAML. **One consequence, because a reader will see it:** GitHub renders the block as a table
above the body.

### The eight fields

**Four on the spec, four on each slice.** YAML, snake case, `type` first and the gates last so a diff shows
a gate appearing at the end of the block rather than in the middle of it.

| Field | Lives on | Written at | Read by |
| --- | --- | --- | --- |
| `type` | spec | Initiate | **a human only.** `feature` \| `bug` \| `refactor` \| `config` \| `doc`. **Nothing in `dev-path` branches on it today** — it is kept because a human reading a spec is a reader |
| `upstream` | spec | Initiate | a human; the sibling report. A **list**; each entry carries `url`, `read_at`, `source_updated`. Normalised at write time |
| `intent_accepted` | spec | Initiate | the router — `dev-path:technical-design` refuses without it, and so do `dev-path:survey` and `dev-path:integrate` |
| `design_approved` | spec | Design | the router — `dev-path:build` refuses without it, and so do `dev-path:slice`, `dev-path:critique` and `dev-path:integrate` |
| `depends_on` | each slice | Slice | the cited-paths check; Build's structural refusal; the order walk |
| `touches` | each slice | Slice | the cited-paths check; the contention script; Build's mid-run-stop intersection — **three readers and no fourth** |
| `done` | each slice | Build | the router; Build's `depends_on` refusal; derived spec progress |
| `fix_cycles` | each slice | Critique | the two-cycle cap, read by `dev-path:build` at its start. **Its presence** is read by Integrate's step 3 — absent on a built slice, the slice pass never ran |

> **Value is always `true`. Absence is how you say no. Nothing ever writes `false`.**

There is no such thing as a spec that was explicitly un-approved — you either have the human's yes or you
are in every spec's starting state. **A guard written against `done: false` can never fire**, which is why
block 3 above tests for the absence of `done: true`.

**`done: true` has a predicate, and it is the acceptance criteria.** A slice is done when every `- [ ]`
under its `## Acceptance criteria` is ticked. `done` is the one field whose name does not carry its own
meaning, so it is stated here: *done according to what?*

> **Every stored field is either a thing a human did or a thing a machine counted or recorded. None is a
> thing a model judged.**

**The two gates.** Gate 1, intent accepted, stores `intent_accepted: true` at the end of Initiate. Gate 2,
design approved, stores `design_approved: true` at the end of Design, before any code exists — and because
Slice sits behind it, the human approves the design *and* the slice layout at one stop. Merge is a third
human gate and `dev-path` does not own it: it is branch protection.

### There is no `stage:` field, and no progress information is lost

| Question | Answered by | Field? |
| --- | --- | --- |
| Survey done? | `## Current state` is non-empty | no |
| Design done? | `## Design` is non-empty | no |
| Sliced? | files exist in `slices/` | no |
| Built? | every slice carries `done: true` | no |
| Critiqued? | every slice carrying `done: true` has a `fix_cycles:` line | no |
| Critique clean? | no `- [ ]` anywhere in the spec directory | no |
| In flight? | the spec exists only on a branch | no — git |
| Merged? | the spec is on the base branch | no — git |
| Abandoned? | a closed pull request whose file never got there | no — git |

**The cost, stated rather than smoothed: there is no single place to look.** Progress is **nine
observations — six over the files, three over git** — rather than one `head -5`. A `stage:` field would
not add this; it would duplicate it, and if `stage: built` said built while two of five slices lacked
`done: true`, the slice files would be right.

> **`fix_cycles` absent on a slice that carries code ⇔ the slice pass never ran on it.**

**That row is derived rather than stored, and it is the one worth spelling out.** Slice writes no
`fix_cycles:` line at creation, Critique writes `fix_cycles: 0` on its first pass over a slice that has
none, and nothing else ever writes the field — so the line's *presence* is the pass's own trace.
**`done: true` is the mechanical form of *carries code***, which is how the row asks the question and how
Integrate's step 3 tests it. **The two Critique rows are different questions**, and a real run answered
them differently: seven slice files, six at `done: true`, every `## Critique findings` empty, no
`fix_cycles:` line anywhere in the directory, and every downstream check clean. Integrate's step 3 refuses
on it now, and **no ninth field was needed** — which is why the row's third column says no.

### The disposition grammar

```markdown
## Critique findings
- [x] fixed — `ToleranceService` swallowed the DML exception
- [x] false positive — null guard at line 42; the caller guarantees non-null
- [x] won't fix — hard-coded org id in the test; fixture is scratch-org-local
- [ ] bulk path still throws above 200 rows
```

```markdown
## Outcome checks
- [x] met — Tolerances configurable per quantity, unit price and total
- [ ] unmet — Bulk update over 200 rows completes without error
```

| Marker | Means |
| --- | --- |
| `- [ ]` | **still open** — Integrate refuses |
| `- [ ] unmet` | the same open box with its shortfall spelled out. **Not a sixth state** — every check greps `^- \[ \]`, which matches it |
| `- [x] fixed` / `- [x] met` | the code does it |
| `- [x] false positive` | there was nothing there |
| `- [x] won't fix` | **real, not done, shipping anyway** |

> **Critique clean ⇔ no `- [ ]` remains anywhere in the spec directory.**

One grep, zero judgment, every cycle. **Section-blind, deliberately** — a box put somewhere the design
never anticipated fails loudly rather than quietly. Every box in the directory has an owner, which is the
only reason a directory-wide check is safe.

**What is still section-dependent is what Build *does* about a box.** Under `## Critique findings` an open
box means *fix this*; under `## Deviations` it means *do not proceed on this slice until a human clears
it*. **Two readings of one test** — the grep answers *is anything open*, the section answers *what do I do
about this one*.

**Every checked box carries its tag as the first word.** A bare checked box reads as *fixed in code* when
it may not have been, and **only `fixed` and `met` mean the code changed.**

**`- [x] won't fix — <reason>` is the way to ship something knowingly unresolved.** One line, loud, riding
into the pull request body in front of the human who has to approve it. No flag, no date, no waiver
machinery — a way out that costs more than compliance gets abused, and one that costs less gets used
honestly. **It accumulates**, so on the base branch `grep -rn "won't fix" dev-path/` is the standing ledger
of everything the team knowingly shipped unresolved. **Pin that apostrophe as ASCII** — a typographic one
silently empties the ledger.

**`dev-path` writes `fixed`, `met` and `false positive`. It never writes `won't fix`** — that one is the
human's, by hand, under any heading.

### Nothing writes a placeholder

> **A stage writes a section only when it has something to put in it. Absent and empty mean the same
> thing.**

Gating a section's presence yields the word `none` typed to satisfy a check, which is worse than nothing.
**`## Outcome checks` is the one deliberate exception** — always written, one line per Outcome, because
otherwise *nothing was wrong* and *the pass never ran* are indistinguishable.

**The slice pass needs no such exception, which is why the list has one entry and not two.** Its trace is
the `fix_cycles:` line on the slice, so an empty `## Critique findings` is already distinguishable from a
pass that never ran — and Integrate refuses on that absence.

</details>

## What this does not claim

<details>
<summary><b>The disclaim list and the admissions</b></summary>

**This design's house style is to name its own holes. A reader who does not find these sentences in the
built plugin has found a defect in the plugin, not in the design.**

### The outcome claim is unavailable

**`dev-path` does not claim to make the work better or faster.** That claim is unmeasurable at this scale,
and a design that promises an outcome it cannot observe is making a claim it can never be held to. Across
1,650 sessions, no property of an instruction file — size, position, architecture, contradictions in
adjacent files — produced any detectable effect. At two to three engineers a 4% change is undetectable.

**Two claims are defensible, and they are what `dev-path` commits to:**

- **Revealed preference** — an engineer who ran it once runs it again unprompted. Observable at N = 1, and
  the only claim that survives the maintainer not being in the room.
- **A fresh reader can act on it** — a spec on the base branch is one a stranger could act on without
  asking its author. The only **checkable** claim.

**Everything beyond those two is anecdote, and `dev-path` calls it that.**

### What a solo run cannot test

**Because a green pass otherwise reads as validation.** A solo run on a non-Salesforce project cannot test:

- **both gates and the merge approval** — no second human, so *the one gate roughly ninety systems all
  kept* is exactly the one a solo run cannot exercise;
- **every repo precondition** on `dev-path:fit-check`'s list;
- **the whole Salesforce half** — verticality, the deploy gate, the `Active`/`Obsolete` flow rule, the
  custom-metadata no-verification case, the LWC job, scratch orgs;
- **cross-spec contention** — one operator, one spec at a time.

**Two things even a scripted, coverage-driven pass cannot reach:** whether the slicing rule survives **real
requirements**, and whether pull-request review of a `dev-path` spec produces **useful** review. Both need
a real spec from a real body of work, so both are **unvalidated by construction** until the first one runs.
A synthetic repo claiming otherwise is the dishonest version.

### Where the design knowingly does not enforce what it looks like it enforces

> **The agent writes the field that gates the agent.**
> `intent_accepted` and `design_approved` record that a human said yes; they do not enforce it.
> **The front-matter check runs only when a `dev-path` skill
> runs** — a hand-edited spec on a branch nobody re-enters reaches the base branch unchecked, and nothing
> catches it but the human reviewer. **And a conversation the human refuses to have is a gate whose
> mechanism is live and whose signal is dead, which `dev-path` cannot fix.**
>
> The principle that **a trust boundary needs a trusted location** is acknowledged and consciously not
> satisfied.

**The intent gate's mechanical check is nearly worthless.** Five sections, two checked for non-emptiness.
The human reading is the whole gate.

**An unanswered question can reach the base branch.** A mid-flight question is a recorded assumption, never
a gate. That is the posture, not a leak — the alternative is a gate nobody can release.

**`intent_accepted: true` can end up attached to Outcomes that were later rewritten**, and the design gate
is what covers that.

**A no-op design conversation costs one re-approval**, taken deliberately over a model judging materiality.

### What verification does and does not reach

**Verticality has no mechanical gate in this design.** The mechanism is real and the design declines to
spend it per slice: two orgs per spec, not N+1.

**Green is provably not done.** A slice whose feature was a dynamic query on a nonexistent field passed
validation, passed its test and scored 86.7% coverage.

**A slice made only of custom metadata has no behavioural verification whatsoever**, and no check is
invented for it. Nor for permission sets, layouts or screen flows — **the platform ships no runner that can
fail a build for any of them.**

**The only verifier of slice completeness is a person**, at the design gate, before code exists. **And a
fluent behaviour line can dress a bad slice** — the template narrows the lie; only the person kills it.

**One open-box check, and the section still decides what Build does about a box.**

### What is not bounded, and what is not observed

**`dev-path`'s orchestrator is unbounded and cannot be bounded.** Both real token budgets found anywhere
are enforced by programs; this orchestrator is a model running a skill, and no hook input carries token
counts or context size. **Nobody in the coding-agent systems surveyed has such a bound either** — so it is
an admission, not a gap to fill.

**The determinism split.** `fix_cycles` being an integer and `>= 2` being arithmetic is deterministic, and
so is *is a box still open* — a regex against a fixed grammar, roughly 100% accurate where prose reads at
roughly 5%. **The evaluation is not**, because the router is the checker and that is a model reading a file.
**Nor is the increment**: `fix_cycles` rises because Critique's instructions say so, and a missed increment
means the cap silently never trips. **What bounds the damage: a missed increment causes more unattended
fixing, not a bad merge.**

**Nothing is built to observe.** No metrics script, no `dev-path:status`, no dashboard, zero new fields.
Observation has no remote channel by construction, and every scheduled measurement found anywhere in this
environment is dead.

**The plugin must not claim the code-health metrics measure whether `dev-path` works.**

**Unattended is not opaque.** A human can navigate to a live worker from the orchestrating session, watch
it run, and navigate back. That is why `dev-path` names no transcript read.

**Nothing depends on worker lifecycle for correctness, only for cost.**

**Live messaging is a declined available mechanism, not an assumed-absent one.** Sending a message to the
main conversation from a background subagent works, and returns *queued for the main conversation's next
turn* — queued, not interrupting, so it saves not one step over returning.

**Serial slices are a starting posture, not a ceiling.** Presenting serial execution as a principle would
be dishonest.

**Two nested bounds hold the outer loop, which is why a new slice's counter starting at zero is not a bug.**

### Softness that is stated rather than hidden

**Skill-to-skill invocation is model-driven and is not guaranteed.** `dev-path:technical-design` reaching
`dev-path:survey` and `dev-path:slice`, `dev-path:build` reaching `dev-path:critique`, and
`dev-path:integrate` reaching `dev-path:learn`, are instructions naming a skill. There is no call syntax and
no event that fires on a skill finishing. Claude reads the instruction and normally follows it, and
**nothing in the harness makes it certain.** Both ways it can fail are visible in the artifact.

**The Build → Critique edge is the one with a demonstrated failure, and its detection test is
`fix_cycles`.** For one release `dev-path:build` described a Build ↔ Critique loop and instructed nobody to
run one — three of the four compositions were imperatives, that one was implicit, and the first real spec
built seven slices, six of them to `done: true`, with an empty `## Critique findings` on every one and a
real correctness defect among them. The imperative exists now, and what catches a session skipping it is
that **`fix_cycles` absent on a slice that carries code is the slice pass never having run**, which
Integrate refuses on. **That pairing is the answer everywhere in this design**: an instruction a session
may skip is made visible in the artifact rather than shouted louder.

**`dev-path` has no bypass, because it never blocked anything.** Non-use is always available and always
free — which is why choosing not to use it is an adoption question, not evidence against the design.

**A plugin that failed to install cannot detect that it failed to install.**

**The adoption mechanism is a person, and it stops working at engineer four and at the first reinstall.**

**Abandonment must delete the branch, and this mandate has no mechanism.** Abandonment is a human closing a
pull request on github.com; no `dev-path` skill is running, no hook event fires on one, and there is no
block to paste. **What it costs when they forget:** a branch with no pull request open against it and no
spec merged. *The ref is the status* still answers, but it stops distinguishing *abandoned* from *in flight
and quiet* — and this is the command that still tells them apart:

```
gh pr list --state closed --search "is:unmerged"
```

**A rejected design is findable but not surfaced, deliberately.** Nothing pushes it at you at the moment
someone re-proposes the same idea.

**`dev-path` cannot forbid migration onto an existing repo, and does not try.** The preconditions assume a
first commit; three of them are one-time repo-wide jobs a running repo does outside `dev-path`, before it
starts. A repo arriving with its own slicing rule has two rules until a human picks one.

**A repo whose promotions run through DevOps Center is out of scope, and deliberately not a precondition.**
DevOps Center names the branch and opens the pull request itself from org-side credentials, and a pull
request merged outside it leaves the work item *partially promoted* — which blocks that stage for everyone,
not only for its own work item. So one pull request per spec with auto-merge armed cannot coexist with it,
and **Integrate genuinely breaks** on that class of repo. It is not on the precondition list because the
governance is **entirely org-side** — there is no repo artifact anywhere to observe, so `dev-path:fit-check`
could never check it, and **an unenforceable entry on that list is the exact defect the list exists to
prevent.**

**Survey gets more expensive as the corpus grows.** Accepted, and to be watched; the bounded-by-query rule
is what keeps the curve survivable.

### Two structural limits, recorded rather than solved

**Two specs inventing the same object for the same concept never collide.** If one creates
`RentalContractLine__c` and another `RentalLineItem__c`, **git sees no conflict, CI sees no conflict, both
scratch orgs deploy clean, both pull requests merge green. Nothing goes red anywhere.** Survey is the only
surface that catches a *concept* collision — every later surface can only catch a *path* collision — which
is why its sideways-reading instruction is load-bearing, and **the design surfaces rather than prevents.**

**A trigger derived from existing artifacts is blind on a greenfield repo.** `touches` holds pre-existing
paths only, so anything derived from it sees the brownfield case and misses the greenfield one — on a
target whose dominant act is creating. **This is a class with two known instances; check every future
derived trigger against it.**

### The one open risk this design carries and cannot close

**Every measurement available concerns whether a rule was *delivered*, never whether delivery changed
*judgment*.** The instrumented probe measured a nameable, binary instruction and found delivery and
compliance tracking together 15 out of 15 — but a canary token is trivially checkable.

**So: if presence does not move judgment behaviour, Critique carries the standards attachment alone** — the
review-only posture this design rejected. That is a risk, not a decision to make, and it is stated rather
than resolved.

### Where this design does something the surveyed systems do not

**No precedent was found for carrying one draft pull request across a whole workflow.** Nothing in roughly
120 repos does it. Every primitive is documented behaviour, so **the residual risk is unfamiliarity, not
mechanism.**

**Relevance-scoping is the one axis nobody in the surveyed systems exploited** — and the claim that it
*discards nothing* is **false**: `paths:` silently withholds a rule from an agent creating a new file, with
no signal that a rule exists and was withheld. **The cost claim stands; the coverage claim does not.** And
nobody has written down the pair *scope your rules and instruct reading so the scoping works*; the halves
have precedent and the best public instance ships the bug.

**Nothing in roughly ninety systems retrieves from a corpus of prior specs.** So Survey has no built
retrieval mechanism, and the instruction to grep is an instruction where there was silence, not a reversal.

### Reasons that must survive, or a later reader thinks something lost its rationale

**Normalising `upstream.url` at write time did not lose half its reason.** There is **no drift check and
there cannot be one** — detecting that upstream moved requires reading upstream a second time, and the
reader is architecturally unavailable rather than merely unbuilt — so the sibling report carries the
normalisation alone.

**`## dev-path feedback` leaving the repo does not reintroduce the tracker.** The settled constraint is
about the **context store**; this channel is write-only, off-workflow, human-initiated and human-confirmed.
**And `Jonah-Stephans/dev-path` must be public — a hard requirement, not a preference**, because that
channel files issues with an engineer's own `gh` credentials and the install commands above must work
without a token.

**A directory level per requirements set is forbidden**, because it is the deleted level returning by the
back door.

**There is no `stage:` field, and the ergonomic cost is real** — progress is nine observations rather than
one.

**You refer to a spec by its draft pull request's number or title**, and there is no `pr:` field.

**Why `dev-path` puts file paths in specs when adjacent tooling forbids it** — three reasons that rule
could exist, and only one falls. **Rot** falls, because a spec in git moves with the code. **Altitude**
survives: modules are stable, and which file a module lives in is Build's business. **Anchoring survives,
and git does nothing about it** — tell an agent the change goes in a named file and it edits that file even
when the right change is elsewhere. So `creates:` is deleted, a spec-level paths field is deleted, and
`touches` is declared as *what this slice will collide with, not where to work*. **The residual cost is a
prose mitigation for a model-behaviour risk, which is weak: the anchoring risk is live.**

**Which standard a repo uses is out of scope, and the plugin is built so the answer is swappable.** A repo
with no standards rule builds against nothing, which is the honest degradation and not a defect.

**Build's test-first line is a suggestion whose rationale names its own expiry** — it retires when Apex
gets mutation testing.

**Waivers split by gate kind** — none on `dev-path`'s two gates, because you cannot route around a human
refusing to approve something, and the first request for one means the gate is wrong. Every check
`dev-path` performs is fixable on the spot. **CI gates are different and they are the repo's**, with a
deliberate, dated exception route meeting four obligations.

**`dev-path` ships its own conversation instructions rather than calling a third-party skill.** No
third-party plugin dependency, and a general grilling skill ends when the questions run out while this
conversation must end in an approval and a written artifact.

**Branch-name discovery requires an attached HEAD.** `git branch --show-current` returns empty with exit
code 0 under a detached HEAD, so `dev-path` says *you are not on a branch* rather than *no spec on this
branch*. It fails safe and it fails confusingly.

**The uniform-directory cost is real**, and the reason it is worth paying is that a file's cost is the extra
cold read, and uniformity compounds across every skill, script and check.

**`checkpoint`'s mild collision with a debugger feature is recorded rather than hidden — and
`confirmation` was *not* the zero-risk alternative**, because first-party tooling ships *confirmation gate*
as a literal meaning something slightly different.

**Build may re-cut unattended and records it**, and *stop and ask* was rejected because it would make the
slice layout more sacred than the design itself.

**`dev-path` names no tool bug and grants no exemption for one.**

**Nothing routes on `type` today.**

**The testing standard is a starting point to be challenged, not an adopted standard.** What is settled is
where it attaches.

**Stage names are prose-facing, skill names are invocation-facing, and only the latter has to be unique.**

**The evidence base is not the target list.** Every measurement above was taken from repos `dev-path` does
not run on — it is built for greenfield second-generation package repos. **Those measurements stand and
none is retracted.**

</details>

## Licence

MIT.
