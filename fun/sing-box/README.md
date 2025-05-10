## Sing-Box Docker Image by honeok

[Sing-Box][1] is a network proxy toolbox by SagerNet, offering robust protocol support, flexibility, and optimized performance for developers and advanced users.

It is widely used for scenarios like scientific internet access, anti-censorship, acceleration, and routing optimization.

## Prepare the host

If you need to install docker by yourself, follow the [official installation guide][2].

## Pull the image

```shell
docker pull honeok/sing-box
```

This pulls the latest release of Sing-Box.

It can be found at [Docker Hub][3].

## Start a container

First, you must create a configuration file on your localhost:

This file can be empty.

```shell
touch "$PWD/config.json"
```

Next, start a container with a listening port of `30000`, first create `docker-compose.yml`.

```shell
vim docker-compose.yml
```

Add the following content to the `docker-compose.yml`  file.

```yaml
services:
  sing-box:
    image: honeok/sing-box
    container_name: sing-box
    restart: unless-stopped
    volumes:
      - $PWD/config.json:/etc/sing-box/config.json
      - $PWD/conf:/etc/sing-box/conf
    network_mode: host
```

Finally, run the following command to start the container.

```shell
docker compose up -d
```

Get the randomly generated `REALITY` configuration by viewing the container log.

```shell
docker logs -f sing-box
```

For reference, you can check the [Configuration][4] for Sing-box.

**Warning**: The port number must be same as configuration and opened in firewall.

[1]: https://github.com/SagerNet/sing-box
[2]: https://docs.docker.com/install
[3]: https://hub.docker.com/r/honeok/sing-box
[4]: https://sing-box.sagernet.org/configuration