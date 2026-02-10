#!/usr/bin/env bash

set -euo pipefail

cdir="$(pwd)"

claude_exe="$(readlink -f $(which claude))"

bwrap_args=(
    --unshare-all
    --share-net

    --cap-drop ALL
    --die-with-parent
    --new-session

    --uid "$(id -u)"
    --gid "$(id -g)"

    --ro-bind /nix/store /nix/store
    --ro-bind /etc/nsswitch.conf /etc/nsswitch.conf
    --ro-bind /etc/protocols /etc/protocols
    --ro-bind /etc/services /etc/services
    --ro-bind /etc/hosts /etc/hosts
    --ro-bind /etc/resolv.conf /etc/resolv.conf
    --ro-bind /etc/ssl /etc/ssl
    --ro-bind /etc/ca-certificates /etc/ca-certificates
    --ro-bind "$(which bash)" /bin/bash
    --ro-bind "$(which sh)" /bin/sh

    --tmpfs /tmp

    --bind "${cdir}" "${cdir}"
    --chdir "${cdir}"

    --proc /proc
    --dev /dev
)

# Add Claude configuration access if files/directories exist
if [ -d "$HOME/.claude" ]; then
    bwrap_args+=(--bind "$HOME/.claude" "$HOME/.claude")
fi

if [ -f "$HOME/.claude.json" ]; then
    bwrap_args+=(--bind "$HOME/.claude.json" "$HOME/.claude.json")
fi

# Add project-level .claude directory if it exists
if [ -d "./.claude" ]; then
    bwrap_args+=(--bind "$cdir/.claude" "$cdir/.claude")
fi

exec bwrap "${bwrap_args[@]}" bash "${claude_exe}" "--dangerously-skip-permissions" "${@}"
