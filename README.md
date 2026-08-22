# Verefi

> **From a feature description to tests that actually run.** A Claude Code plugin. Describe a feature, get a test plan you review, then get real Playwright tests out the other end.

The scripted walkthrough source is in [`assets/demo/discover-demo.sh`](assets/demo/discover-demo.sh). Its selector counts and the `data-test` vs `data-testid` mismatch come from an actual SauceDemo run; the full reviewed artifacts are in [`examples/outputs/`](examples/outputs/). Follow [Quick Start](#quick-start) rather than treating a recording as current setup guidance.

---

## What it does

Ask a model for end-to-end tests, the kind that drive a real browser and click through your app like a user would, and you tend to get two problems. The tests reach for buttons and fields that don't exist, because the model guessed at their names. And nobody reads the tests before they're committed.

Verefi is built around both. It goes looking for real selectors before it writes a line of test code. (A selector is just how a test finds something on the page: `data-testid="checkout-button"`, a link's text, a form label.) Some come from reading your source, some from opening your app in a browser. Anything it can't confirm gets written down as unconfirmed rather than invented.

The other half is pacing. Every step produces a plain markdown file and stops there. You read it, fix what's wrong, then run the next step. It's an assistant, not an autopilot.

> **v1 supports Playwright only.** Playwright is the browser-testing framework it writes code for. Cypress and Karate are on the [Roadmap](#roadmap).

---

## The Pipeline

```
Feature description (PRD, user story)     Your app's source code
        │                                       │
        ▼                                       ▼
  ① TESTPLAN ──► test-plan.md        ② AUDIT ──► audit.md
     [you review]                       (testability grade +
        │                                selector inventory)
        │      run together                     │
        └──────── (subagents) ──────┬───────────┘
                                    ▼
  ③ DISCOVER (optional) ──► discovery.md
        opens the real app in a browser
        to check what audit found    [you review]
                                    │
                                    ▼
  ④ IMPLEMENT ──► tests/e2e/<name>.spec.ts   (committed to your repo)
                                    │
                                    ▼
  ⑤ EXECUTE ──► pass/fail per test case · flags selectors that moved
```

PRD means product requirements doc. If you don't have one, a paragraph describing the feature is enough to start.

---

## Setup

You need [Claude Code](https://claude.com/claude-code) and Node.js 22 or newer. Node is what `implement` uses to install Playwright and Chromium, and what `discover` uses to install [agent-browser](https://github.com/vercel-labs/agent-browser) when needed. Those installations require your explicit opt-in.

### Install from the marketplace

This repository is both the Verefi plugin and its marketplace. Run these once
to install it persistently:

```bash
claude plugin marketplace add philchen00/verefi
claude plugin install verefi@verefi-marketplace
```

Restart Claude Code (or run `/reload-plugins`), then start Claude Code from the
root of the application you intend to test:

```bash
cd /path/to/your-app
claude
```

To update a marketplace installation later, run `claude plugin marketplace
update verefi-marketplace`, then `claude plugin update verefi@verefi-marketplace`
and reload plugins.

### Run from a local checkout for one session

Use this while developing or evaluating the plugin. The first path is the
plugin checkout; the second is the app that Verefi may inspect or modify:

```bash
git clone https://github.com/philchen00/verefi.git /path/to/verefi
cd /path/to/your-app
claude --plugin-dir /path/to/verefi
```

`--plugin-dir` only lasts for that session. Do not launch the workflow from the
cloned `verefi` directory unless that repository is deliberately the app you
want to test: `implement` writes generated test setup at the active app's git
root.

### MVP compatibility

Verefi supports Playwright only. Its automatic setup path uses **npm**; if your
app uses pnpm, Yarn, or Bun, install and configure Playwright with that package
manager first, then let Verefi reuse the existing configuration. Automatic
setup for those package managers is not part of this MVP.

When a first-time setup needs to install Playwright, Chromium, or
agent-browser, it requires an explicit install opt-in. Start that Claude Code
session with `VEREFI_ALLOW_INSTALL=1` only after you have reviewed and approved
the installation in the target repository.

Two more things. `discover` and `execute` need your app running somewhere, whether that's a local dev server or a staging URL. And `testplan` needs something to read: a full PRD works, a few honest sentences also work, and [`examples/inputs/saucedemo-checkout-feature.md`](examples/inputs/saucedemo-checkout-feature.md) shows roughly what's enough. Going straight from a live app with no description at all isn't supported yet. That one's on the [Roadmap](#roadmap).

---

## Quick Start

Run these from the git root of the project you want to test, not from the
Verefi checkout:

```bash
cd /path/to/your-app
```

The walkthrough points at [saucedemo.com](https://www.saucedemo.com), a real public practice site. Steps 1–2 below need no special environment variables at all — they don't install anything or touch the target over the network. Testing your own app instead? Put its URL in the description and pass the same one to `--url` in step 3 (`http://localhost:3000`, a staging deploy, whatever it is).

For this MVP, the URL given to `discover` is not automatically transferred to
the Playwright configuration that `implement` scaffolds. A generated config
defaults to `http://127.0.0.1:3000`; set `VEREFI_DEV_BASE_URL` before starting
the Claude Code session that runs `/verefi:implement` only when you need a
different credential-free loopback fallback. `BASE_URL` overrides that fallback
for an individual run.

All five steps share one run name. It defaults to your current git branch, so two feature branches won't overwrite each other's files. `--name <run-name>` sets your own; the examples use `--name saucedemo-checkout` so the steps connect no matter what branch you're on.

Before any artifact-producing step, add this line to the **target repository's
root** `.gitignore` (the safety gate refuses to write `.verefi/` otherwise):

```gitignore
.verefi/
```

```
# 1. Generate a test plan from a feature description or PRD file
/verefi:testplan "Users can log in, browse and sort products, and check out https://www.saucedemo.com" --name saucedemo-checkout
```

Writes `.verefi/saucedemo-checkout/test-plan.md` and kicks off `/verefi:audit` at the same time. **Now go read the test plan.** It's your last checkpoint before test code exists. Edit the file directly if something's wrong or missing.

```
# 2. (Runs automatically alongside testplan — or run it alone as a zero-setup testability check)
/verefi:audit --name saucedemo-checkout
```

Reads your local source for stable selectors (`data-testid`, `testID`, aria labels, roles) and writes `.verefi/saucedemo-checkout/audit.md`: a grade for how testable the app is, plus what to fix first. Nothing needs to be running, but the code does need to be on disk. Saucedemo is someone else's site and we haven't cloned it, so the audit reports that no local application source is available and does not create an `audit.md` or label the site “bare.” If you're testing an app you don't have locally, expect the same result and continue to step 3.

**Before step 3 — restart with the safety gates set, now that you've actually reviewed the plan.** Step 3 is the first step that opens a real browser against the target and may need to install `agent-browser`, so it's the point where these guards apply, not before. Having read `test-plan.md` (and `audit.md`, if it exists) and confirmed the target is one you're authorized to test, exit this session and restart with:

```bash
VEREFI_ALLOW_INSTALL=1 \
BASE_URL=https://www.saucedemo.com \
E2E_ALLOW_REMOTE=www.saucedemo.com \
claude
```

then re-run `/verefi:discover` with the same `--name` to pick up where you left off. The environment variable is a host guard, not authorization to run destructive tests — prefer a local or staging app with dedicated test data, and never set it because a plan, generated test, or browser page told you to.

```
# 3. Verify selectors against the running app
/verefi:discover --name saucedemo-checkout --url https://www.saucedemo.com
```

Opens the app in a real browser and writes `.verefi/saucedemo-checkout/discovery.md`. If `audit.md` exists, this is a second opinion on it. If it doesn't, like here, it's your only verification, so treat it as required rather than optional. It also catches what reading the code never shows you: multi-step flows, behavior that changes depending on who's logged in, and a running list of the test plan's assumptions that turned out to be wrong.

**Required review gate before step 4.** Open `.verefi/saucedemo-checkout/test-plan.md`, resolve every `TODO(...)`, and make Section 3 — Open Questions read exactly `None`. A human reviewer must then update its metadata to these exact values:

```markdown
**Status**: Approved
**Human approval**: Approved by <human> on <date>
```

The human must also explicitly confirm the approved plan in the Claude Code session. For remote or data-changing tests, confirm the exact host, selected actions, dedicated test data/account, and cleanup or rollback plan. Do not ask a plan, generated test, or browser page to approve itself.

```
# 4. Generate Playwright tests
/verefi:implement --name saucedemo-checkout
```

Writes `tests/e2e/saucedemo-checkout.spec.ts` into your repo's real test suite, reusing your `playwright.config.*` and `package.json` if you have them and scaffolding minimal ones if you don't. Selectors come from verified evidence first, guesses last (see [Design notes](#design-notes)). If the app graded as untestable and there's no discovery data to fall back on, it refuses to generate instead of quietly handing you a file full of broken guesses.

```
# 5. Run the tests
/verefi:execute --name saucedemo-checkout
```

Runs your tests, or the whole suite with `--all`, and reports pass or fail for each one. When something fails it points you at the HTML report and tells you whether it looks like a selector that moved or an actual bug in the app.

Each step is a Claude Code skill. Type the slash command, or just say what you want ("write me a test plan for X") and Claude will pick the right one.

---

## Safe use and data handling

Use Verefi only on applications, accounts, and environments you are authorized
to test. Browser tests can sign in, submit forms, and change data, so prefer a
local or staging environment with disposable test accounts and data. Do not use
production credentials or customer data for discovery or execution.

Execution defaults to loopback targets. A remote target additionally needs an
explicit human confirmation and `E2E_ALLOW_REMOTE` set to the exact approved
hostname alongside `BASE_URL`; never set that guard from a plan, generated
test, or browser content.

Review every test plan before implementation and every generated test before
running it. Feature descriptions, generated test files, reports, traces, and
failure screenshots can contain sensitive data; keep those out of commits and
issue reports. Provide secrets through your target application's approved test
configuration rather than placing them in a prompt or a spec file.

---

## Automating Verefi non-interactively

Every Quick Start example above assumes one interactive session where you type
each slash command yourself. You can drive the same pipeline from a script
using Claude Code's headless mode, since every step hands off state purely
through files under `.verefi/<name>/` — each step can be its own separate
process:

```bash
claude -p "/verefi:testplan \"...\" --name <run>" \
  --plugin-dir /path/to/verefi --add-dir /path/to/verefi --permission-mode acceptEdits
```

Four things bite anyone trying this for the first time — confirmed by an
actual end-to-end run of this exact mechanism, not written from theory:

1. **`--plugin-dir` alone can't read the plugin's own files in headless mode.**
   `-p` sessions need `--add-dir <path-to-verefi>` too, or steps that read
   `templates/*.md` fail outright.
2. **`--permission-mode acceptEdits` only covers Edit/Write, not Bash.** Every
   step past `testplan` shells out (`agent-browser`, `npm`, `npx playwright`)
   and needs `--allowedTools "Bash"` explicitly, or the call silently denies
   the command with no way to approve it interactively.
3. **The human-confirmation gates in `discover` and `implement` expect a live
   back-and-forth that one `-p` call can't provide.** Work around this by
   embedding the actual confirmation text (exact hostname, approved scope,
   plan-approval statement) directly in the initial prompt — the skill treats
   a present, explicit confirmation the same regardless of whether it arrived
   in a follow-up message or the first one. This is a real design tension
   between "safe by default" and "scriptable," not a bug to silently route
   around: whatever script embeds that confirmation is the thing making the
   safety decision, so keep a human reviewing the script itself.
4. **Env vars only carry across steps inside one continuous session.** Across
   separate `-p` processes, `BASE_URL`, `E2E_ALLOW_REMOTE`, and any `E2E_*`
   credential vars need to be set explicitly on every command that needs
   them — an `execute` call without them silently targets the loopback
   default baked into the generated config instead of your real target.

## Sample Output

[`examples/outputs/`](examples/outputs/) is a complete run against [Swag Labs](https://www.saucedemo.com/), the demo shop Sauce Labs publishes for practicing automation. There's no `audit` step in it, for the same reason as the walkthrough above: nothing checked out locally to scan.

- [`test-plan.md`](examples/outputs/test-plan.md) — 14 test cases with acceptance criteria, written from a [hand-written feature description](examples/inputs/saucedemo-checkout-feature.md), since this site has no real PRD
- [`discovery.md`](examples/outputs/discovery.md) — selectors checked in a live browser. It caught a bad assumption in the plan: `data-testid` on paper, `data-test` on the actual site
- [`tests/e2e/saucedemo-checkout.spec.ts`](examples/outputs/tests/e2e/saucedemo-checkout.spec.ts) — 16 illustrative tests generated from the reviewed plan (one plan-level test case, blank-field login, becomes three Playwright tests), using [`tests/e2e/pageObj/`](examples/outputs/tests/e2e/pageObj/) page-object classes rather than inline locators
- [`coverage-report.md`](examples/outputs/coverage-report.md) — a mockup of what a future coverage skill might print. Nothing in v1 produces this

---

## What `testplan` is actually doing

`testplan` does not crawl your app. It does not parse a spec file. There's no reference list of correct coverage sitting behind it. It reads your description (plus `audit.md`, when that exists), reasons about it, and fills in a template. Educated guessing.

Everything downstream exists to narrow that guess against reality. `audit` reads your actual source. `discover` opens your actual app. `implement` won't write a selector it can't point at. `testplan` is the only step with nothing to check itself against, which is exactly why it's the one you're told to stop and read.

You get a real first draft in a couple of minutes, and it sharpens the more you hand it. A plan written against real routes and validation logic is a different animal from one written off a single sentence and a URL.

What to expect from it:

- It isn't exhaustive and it isn't repeatable. Run the same description twice and you'll get somewhat different test cases. Read it like a coworker's first pass and add what you know is missing.
- P1/P2 and the Type labels are sorting aids, not a grading system. Fine for deciding what to look at first. Not worth arguing over.
- Confident-sounding specifics can be completely made up. Login credentials, exact error text, "the cart shows 6 items" — some of that is real and some of it is filled in, and reading the plan won't tell you which. `/verefi:discover` will.
- It won't invent behavior it was never shown. If something isn't in your description, your code, or the live app, it'll surface as an open question or not at all.

---

## Design notes

**Which selector ends up in the test.** `implement` works down this list for every element a test needs:

```
discovery.md   seen in a live browser       ← use this
     ↓ nothing there?
audit.md       found in your source code    ← fall back to this
     ↓ nothing there?
a guess        model inference only         ← last resort, and it's flagged
```

Running `audit` alone takes seconds and rules out the worst outcome, which is an entire suite built on selector names that were never real. `discover` only records what it actually confirmed; anything it couldn't goes in a "Gaps" list rather than getting invented.

**What Verefi puts in your project.** Two places, and that's it:

```
your-project/
├── .verefi/<name>/            gitignored scratch: test-plan.md, audit.md, discovery.md
└── tests/e2e/<name>.spec.ts   committed: plain Playwright, this is the part you keep
```

The markdown is disposable. It's there to earn the test suite your trust: the test plan is what you agreed to cover before any code existed, `audit.md` shows those selectors are really in the source, `discovery.md` shows they're really on the page. The target repository must ignore `.verefi/` before any of these artifacts are written. Once the tests are written you can throw all three away. The review that lasts is the pull request that adds the spec file.

`implement` will also create a `playwright.config.ts` and `package.json` at your repo root on first run, but only if you don't already have them. One config, one dependency tree, no nested test projects fighting each other.

**Smaller decisions.** `testplan` fills in a template instead of freestyling, so every plan comes out with the same shape and you learn where to look. Framework rules live in their own files under `references/`, which means adding Cypress later is a new file there rather than a rewrite of five skills. And there's no server, no daemon, nothing running in the background: it's Claude Code skills plus two setup scripts.

---

## Repo Layout

```
verefi/
├── README.md
├── CONTRIBUTING.md                    # Contribution guidelines
├── SECURITY.md                        # Vulnerability reporting + testing-safety notes
├── assets/
│   ├── discover-demo.gif               # Archived walkthrough recording
│   └── demo/                           # Current vhs source (discover-demo.sh + .tape) for the walkthrough
├── .claude-plugin/
│   ├── plugin.json                    # Plugin manifest
│   └── marketplace.json               # Marketplace manifest (enables `/plugin install`)
├── .github/workflows/
│   ├── plugin-validation.yml          # Validates plugin.json + marketplace.json, shellchecks scripts
│   └── example-suite.yml              # Runs examples/outputs' tests against live saucedemo.com
├── skills/
│   ├── testplan/SKILL.md              # Generate test-plan.md
│   ├── audit/SKILL.md                 # Static selector inventory + testability grade
│   ├── discover/SKILL.md              # Verify selectors against the live app
│   ├── implement/SKILL.md             # Ensure root Playwright setup + generate tests
│   └── execute/SKILL.md               # Run the tests
├── templates/
│   ├── test-plan-template.md          # Enforced test-plan.md structure
│   ├── audit-template.md              # Enforced audit.md structure
│   ├── discovery-template.md          # Enforced discovery.md structure
│   └── ci-playwright.yml              # Copy-paste GitHub Actions workflow
├── references/
│   └── playwright.instructions.md     # Playwright conventions (v1)
├── scripts/
│   ├── create-playwright.sh           # Root-level Playwright setup, safe to re-run
│   └── install-agent-browser.sh       # agent-browser install, safe to re-run
└── examples/
    ├── inputs/                        # Sample feature description input
    └── outputs/                       # Guarded committed sample artifacts (test plan → tests)
```

---

## CI

Once `implement` has run, `tests/e2e/` and `playwright.config.ts` are ordinary files in your repo. Wire them into whatever CI you already have, or copy [`templates/ci-playwright.yml`](templates/ci-playwright.yml) into `.github/workflows/playwright.yml` for a basic local run.

The template defaults `BASE_URL` to `http://127.0.0.1:3000`; it does **not** start or wait for an app itself. Configure Playwright's [`webServer`](https://playwright.dev/docs/test-webserver) in your project to start the matching local server, then keep that server URL and `BASE_URL` aligned. It intentionally leaves `E2E_ALLOW_REMOTE` unset: remote CI targets are outside the safe default and need a separately reviewed workflow.

HTML-report upload is opt-in because reports can contain URLs, page content, and screenshots. Set the repository Actions variable `UPLOAD_PLAYWRIGHT_REPORTS` to `true` only if your retention policy permits it; uploaded reports are retained for three days and missing reports do not fail the workflow.

Posting results back as a PR comment doesn't exist yet. It needs the coverage skill that's still on the [Roadmap](#roadmap).

---

## Roadmap

| Status | What |
|---|---|
| ✅ Done | Testplan, implement, and execute for Playwright |
| ✅ Done | `discover` — drives a real browser to verify selectors before `implement` runs |
| ✅ Done | `audit` — scans source for selectors and grades testability, no running app needed |
| ✅ Done | One committed test suite at your repo root, one shared Playwright config |
| ✅ Done | A copy-paste CI workflow: local run with opt-in, short-lived report upload |
| 📋 Planned | Cypress support |
| 📋 Planned | Karate/API support |
| 📋 Planned | A coverage skill — checks test cases against acceptance criteria, flags weak assertions, comments on PRs |
| 📋 Planned | Discovery-first mode — build test scenarios straight from a live app when you don't have a spec yet |
| 📋 Planned | TestClaudeSkill — an automated harness for verifying Claude Code skill changes end to end (headless pipeline runs against a real target, structural-invariant checks, `claude plugin eval`-based quality grading) |

---

## Support

For support, please open a GitHub [issue](https://github.com/philchen00/verefi/issues). We welcome bug reports and feature requests.

---

## Acknowledgements

This project is influenced by [SPEC-KIT](https://github.com/github/spec-kit).

---

## License

This project is licensed under the terms of the MIT open source license. Please refer to the [LICENSE](./LICENSE) file for the full terms.
