#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Clear the fstab file to make sure its content is not displayed when selecting
# folder to add.
echo > /etc/fstab

if [ ! -f /config/xdg/config/czkawka/czkawka_gui_config.txt ]; then
   mkdir -p /config/xdg/config/czkawka
   touch /config/xdg/config/czkawka/czkawka_gui_config.txt
fi

if [ ! -f /config/xdg/data/recently-used.xbel ]; then
   mkdir -p /config/xdg/data
   cp /defaults/recently-used.xbel /config/xdg/data/recently-used.xbel
fi

# Take ownership of the config directory content.
find /config -mindepth 1 -exec chown $USER_ID:$GROUP_ID {} \;

# vim: set ft=sh :
