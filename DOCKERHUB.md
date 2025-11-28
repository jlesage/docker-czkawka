# Docker container for Czkawka
[![Release](https://img.shields.io/github/release/jlesage/docker-czkawka.svg?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-czkawka/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/czkawka/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/czkawka/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/jlesage/czkawka?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/czkawka)
[![Docker Stars](https://img.shields.io/docker/stars/jlesage/czkawka?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/czkawka)
[![Build Status](https://img.shields.io/github/actions/workflow/status/jlesage/docker-czkawka/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/jlesage/docker-czkawka/actions/workflows/build-image.yml)
[![Source](https://img.shields.io/badge/Source-GitHub-blue?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-czkawka)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg?style=for-the-badge)](https://paypal.me/JocelynLeSage)

This is a Docker container for [Czkawka](https://github.com/qarmin/czkawka).

The graphical user interface (GUI) of the application can be accessed through a
modern web browser, requiring no installation or configuration on the client

> This Docker container is entirely unofficial and not made by the creators of Czkawka.

---

[![Czkawka logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/czkawka-icon.png&w=110)](https://github.com/qarmin/czkawka)[![Czkawka](https://images.placeholders.dev/?width=224&height=110&fontFamily=monospace&fontWeight=400&fontSize=52&text=Czkawka&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://github.com/qarmin/czkawka)

Czkawka is written in Rust, simple, fast and easy to use app to remove
unnecessary files from your computer.

---

## Quick Start

**NOTE**:
    The Docker command provided in this quick start is an example, and parameters
    should be adjusted to suit your needs.

Launch the Czkawka docker container with the following command:
```shell
docker run -d \
    --name=czkawka \
    -p 5800:5800 \
    -v /docker/appdata/czkawka:/config:rw \
    -v /home/user:/storage:rw \
    jlesage/czkawka
```

Where:

  - `/docker/appdata/czkawka`: Stores the application's configuration, state, logs, and any files requiring persistency.
  - `/home/user`: Contains files from the host that need to be accessible to the application.

Access the Czkawka GUI by browsing to `http://your-host-ip:5800`.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-czkawka.

## Support or Contact

Having troubles with the container or have questions? Please
[create a new issue](https://github.com/jlesage/docker-czkawka/issues).

For other Dockerized applications, visit https://jlesage.github.io/docker-apps.
