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

[ -f /config/xdg/data/recently-used.xbel ] || {
    mkdir -p /config/xdg/data
    cp /defaults/recently-used.xbel /config/xdg/data/recently-used.xbel
}

[ -f /config/xdg/config/krokiet/config_general.json ] || {
    mkdir -p /config/xdg/config/krokiet
    cp /defaults/config_general.json /config/xdg/config/krokiet/
}

# Handle dark mode (for krokiet).
if is-bool-val-false "${DARK_MODE:-0}"; then
    jq -c -M '.dark_theme = false' /config/xdg/config/krokiet/config_general.json | sponge /config/xdg/config/krokiet/config_general.json
else
    jq -c -M '.dark_theme = true' /config/xdg/config/krokiet/config_general.json | sponge /config/xdg/config/krokiet/config_general.json
fi

# Adjust the main window selection.
echo '<Type>normal</Type>' > /tmp/main-window-selection.xml
if is-bool-val-true "${CZKAWKA_GUI_KROKIET:-0}"; then
    echo '<Name>krokiet</Name>' >> /tmp/main-window-selection.xml
else
    echo '<Name>czkawka_gui</Name>' >> /tmp/main-window-selection.xml
fi

# vim: set ft=sh :
