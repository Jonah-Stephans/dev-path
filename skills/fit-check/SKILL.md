---
description: Check a repo against the twenty-five preconditions dev-path needs and report where it stands. Use before adopting dev-path on a repo, or any time afterwards to see what is still missing.
disable-model-invocation: true
---

# Fit check

**Human-invoked, never fired by `dev-path`. It is not a stage.**

**It reads no spec** — no front matter, no branch-name discovery, no slug. It runs in a repo that may
contain zero specs, so nothing about the other nine skills' opening read applies here. **Say that, or it
gets wired like the other nine.**

**It stores nothing.** No file, no field, no report artifact. A stale readiness report is worse than none.

**It blocks nothing**, so nobody ever needs to route around it. It is a setup-time recommendation,
re-runnable at any time, never required.

**Two moments, one skill.** *What does this repo need* on a new repo and *where does this repo stand* on an
existing one are the same twenty-five checks with the output shaped by what is found.

**What `dev-path` runs on: greenfield second-generation package repos.** That is what these preconditions
assume — a first commit. **Migration onto an existing repo is neither designed nor forbidden**, and there
is **no migration mode and no second flavour of any requirement.** Three of the entries are one-time
repo-wide jobs a running repo does *outside* `dev-path`, before it starts, because each invalidates source
tracking or rewrites the whole tree: entries 8, 11 and 16. The bill belongs to the repo, is paid once, and
is paid before `dev-path` starts.

## Refuse first

**The repo arrives as `$ARGUMENTS`** when one is given; otherwise use the current directory.

- **Not a git repository** → **stop**, and say so.
- **`gh` is unavailable or unauthenticated** → **carry on**, reporting every API-backed entry as *could
  not determine*. Do not stop: two thirds of the list is readable from the working tree.

**Prefix every message this skill prints when it stops with `dev-path: `.** Suggested.

## Run order

**Mandated: entry 16 before entry 11, and entry 11 before entry 10.** Three of these entries lie when run
alone — metadata format changes which file names exist at all, and decomposition changes what a size
reading means.

## The verdict grammar

> **present · absent · could not determine · not observable**

**Four tokens, and the fourth is not a nicety.** *Could not determine* says a check ran and was
inconclusive, which invites a later maintainer to improve the check. **Not observable says there is no
check, and improving it means inventing one** — which is the one act this skill must never perform.

### Three things this skill must never do

1. **Never report green by default.** Entries 17, 18, 19 and 20 need *interpretation* of workflow
   semantics rather than a lookup. **Never a silent pass.**
2. **Never read an empty repository setting as `false`.** On some GitHub plans settings come back null
   rather than false; null read as *off* is a false alarm and read as *on* is a false pass. **Test for the
   key's presence before believing its absence.**
3. **Never treat vacuous as satisfied.** On a repo with no history, entry 12 has no labels files to count
   and entry 16 has nothing to convert. **A trigger derived from existing artifacts is blind on a
   greenfield repo**, which is exactly where `dev-path` runs.

### Six rules that apply to every entry

1. **Never report *absent* when the artifact under test is missing.** No `.github/workflows/`, no
   pull-request-triggered workflow, no `sfdx-project.json` — those are **could not determine** (*nothing
   to observe*), not *absent* (*observed to be missing*).
2. **Glob both extensions.** `.github/workflows/*.yml` **and** `*.yaml`. A check that globs one reports a
   false absent on a repo that uses the other.
3. **Follow local `uses:` and stop honestly at the boundary.** A job delegating to
   `./.github/workflows/x.yml` or a local composite action moves the evidence into a file you must also
   read. **Anything still external downgrades that workflow's *absent* verdicts to *could not
   determine*** — and a `run:` shelling out to a script you did not read does the same.
4. **`on:` parses as a boolean under YAML 1.1**, whose `bool` type covers `on` and `off`. A 1.1 loader
   turns the key into `true`, so `d['on']` is missing and the triggers live at `d[True]`. **Every entry
   that reads a trigger then false-absents, silently — the highest-blast-radius bug available to this
   skill.** Prefer `grep` for trigger detection, and where a parser is used, **accept both keys.**
