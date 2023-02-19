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
    lld \
    patch \
    pkgconf \

xx-apk --no-cache --no-scripts add \
    musl-dev \
    gcc \
    gtk4.0-dev \
    libheif-dev \

# Install Rust.
# NOTE: Czkawka often requires a recent version of Rust that is not avaialble
#       yet in Alpine repository.
USE_RUST_FROM_ALPINE_REPO=false
if $USE_RUST_FROM_ALPINE_REPO; then
    apk --no-cache add rust cargo
else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
    source /root/.cargo/env
fi

#
# Download sources.
#

log "Downloading Czkawka..."
mkdir /tmp/czkawka
curl -# -L ${CZKAWKA_URL} | tar xz --strip 1 -C /tmp/czkawka

#
# Compile Czkawka.
#

# Create cargo profile.
# https://github.com/johnthagen/min-sized-rust
mkdir /tmp/czkawka/.cargo
echo "[profile.release]" >> /tmp/czkawka/.cargo/config.toml
echo "strip = true" >> /tmp/czkawka/.cargo/config.toml
echo "opt-level = 'z'" >> /tmp/czkawka/.cargo/config.toml
echo "lto = true" >> /tmp/czkawka/.cargo/config.toml
echo "panic = 'abort'" >> /tmp/czkawka/.cargo/config.toml
echo "codegen-units = 1" >> /tmp/czkawka/.cargo/config.toml

log "Patching Czkawka..."
patch -p1 -d /tmp/czkawka < "$SCRIPT_DIR"/main-window-maximized.patch
patch -p1 -d /tmp/czkawka < "$SCRIPT_DIR"/hide-title-buttons.patch
patch -p1 -d /tmp/czkawka < "$SCRIPT_DIR"/results_location.patch
patch -p1 -d /tmp/czkawka < "$SCRIPT_DIR"/disable_trash.patch

log "Compiling Czkawka..."
# NOTE: When not installing Rust from the Alpine repository, we must compile
#       with `RUSTFLAGS="-C target-feature=-crt-static"` to avoid crash during
#       GTK initialization.  See https://github.com/qarmin/czkawka/issues/416.
(
    cd /tmp/czkawka
    # shared-mime-info.pc is under /usr/share/pkgconfig.
    PKG_CONFIG_PATH=/$(xx-info)/usr/share/pkgconfig \
    RUSTFLAGS="-C target-feature=-crt-static" \
    xx-cargo build --release --all-features
)

log "Installing Czkawka..."
mkdir /tmp/czkawka-install
cp -v /tmp/czkawka/target/*/release/czkawka_cli /tmp/czkawka-install/
cp -v /tmp/czkawka/target/*/release/czkawka_gui /tmp/czkawka-install/
