# vps-proxy-doctor

自己租的 VPS 上跑代理，手机 Clash Meta 或电脑 Clash Verge 连不上、能连但网页打不开、有的网站不行、特别慢——装这个 skill，让 AI 一层层帮你查。

不是教你怎么装 Clash。装客户端的教程满网都是，缺的是装完之后坏在哪。

俗称梯子、翻墙、科学上网。这里解决的就是这些场景里“为什么连不上”。

## 适用

- 自己租了 VPS，代理跑在自己的服务器上
- 手机用 Clash Meta，电脑用 Clash Verge Rev 或别的 mihomo 客户端
- 已经能连，或者连不上，想找原因

不适用：买机场的、不想碰命令行的、想让 AI 替你租服务器的。

## 安装

用 DSH 的话一条命令：

```bash
dsh plugin add 1334104926/vps-proxy-doctor
```

不用 DSH，或者想手动装，把 skill 目录复制过去：

```bash
git clone https://github.com/1334104926/vps-proxy-doctor.git
cp -r vps-proxy-doctor/skills/vps-proxy-doctor ~/.agents/skills/
```

也可以只装到某个项目：

```bash
cp -r vps-proxy-doctor/skills/vps-proxy-doctor /你的项目/.agents/skills/
```

Claude Code 用 `~/.claude/skills/`，路径同理。

放进去就能用，不用重启。

## 里面有什么

```
package.json                 声明 dsh.bundle，让 `dsh plugin add` 能装
cordis.patch.yml             插件挂载点
index.js                     把 skills/ 注册成一个 skill 提供方
examples/walkthrough.md      一次真实的排查过程
skills/vps-proxy-doctor/
├── SKILL.md                 主文件，先读这个
├── references/
│   ├── diagnose.md          分层排查，七层
│   ├── clients.md           Clash Meta 和 Clash Verge 配置
│   └── server.md            服务端：选协议、装、加固
└── scripts/
    ├── vps-check.sh         在 VPS 上跑，只读
    ├── client-check.sh      Linux/macOS 客户端
    └── client-check.ps1     Windows 客户端
```

三个脚本都只做探测，不改任何设置。

想看一遍真实的排查过程，读 [examples/walkthrough.md](examples/walkthrough.md)。

## 怎么用

对 AI 说：

> 我的代理连不上了，VPS 是 xxx.xxx.xxx.xxx，端口 443

它会先问服务端跑的是什么、客户端是什么、症状是哪一种，再让你跑 `vps-check.sh`，然后按结果往下查。

## 边界

- 不含任何服务端一键安装脚本。安装方式各家用各家的，抄错了更难查。
- 不替你决定用哪个协议。文档里只给取舍。
- 脚本里的地址、端口、密钥全是占位符。

## 免责

自建代理的合规性取决于你所在的地区。这个仓库只提供技术排查思路，不对使用后果负责。

## License

MIT