5. **Two expression casts change verdicts.** `null` and `false` both cast to `0`, so
   `github.event.pull_request.draft == false` is *true* on an event with no pull request — which is what
   makes entry 5's canonical guard safe. A non-numeric string casts to `NaN`, so `draft == 'false'` is
   never true and that spelling **blocks every run: report it as a defect, not a pass.** Likewise
   `'true' == true` is false, which is why a changed-files output must be quoted in an `if`.
6. **Run entry 16 before entry 11, and entry 11 before entry 10.**

## On a repo that is not Salesforce

**The discriminator is `sfdx-project.json` at the repository root** — the file every `sf` project command
requires. Absent, and this is not a Salesforce project.

**Report not-applicable and carry on. Do not fail, and do not invent equivalents.**

| | Entries |
| --- | --- |
| **Still reported** — properties of git, GitHub and Claude Code, which any repo has | 1 · 2 · 3 · 4 · 5 · 8 · 17 · 21 · 22 · 23 · 24 · 25 |
| **Not applicable** — they name platform artifacts that do not exist here | 6 · 7 · 9 · 10 · 11 · 12 · 13 · 14 · 15 · 16 · 18 · 19 · 20 |

**Three rules, and each one is a way this could go wrong instead:**

1. **Never report the thirteen as *absent*.** *Absent* means observed to be missing, and a repo with no
   `sfdx-project.json` has not failed to decompose its permission sets — the axis does not exist there.
   Reporting thirteen absents on a Node repo is a report nobody reads twice.
2. **Not-applicable is stated once, at the top, not thirteen times.** It is a fact about the repo, not a
   verdict on each entry, so **it does not become a fifth verdict token.** *"No `sfdx-project.json`: this
   is not a Salesforce project, so thirteen of the twenty-five do not apply."*
3. **Never translate an entry into the repo's own ecosystem.** No looking for the Node equivalent of a
   decomposition preset. That is inventing a check.

**Still offer the safe fixes** — `.gitattributes` and the `.rstk/` ignore line are both in the reported
set and neither is platform-specific.

## The twenty-five, and how each is observed

**Three groups, sorted by whether you would notice it missing.** The hard-versus-soft split is
deliberately not used: it is a claim about *importance*, which is the one axis three people writing a
standard will argue about while learning nothing actionable, and it has no mechanical consequence
anywhere.

| Group | Means | Count |
| --- | --- | --- |
| **1 — announces itself** | the act that needs it fails, and the tool's own error is the whole signal | **3** |
| **2 — silent in flight, visible on inspection** | nothing fails; the value is simply absent, but the property is readable from the repo | **18** |
| **3 — silent and out of reach** | a behaviour or a posture. Nothing observes it, ever — at most a symptom | **4** |

**Branch protection is in group 2, and that reclassification is what justifies the axis.** Nothing errors
when the base branch is unprotected — the pull request simply merges without a second human, which is the
one gate roughly ninety surveyed systems never removed, **failing open with no signal anywhere.** Under
hard-versus-soft, entry 1 is the item everyone would have called hardest, and the agreement would have
concealed that nothing whatsoever detects its absence.

### Branch protection and pull-request mechanics

| # | Entry | Group | Observed by | Can reach |
| --- | --- | --- | --- | --- |
| 1 | `main` protected, non-author approval required | 2 | `gh api repos/{o}/{r}/rules/branches/main` → a `pull_request` rule with `parameters.required_approving_review_count >= 1`. Cheap precondition: `gh api repos/{o}/{r}/branches/main --jq .protected` | present · absent · could not determine |
| 2 | `require_last_push_approval: true`, alongside `dismiss_stale_reviews_on_push: false` | 2 | Same call, same rule: `parameters.require_last_push_approval == true` and `dismiss_stale_reviews_on_push == false` | present · absent · could not determine |
| 3 | Required status checks stay **loose** — `strict_required_status_checks_policy: false` | 2 | Same call, `required_status_checks` rule: `parameters.strict_required_status_checks_policy == false`, **and** at least one entry in `required_status_checks` | present · absent · could not determine |
| 4 | Auto-merge enabled on the repo | **1** | `gh api graphql` → `repository.autoMergeAllowed` | present · absent |
| 5 | CI does not run on draft pull requests | 2 | `.github/workflows/*.{yml,yaml}`: a job-level `if: github.event.pull_request.draft == false`, or a `types:` list of `[ready_for_review]` alone, or a `merge_group`-only trigger | present · absent · could not determine |

