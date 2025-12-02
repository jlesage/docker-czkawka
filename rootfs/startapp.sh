#!/bin/sh
export HOME=/config

export LIBGL_ALWAYS_SOFTWARE=true
export SLINT_BACKEND=software

cd /storage
if is-bool-val-true "${CZKAWKA_GUI_KROKIET:-0}"; then
    exec /usr/bin/krokiet
else
    exec /usr/bin/czkawka_gui
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4
