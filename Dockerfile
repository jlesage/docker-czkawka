#
# czkawka Dockerfile
#
# https://github.com/jlesage/docker-czkawka
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.12-v3.5.7

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software versions.
ARG CZKAWKA_VERSION=4.1.0

# Define software download URLs.
ARG CZKAWKA_URL=https://github.com/qarmin/czkawka/archive/${CZKAWKA_VERSION}.tar.gz

# Define working directory.
WORKDIR /tmp

# Install dependencies.
RUN add-pkg \
        gtk+3.0 \
        gnome-icon-theme \
        alsa-lib \
        # FFmpeg needed to find similar videos.
        ffmpeg \
        && \
    true

# Install Czkawka.
# NOTE: When not installing Rust from the Alpine repository, we must compile
#       with `RUSTFLAGS="-C target-feature=-crt-static"` to avoid crash during
#       GTK initialization.  See https://github.com/qarmin/czkawka/issues/416.
RUN \
    # Install packages needed by the build.
    add-pkg --virtual build-dependencies \
        build-base \
        bash \
        curl \
        gtk+3.0-dev \
        alsa-lib-dev \
        && \
    # Install Rust.
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y && \
    source /root/.cargo/env && \
    # Download.
    echo "Downloading Czkawka..." && \
    mkdir /tmp/czkawka && \
    curl -# -L ${CZKAWKA_URL} | tar xz --strip 1 -C /tmp/czkawka && \
    # Create cargo profile.
    # https://github.com/johnthagen/min-sized-rust
    mkdir /tmp/czkawka/.cargo && \
    echo "[profile.release]" >> /tmp/czkawka/.cargo/config.toml && \
    echo "opt-level = 'z'" >> /tmp/czkawka/.cargo/config.toml && \
    echo "lto = true" >> /tmp/czkawka/.cargo/config.toml && \
    echo "panic = 'abort'" >> /tmp/czkawka/.cargo/config.toml && \
    echo "codegen-units = 1" >> /tmp/czkawka/.cargo/config.toml && \
    # Patching sources.
    sed-patch 's|<property name="show-close-button">True</property>|<property name="show-close-button">False</property>|' /tmp/czkawka/czkawka_gui/ui/main_window.ui && \
    # Compile.
    echo "Compiling Czkawka..." && \
    cd /tmp/czkawka && \
    RUSTFLAGS="-C target-feature=-crt-static" cargo build --release && \
    # Install.
    strip target/release/czkawka_cli && \
    strip target/release/czkawka_gui && \
    cp -av target/release/czkawka_cli /usr/bin/ && \
    cp -av target/release/czkawka_gui /usr/bin/ && \
    cd .. && \
    # Cleanup.
    rustup self uninstall -y && \
    rm /root/.profile && \
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

RUN \
    # Maximize only the main window.
    sed-patch 's/<application type="normal">/<application type="normal" title="Czkawka">/' \
        /etc/xdg/openbox/rc.xml && \
    # Make sure the main window is always in the background.
    sed-patch '/<application type="normal" title="Czkawka">/a \    <layer>below</layer>' \
        /etc/xdg/openbox/rc.xml

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/czkawka-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="Czkawka"

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]
VOLUME ["/trash"]

# Metadata.
LABEL \
      org.label-schema.name="czkawka" \
      org.label-schema.description="Docker container for Czkawka" \
      org.label-schema.version="$DOCKER_IMAGE_VERSION" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-czkawka" \
      org.label-schema.schema-version="1.0"
