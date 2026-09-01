#!/usr/bin/env bash

set -euo pipefail

cdir="$(pwd)"

tool_exe="$(readlink -f $(which pi-coding-agent))"

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
    --ro-bind "$(which sh)" /bin/sh

    --tmpfs /tmp

    --bind "${cdir}" "${cdir}"
    --chdir "${cdir}"

    --proc /proc
    --dev /dev
)

# if ! [[ -d "$HOME/.config/pi-coding-agent" ]]; then
#     echo "~/.config/pi-coding-agent does not exist"
# fi
# bwrap_args+=(--bind "$HOME/.config/pi-coding-agent" "$HOME/.config/pi-coding-agent")
export SHELL="$(which bash)"

exec bwrap "${bwrap_args[@]}" "${tool_exe}" "${@}"
