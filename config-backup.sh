#!/usr/bin/env bash

# set -e: exit script immediately upon error
set -e

if [ $EUID != 0 ]; then
    sudo -H "$0" "$@"
    exit $?
fi

if [ ! -d "$HOME/.config-backup" ] ; then
    cd && git clone ssh://root@lemuel:222/root/src/config-backup ".config-backup"
fi

chmod 700 "$HOME/.config-backup"
CONFIG_DIR="$HOME/.config-backup/$(hostname -s)"
mkdir -p "$CONFIG_DIR" || exit
CONFIG_LIST=$CONFIG_DIR/config.txt
touch "$CONFIG_LIST"

cd "$CONFIG_DIR" && git pull --rebase --autostash

if [ "$1" != ""  ] ; then echo "$1" >> "$CONFIG_LIST" ; fi
sort -uo "$CONFIG_LIST" "$CONFIG_LIST"
rsync -av --files-from="$CONFIG_LIST" / "$CONFIG_DIR/"
cd "$CONFIG_DIR" && git add . && git commit -m "$(date)" && git push

tree -aI .git "$CONFIG_DIR/.."
