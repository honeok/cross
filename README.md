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

脚本支持以下命令行**参数**来选择不同区域的路由回程

```shell

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

默认执行广东、上海、北京、四川三网回程:
  ./BestTrace.sh

指定参数示例:
  ./BestTrace.sh -nmg       # 测试内蒙古
  ./BestTrace.sh -nmg -d    # 测试后删除 nexttrace
  ./BestTrace.sh -d         # 单独删除 nexttrace
```

### 示例用法：

```shell
bash <(curl -sL raw.githubusercontent.com/honeok/cross/master/BestTrace.sh) -nmg     # 内蒙古三网路由
bash <(curl -sL raw.githubusercontent.com/honeok/cross/master/BestTrace.sh) -nmg -d  # 路由追踪完成后删除nexttrace
```

