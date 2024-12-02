<div align="center">
  <br>
  <img width="360" style="max-width:80%" src="https://raw.githubusercontent.com/nezhahq/nezha/master/.github/brand.svg" title="哪吒监控 Nezha Monitoring">
  <br>
  <small><i>LOGO designed by <a href="https://xio.ng" target="_blank">熊大</a> .</i></small>
  <br><br>
</div>

# 使用方法

将原有脚本替换为本脚本即可

![Image](assets/nezha.png)

国外服务器：
```shell
curl -fskL raw.githubusercontent.com/honeok/cross/master/nezha/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh
```
国内服务器：
```shell
curl -fskL gh.611611.best/raw.githubusercontent.com/honeok/cross/master/nezha/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh
```

## 运行参数

编辑`/etc/systemd/system/nezha-agent.service`然后在 `ExecStart=` 这一行的末尾加上参数

参数清单：

- `--report-delay`: 控制系统信息上报的间隔，默认为 1 秒，可以设置为 3 来进一步降低 agent 端系统资源占用（配置区间 1-4）
- `--skip-conn`: 不监控连接数，推荐 机场/连接密集型 服务器或CPU占用较高的服务器设置
- `--skip-procs`: 不监控进程数，也可以降低 Agent 占用
- `--disable-auto-update`: 禁止自动更新 Agent（安全特性）
- `--disable-force-update`: 禁止强制更新 Agent（安全特性）
- `--disable-command-execute`: 禁止在 Agent 上执行定时任务、打开在线终端（安全特性）
- `--tls`: 启用 SSL/TLS 加密（使用nginx反向代理Agent的grpc连接，并且nginx开启SSL/TLS时，需要启用该项配置）
- `--temperature`: 启用GPU监控（如果支持）

**重启服务：**

```shell
# 手动编辑
sudo vim /etc/systemd/system/nezha-agent.service
sudo systemctl daemon-reload
sudo systemctl restart nezha-agent
sudo systemctl status nezha-agent

# 直接修改，禁用Agent自动更新命令
sed -i '/^ExecStart=/ {/"--disable-auto-update"/! s/$/ "--disable-auto-update"/}' /etc/systemd/system/nezha-agent.service && systemctl daemon-reload
```

## Agent版本回退

以v.19.5为例，替换以下agent版本执行即可

```shell
wget -q https://github.com/nezhahq/agent/releases/download/v0.19.5/nezha-agent_linux_amd64.zip && unzip -o nezha-agent_linux_amd64.zip -d /opt/nezha/agent && rm nezha-agent_linux_amd64.zip && systemctl daemon-reload && systemctl restart nezha-agent
```