### Orgs

| # | Entry | Group | Observed by | Can reach |
| --- | --- | --- | --- | --- |
| 6 | Scratch orgs, not a shared dev org | **1** | `find . -name '*scratch-def.json'` (**glob the suffix, never the default name**), the definition's `edition`/`snapshot`/`sourceOrg`, `sf org create scratch` in a workflow, and a committed `.sf/config.json` pinning `target-org` — which is positive evidence of the opposite | present (configured) · absent · **not observable** (the practice) |
| 7 | **Two fresh orgs per spec** — not per slice; may be needed as early as Design | **1** | nothing | **not observable** |

**Report entries 6 and 7 as *configured* or *not observable*, never as absent.** What is observable is
whether `sfdx-project.json` and a scratch org definition exist — never whether an org has been created.
**Entry 7 degrades exactly as a group-1 entry should:** with no default org set, Build's first deploy fails
with the CLI's own error and `dev-path` adds nothing.

**Who creates the two orgs, because no stage does:**

| Org | Created by |
| --- | --- |
| the engineer's own scratch org, kept for the life of the spec | **the engineer.** No `dev-path` stage creates it |
| the fresh org for the whole-spec deploy at the ready transition | **the repo's CI**, as part of the deploy gate `dev-path` does not run |

**A plugin that creates orgs is a plugin that names one**, which is the line the plugin does not cross.
**The two orgs do different jobs and neither is per slice:** the engineer's own proves the code works and
**cannot** prove verticality, because by the time slice 5 lands it already holds slices 1 through 4; the
fresh one is the only deploy in a spec's life that can fail on a dangling reference, because references
resolve against org state ∪ payload. **A 10-slice spec costs 2 orgs, not 11.**

**And *may be needed as early as Design* is the sketch case:** using the spec's own scratch org for a
real-runtime sketch pulls the first org's creation earlier than Build.

### Source shape

| # | Entry | Group | Observed by | Can reach |
| --- | --- | --- | --- | --- |
| 8 | `.gitattributes` with `* text=auto eol=lf`, in the first commit ‡ | 2 | Two greps of the root `.gitattributes` for `text=auto` and `eol=lf` on pattern `*` — **the split form is equivalent and must be accepted.** Then `git show $(git rev-list --max-parents=0 HEAD):.gitattributes` for *in the first commit* | present · absent · could not determine |
| 9 | No explicit-member `package.xml` | 2 | Every file containing `<Package` and the metadata namespace, then `grep -oE '<members>[^<]*</members>' \| grep -v '<members>\*</members>'` — a non-empty result is an explicit member | present · absent |
| 10 | A **fresh retrieve** at API version ≥ 54.0 — **not a version bump** | 2 | **Count `<fieldPermissions>` blocks whose `<readable>` and `<editable>` are both `false`** — see the correction below | present · absent · could not determine |
| 11 | Decomposition presets on at bootstrap, including the beta permission-set preset ‡ | 2 | `jq '((.sourceBehaviorOptions // []) + (.registryPresets // []))' sfdx-project.json` contains `decomposePermissionSetBeta2` (or the legacy `decomposePermissionSetBeta`) | present · absent |
| 12 | One custom-labels file per slice | **3** | nothing observes the practice. A count of `*.labels-meta.xml` files is not it | **not observable** |
| 13 | `.forceignore` profiles; version permission sets; keep access in permission sets | 2 | Three sub-properties, three different answers — see the correction below | present · absent · **not observable** (one of the three) |
| 14 | Permission set **groups** edited outside the deploy phase | **3** | nothing observes the practice. `find -name '*.permissionsetgroup-meta.xml'` and a grep for `Test.calculatePermissionSetGroup` are adjacent facts worth printing | **not observable** |
| 15 | Multiple `packageDirectories`, no `package` keys | 2 | `jq -e '(.packageDirectories\|length > 1) and (.packageDirectories\|all(has("package")\|not))' sfdx-project.json`. Also check every `path` exists on disk | present · absent |
| 16 | Source-format conversion, once ‡ | 2 | Bare-suffix files (`*.object`, `*.profile`, `*.labels`, `*.flow` …) are metadata-format evidence; `*-meta.xml` on XML-only types plus a decomposed `objects/` is source-format evidence. **Four outcomes, including mixed** | present · absent · absent (mixed) · could not determine |

