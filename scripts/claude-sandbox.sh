#!/usr/bin/env bash

set -euo pipefail

cdir="$(pwd)"

claude_exe="$(readlink -f $(which claude))"

firejail_args=(
    --noprofile             # no default settings

    --private-tmp
    --noroot
    --caps.drop=all
    --nonewprivs
    --nogroups

    # Filesystem access - whitelist specific paths only
    --whitelist=/nix/store
    --read-only=/nix/store
    --whitelist="$cdir"
    --read-write="$cdir"
)

# Add Claude configuration access if files/directories exist
if [ -d "$HOME/.claude" ]; then
    firejail_args+=(--whitelist="$HOME/.claude")
    firejail_args+=(--read-write="$HOME/.claude")
fi

if [ -f "$HOME/.claude.json" ]; then
    firejail_args+=(--whitelist="$HOME/.claude.json")
    firejail_args+=(--read-write="$HOME/.claude.json")
fi

# Add project-level .claude directory if it exists
if [ -d "./.claude" ]; then
    firejail_args+=(--whitelist="$cdir/.claude")
    firejail_args+=(--read-write="$cdir/.claude")
fi

# firejail_args+=(--net=none)  # Uncomment to disable network access

exec firejail "${firejail_args[@]}" bash "${claude_exe}" "--dangerously-skip-permissions" "${@}"
