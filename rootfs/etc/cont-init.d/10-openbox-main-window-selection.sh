#!/bin/sh
#
# Main main window selection must be determined dynamically.
# This must be executed before `10-openbox.sh`.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

echo '<Type>normal</Type>' > /tmp/main-window-selection.xml
if is-bool-val-true "${CZKAWKA_GUI_KROKIET:-0}"; then
    echo '<Name>krokiet</Name>' >> /tmp/main-window-selection.xml
else
    echo '<Title>Czkawka *</Title>' >> /tmp/main-window-selection.xml
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4
