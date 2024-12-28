# cross

[![Build Status](https://github.com/honeok/cross/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/honeok/cross/actions/workflows/shellcheck.yml/badge.svg)
[![License](https://img.shields.io/github/license/honeok/cross.svg?style=flat)](./LICENSE)
[![Commit](https://img.shields.io/github/last-commit/honeok/cross)](https://github.com/honeok/cross)
[![Commit Activity](https://img.shields.io/github/commit-activity/m/honeok/cross.svg)](https://github.com/honeok/cross)
[![GitHub Stars](https://img.shields.io/github/stars/honeok/cross?style=flat)](https://github.com/honeok/cross)
[![Issues](https://img.shields.io/github/issues/honeok/cross.svg)](https://img.shields.io/github/issues/honeok/cross.svg)

The towering giant tower, I see it, with people jumping down every moment. When I was young, I didn’t understand and thought they were snowflakes.

## BestTrace路由追踪

国外服务器：
```shell
bash <(curl -sL https://github.com/honeok/cross/raw/master/BestTrace.sh)
```
国内服务器：
```shell
bash <(curl -sL https://cdn.611611.best/https://github.com/honeok/cross/raw/master/BestTrace.sh)
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

## 内存超售检测

国外服务器：
```shell
bash <(curl -sL https://github.com/honeok/cross/raw/master/memoryCheck.sh)
```
国内服务器：
```shell
bash <(curl -sL https://cdn.611611.best/https://github.com/honeok/cross/raw/master/memoryCheck.sh)
```

## Backtrace三网回程路由线路测试

基于 https://github.com/oneclickvirt/backtrace 一键安装脚本的调优
![](https://cdn.img2ipfs.com/ipfs/QmQ5EnCV9en5aLFSGM4mKwvh5jpMPDy8JsmbkdBtshYUP2?filename=image.png)

国外服务器：
```shell
bash <(curl -sL https://github.com/honeok/cross/raw/master/backtrace.sh)
```
国内服务器：
```shell
bash <(curl -sL https://cdn.611611.best/https://github.com/honeok/cross/raw/master/backtrace.sh)
```

## TeamSpeak服务器一键脚本

国外服务器：
```shell
bash <(curl -sL https://github.com/honeok/cross/raw/master/play/ts.sh)
```
国内服务器：
```shell
bash <(curl -sL https://cdn.611611.best/https://github.com/honeok/cross/raw/master/play/ts.sh)
```

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=honeok/cross&type=Date)](https://star-history.com/#honeok/cross&Date)