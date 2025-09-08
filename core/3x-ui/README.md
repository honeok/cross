# 3x-ui

[3x-ui][1] advanced, open-source web-based control panel designed for managing Xray-core server. It offers a user-friendly interface for configuring and monitoring various VPN and proxy protocols.

As an enhanced fork of the original X-UI project, 3X-UI provides improved stability, broader protocol support, and additional features.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://github.com/MHSanaei/3x-ui/raw/main/media/3x-ui-dark.png">
    <img alt="3x-ui" src="https://github.com/MHSanaei/3x-ui/raw/main/media/3x-ui-light.png">
  </picture>
</p>

> [!IMPORTANT]
> This project is only for personal using, please do not use it for illegal purposes, please do not use it in a production environment.

## Prepare the host

If you need to install docker by yourself, follow the [official][2] installation guide.

## Pull the image

```shell
docker pull honeok/3x-ui
```

This pulls the latest release of 3x-ui.

It can be found at [Docker Hub][3].

## Start a container

create `docker-compose.yaml`.

```shell
tee docker-compose.yaml >/dev/null <<'EOF'
services:
  3x-ui:
    image: honeok/3x-ui
    container_name: 3x-ui
    restart: unless-stopped
    volumes:
      - $PWD/db/:/etc/x-ui
      - $PWD/cert/:/root/cert
    environment:
      TZ: Asia/Shanghai
    #   USER_NAME: admin
    #   USER_PASSWORD: admin
    #   BASE_PATH: admin
    #   PANEL_PORT: 54321
    network_mode: host
EOF
```

Finally, run the following command to start the container.

```shell
docker compose up -d
```

Get your login information.

```shell
docker logs -f 3x-ui
```

**Warning**: The port number must be same as configuration and opened in firewall.

[1]: https://github.com/MHSanaei/3x-ui
[2]: https://docs.docker.com/install
[3]: https://hub.docker.com/r/honeok/3x-ui