#
# czkawka Dockerfile
#
# https://github.com/ultrahkr/docker-czkawka
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.12-v3.5.7

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software versions.
ARG CZKAWKA_VERSION=3.2.0

# Define software download URLs.
ARG CZKAWKA_URL=https://github.com/qarmin/czkawka/archive/refs/tags/${CZKAWKA_VERSION}.tar.gz

# Define working directory.
WORKDIR /tmp

# Install dependencies.
RUN add-pkg \
        gtk+3.0 \
        adwaita-icon-theme \
        alsa-lib \
        && \
    true

# Install Czkawka.
RUN \
    # Install packages needed by the build.
    add-pkg --virtual build-dependencies \
        build-base \
        curl \
        cargo \
        gtk+3.0-dev \
        alsa-lib-dev \
        && \
    # Download.
    echo "Downloading Czkawka..." && \
    mkdir czkawka && \
    curl -# -L ${CZKAWKA_URL} | tar xz --strip 1 -C czkawka && \
    # Compile.
    echo "Compiling Czkawka..." && \
    cd czkawka && \
    echo "[profile.release]" >> Cargo.toml && \
    echo "opt-level = 'z'" >> Cargo.toml && \
    echo "lto = true" >> Cargo.toml && \
    sed-patch 's|applications-engineering|applications-system|' czkawka_gui/main_window.glade && \
    sed-patch 's|<property name="show-close-button">True</property>|<property name="show-close-button">False</property>|' czkawka_gui/main_window.glade && \
    cargo build --release && \
    # Install.
    strip target/release/czkawka_cli && \
    strip target/release/czkawka_gui && \
    cp -av target/release/czkawka_cli /usr/bin/ && \
    cp -av target/release/czkawka_gui /usr/bin/ && \
    cd .. && \
    # Cleanup.
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
      org.label-schema.vcs-url="https://github.com/ultrahkr/docker-czkawka" \
      org.label-schema.schema-version="1.0"