‡ = a one-time repo-wide job that precedes `dev-path`.

**Entries 12 and 14 carry their whole argument here, because the paragraph *is* the mechanism.**

**Entry 12 — one custom-labels file per slice.** `labels/` is among the largest and most-contended files in
a repo of this shape, and real commits **append at a shared tail offset**: three consecutive commits were
measured landing within about 120 lines of each other. Sequentially that is fine; **concurrently they
collide every time.** Two independent `*.labels-meta.xml` files recompose into one deployable payload on a
stock CLI, so the convention **works today with no flag and no plugin.**

**Entry 14 — permission set groups edited outside the deploy phase.** Group recalculation is
**asynchronous** — *seconds to hours* — and it is aggravated by precisely what a gate does: Apex tests and
metadata deployments. So **a slice that edits a permission set group can break the permissions of the very
test users its own gate depends on.** A slice may freely create and edit its own permission set; adding it
to a group is a separate, later, non-gating step — or the check calls
`Test.calculatePermissionSetGroup()`, which forces an immediate calculation.

### Properties the CI must have

| # | Entry | Group | Observed by | Can reach |
| --- | --- | --- | --- | --- |
| 17 | CI can run a diff-scoped check evaluating changed **lines** | 2 | reviewdog's `filter_mode` (absent, `added` or `diff_context` are all line-scoped), or `git diff --unified=0` in a `run:`, or new-code / patch-coverage services | present · absent · could not determine |
| 18 | A flow in a delta must be `Active` or `Obsolete` | 2 | Two separate things: a delta of changed flow files, **and** an assertion on `<status>`. Allowed `Active` · `Obsolete`; reject `Draft` · `InvalidDraft` · `UnderReview` | present · absent · could not determine |
| 19 | A CI job runs the LWC test suite | 2 | `sfdx-lwc-jest` or `npm run test:unit` in a workflow, corroborated by `package.json`'s `devDependencies["@salesforce/sfdx-lwc-jest"]` and `__tests__/*.test.js` on disk | present · absent · could not determine |
| 20 | The deploy gate is skipped when a change carries no platform metadata | 2 | `.jobs.<deploy>.if` on a changed-files output — **not** `.on.*.paths`, which has the opposite effect on a required check | present · absent · could not determine |
| 21 | Each CI gate's exception route meets the four obligations | **3** | Four obligations, four sub-verdicts, and an overall verdict that can never be *present* — see the correction below | could not determine (overall) |

**Entry 18's reason: a `Draft` flow deploys unvalidated behind a green build**, and `Draft` is what you get
when the status element is omitted. The predicate permits legitimate retirements and catches the flows that
would each deploy proving nothing.

**Entry 20's reason: a docs-only spec, or one touching only `.claude/rules/`, produces an empty deploy
payload**, so the one mechanical gate either passes vacuously or breaks the build for a typo fix.

> **Read the empty-delta guard off the change, never off `touches`.**

`touches` holds pre-existing paths only, so on a greenfield repo it is empty on exactly the create-only
slices this guard has to judge. **Deriving the skip from `touches` would skip the one mechanical
verification the platform offers on the specs that most need it.** The honest input is the payload the
deploy would carry, and the repo already computes it.

**Entries 18 and 20 sit inside the deploy gate, and four conditions bind that gate:** a **fresh** org,
because references resolve against org state ∪ payload; an **explicit test level**, since the default runs
no tests; **org-wide coverage defaults**; and **read the exit code, not the result object.** `dev-path`
does not run the gate — these are what it requires of the repo's.

### Coexistence

| # | Entry | Group | Observed by | Can reach |
| --- | --- | --- | --- | --- |
| 22 | `.claude/rules/` stays commit-eligible | 2 | `git check-ignore -v --non-matching .claude/rules/ .claude/rules/dev-path-probe.md`, and again with `--no-index`. **Probe a non-`rstk-` filename** | present · absent |
| 23 | `.claude/lessons.md` left alone | 2 | `git check-ignore -v --non-matching .claude/lessons.md`, plus `git ls-files --error-unmatch` and `git log --diff-filter=D -- .claude/lessons.md` | present · absent · could not determine |
| 24 | `.rstk/` gitignored | 2 | `git check-ignore -v --non-matching .rstk/ .rstk/probe.json` — **with the trailing slash**. Then `git ls-files -- .rstk`, because already-committed is a worse state than un-ignored and needs a different fix | present · absent |

