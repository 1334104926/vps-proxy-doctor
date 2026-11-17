---
name: vps-proxy-doctor
description: 当用户自己租了 VPS 跑代理，手机用 Clash Meta 或电脑要上外网，出现连不上、很慢、部分网站打不开时使用；也用于给自建代理配客户端、换协议、加固服务端。
---

# 自建代理：配客户端与排障

**自建**指用户自己租 VPS，代理服务跑在自己的服务器上。买机场的不适用。

## 开工前先问三句

1. VPS 上跑的是什么？xray、sing-box、mihomo、还是只有 SSH？
2. 客户端是什么？手机 Clash Meta、Windows Clash Verge Rev，还是别的？
3. 症状是哪一种？

| 症状 | 大概率在哪一层 |
| --- | --- |
| 完全连不上 | 端口、防火墙、服务没起来、IP 被封 |
| 能连，网页打不开 | DNS、规则分流、系统代理没生效 |
| 有的网站能开，有的不行 | 规则误杀、目标站封了 VPS 的 IP |
| 能上，但很慢 | 线路、晚高峰限速、加密方式吃 CPU |

## 只读优先

**先查，别先改。** 在 VPS 上跑 `scripts/vps-check.sh`，在客户端跑 `scripts/client-check.sh`（Windows 用 `.ps1`）。

两份输出放到一起看，能定位九成问题。改配置前先备份，一次只改一处。

## 分层往下查

1. **机器活着吗**：SSH 能不能进。进不去就是 VPS 本身的问题，跟代理无关。
2. **端口通不通**：从客户端测 VPS 的端口。国内能 SSH 但代理端口不通，是典型的端口封锁。
3. **服务在跑吗**：`systemctl status`。崩了先看日志里的报错，别看配置。
4. **时间对不对**：偏差超过 2 分钟，VMess 和 TLS 都会失败。`timedatectl` 一看就知道。
5. **DNS**：客户端解析出来的地址和 VPS 上解析的不一致，就是污染或者 DNS 配错。
6. **规则**：把代理切成全局试一次。全局能用、规则不能用，就是分流规则的问题。

详细步骤和命令见 `references/diagnose.md`。

## 客户端配置

手机 Clash Meta 和 Windows Clash Verge Rev 用的是同一份 YAML。服务端的参数（地址、端口、UUID、公钥、SNI）必须从 VPS 上取，不能编。

模板和导入步骤见 `references/clients.md`。

## 硬规则

- 密钥、订阅链接、VPS 的 IP 和端口，不写进公开仓库。
- 改 SSH 配置前先确认还有一条能进的会话，别把自己锁在外面。
- 关掉密码登录之前，先确认密钥能进。
- 云厂商的安全组和系统防火墙是两层，两层都要开。
- 不替用户决定用哪个协议，先问他要不要折腾。

## 什么时候别修

- VPS 的 IP 被整段封了：换 IP 比重装协议快。
- 用户只想看几个网页：告诉他买机场更省事，自建的成本在维护。

## 目录

- `references/diagnose.md`：分层排查的完整命令和判断标准。
- `references/clients.md`：Clash Meta / Clash Verge 的配置模板和导入步骤。
- `references/server.md`：服务端最小配置、加固、换协议。
- `scripts/vps-check.sh`：在 VPS 上跑的只读检查。
- `scripts/client-check.sh`：Linux/macOS 客户端检查。
- `scripts/client-check.ps1`：Windows 客户端检查。
