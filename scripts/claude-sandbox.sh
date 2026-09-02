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
    --ro-bind "$(which env)" /usr/bin/env

    --tmpfs /tmp

    --bind "${cdir}" "${JARVIS_SANDBOX_DIR}"
    --chdir "${JARVIS_SANDBOX_DIR}"

    --proc /proc
    --dev /dev
)

if [[ ! -d "$JARVIS_STORAGE_DIR/.claude" ]]; then
    mkdir -p "$JARVIS_STORAGE_DIR/.claude"
fi

if [[ ! -f "$JARVIS_STORAGE_DIR/.claude.json" ]]; then
    touch "$JARVIS_STORAGE_DIR/.claude.json"
fi

bwrap_args+=(--bind "$JARVIS_STORAGE_DIR/.claude" "$HOME/.claude")
bwrap_args+=(--bind "$JARVIS_STORAGE_DIR/.claude.json" "$HOME/.claude.json")

exec bwrap "${bwrap_args[@]}" "${claude_exe}" "--dangerously-skip-permissions" "${@}"
