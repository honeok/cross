<p align="center">
  <img src="https://github.com/honeok/cross/actions/workflows/shellcheck.yml/badge.svg" alt="Build Status" />
  <img src="https://img.shields.io/github/license/honeok/cross.svg?style=flat" alt="License" />
  <img src="https://img.shields.io/github/last-commit/honeok/cross" alt="Commit" />
  <img src="https://img.shields.io/github/commit-activity/m/honeok/cross.svg" alt="Commit Activity" />
  <img src="https://img.shields.io/github/stars/honeok/cross?style=flat" alt="GitHub Stars" />
  <img src="https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fhoneok%2Fcross&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false" alt="Hits" />
</p>

# cross

Life is vast and unpredictable, yet ultimately insignificant.

## bestTrace路由追踪

国外服务器：
```shell
bash <(curl -sL https://github.com/honeok/cross/raw/master/bestTrace.sh)
```
国内服务器：
```shell
bash <(curl -sL https://cdn.611611.best/https://github.com/honeok/cross/raw/master/bestTrace.sh)
```

### 参数说明：

**如果没有传参默认执行广东上海北京四川三网回程**

脚本支持以下命令行**参数**来选择不同区域的路由回程

**可选参数**

默认执行广东、上海、北京、四川三网回程

```shell
bash bestTrace.sh

可选参数:
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
bash bestTrace.sh -h         # 帮助命令
bash bestTrace.sh -nmg       # 测试内蒙古
bash bestTrace.sh -nmg -hlj  # 同时测试内蒙古和黑龙江
bash bestTrace.sh -nmg -d    # 测试后删除 NextTrace
```

## backTrace三网回程路由线路测试

基于 https://github.com/oneclickvirt/backtrace 一键安装脚本的调优
![](https://cdn.img2ipfs.com/ipfs/QmQ5EnCV9en5aLFSGM4mKwvh5jpMPDy8JsmbkdBtshYUP2?filename=image.png)

国外服务器：
```shell
bash <(curl -sL https://github.com/honeok/cross/raw/master/backTrace.sh)
```
国内服务器：
```shell
bash <(curl -sL https://cdn.611611.best/https://github.com/honeok/cross/raw/master/backTrace.sh)
```

## Docker一键安装脚本

<p align="center">
  <img src="https://hits.seeyoufarm.com/api/count/keep/badge.svg?url=https%3A%2F%2Fgithub.com%2Fhoneok%2Fcross%2Fraw%2Fmaster%2Fget-docker.sh" alt="Hits" />
</p>

![](https://cdn.img2ipfs.com/ipfs/QmUbYENaH5ZUaAAdNydhW4Vr22Le6mPyykMpYv1Z4VgcpN?filename=image.png)

国外服务器
```shell
bash <(curl -sL https://github.com/honeok/cross/raw/master/get-docker.sh)
```
国内服务器
```shell
bash <(curl -sL https://cdn.611611.best/https://github.com/honeok/cross/raw/master/get-docker.sh)
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
