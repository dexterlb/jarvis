#!/usr/bin/env bash

set -euo pipefail

cdir="$(pwd)"

goose_exe="$(readlink -f $(which goose))"

bwrap_args=(
    --unshare-all
    --share-net

    --cap-drop ALL
    --die-with-parent
    --new-session

    --uid "$(id -u)"
    --gid "$(id -g)"

    --ro-bind /nix/store /nix/store
    --ro-bind /etc/nix /etc/nix
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

function add_goose_dir {
    if [[ ! -d "$JARVIS_STORAGE_DIR/${2}" ]]; then
        mkdir -p "$JARVIS_STORAGE_DIR/${2}"
    fi

    bwrap_args+=(--bind "$JARVIS_STORAGE_DIR/${2}" "${1}")
}

add_goose_dir "$HOME/.config/goose" config-goose
add_goose_dir "$HOME/.local/share/goose" share-goose
add_goose_dir "$HOME/.local/cache/goose" cache-goose

exec bwrap "${bwrap_args[@]}" "${goose_exe}" "${@}"
