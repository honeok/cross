# cross

[![Build Status](https://github.com/honeok/cross/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/honeok/cross/actions/workflows/shellcheck.yml/badge.svg)
[![License](https://img.shields.io/github/license/honeok/cross.svg?style=flat)](./LICENSE)
[![Commit](https://img.shields.io/github/last-commit/honeok/cross)](https://github.com/honeok/cross)
[![Commit Activity](https://img.shields.io/github/commit-activity/m/honeok/cross.svg)](https://github.com/honeok/cross)
[![Issues](https://img.shields.io/github/issues/honeok/cross.svg)](https://img.shields.io/github/issues/honeok/cross.svg)
[![Stars](https://img.shields.io/github/stars/honeok/cross.svg)](https://img.shields.io/github/stars/honeok/cross.svg)

<br>
The towering giant tower, I see it, with people jumping down every moment. When I was young, I didn’t understand and thought they were snowflakes.
</br>

****

## 哪吒监控安装脚本 V0

<div align="center">
  <br>
  <img width="360" style="max-width:80%" src="https://raw.githubusercontent.com/nezhahq/nezha/master/.github/brand.svg" title="哪吒监控 Nezha Monitoring">
  <br>
  <small><i>LOGO designed by <a href="https://xio.ng" target="_blank">熊大</a> .</i></small>
  <br><br>
</div>

[文档](nezha/README.md)

国外服务器：
```shell
curl -fskL raw.githubusercontent.com/honeok/cross/master/nezha/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh
```
国内服务器：
```shell
curl -fskL gh.611611.best/raw.githubusercontent.com/honeok/cross/master/nezha/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh
```
## BestTrace路由追踪

国外服务器：
```shell
bash <(curl -fskL raw.githubusercontent.com/honeok/cross/master/BestTrace.sh)
```
国内服务器：
```shell
bash <(curl -fskL gh.611611.best/raw.githubusercontent.com/honeok/cross/master/BestTrace.sh)
```

### 参数说明：

**如果没有传参默认执行广东上海北京四川三网回程**

脚本支持以下命令行**参数**来选择不同区域的路由回程

**可选参数**

默认执行广东、上海、北京、四川三网回程

```shell
bash BestTrace.sh

               # -- 可选参数 --
                  -nmg  # 内蒙古
                  -hlj  # 黑龙江
                  -xj   # 新疆
                  -tj   # 天津
                  -bj   # 北京
                  -ln   # 辽宁
                  -hb   # 河北
                  -sd   # 山东
                  -js   # 江苏
                  -zj   # 浙江
                  -fj   # 福建
                  -ah   # 安徽
                  -jx   # 江西
                  -xz   # 西藏
                  -sc   # 四川
                  -sh   # 上海
                  -gd   # 广东
```

**指定参数示例**

```shell
bash BestTrace.sh -h         # 帮助命令
bash BestTrace.sh -d         # 单独删除 nexttrace
bash BestTrace.sh -nmg       # 测试内蒙古
bash BestTrace.sh -nmg -d    # 测试后删除 nexttrace
```

## TeamSpeak服务器一键脚本

国外服务器：
```shell
bash <(curl -fskL raw.githubusercontent.com/honeok/cross/master/play/ts.sh)
```
国内服务器：
```shell
bash <(curl -fskL gh.611611.best/raw.githubusercontent.com/honeok/cross/master/play/ts.sh)
```

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=honeok/cross&type=Date)](https://star-history.com/#honeok/cross&Date)