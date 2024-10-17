#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

function log {
    echo ">>> $*"
}

CZKAWKA_URL="$1"

if [ -z "$CZKAWKA_URL" ]; then
    log "ERROR: Czkawka URL missing."
    exit 1
fi

#
# Install required packages.
#
apk --no-cache add \
    bash \
    curl \
    clang \
    g++ \
    lld \
    patch \
    pkgconf \

xx-apk --no-cache --no-scripts add \
    musl-dev \
    gcc \
    libstdc++-dev \
    gtk4.0-dev \
    libheif-dev \

CZKAWKA_FEATURES="heif"
if ! xx-info is-cross; then
    CZKAWKA_FEATURES="$CZKAWKA_FEATURES,libraw"
fi

# Install Rust.
# NOTE: Czkawka often requires a recent version of Rust that is not available
#       yet in Alpine repository.
USE_RUST_FROM_ALPINE_REPO=false
if $USE_RUST_FROM_ALPINE_REPO; then
    apk --no-cache add \
        rust \
        cargo
else
    apk --no-cache add \
        gcc \
        musl-dev
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
    source /root/.cargo/env

    # NOTE: When not installing Rust from the Alpine repository, we must compile
    #       with `RUSTFLAGS="-C target-feature=-crt-static"` to avoid crash
    #       during GTK initialization.
    #       See https://github.com/qarmin/czkawka/issues/416.
    export RUSTFLAGS="-C target-feature=-crt-static"
fi

# Fix the xx-cargo setup.  See https://github.com/tonistiigi/xx/issues/104.
if xx-info is-cross; then
    xx-cargo --setup-target-triple
    if [ ! -e "/$(xx-cargo --print-target-triple)" ]; then
        ln -s "$(xx-info)" "/$(xx-cargo --print-target-triple)"
    fi
    if [ ! -e "$(xx-info sysroot)/usr/lib/gcc/$(xx-cargo --print-target-triple)" ]; then
        ln -s "$(xx-info)" "$(xx-info sysroot)/usr/lib/gcc/$(xx-cargo --print-target-triple)"
    fi
fi

#
# Download sources.
#

log "Downloading Czkawka..."
mkdir /tmp/czkawka
curl -# -L -f ${CZKAWKA_URL} | tar xz --strip 1 -C /tmp/czkawka

#
# Compile Czkawka.
#

# Create cargo profile.
# https://github.com/johnthagen/min-sized-rust
mkdir /tmp/czkawka/.cargo
echo "[profile.release]" >> /tmp/czkawka/.cargo/config.toml
echo "strip = true" >> /tmp/czkawka/.cargo/config.toml
echo "opt-level = 's'" >> /tmp/czkawka/.cargo/config.toml
echo "lto = 'thin'" >> /tmp/czkawka/.cargo/config.toml
echo "panic = 'abort'" >> /tmp/czkawka/.cargo/config.toml
echo "codegen-units = 1" >> /tmp/czkawka/.cargo/config.toml

log "Patching Czkawka..."
PATCHES="
    main-window-maximized.patch
    hide-title-buttons.patch
    results_location.patch
    disable_trash.patch
    fix-systemtime-crash.patch
"
for PATCH in $PATCHES; do
    log "Applying $PATCH..."
    patch  -p1 -d /tmp/czkawka < "$SCRIPT_DIR"/"$PATCH"
done

log "Compiling Czkawka CLI..."
(
    cd /tmp/czkawka
    # shared-mime-info.pc is under /usr/share/pkgconfig.
    PKG_CONFIG_PATH=/$(xx-info)/usr/share/pkgconfig \
    xx-cargo build --release --bin czkawka_cli --features "$CZKAWKA_FEATURES"
)

log "Compiling Czkawka GUI..."
# NOTE: When not installing Rust from the Alpine repository, we must compile
#       with `RUSTFLAGS="-C target-feature=-crt-static"` to avoid crash during
#       GTK initialization.  See https://github.com/qarmin/czkawka/issues/416.
(
    cd /tmp/czkawka
    # shared-mime-info.pc is under /usr/share/pkgconfig.
    PKG_CONFIG_PATH=/$(xx-info)/usr/share/pkgconfig \
    xx-cargo build --release --bin czkawka_gui --features "$CZKAWKA_FEATURES"
)

log "Installing Czkawka..."
mkdir /tmp/czkawka-install
cp -v /tmp/czkawka/target/*/release/czkawka_cli /tmp/czkawka-install/
cp -v /tmp/czkawka/target/*/release/czkawka_gui /tmp/czkawka-install/
