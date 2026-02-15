#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

export CC=xx-clang
export CXX=xx-clang++

export RUSTFLAGS="-C link-args=-Wl,-zstack-size="8388608

CZKAWKA_FEATURES="container_trash,heif,libraw"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

log() {
    echo ">>> $*"
}

CZKAWKA_URL="$1"
LIBHEIF_URL="$2"

if [ -z "$CZKAWKA_URL" ]; then
    log "ERROR: Czkawka URL missing."
    exit 1
fi

if [ -z "$LIBHEIF_URL" ]; then
    log "ERROR: libheif URL missing."
    exit 1
fi

#
# Install required packages.
#
apk --no-cache add \
    bash \
    curl \
    git \
    clang \
    cmake \
    make \
    g++ \
    lld \
    patch \
    pkgconf \

xx-apk --no-cache --no-scripts add \
    musl-dev \
    gcc \
    libstdc++-dev \
    gtk4.0-dev \

# For libheif.
xx-apk --no-cache --no-scripts add \
    libde265-dev \
    x265-dev \
    aom-dev \
    libjpeg-turbo-dev \
    libpng-dev \

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
    export RUSTFLAGS="$RUSTFLAGS -C target-feature=-crt-static"
fi

# Fix the xx-cargo setup. See https://github.com/tonistiigi/xx/issues/104.
# When building linux/arm/v6, there is a mismatch in triples:
#   - cargo: arm-unknown-linux-musleabi
#   - xx-info: armv6-alpine-linux-musleabihf.
if xx-info is-cross; then
    xx-cargo --setup-target-triple
    if [ ! -e "/$(xx-cargo --print-target-triple)" ]; then
        ln -s "$(xx-info)" "/$(xx-cargo --print-target-triple)"
    fi

    for d in $(find $(xx-info sysroot) -name "$(xx-info)" -type d); do
        cargo_d="$(dirname "$d")/$(xx-cargo --print-target-triple)"
        [ ! -e "$cargo_d" ] || continue

        log "xx-cargo setup fix: creating symlink '$cargo_d', pointing '$(xx-info)'."
        ln -s "$(xx-info)" "$cargo_d"
    done
fi

#
# Download sources.
#

log "Downloading Czkawka..."
mkdir /tmp/czkawka
curl -# -L -f ${CZKAWKA_URL} | tar xz --strip 1 -C /tmp/czkawka

log "Downloading libheif..."
mkdir /tmp/libheif
curl -# -L -f ${LIBHEIF_URL} | tar xz --strip 1 -C /tmp/libheif

#
# Compile libheif
#

log "Configuring libheif..."
(
    export CPPFLAGS="-O2"
    export CXXFLAGS="-O2"
    mkdir /tmp/libheif/build && \
    cd /tmp/libheif/build && cmake \
        $(xx-clang --print-cmake-defines) \
        -DCMAKE_FIND_ROOT_PATH=$(xx-info sysroot) \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=None \
        -DCMAKE_SKIP_INSTALL_RPATH=ON \
        -DWITH_EXAMPLES=ON \
        -DWITH_GDK_PIXBUF=OFF \
        -DBUILD_TESTING=OFF \
        ..
)

log "Compiling libheif..."
make -C /tmp/libheif/build -j$(nproc)

log "Installing libheif..."
make DESTDIR=$(xx-info sysroot) -C /tmp/libheif/build install
find $(xx-info sysroot)usr/lib -name "*.la" -delete

make DESTDIR=/tmp/libheif-install -C /tmp/libheif/build install
find /tmp/libheif-install -name "*.la" -delete
find /tmp/libheif-install -name "*.pc" -delete
rm -r /tmp/libheif-install/usr/lib/cmake
rm -r /tmp/libheif-install/usr/include

#
# Compile Czkawka.
#

# Create cargo profile.
# https://github.com/johnthagen/min-sized-rust
echo "" >> /tmp/czkawka/.cargo/config.toml
echo "[profile.release]" >> /tmp/czkawka/.cargo/config.toml
echo "strip = true" >> /tmp/czkawka/.cargo/config.toml
echo "debug = false" >> /tmp/czkawka/.cargo/config.toml
echo "overflow-checks = true" >> /tmp/czkawka/.cargo/config.toml
echo "opt-level = 's'" >> /tmp/czkawka/.cargo/config.toml
echo "lto = 'thin'" >> /tmp/czkawka/.cargo/config.toml
echo "panic = 'unwind'" >> /tmp/czkawka/.cargo/config.toml
echo "codegen-units = 1" >> /tmp/czkawka/.cargo/config.toml

log "Patching Czkawka..."
PATCHES="
    main-window-maximized.patch
    hide-title-buttons.patch
    similar-video-panic-fix.patch
    results_location.patch
    container-trash.patch
    dark-theme.patch
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
(
    cd /tmp/czkawka
    # shared-mime-info.pc is under /usr/share/pkgconfig.
    PKG_CONFIG_PATH=/$(xx-info)/usr/share/pkgconfig \
    xx-cargo build --release --bin czkawka_gui --features "$CZKAWKA_FEATURES"
)

log "Compiling Czkawka Krokiet GUI..."
(
    export SLINT_STYLE=fluent
    cd /tmp/czkawka
    # shared-mime-info.pc is under /usr/share/pkgconfig.
    PKG_CONFIG_PATH=/$(xx-info)/usr/share/pkgconfig \
    xx-cargo build --release --bin krokiet --features "$CZKAWKA_FEATURES"
)

log "Installing Czkawka..."
mkdir /tmp/czkawka-install
cp -v /tmp/czkawka/target/*/release/czkawka_cli /tmp/czkawka-install/
cp -v /tmp/czkawka/target/*/release/czkawka_gui /tmp/czkawka-install/
cp -v /tmp/czkawka/target/*/release/krokiet /tmp/czkawka-install/
