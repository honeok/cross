# Xray

[![GitHub Release](https://img.shields.io/github/v/tag/XTLS/Xray-core.svg?label=release&logo=github)](https://github.com/XTLS/Xray-core/releases)
[![GitHub Release](https://img.shields.io/github/v/tag/233boy/Xray.svg?label=release&logo=github)](https://github.com/233boy/Xray/releases)
[![GitHub Releases Stats](https://img.shields.io/github/downloads/XTLS/Xray-core/total.svg?label=downloads&logo=github)](https://somsubhra.github.io/github-release-stats/?username=XTLS&repository=Xray-core)

[Project X][1] originates from XTLS protocol, providing a set of network tools such as [Xray-core][2] and [REALITY][3].

<img src="https://raw2.seadn.io/ethereum/0x5ee362866001613093361eb8569d59c4141b76d1/7fa9ce900fb39b44226348db330e32/8b7fa9ce900fb39b44226348db330e32.svg" alt="Project X NFT" width="150"/>

This repository uses [233boy's script][4] to install Xray-core and then applies a custom configuration.

```shell
bash <(curl -Ls https://github.com/233boy/Xray/raw/main/install.sh)
```

This script is used to fetches and updates the latest geo data file automatically.

Manual update.

```shell
bash <(curl -Ls https://github.com/honeok/cross/raw/master/config/xray/up.sh)
```

Automatic update.

```shell
(crontab -l 2>/dev/null; echo "0 7 * * * /bin/bash -c 'bash <(curl -Ls https://github.com/honeok/cross/raw/master/config/xray/up.sh)'") | crontab -
```

[1]: https://github.com/XTLS
[2]: https://github.com/XTLS/Xray-core
[3]: https://github.com/XTLS/REALITY
[4]: https://github.com/233boy/Xray