> **A precondition on the repo comes with a backstop, never alone — and say why: another plugin's presence
> depends on the *engineer*, not the repo, so it is not observable from the repo at all. A precondition
> that cannot be checked needs one.**

**Entry 24's backstop is Build's commit audit.** If the ignore is missing, or a new tool starts writing
somewhere nobody anticipated, the file is committed and written down as excess. `dev-path` **benefits from
the ignore without depending on it.**

### Culture

| # | Entry | Group | Observed by | Can reach |
| --- | --- | --- | --- | --- |
| 25 | A check going red on `main` is an alarm, not a waiver | **3** | The symptom only, and it is three calls rather than one — see the correction below | **not observable** (the property) |

**A group-3 entry needs its argument written down in full, because writing it down is the only mechanism it
will ever have.** So the honest-degradation paragraph is **four entries long, not half the list.**

## Seven corrections, where the reasonable first guess was measured and was wrong

### Entry 4 — the obvious route is refuted, and it is destructive

**`gh pr merge --auto` does not reliably fail when a repo has auto-merge disabled, and probing with it can
merge a live pull request.** `gh`'s merge command sets auto-merge only when the pull request is *not*
already immediately mergeable — on a `CLEAN`, `HAS_HOOKS` or `UNSTABLE` state, `--auto` silently becomes a
**real merge**, the auto-merge mutation is never called, and the repo setting is never consulted. Even when
the mutation is reached, its error conflates at least five causes.

> **Never run a mutating command to observe a setting.**

**The read-only route is GraphQL `repository.autoMergeAllowed`**, which works at read permission and
returns a real boolean. **The REST field `allow_auto_merge` is omitted entirely below push permission**
rather than returned as `false`, so a check reading it must test for the key's presence before believing
its absence.

### Entries 1–3 — the API the entries name is not the only one that satisfies them

**The entries are phrased in classic branch-protection keys, and modern repos use rulesets.** A check
reading only `branches/main/protection` reports all three absent on a repo that satisfies all three.

1. **`repos/{o}/{r}/rules/branches/{branch}` is the primary call.** It returns the *effective* rules for
   the branch, including rules inherited from an organisation, and it works at **read** permission.
   `branches/{branch}/protection` needs **admin**.
2. **A 404 from `branches/{branch}/protection` means either *unprotected* or *you are not an admin*, and
   the status cannot tell you which.** Disambiguate with `repos/{o}/{r} --jq .permissions.admin` and
   `branches/main --jq .protected`. **A non-admin 404 is *could not determine*, never *absent*.**
3. **The two APIs spell two of the keys differently.** `strict_required_status_checks_policy` is
   `required_status_checks.strict` in classic protection, and `dismiss_stale_reviews_on_push` is
   `dismiss_stale_reviews`. A check that greps for the entry's own wording finds nothing on the classic
   route.

**Entry 3 needs three states rather than two**, because a repo with **no** required checks is vacuously
loose. *Loose* is only *present* when something is required in the first place.

**Entry 1 has no field of its own**, and that is fine: the platform structurally forbids approving your own
pull request, so `required_approving_review_count >= 1` **is** the observation of *non-author approval
required*.

### Entry 10 — the version number is not the evidence

*A file size and emphatically not the version number it looks like* holds. **But the ≥ 54.0 boundary is not
backed by any documented behaviour change** — the release notes for that version mention neither permission
sets nor field permissions, and the `PermissionSet` metadata type carries no version gate on
`fieldPermissions` at all. **Do not ship 54.0 as the reason.**

**What to check instead, in this order:**

1. **Grants-nothing blocks.** Count `<fieldPermissions>` entries with `<readable>false</readable>` and
   `<editable>false</editable>`. **Zero, with a small total → present. One to fifty → could not
   determine**, because a handful of deliberate revocations look identical. **More than fifty, and a large
   fraction of the total → absent**: that is a whole-org enumeration, not a grant. Nobody authors a grant
   that grants nothing. **This test is independent of file size, indentation, line endings and
   decomposition**, which is why it leads.
