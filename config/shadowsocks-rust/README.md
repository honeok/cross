# shadowsocks-rust

[![GitHub Release](https://img.shields.io/github/v/release/shadowsocks/shadowsocks-rust.svg?logo=github)](https://github.com/shadowsocks/shadowsocks-rust/releases)
[![GitHub Releases Stats](https://img.shields.io/github/downloads/shadowsocks/shadowsocks-rust/total.svg?&logo=github)](https://somsubhra.github.io/github-release-stats/?username=shadowsocks&repository=shadowsocks-rust)

![Shadowsocks](https://fastly.jsdelivr.net/gh/teddysun/shadowsocks_install@master/shadowsocks.png)

**_The connection may be severed, but the blue paper plane flies forever._** ✈️

This is a port of [shadowsocks][1].

shadowsocks is a fast tunnel proxy that helps you bypass firewalls.

## Install

```shell
bash <(curl -Ls https://fastly.jsdelivr.net/gh/honeok/cross@master/config/shadowsocks-rust/install.sh)
```

First, the installation script will create a simple configuration file on the host machine.

lie in `/etc/shadowsocks-rust/config.json`.

For detailed configuration files, please refer to the official [documentation][2].

```json
{
  "server": "::",
  "server_port": 8388,
  "password": "password",
  "timeout": 300,
  "method": "chacha20-ietf-poly1305",
  "mode": "tcp_and_udp"
}
```

## Uninstall

```shell
bash <(curl -Ls https://fastly.jsdelivr.net/gh/honeok/cross@master/config/shadowsocks-rust/remove.sh)
```

[1]: https://github.com/shadowsocks/shadowsocks
[2]: https://github.com/shadowsocks/shadowsocks-rust
