---
description: Produce something physical to settle an open design question on a devpath spec. Use when a design conversation stalls because two people picture different screens.
disable-model-invocation: true
---

# Sketch

**Human-invoked. Not a stage.** Say it plainly, or a later reader adds it to the stage list. Nothing in
`devpath` fires this skill; a human types it.

It is the side trip `devpath` offers when a design question needs something physical. **It owns the
plumbing and says nothing about the craft.**

**Why it is a skill rather than an instruction in the design conversation.** The alternative makes the loop
depend on Design writing a good brief **and** the human transcribing it correctly — two forgettable
human-mediated hops. A skill that reads the spec directly removes both.

## Refuse first

**The slug arrives as `$ARGUMENTS`, and this skill refuses without one.**

- **No argument** → **stop.** Say the next act: run it again as `/devpath:sketch <slug>`.
- **No `devpath/<slug>/` directory** → **stop**, and say which slugs exist.

**Not branch discovery, deliberately.** This is not one of the eight stage skills, and the parallel-session
shape below means **the branch it runs on is not reliably the spec's** — an artifact may land on a
throwaway branch or nowhere at all. Discovering the spec from the branch would find the wrong spec or no
spec, on the ordinary route.

**Prefix every message this skill prints when it stops with `devpath: `.** Suggested.

## Read

**`## Open questions` first**, plus `## Intent`, `## Outcomes` and `## Current state` for context.

**If no open question is written yet** — the human decided mid-conversation to come here — **ask for
one.** That is the only fallback needed.

## Write

**Place the artifact by its reader.**

- **Read by a later stage** → `devpath/<slug>/sketches/`, at a relative path Build can open.
- **A throwaway spike** → a throwaway branch, or nowhere.

**`devpath/<slug>/sketches/` is the only place a non-text file exists anywhere in `devpath`.** Every
other artifact is prose or YAML. Bounded to an image or a small HTML file; **never build output.**

**Write a short decision note beside the artifact** — the question, the answer, the artifact path.

**Never commit to the spec branch, and never write `spec.md`.**

**Why not `spec.md`.** The primary shape is that the design session **stays open** and this runs in a
**parallel** session. **Two live sessions, one file, is a straight collision.** So this skill's only writes
are new files, and **the decision travels through the human** — which is also the right channel for a
decision. `devpath:technical-design` writes `## Design`, always.

**Why not the spec branch, and this is the rule worth having rather than a caution.** One branch per spec,
and a parallel session runs with **the spec branch already checked out** — so committing a spike to it is
the default thing that happens if nothing says otherwise, and the spike lands in the spec's own pull
request before Build starts. *"Don't commit that here"* is exactly the rule a human forgets at the end of a
day and a skill never does.

**Build rewrites rather than promotes a spike.** On a platform where a spike is deployable metadata,
shipping it needs no rewrite at all, which is why this is stated rather than assumed.

## Both directions work, and the decision note is what makes the second one real

- **Session open, the primary route:** the human carries the decision back in conversation and Design
  writes `## Design`. The note is redundant in the moment and is what Build reads later.
- **Session closed, the fallback, and it must work:** the human re-runs `devpath:technical-design`, which
  reads the front matter, sees no `design_approved`, reads `## Open questions`, and **finds the note beside
  the spec answering it.** Without the note the decision would exist only in a dead transcript.

That is why `devpath:technical-design` reads its spec *directory* on start rather than only `spec.md`.

## Stop

**End by stating the decision** in the register `## Design` needs — one or two sentences plus the artifact
path. Then stop.

## What this skill deliberately does not say

**It says nothing about how to make a good mockup, and that absence is deliberate rather than an
oversight** — say so, or the first reader fills it in. Craft advice here is what turns a program-agnostic
skill into one shaped around a particular product's conventions.

**No prototyping tool is named**, for the same reason one level down: a plugin that names a specific tool
inherits its rot.

**One timing consequence, so it is not read as a defect.** Using the spec's own scratch org for a
real-runtime sketch pulls that org's creation earlier than Build. That is a real consequence of asking a
design question that only the real runtime answers.
