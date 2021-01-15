# Docker container for Czkawka
[![Docker Image Size](https://img.shields.io/microbadger/image-size/jlesage/czkawka)](http://microbadger.com/#/images/jlesage/czkawka) [![Build Status](https://drone.le-sage.com/api/badges/jlesage/docker-czkawka/status.svg)](https://drone.le-sage.com/jlesage/docker-czkawka) [![GitHub Release](https://img.shields.io/github/release/jlesage/docker-czkawka.svg)](https://github.com/jlesage/docker-czkawka/releases/latest) [![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/JocelynLeSage/0usd)

This is a Docker container for [Czkawka](https://github.com/qarmin/czkawka).

The GUI of the application is accessed through a modern web browser (no installation or configuration needed on the client side) or via any VNC client.

---

[![Czkawka logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/czkawka-icon.png&w=200)](https://github.com/qarmin/czkawka)[![Czkawka](https://dummyimage.com/400x110/ffffff/575757&text=Czkawka)](https://github.com/qarmin/czkawka)

Czkawka is written in Rust, simple, fast and easy to use app to remove
unnecessary files from your computer.

---

## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

Launch the Czkawka docker container with the following command:
```
docker run -d \
    --name=czkawka \
    -p 5800:5800 \
    -v /docker/appdata/czkawka:/config:rw \
    -v $HOME:/storage:rw \
    jlesage/czkawka
```

Where:
  - `/docker/appdata/czkawka`: This is where the application stores its configuration, log and any files needing persistency.
  - `$HOME`: This location contains files from your host that need to be accessible by the application.

Browse to `http://your-host-ip:5800` to access the Czkawka GUI.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-czkawka.

## Support or Contact

Having troubles with the container or have questions?  Please
[create a new issue].

For other great Dockerized applications, see https://jlesage.github.io/docker-apps.

[create a new issue]: https://github.com/jlesage/docker-czkawka/issues
