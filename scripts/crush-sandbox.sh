#!/usr/bin/env bash

set -euo pipefail

cdir="$(pwd)"

crush_exe="$(readlink -f $(which crush))"

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

function add_crush_dir {
    if [[ ! -d "$JARVIS_STORAGE_DIR/${2}" ]]; then
        mkdir -p "$JARVIS_STORAGE_DIR/${2}"
    fi

    bwrap_args+=(--bind "$JARVIS_STORAGE_DIR/${2}" "${1}")
}

project_slug="$(echo "${JARVIS_SANDBOX_DIR}" | sed -E 's/\//_/g')"
add_crush_dir "${JARVIS_SANDBOX_DIR}/.crush" per-project/"${project_slug}"
add_crush_dir "$HOME/.config/crush" config-crush
add_crush_dir "$HOME/.local/share/crush" share-crush

exec bwrap "${bwrap_args[@]}" "${crush_exe}" "${@}"