2. **Two documented proofs, both far below 54.0**, where they apply: `<enabled>false</enabled>` inside
   `<userPermissions>` proves a retrieve at API ≤ 28.0, and a profile's
   `<objectPermissions><allowRead>false</allowRead>` proves ≤ 27.0.
3. **Size, last, and labelled as a heuristic.** `find … -name '*.permissionset-meta.xml' -o -name
   '*.profile-meta.xml' -size +1000000c`. **One million bytes aggregate per component** is a proposed
   floor derived from arithmetic rather than documentation: each `<fieldPermissions>` block runs 153–194
   bytes, so a 3,710,296-byte file holds roughly nineteen to twenty-four thousand of them. Size can yield
   *absent* or *could not determine*. **It can never yield *present*.**

> **Entry 11 must run before entry 10.** Once decomposition is on, one permission set is scattered across
> thousands of files and its root file is about 150 bytes **regardless of how much access it grants** — so
> a per-file size check reports green on every decomposed repo. **Aggregate per component.** This is the
> single most likely implementation bug in this skill.

### Entry 11 — the key, named

**The key is `sourceBehaviorOptions`** in `sfdx-project.json`, an array of strings. **There is a deprecated
older spelling, `registryPresets`,** with the same meaning; a check reading only the current key reports
absent on an early-adopter repo. **Read both.**

Seven presets exist. **The beta permission-set preset is `decomposePermissionSetBeta2`** for a new repo;
the v1 `decomposePermissionSetBeta` is still accepted by the CLI but no longer documented, so it is
*present, on the legacy value* rather than absent. The custom-labels pair is `decomposeCustomLabelsBeta2`
and its v1; `decomposeSharingRulesBeta`, `decomposeWorkflowBeta` and
`decomposeExternalServiceRegistrationBeta` have no v2.

**First-commit-only is a hard failure rather than a warning:** the conversion command throws outright if
the target org supports source tracking, and its own remediation is to delete the org and create a new one.

### Entry 13 — three sub-properties, three different answers

**The entry is three things in one line, and they do not share a verdict. Report them separately or the
composite is meaningless.**

- **(a) `.forceignore` ignores profiles — solidly observable.** **Be permissive about the pattern:** a bare
  `profiles`, `profiles/`, `**/profiles/**` and `*.profile-meta.xml` were all measured excluding a real
  profile. A check matching one literal form reports a false absent.
- **(b) Permission sets are under version control — weakly observable.**
  `git ls-files '*.permissionset-meta.xml' | wc -l` above zero, with no matching line in `.forceignore` or
  `.gitignore`, is *present*. **Zero is *could not determine*, never *absent*** — a repo with no permission
  sets has violated nothing, and this is the likeliest place in the whole list to report a false red.
  Committed permission sets *plus* an ignore line matching them is a genuine contradiction worth surfacing
  loudly: files are committed that the CLI will refuse to deploy.
- **(c) Access is kept in permission sets — not observable.** It is a practice. A ratio of profile-borne
  grants to permission-set-borne grants is a proxy and **must never report *present*.**

### Entry 21 — which half is observable, precisely

**The observable half is the wiring; the unobservable half is the predicate.**

| Obligation | Verdict it can reach |
| --- | --- |
| 1 — runs on the same events as the gate | **present · absent** — pure workflow topology, compare the two `on:` blocks |
| 2 — its failure is the gate's failure | **absent · could not determine.** Falsifiable, never provable: a file can prove warn-only, never prove propagation |
| 3 — stale means expired *or* dangling | **not observable** — the predicate is inside the gate's own code |
| 4 — fails closed on a missing or malformed date | **not observable** — same |

**So this entry reports four sub-verdicts and an overall *could not determine*, always.** The entry is
conjunctive, so one unknown clause makes the conjunction unknown, and an overall *present* is not
reachable. **Say that**, or the first person to see four sub-verdicts and three green-ish rows will roll
them up into a pass.

**Ship the best falsifier for obligation 2**, because it is cheap and it is the failure the obligation was
earned from: a step's default shell has `-e` but **not** `pipefail`, so `run: ./check.sh | tee log`
**cannot fail.** Along with `continue-on-error: true` and a trailing `|| true`, that is the whole grep.

