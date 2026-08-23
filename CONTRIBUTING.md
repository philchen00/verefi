# Contributing to Verefi

Thanks for helping improve Verefi. Contributions that make generated tests more
reliable, safer, and easier to review are especially welcome.

## Before opening a pull request

1. Start from the latest `main` in a focused branch.
2. Keep the change small and explain the user-facing behavior it changes.
3. Do not commit credentials, tokens, customer data, browser reports, traces,
   screenshots, or other sensitive test artifacts.
4. Run the plugin validation from the repository root:

   ```bash
   claude plugin validate --strict .
   claude plugin validate --strict .claude-plugin/plugin.json
   ```

5. Run the structural invariant checks (see below):

   ```bash
   ./scripts/tests/run-invariant-tests.sh
   ./scripts/check-invariants.sh \
     --plan examples/outputs/test-plan.md \
     --spec examples/outputs/tests/e2e/saucedemo-checkout.spec.ts \
     --pageobj-dir examples/outputs/tests/e2e/pageObj
   ```

6. If you change a published plugin behavior, update the plugin version and the
   matching marketplace entry so installed users can receive the release.

## Testing a skill change

Verefi's "code" is markdown interpreted by an LLM, so the same instructions
legitimately produce different concrete output run to run. That makes a
golden-file diff the wrong tool: it reports different-but-equally-valid wording
as a regression, which is the false-positive signal that trains people to ignore
the check. Evaluation is split into layers instead.

**Structural invariants** (`scripts/check-invariants.sh`) — properties that must
hold for *any* correct run, regardless of wording, ordering, or which valid
selector was chosen. They cover plan structure, the N6 review tiers (no
`Auto-cleared` case may be P1 or non-read-only; header counts must match the
per-case tally; every classification must state a reason), approval-gate
consistency, and spec/plan cross-checks (every plan case has a test, every test
traces to a plan case, no `test.fail()`, no page object named like a test file).
Checks whose artifact you didn't pass report `SKIP`, never `PASS`.

Run it against any artifact set:

```bash
./scripts/check-invariants.sh --plan .verefi/<name>/test-plan.md \
  --spec tests/e2e/<name>.spec.ts --pageobj-dir tests/e2e/pageObj
```

**Approval-field integrity** (`--approval-baseline`) — the one property that
cannot be checked from a single file. Copy the plan before running a skill
stage, then compare:

```bash
cp .verefi/<name>/test-plan.md /tmp/plan-before.md
# ...run the skill stage...
./scripts/check-invariants.sh --plan .verefi/<name>/test-plan.md \
  --approval-baseline /tmp/plan-before.md
```

No skill may ever write `**Status**` or `**Human approval**`. An agent that
fills those in produces a plan whose contents are *correct* and which therefore
satisfies every static check — "accurate" is not the property an approval field
carries, "a person asserted this" is. Only the diff tells them apart.

**The checker's own self-test** (`scripts/tests/run-invariant-tests.sh`) — a
checker that only ever runs green is indistinguishable from one that checks
nothing, so every negative case asserts the specific invariant id that must
fail, not merely a non-zero exit. Add a case here whenever you add an invariant.
Fixtures live in `scripts/tests/fixtures/` and are mutated in a scratch dir;
they are never modified in place.

**Quality grading** of the genuinely subjective parts (is this test case
well-prioritized, is this selector choice reasonable given the gap) is left to
`claude plugin eval` rather than reimplemented here. It was still early access
on this account as of 2026-08-23; when it lands, eval cases belong under
`evals/` as `prompt.md` + `graders/*.md`.

## Development notes

Verefi is a Claude Code plugin that operates on the repository where Claude
Code is launched. Test it only against applications and accounts you are
authorized to use. The MVP scaffolding path uses npm and Playwright; preserve
that limitation in documentation unless the implementation changes as well.

## Releasing

Versions follow semver: patch (`0.1.1` → `0.1.2`) for fixes and docs, minor
(`0.1.x` → `0.2.0`) for new skills or backward-compatible behavior changes,
major for anything that breaks an existing skill's interface.

1. Bump `version` in **both** `.claude-plugin/plugin.json` and the matching
   entry in `.claude-plugin/marketplace.json` — they must agree; `claude
   plugin validate --strict` and `claude plugin tag` both enforce this.
2. Merge that change to `main`.
3. From `main`, cut the tag:

   ```bash
   claude plugin tag --dry-run .   # preview: confirms both files agree and shows the exact tag
   claude plugin tag --push .      # creates verefi--v<version> and pushes it to origin
   ```

`claude plugin tag` refuses to run on a dirty working tree or re-tag an
existing version by default — use `--force` only if you specifically mean to
overwrite a tag that was cut in error.

## Reporting problems

Use [GitHub Issues](https://github.com/philchen00/verefi/issues) for bugs and
feature requests. Please use the private process in [SECURITY.md](SECURITY.md)
for vulnerabilities.
