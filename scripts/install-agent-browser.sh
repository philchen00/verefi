#!/usr/bin/env bash
#
# Install the reviewed agent-browser CLI only after an explicit opt-in. A
# version mismatch is surfaced rather than silently changing a global tool.

set -euo pipefail

AGENT_BROWSER_VERSION="${1:-0.27.0}"

fail() {
  echo "$1" >&2
  exit 2
}

if ! [[ "$AGENT_BROWSER_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-.+][A-Za-z0-9.-]+)?$ ]]; then
  fail "VEREFI_INVALID_AGENT_BROWSER_VERSION=$AGENT_BROWSER_VERSION (use an exact version)"
fi

installed_version() {
  local raw_version
  # Capture the command substitution's own exit status explicitly — under
  # set -euo pipefail, a non-zero exit from `agent-browser --version` piped
  # straight into awk would abort the whole script here with no diagnostic
  # at all, instead of the clean fail() message below.
  if ! raw_version="$(agent-browser --version 2>/dev/null)"; then
    fail "VEREFI_AGENT_BROWSER_VERSION_CHECK_FAILED=agent-browser --version exited non-zero (corrupted or incompatible existing install?)"
  fi
  printf '%s\n' "$raw_version" | awk '{print $NF}'
}

if command -v agent-browser >/dev/null 2>&1; then
  INSTALLED_VERSION="$(installed_version)"
  if [ "$INSTALLED_VERSION" = "$AGENT_BROWSER_VERSION" ]; then
    echo "AGENT_BROWSER_INSTALLED=true"
    echo "AGENT_BROWSER_VERSION=$INSTALLED_VERSION"
    echo "✓ agent-browser $INSTALLED_VERSION already installed"
    exit 0
  fi
  fail "VEREFI_AGENT_BROWSER_VERSION_MISMATCH=found:$INSTALLED_VERSION required:$AGENT_BROWSER_VERSION (review and update it yourself)"
fi

if [ "${VEREFI_ALLOW_INSTALL:-}" != "1" ]; then
  echo "VEREFI_PERMISSION_REQUIRED=agent-browser-install" >&2
  echo "This installs agent-browser $AGENT_BROWSER_VERSION globally and downloads its browser runtime." >&2
  echo "Review the action, then re-run with VEREFI_ALLOW_INSTALL=1." >&2
  exit 2
fi

if ! command -v npm >/dev/null 2>&1; then
  fail "VEREFI_NPM_REQUIRED=true"
fi

echo "Installing agent-browser $AGENT_BROWSER_VERSION..."
npm install --global "agent-browser@$AGENT_BROWSER_VERSION"
agent-browser install

INSTALLED_VERSION="$(installed_version)"
if [ "$INSTALLED_VERSION" != "$AGENT_BROWSER_VERSION" ]; then
  fail "VEREFI_AGENT_BROWSER_INSTALL_VERIFICATION_FAILED=expected:$AGENT_BROWSER_VERSION actual:$INSTALLED_VERSION"
fi

echo "AGENT_BROWSER_INSTALLED=true"
echo "AGENT_BROWSER_VERSION=$INSTALLED_VERSION"
echo "✓ Installed agent-browser $INSTALLED_VERSION"
