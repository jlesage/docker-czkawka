#!/bin/sh

export HOME=/config
export LIBGL_ALWAYS_SOFTWARE=true

cd /storage
exec /usr/bin/czkawka_gui

# vim:ft=sh:ts=4:sw=4:et:sts=4
