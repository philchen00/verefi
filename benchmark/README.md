# Verefi benchmarks

Regression testing for the **AI workflow itself** — does Verefi still produce
good output after a skill, prompt, or model change?

Design and rationale live in `feedback/benchmark-runner-evaluation-framework.md`.
This directory currently holds **the benchmark target only**. The Runner
(§39 of that draft — the piece that executes the pipeline headlessly and
collects artifacts) is not built yet.

```
benchmark/
  benchmarks/
    checkout-basic/
      benchmark.yaml      # manifest: workflow, expectations, mutations, approval
      README.md           # requirements + instrumentation map — read this first
      app/                # the benchmark application (static, no build)
      mutations/          # seeded defects, one script each
  runs/                   # gitignored run output
```

## Why a purpose-built app

Mutation testing is the strongest signal in the framework: rather than asking
"did Verefi generate tests?", it asks "would those tests catch a real defect?"
That requires seeding defects into the app's source — which rules out a
third-party site like saucedemo, since you cannot introduce a wrong tax
calculation into someone else's deployment.

A local app also keeps the whole benchmark on loopback, so the pipeline's
remote-host guard never needs an exception.

## Running the app by hand

```bash
cd benchmarks/checkout-basic
python3 -m http.server 4173 --directory app
# http://127.0.0.1:4173  ·  demo_user / demo_pass
```

## Applying a mutation

Always to a **copy** — the scripts patch in place.

```bash
cp -r app /tmp/mutant
./mutations/checkout-001.sh /tmp/mutant
python3 -m http.server 4174 --directory /tmp/mutant
```

Each script exits 3 with `MUTATION_ANCHOR_ERROR` if its anchor no longer
matches the application exactly, rather than silently patching nothing. That
distinction is the whole point: a mutation that fails to apply makes every
generated test pass, and the scorecard would report "defect not detected" —
blaming Verefi for a harness bug.

## Two rules for anything built here

**Never let the harness self-approve.** The pipeline's human approval gate is
its core claim. A benchmark manifest may carry a human-authored
pre-authorization for its own disposable app (see `approval:` in
`benchmark.yaml`), and the runner may pass that text through — but no
automation may compose an approval, edit a plan's `Status` / `Human approval`
fields, or treat a missing `approval:` block as permission to skip `implement`
and score the rest. Every run must prove the approval fields were untouched
(`scripts/check-invariants.sh --approval-baseline`).

**Every evaluator needs a seeded failure proving it can fail.** A checker that
only ever reports green is indistinguishable from one that checks nothing.
`scripts/tests/run-invariant-tests.sh` is the existing example: each negative
case asserts the specific invariant id that must fail, not merely a non-zero
exit.
