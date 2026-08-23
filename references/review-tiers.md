# Review tiers — risk-tiered test-plan approval

The single definition of how a test case gets classified `Auto-cleared` or
`Needs review`. `discover`, `audit`, `testplan`, and `implement` all defer to
this file rather than restating the rule, so there is exactly one place the
threshold can change.

## Why this exists

`test-plan.md`'s human sign-off is the one hard approval gate in the pipeline,
and today it treats every test case identically: the reviewer reads the whole
plan top to bottom regardless of how much of it is already backed by verified
evidence or how low-stakes it is. That fails in two directions at once. It
doesn't scale — a 14-case plan is readable, a real product's plan isn't, and
long plans push reviewers into skimming, which is the passive-review failure
mode the gate exists to prevent. And it wastes the attention it does get: a P3
edge case backed by a live-verified selector gets the same scrutiny as a P1
checkout flow whose selectors are still a guess, when they deserve the
opposite.

Tiering fixes the *distribution* of review effort, not the amount of authority
the human holds. See "The AI pre-filters, it never self-approves" below — that
constraint is not negotiable and not a default that can be turned off.

## When to compute tiers

Tiers need evidence, so they cannot be computed at `testplan` time — nothing
has looked at the app yet, and every case would be `Needs review` by
definition. Compute them at the first point where evidence exists, and
recompute (overwrite) whenever stronger evidence arrives:

| Stage | What it does |
|---|---|
| `testplan` | Writes `**Review tier:** Unclassified — pending evidence` for every case. Never guesses a tier. |
| `audit` | If `test-plan.md` already exists for this run, classify from `audit.md`'s static evidence and write the tiers back. |
| `discover` | Always classify and write the tiers back, overwriting any `audit`-derived tier — live verification outranks static evidence. |
| `implement` | Never computes or edits tiers. Reads them only to check the approval gate (see below). |

Recomputing on stronger evidence is expected: a case `audit` could only tier
from a static grep may become `Auto-cleared` once `discover` confirms the
selector resolves live. Always state which artifact a classification came
from, so a reviewer can tell live-verified from statically-inferred.

## The rule

A test case is **`Auto-cleared`** only when all three hold:

1. **Evidence-verified** — every element the case depends on appears in
   `discovery.md` Section 1 (live-verified, strongest) or, when no discovery
   ran, in `audit.md`'s inventory (static evidence). A live-confirmed
   role/text fallback counts as verified; it's lower-confidence than a
   test-id, not unverified.
2. **Not P1.**
3. **Data impact is `Read-only`.**

A test case is **`Needs review`** if *any* of those fails. Each condition alone
is enough — they are not weighed against each other.

Every tier is written with its reason, so the classification is auditable
rather than asserted:

```markdown
**Review tier:** Auto-cleared — all selectors live-verified (discovery.md §1), P2, read-only
**Review tier:** Needs review — P1
**Review tier:** Needs review — no evidence for the "Remove" control (discovery.md §2, no fallback)
**Review tier:** Needs review — creates isolated test data
```

### Why each condition is disqualifying on its own

**Guessed → review**, at any priority. An invented selector is the exact
failure this pipeline exists to prevent, and it is no less invented in a P3
case than a P1 one. Priority describes what a test covers, not whether the
test is real. A guessed-but-P3 case that auto-cleared would reintroduce the
fabricated-selector failure mode through the back door, which is why priority
alone is never a safe filter.

**P1 → review**, even when fully verified. A verified P1 case is trustworthy
at the selector level, but P1 means the plan itself named it business-critical;
whether the *right* thing is being asserted is a product judgment that
verification cannot supply.

**Non-read-only → review**, at any priority, with any evidence. This one does
not come from the evidence/priority axes at all — it protects a rule that
already exists. `test-plan-template.md` requires explicit human approval for
any data impact other than `Read-only`, and `implement`'s Step 0 gate requires
direct human confirmation of side-effecting actions, their dedicated test
data/account, and cleanup/rollback. Auto-clearing a state-changing case
because it happened to be P3 with good selectors would quietly relax a safety
rule that predates tiering. Tiering may only ever redistribute review effort
within what the existing gates already permit — it must never subtract from
them.

### No evidence at all

When neither `discovery.md` nor `audit.md` exists (for example, a third-party
target with no local source, where `audit` correctly declines to produce a
file), every case is `Needs review` — that falls straight out of condition 1
rather than needing its own rule. Say so plainly rather than presenting a plan
as untriaged: "No evidence artifact exists for this run, so all N cases are
flagged for review."

## Presenting the flagged subset

Stream the `Needs review` cases **one at a time** — case, tier reason, and what
specifically to check — rather than telling the reviewer to re-read the
document. A document invites skimming; a stream that stops on each case forces
an actual decision on each one.

The auto-cleared majority is never hidden. Summarize it in one visible line the
reviewer has to accept as part of approving — what was cleared, and on what
basis:

```
9 of 14 cases auto-cleared: all selectors live-verified in discovery.md, none P1, all read-only.
5 flagged: TC-001 (P1), TC-005 (P1), TC-010 (P1, creates data), TC-011 (P1, creates data), TC-013 (creates data).
```

## The AI pre-filters, it never self-approves

Auto-clearing is a reading order, not an approval. It must never become "the
agent decided this part didn't need a human."

- The human still takes **one explicit approval action covering the whole
  plan**, auto-cleared cases included.
- That action acknowledges the auto-cleared set explicitly, by recording the
  counts in the approval field (see `test-plan-template.md`) — so accepting
  them is a thing the reviewer did, not a thing that happened while they
  weren't looking.
- No skill may write `Approved`, complete the `**Human approval**` field, or
  treat a tier as standing in for any part of that approval. `Auto-cleared`
  means "read this second," never "this is approved."
- A reviewer can always override a tier by hand. `Auto-cleared` → `Needs
  review` is a normal edit, and nothing downstream may revert it.

## An approval that predates tiering is stronger, not weaker

A plan can be approved first and tiered afterward — a plan approved before this
feature existed, or one re-tiered by a later `discover` run. Its approval is
the short `Approved by <human> on <date>` form with no counts, which the check
in `implement`'s Step 0 would otherwise stop on.

Accept it, and say why plainly: an approval given *before* any triage existed
is an approval of the **whole plan at full scrutiny**. The human read every
case, including the ones a tier would later auto-clear. That is strictly more
review than the tiered flow asks for, so honoring it takes nothing away. The
count check exists to catch someone approving an already-tiered plan without
acknowledging its flagged set — not to invalidate a stronger, earlier review.

Two conditions, both checkable, keep this from becoming a bypass:

1. **The triage must declare itself retroactive**, naming the date tiers were
   computed, and that date must be *after* the approval date. Order matters:
   tiers computed before an approval must be acknowledged by it.
2. **Tier computation must be the only change since the approval.** If test
   cases, targets, or data-impact notes changed after sign-off, the approval no
   longer describes the plan in front of you — that invalidates it for reasons
   that have nothing to do with tiering, and the plan needs re-approval.

Never *create* this state to get past the gate. Writing tiers onto an approved
plan and labeling them retroactive, so an agent-added triage inherits a human's
earlier approval, is the self-approval failure wearing a timestamp. Tiering an
already-approved plan is a thing a human asks for, not a thing a skill does on
its own initiative.
