## X-UI Docker Image by honeok 

[![Docker Pulls](https://img.shields.io/docker/pulls/honeok/x-ui.svg?style=flat-square)](https://hub.docker.com/r/honeok/x-ui)
[![Docker Image Size](https://img.shields.io/docker/image-size/honeok/x-ui.svg?style=flat-square)](https://hub.docker.com/r/honeok/x-ui)
[![License](https://img.shields.io/github/license/honeok/cross.svg?style=flat-square)](https://www.gnu.org/licenses/old-licenses/gpl-2.0-standalone.html)

[English](./README.md) |  [中文](./README.zh_CN.md)

[FranzKafkaYu/x-ui][1] It is a multi-protocol, multi-user management panel based on the Xray core, offering an intuitive web interface to facilitate user management and proxy server configuration.

It supports multiple protocols (such as V2Ray, Trojan, Shadowsocks, VLESS, VMess).

X-UI is developed in Go, with excellent performance and low memory usage.

Users can access the panel via a browser to easily set inbound rules, add users, manage traffic, and configure expiration times.

> **Disclaimer:** This project is solely for personal learning and communication. Please do not use it for illegal purposes or in production environments.

## Environment Preparation

If you need to install Docker yourself, please follow the steps below [official installation guide][2].

## Pull the image

This is the latest version of the X-UI image. (As FranzKafkaYu's X-UI was archived on November 14, 2024, this image will be updated in accordance with the official Xray version.)

```shell
docker pull honeok/x-ui
```

It can be found at the following URL: [Docker Hub][3].

## Start the container

**Default Panel Settings**

The following are the default environment variable configurations for container startup:

| Variable Name | Default Value | describe |
|----------------|------------------|------------|
| `USER_NAME`    | random generation | Username |
| `USER_PASSWORD`| random generation | Login password |
| `PANEL_PORT`   | random port(10000~65535) | access port |

> [!WARNING]  
> It is recommended to record the randomly generated username and password after the first launch, or customize the settings through environment variables to enhance security.<br>
> make sure `PANEL_PORT` Not occupied to avoid port conflicts.<br>
> If you choose not to modify these settings, they will be randomly generated.<br>
> After startup, pass `docker logs x-ui -f` View randomly generated configurations.

1. Use`Docker cli` **Quick Start**

```shell
docker run -d \
    -v $PWD/db:/etc/x-ui/ \
    -v $PWD/cert:/root/cert/ \
    --network=host \
    --cap-add=NET_ADMIN \
    --restart=unless-stopped \
    --name x-ui \
    honeok/x-ui:latest
```

2. Use`Docker Compose`start up **recommend**

```yaml
services:
  x-ui:
    image: honeok/x-ui
    container_name: x-ui
    restart: unless-stopped
    environment:
      USER_NAME: admin
      USER_PASSWORD: admin
      PANEL_PORT: 54321
    volumes:
      - $PWD/db/:/etc/x-ui
      - $PWD/cert/:/root/cert
    network_mode: host
    cap_add:
      - NET_ADMIN
```

3. Finally, run the following command to start the container:

```shell
docker compose up -d
```

4. Use `docker logs x-ui -f` View your login address and randomly generated password.

## How to use

Use after entering the container`x-ui`Call up the management panel, **Please note** After modifying the configuration, you need to restart the container`docker restart x-ui`or`docker compose restart`

```shell
docker exec -ti x-ui sh
```

View your X-UI configuration information on the host machine.

```shell
docker exec -i x-ui sh -c 'echo 4 | x-ui'
```

[1]: https://github.com/FranzKafkaYu/x-ui
[2]: https://docs.docker.com/install
[3]: https://hub.docker.com/r/honeok/x-ui
[4]: https://sing-box.sagernet.org/configuration