## TeamSpeak服务器一键脚本

```shell
bash <(curl -sL raw.githubusercontent.com/honeok/cross/master/interesting/ts.sh)
```

## BestTrace路由追踪

```shell
bash <(curl -sL raw.githubusercontent.com/honeok/cross/master/BestTrace.sh)
```

### 参数说明：

**如果没有传参默认执行广东上海北京四川三网回程**

脚本支持以下命令行参数来选择不同区域的路由回程：

- `-hlj`：黑龙江
- `-nmg` ：内蒙古
- `-bj`：北京
- `-js`：江苏
- `-sd`：山东
- `-sh`：上海
- `-sc`：四川
- `-gd`：广东

**单独的参数**：`-d`

### 示例用法：

```shell
bash <(curl -sL raw.githubusercontent.com/honeok/cross/master/BestTrace.sh) -hlj     # 黑龙江三网路由
bash <(curl -sL raw.githubusercontent.com/honeok/cross/master/BestTrace.sh) -hlj -d  # 路由追踪完成后删除nexttrace
```