**The four obligations, and each is earned from a measured failure.** It runs on the same events as the
gate — the axis is the **clock, not the process**, so a separate script is fine as a required step in the
same build and a cron is not. Its failure is the gate's failure — the commonest failure by far: four
independent codebases wrote the staleness detector and then discarded its result in the exit code. Stale
means expired *or* dangling — one project's ignore file is wired correctly on every run and **100% of its
entries are dead** after a directory move silently broke the matcher. And it must fail closed — a missing
or malformed date making a waiver **permanent** is a bug three tools shipped independently.

### Entry 25 — the symptom is three calls, not one

**The naive one-call version returns a confidently wrong answer.**

1. **Which checks are *required*** — the word doing all the work. On a **private repo below the paid tier
   both endpoints return HTTP 403**, so **403 is *could not determine*, never *nothing is required*.**
   Without this step every downstream statement weakens from *a required check* to *any check*, and must be
   labelled as such.
2. **Is anything red now** — `repos/{o}/{r}/commits/main/check-runs?filter=latest`, reading `conclusion`
   for `failure`, `timed_out`, `action_required` or `cancelled`. **The check-run name is `workflow / job`**,
   and joining it wrongly to a required-check context is a quiet source of false verdicts.
   **`commits/main/status` is a different system** — it covers only legacy commit statuses and returns
   `state: "pending"`, `total_count: 0` forever on an Actions-only repo.
3. **For how long** — a bounded walk back through the history of that reference. There is no single field
   for it.

**And none of the three is the property.** *How long has a check been red* is a symptom; *is this team the
kind that waives* is not observable by anything.

## The report's layout

**Grouped by the six headings of the entry table, in table order** — branch protection and pull-request
mechanics, orgs, source shape, properties the CI must have, coexistence, culture. **One line per entry.**

```
4 · Auto-merge enabled on the repo — present
7 · Two fresh orgs per spec — not observable
13 · .forceignore profiles; version permission sets; keep access in permission sets — could not determine
     profiles ignored — present
     permission sets versioned — absent
     access kept in permission sets — could not determine (zero permission sets)
21 · Each CI gate's exception route meets the four obligations — could not determine
     enumerated — present
     wired to the exit code — could not determine
     stale means expired or dangling — could not determine
     fails closed — not observable
```

**Three rules and each is a way the layout goes wrong instead.**

1. **Group by the entry table, never by verdict.** Grouping by verdict produces a list of twelve absences
   with no way to see that they are all one area of the repo, and the fix for an area is one conversation.
2. **Sub-rows are indented under their entry and carry their own verdict.** The entry's own line carries
   the overall — *could not determine* for entry 21 always.
3. **The not-applicable sentence is stated once, at the top**, never per entry. It is a fact about the
   repo, and repeating it thirteen times is the report nobody reads twice.

## The safe fixes

**Three fixes are safe and the list is closed at three:**

- write `.gitattributes` with `* text=auto eol=lf`;
- add the `.rstk/` line to `.gitignore`;
- enable auto-merge on the repo.

**Offer them as a list at the end of the report, one line each, and apply nothing in the turn that
reports.** The human names the ones they want; apply those and no others. **Never on your own initiative,
and never all of them on a bare *yes*.**

**Enabling auto-merge is the one that writes to GitHub, and that is not a contradiction of *it stores
nothing*.** *Stores nothing* is about `dev-path`'s own artifacts — no report file, no field, no readiness
note. This is **the human's act, performed on request.**

```sh
gh api -X PATCH repos/{owner}/{repo} -F allow_auto_merge=true
```

**The route is REST, and `enablePullRequestAutoMerge` cannot do this and must not be named here.** Its
subject is **a pull request**; it queues one merge and leaves `repository.autoMergeAllowed` — the field
entry 4 reads — untouched. There is no GraphQL route at all: `UpdateRepositoryInput` carries no auto-merge
field, and `Repository.autoMergeAllowed` is readable and not writable. **It also has to be a
repository-level call because this skill may run on a repo with no open pull request**, which is the
ordinary case for entry 4. **And never `gh pr merge --auto`**, which is a merge wearing a setting's
clothes.

**Everything else is the human's**, because the decomposition presets invalidate source tracking and are
therefore first-commit-only, and branch protection is a policy call.

## Stop

Show the report and the fix offer, and stop. **Store nothing.**

**One residual weakness, stated rather than smoothed: this skill can be run once and never again, and
nothing observes that.** It is not fixable by adding a trigger without making it blocking, which it must
not be.
