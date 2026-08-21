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
