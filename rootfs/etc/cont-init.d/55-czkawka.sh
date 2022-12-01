#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Generate machine id.
if [ ! -f /config/machine-id ]; then
    echo "generating machine-id..."
    cat /proc/sys/kernel/random/uuid | tr -d '-' > /config/machine-id
fi

# Clear the fstab file to make sure its content is not displayed when selecting
# folder to add.
echo > /etc/fstab

if [ ! -f /config/xdg/data/recently-used.xbel ]; then
    mkdir -p /config/xdg/data
    cp /defaults/recently-used.xbel /config/xdg/data/recently-used.xbel
fi

# Check if we have permission to write to the trash.
USE_TRASH="$(grep -A1 "\-\-use_trash:" "$CONFIG_DIR"/czkawka_gui_config.txt | tail -n1)"
if [ "$USE_TRASH" = "true" ]; then
    if [ -n "${SUP_GROUP_IDS:-}" ]; then
        if ! su-exec -u $USER_ID -g $GROUP_ID -G $SUP_GROUP_IDS test -w /trash
        then
            echo "ERROR: No permission to write into the trash."
        fi
    else
        if ! su-exec $USER_ID:$GROUP_ID test -w /trash
        then
            echo "ERROR: No permission to write into the trash."
        fi
    fi
fi

# vim: set ft=sh :
