# Security Policy

## Supported versions

Security fixes are made on the latest release of Verefi. The current supported
release line is `0.1.x`.

## Reporting a vulnerability

Please report suspected vulnerabilities privately through the
[GitHub Security Advisories form](https://github.com/philchen00/verefi/security/advisories/new).
Do not open a public issue for a vulnerability until a maintainer has had a
chance to investigate it.

Include the affected version, a clear reproduction, the potential impact, and
any suggested mitigation. We will acknowledge a report within seven days and
will coordinate a disclosure timeline with you after confirming the issue.

## Testing safety

Verefi can inspect source code, open supplied URLs, generate browser tests, and
run those tests. Treat the plugin, its generated tests, and all browser
artifacts as trusted only after review. Use accounts, applications, and data you
are authorized to test; prefer local or staging environments and disposable
test data. Never include production credentials, tokens, customer data, or
other secrets in feature descriptions, plans, generated tests, reports, traces,
or screenshots.

Remote test execution must be explicitly approved for the exact non-production
hostname. Keep the runtime host guard enabled by setting `E2E_ALLOW_REMOTE` to
that hostname exactly (without a scheme, path, or wildcard) alongside
`BASE_URL`; this safeguard never replaces human authorization or dedicated test
data.
