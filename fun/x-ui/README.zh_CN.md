## X-UI Docker Image by honeok 

[![Docker Pulls](https://img.shields.io/docker/pulls/honeok/x-ui.svg?style=flat-square)](https://hub.docker.com/r/honeok/x-ui)
[![Docker Image Size](https://img.shields.io/docker/image-size/honeok/x-ui.svg?style=flat-square)](https://hub.docker.com/r/honeok/x-ui)
[![License](https://img.shields.io/github/license/honeok/cross.svg?style=flat-square)](https://www.gnu.org/licenses/old-licenses/gpl-2.0-standalone.html)

[English](./README.md) |  [中文](./README.zh_CN.md)

[FranzKafkaYu/x-ui][1] 是一个基于 Xray 核心的多协议、多用户管理面板，提供直观的 Web 界面，方便用户管理和配置代理服务器。

它支持多种协议（如 V2Ray、Trojan、Shadowsocks、VLESS、VMess 等）。

X-UI 使用 Go 语言开发，性能优异，内存占用低。

用户可以通过浏览器访问面板，轻松设置入站规则、添加用户、管理流量和到期时间。

> **Disclaimer:** 此项目仅供个人学习交流，请不要用于非法目的，请不要在生产环境中使用。

## 环境准备

如果你需要自己安装docker，请按照以下步骤操作 [official installation guide][2].

## 拉取镜像

这是X-UI镜像的最新版本 （由于FranzKafkaYu的X-UI已归档于`2024.11.14`，本镜像将随Xray官方版本更新）

```shell
docker pull honeok/x-ui
```

可以在以下网址找到 [Docker Hub][3].

## 启动容器

**默认面板设置**

以下为容器启动时的默认环境变量配置：

| 变量名          | 默认值            | 说明        |
|----------------|------------------|------------|
| `USER_NAME`    | 随机生成         | 登录用户名  |
| `USER_PASSWORD`| 随机生成         | 登录密码    |
| `PANEL_PORT`   | 随机端口(10000~65535) | 访问端口 |

> [!WARNING]  
> 建议在首次启动后记录随机生成的用户名和密码，或通过环境变量自定义设置以增强安全性。<br>
> 确保 `PANEL_PORT` 未被占用，以避免端口冲突。<br>
> 如果您选择不修改这些设置，它们将随机生成。<br>
> 启动后通过 `docker logs x-ui -f` 查看随机生成的配置。

1. 使用`Docker cli` **快速启动**

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

2. 使用`Docker Compose`启动 **推荐**

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

3. 最后，运行以下命令来启动容器：

```shell
docker compose up -d
```

4. 通过 `docker logs x-ui -f` 查看登录地址和随机生成的密码。

## 使用方法

进入容器后使用`x-ui`唤出管理面板，**请注意** 修改配置后需要重启容器`docker restart x-ui`或`docker compose restart`

```shell
docker exec -ti x-ui sh
```

在宿主机查看您的X-UI配置信息

```shell
docker exec -i x-ui sh -c 'echo 4 | x-ui'
```

[1]: https://github.com/FranzKafkaYu/x-ui
[2]: https://docs.docker.com/install
[3]: https://hub.docker.com/r/honeok/x-ui
[4]: https://sing-box.sagernet.org/configuration