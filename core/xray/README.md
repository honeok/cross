# Xray

[![GitHub Release](https://img.shields.io/github/v/tag/XTLS/Xray-core.svg?label=release&logo=github)](https://github.com/XTLS/Xray-core/releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/honeok/xray.svg?logo=docker&color=blue&logoColor=white)](https://hub.docker.com/r/honeok/xray)
[![Docker Image Size](https://img.shields.io/docker/image-size/honeok/xray.svg?logo=docker&color=blue&logoColor=white)](https://hub.docker.com/r/honeok/xray)
[![Docker Image Version](https://img.shields.io/docker/v/honeok/xray.svg?logo=docker&color=blue&logoColor=white)](https://hub.docker.com/r/honeok/xray)

[Project X][1] originates from XTLS protocol, providing a set of network tools such as [Xray-core][2] and [REALITY][3].

As the project's core, it functions as a high-performance superset of v2fly-core while retaining full backward compatibility.

<img src="https://raw2.seadn.io/ethereum/0x5ee362866001613093361eb8569d59c4141b76d1/7fa9ce900fb39b44226348db330e32/8b7fa9ce900fb39b44226348db330e32.svg" alt="Project X NFT" width="150"/>

## Prepare the host

If you need to install docker by yourself, follow the [official][4] installation guide.

## Pull the image

This pulls the latest release of Xray-core.

It can be found at [Docker Hub][5].

```shell
docker pull honeok/xray
```

## Start a container

First, create and edit `config.json` on your host. You must provide a valid
Xray configuration manually.

Next, create `docker-compose.yaml` in the same directory:

```shell
tee docker-compose.yaml >/dev/null <<'EOF'
services:
  xray:
    image: honeok/xray
    container_name: xray
    restart: unless-stopped
    volumes:
      - $PWD/config.json:/etc/xray/config.json
    network_mode: host
EOF
```

Start the container:

```shell
docker compose up -d
```

For reference, check the [Configuration][6] for Xray-core.

**Note**: The port you configured must be opened in the firewall.

[1]: https://github.com/XTLS
[2]: https://github.com/XTLS/Xray-core
[3]: https://github.com/XTLS/REALITY
[4]: https://docs.docker.com/install
[5]: https://hub.docker.com/r/honeok/xray
[6]: https://xtls.github.io
