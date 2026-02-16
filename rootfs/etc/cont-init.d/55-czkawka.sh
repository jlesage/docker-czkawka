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

[ -f "$XDG_DATA_HOME"/recently-used.xbel ] || {
    mkdir -p "$XDG_DATA_HOME"
    cp /defaults/recently-used.xbel "$XDG_DATA_HOME"/
}

[ -f "$XDG_CONFIG_HOME"/gtk-3.0/bookmarks ] || {
    mkdir -p "$XDG_CONFIG_HOME"/gtk-3.0/
    cp /defaults/bookmarks "$XDG_CONFIG_HOME"/gtk-3.0/
}

[ -f "$XDG_CACHE_HOME"/czkawka/krokiet_info_dialog_seen.txt ] || {
    mkdir -p "$XDG_CACHE_HOME"/czkawka
    cp /defaults/krokiet_info_dialog_seen.txt "$XDG_CACHE_HOME"/czkawka/
}

if is-bool-val-true "${CZKAWKA_GUI_KROKIET:-0}"; then
    echo "WARNING: The CZKAWKA_GUI_KROKIET environment variable is deprecated"
    echo "         and no longer supported. To use Krokiet, please switch to"
    echo "         its dedicated Docker image."
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4
