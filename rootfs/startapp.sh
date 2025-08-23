#!/bin/sh
export HOME=/config

export LIBGL_ALWAYS_SOFTWARE=true
export SLINT_BACKEND=software

# This is to avoid the following warning:
#   (czkawka_gui:613): Gtk-WARNING **: 17:45:24.876: Unable to acquire the address of the accessibility bus: GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name org.a11y.Bus was not provided by any .service files. If you are attempting to run GT
export GTK_A11Y=none

cd /storage
if is-bool-val-true "${CZKAWKA_GUI_KROKIET:-0}"; then
    exec /usr/bin/krokiet
else
    exec /usr/bin/czkawka_gui
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4
