#
# czkawka Dockerfile
#
# https://github.com/jlesage/docker-czkawka
#

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=

# Define software versions.
ARG CZKAWKA_VERSION=11.0.0
ARG LIBHEIF_VERSION=1.21.2

# Define software download URLs.
ARG CZKAWKA_URL=https://github.com/qarmin/czkawka/archive/${CZKAWKA_VERSION}.tar.gz
ARG LIBHEIF_URL=https://github.com/strukturag/libheif/releases/download/v${LIBHEIF_VERSION}/libheif-${LIBHEIF_VERSION}.tar.gz

# Get Dockerfile cross-compilation helpers.
FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

# Build Czkawka.
FROM --platform=$BUILDPLATFORM alpine:3.20 AS czkawka
ARG TARGETPLATFORM
ARG CZKAWKA_URL
ARG LIBHEIF_URL
COPY --from=xx / /
COPY src/czkawka /build
RUN /build/build.sh "$CZKAWKA_URL" "$LIBHEIF_URL"
RUN xx-verify \
    /tmp/czkawka-install/czkawka_cli \
    /tmp/czkawka-install/czkawka_gui

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.20-v4.11.0

# Define working directory.
WORKDIR /tmp

ARG CZKAWKA_VERSION
ARG DOCKER_IMAGE_VERSION

# Install dependencies.
RUN add-pkg \
        gtk4.0 \
        font-dejavu \
        alsa-lib \
        ffmpeg \
        ffplay \
        # For krokiet support.
        libxkbcommon-x11 \
        # For the file dialog support (via XDG Desktop Portal backend) of krokiet.
        # https://lib.rs/crates/rfd
        dbus \
        xdg-desktop-portal-gtk \
        adwaita-icon-theme \
        # For opening folders.
        pcmanfm \
        && \
    true

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/czkawka-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /
COPY --from=czkawka /tmp/czkawka-install/czkawka_cli /usr/bin/
COPY --from=czkawka /tmp/czkawka-install/czkawka_gui /usr/bin/
COPY --from=czkawka /tmp/czkawka-install/krokiet /usr/bin/
COPY --from=czkawka /tmp/libheif-install/usr/lib /usr/lib

# Set internal environment variables.
RUN \
    set-cont-env APP_NAME "Czkawka" && \
    set-cont-env APP_VERSION "$CZKAWKA_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    set-cont-env DISABLE_GLX 1 && \
    true

# Set public environment variables.
ENV \
    CZKAWKA_GUI_KROKIET=0

# Define mountable directories.
VOLUME ["/storage"]

# Metadata.
LABEL \
      org.label-schema.name="czkawka" \
      org.label-schema.description="Docker container for Czkawka" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION:-unknown}" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-czkawka" \
      org.label-schema.schema-version="1.0"
