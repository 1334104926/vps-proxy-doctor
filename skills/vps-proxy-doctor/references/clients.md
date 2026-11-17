# 客户端配置

手机 Clash Meta 和 Windows Clash Verge Rev 吃同一份 YAML。配一次，两边都能用。

## 参数从服务端拿

下面模板里的尖括号，全部要从 VPS 上取，不能编：

| 参数 | 从哪拿 |
| --- | --- |
| 地址、端口 | 你装服务时定的 |
| UUID | `xray uuid` 或服务端配置里 |
| 公钥（Reality） | `xray x25519` 输出的 Public key |
| short-id | 服务端配置里的 `shortIds` |
| SNI | 你伪装的目标域名，比如 `www.microsoft.com` |

## 一份能用的骨架

```yaml
mixed-port: 7890
allow-lan: false
mode: rule
log-level: info

dns:
  enable: true
  enhanced-mode: fake-ip
  nameserver:
    - 223.5.5.5
    - https://dns.alidns.com/dns-query
  fallback:
    - https://1.1.1.1/dns-query
    - https://8.8.8.8/dns-query

proxies:
  - name: vps
    type: vless
    server: <VPS_IP>
    port: 443
    uuid: <UUID>
    network: tcp
    tls: true
    flow: xtls-rprx-vision
    servername: <SNI>
    client-fingerprint: chrome
    reality-opts:
      public-key: <PUBLIC_KEY>
      short-id: <SHORT_ID>

proxy-groups:
  - name: PROXY
    type: select
    proxies: [vps, DIRECT]

rules:
  - GEOIP,CN,DIRECT
  - MATCH,PROXY
```

服务端不是 VLESS + Reality 的话，`proxies` 那段换成对应的类型。找服务端的出站配置抄，别凭记忆写。

## 手机：Clash Meta

1. 把 YAML 传到手机，存到「下载」目录。
2. 打开 Clash Meta，配置 → 新建 → 从文件导入。
3. 选刚存的文件，点右上角启用。
4. 首页看到「已连接」和实时的上下行流量，才算成功。

**手机常见的两个坑：**

- **电池优化把 Clash 杀了。** 系统设置里把 Clash Meta 设成“不优化”，不然锁屏几分钟就断。
- **私人 DNS 绕过代理。** 系统设置里的私人 DNS 关掉，DNS 交给 Clash。

## Windows：Clash Verge Rev

1. 下载安装，打开「配置」页。
2. 把 YAML 拖进去，或者点「新建 → 本地文件」。
3. 右键配置 → 启用。
4. 打开「系统代理」或者「TUN 模式」。

**系统代理和 TUN 的区别：**

| | 系统代理 | TUN 模式 |
| --- | --- | --- |
| 影响范围 | 只影响走 WinINET 的程序 | 全部流量 |
| 需要管理员 | 不用 | 要 |
| 浏览器 | 能用 | 能用 |
| 命令行、游戏 | 不走 | 走 |

命令行 `curl` 不走系统代理，这是最容易误判的一点。要么开 TUN，要么手动 `-x`。

## 只有 SSH 的情况

VPS 上什么代理都没装，只开了 SSH，也能当出口：

```bash
ssh -N -D 127.0.0.1:1081 root@<VPS>
```

然后 Clash 里加一条：

```yaml
proxies:
  - name: ssh
    type: socks5
    server: 127.0.0.1
    port: 1081
```

这个办法在电脑上很省事，手机上不合适：得一直连着 SSH，切网就断，耗电也高。手机还是用正经协议。

## 配完怎么验

1. 打开 `https://www.gstatic.com/generate_204`，能返回 204 就是通。
2. 打开 `https://ip.sb`，看显示的 IP 是不是你的 VPS。
3. 打开一个国内网站，确认没走代理（走了会慢）。
