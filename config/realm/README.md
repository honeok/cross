# Realm

[![GitHub Release](https://img.shields.io/github/v/release/zhboner/realm.svg?logo=github)](https://github.com/zhboner/realm/releases)
[![GitHub Releases Stats](https://img.shields.io/github/downloads/zhboner/realm/total.svg?&logo=github)](https://somsubhra.github.io/github-release-stats/?username=zhboner&repository=realm)

A simple, high performance relay server written in rust.

<img src="https://fastly.jsdelivr.net/gh/zhboner/realm@master/assets/realm.png" />

## Features

- Zero configuration. Setup and run in one command.
- Concurrency. Bidirectional concurrent traffic leads to high performance.
- Low resources cost.

## Install

You can install realm using either the direct github link or a cdn link.

Direct Link

```shell
bash <(curl -Ls https://github.com/honeok/cross/raw/master/config/realm/realm.sh)
```

CDN Link

```shell
bash <(curl -Ls https://fastly.jsdelivr.net/gh/honeok/cross@master/config/realm/realm.sh)
```

## Configuration

TOML Example

```toml
[log]
level = "warn"
output = "realm.log"

[network]
no_tcp = false
use_udp = true

[[endpoints]]
listen = "0.0.0.0:5000"
remote = "1.1.1.1:443"

[[endpoints]]
listen = "0.0.0.0:10000"
remote = "www.google.com:443"
```

[See more examples here][1]

[1]: https://github.com/zhboner/realm/tree/master/examples
