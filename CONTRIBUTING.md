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

5. If you change a published plugin behavior, update the plugin version and the
   matching marketplace entry so installed users can receive the release.

## Development notes

Verefi is a Claude Code plugin that operates on the repository where Claude
Code is launched. Test it only against applications and accounts you are
authorized to use. The MVP scaffolding path uses npm and Playwright; preserve
that limitation in documentation unless the implementation changes as well.

## Releasing

Versions follow semver: patch (`0.1.1` → `0.1.2`) for fixes and docs, minor
(`0.1.x` → `0.2.0`) for new skills or backward-compatible behavior changes,
major for anything that breaks an existing skill's interface.

Releases are prepared and validated through a private review pipeline before
anything is tagged or published in this repository. That pipeline runs
plugin validation, linting, a secrets scan, and the live example test suite
against every release candidate, then opens a pull request here containing
only the reviewed, publishable files.

If your change affects published plugin behavior, bump `version` in **both**
`.claude-plugin/plugin.json` and the matching entry in
`.claude-plugin/marketplace.json` as part of your PR — they must agree;
`claude plugin validate --strict` enforces this. Do not push a
`verefi--v<version>` tag yourself; tagging and publishing a release is
reserved for the maintainer, only after the private pipeline has passed.
This repository's tag-protection rules block `verefi--v*` tag creation by
anyone other than a repository admin.

## Reporting problems

Use [GitHub Issues](https://github.com/philchen00/verefi/issues) for bugs and
feature requests. Please use the private process in [SECURITY.md](SECURITY.md)
for vulnerabilities.
