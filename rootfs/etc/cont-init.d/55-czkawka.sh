#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

log() {
    if [ -n "${1-}" ]; then
        echo "[cont-init.d] $(basename $0): $*"
    else
        while read OUTPUT; do
            echo "[cont-init.d] $(basename $0): $OUTPUT"
        done
    fi
}

# Clear the fstab file to make sure its content is not displayed when selecting
# folder to add.
echo > /etc/fstab

CONFIG_DIR=/config/xdg/config/czkawka
if [ ! -f "$CONFIG_DIR"/czkawka_gui_config.txt ]; then
    mkdir -p "$CONFIG_DIR"
    cp /defaults/czkawka_gui_config.txt "$CONFIG_DIR"
fi

if [ ! -f /config/xdg/data/recently-used.xbel ]; then
    mkdir -p /config/xdg/data
    cp /defaults/recently-used.xbel /config/xdg/data/recently-used.xbel
fi

# Check if we have permission to write to the trash.
USE_TRASH="$(grep -A1 "\-\-use_trash:" "$CONFIG_DIR"/czkawka_gui_config.txt | tail -n1)"
if [ "$USE_TRASH" = "true" ]; then
    if [ -n "${SUP_GROUP_IDS:-}" ]; then
        if ! s6-applyuidgid -u $USER_ID -g $GROUP_ID -G $SUP_GROUP_IDS test -w /trash
        then
            log "ERROR: No permission to write into the trash."
        fi
    else
        if ! s6-setuidgid $USER_ID:$GROUP_ID test -w /trash
        then
            log "ERROR: No permission to write into the trash."
        fi
    fi
fi

# Take ownership of the config directory content.
find /config -mindepth 1 -exec chown $USER_ID:$GROUP_ID {} \;

# vim: set ft=sh :
