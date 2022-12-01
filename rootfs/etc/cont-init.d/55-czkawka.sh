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

# vim: set ft=sh :
