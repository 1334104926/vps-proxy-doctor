# 服务端

目标：一台 VPS，一个能长期跑、重启会自己起来的代理服务。

## 先选协议

| 协议 | 端口 | 适合 | 代价 |
| --- | --- | --- | --- |
| VLESS + Reality | TCP 443 | 目前最稳，不需要域名和证书 | 配置参数多，客户端要支持 |
| Hysteria2 | UDP | 丢包严重的线路 | 部分网络封 UDP |
| Trojan | TCP 443 | 有域名和证书 | 要维护证书 |
| Shadowsocks | 任意 | 最简单 | 特征明显，容易被识别 |

没有域名和证书，选 Reality。有证书、想省事，选 Trojan。线路很差，试 Hysteria2。

## 安装

不管装哪个，原则一样：一个二进制，一个 systemd 单元，一份配置。

```bash
# 以 sing-box 为例，版本号按官方 release 换
curl -LO https://github.com/SagerNet/sing-box/releases/latest/download/sing-box-linux-amd64.tar.gz
tar -xzf sing-box-linux-amd64.tar.gz
install -m 755 sing-box /usr/local/bin/sing-box
```

单元文件 `/etc/systemd/system/sing-box.service`：

```ini
[Unit]
Description=sing-box
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

```bash
systemctl daemon-reload
systemctl enable --now sing-box
systemctl status sing-box --no-pager
```

`enable` 和 `start` 都要。只 `start` 的话，重启就没了。

具体配置字段以官方文档为准，别抄博客里的旧版本。

## 端口

- 用 443。云厂商和运营商对 443 最宽容。
- 别用 1080、8388、1081、7890，这些是扫描器的重点目标。
- 换端口后，云安全组和系统防火墙都要放行。

```bash
ufw allow 443/tcp
ufw allow 22/tcp
ufw enable
```

云厂商的安全组在网页控制台，跟 `ufw` 是两套，别只开一套。

## 加固

```bash
# 只允许密钥登录
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl reload sshd
```

**改之前先确认你有一条能用的密钥会话。** 改错了就进不去了，只能去控制台救援。

再装个 fail2ban：

```bash
apt install -y fail2ban
systemctl enable --now fail2ban
```

## 不要做的三件事

1. **别把管理面板开到公网。** 3x-ui、x-ui 这类面板，只监听 127.0.0.1，用 SSH 隧道进去。
2. **别用一键脚本装完就不管。** 脚本装的版本往往旧，而且开了你不知道的端口。
3. **别在 VPS 上放别的东西。** 代理机器被盯上的概率不低，上面别有数据。

## 备份

配置就一个文件，改之前复制一份：

```bash
cp /etc/sing-box/config.json /root/config.json.bak.$(date +%F)
```

出问题能立刻退回去。
