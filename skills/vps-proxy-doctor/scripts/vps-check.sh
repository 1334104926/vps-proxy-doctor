#!/bin/sh
# vps-check.sh — 自建代理 VPS 的只读检查，不改任何文件、不动任何服务。
#
# 用法:
#   sh vps-check.sh
#   sh vps-check.sh --proxy http://127.0.0.1:1080
#
# 需要看进程名和防火墙规则时用 root 跑，普通用户也能跑，只是少几项。

set -u

PROXY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --proxy) PROXY="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done

say() { printf '\n== %s ==\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

say "系统"
uname -srm 2>/dev/null
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  echo "${PRETTY_NAME:-unknown}"
fi

say "时间"
date -Is 2>/dev/null
if have timedatectl; then
  timedatectl 2>/dev/null | sed -n '1,8p'
fi
if have chronyc; then
  chronyc tracking 2>/dev/null | sed -n '1,4p'
fi

say "监听端口"
if have ss; then
  ss -lntup 2>/dev/null | sed -n '1,60p'
elif have netstat; then
  netstat -lntup 2>/dev/null | sed -n '1,60p'
else
  echo "没有 ss 也没有 netstat"
fi

say "代理相关进程"
ps -eo pid,etime,rss,args 2>/dev/null \
  | grep -Ei 'xray|sing-box|mihomo|clash|v2ray|trojan|hysteria|tuic|naive|shadowsocks|ss-server|sslocal' \
  | grep -v grep \
  | sed -n '1,20p'
echo "(空表示没找到常见的代理进程)"

say "相关 systemd 单元"
if have systemctl; then
  systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null \
    | grep -Ei 'xray|sing|mihomo|clash|v2ray|trojan|hysteria|tuic|ssh|sshguard|fail2ban'
  echo "(空表示没有匹配的运行中单元)"
fi

say "防火墙"
if have ufw; then
  ufw status 2>/dev/null || echo "ufw 需要 root"
fi
if have nft; then
  echo "-- nft --"
  nft list ruleset 2>/dev/null | sed -n '1,40p' || echo "nft 需要 root"
fi
if have iptables; then
  echo "-- iptables --"
  iptables -S 2>/dev/null | sed -n '1,30p' || echo "iptables 需要 root"
fi

say "DNS"
sed -n '1,10p' /etc/resolv.conf 2>/dev/null
echo "-- 解析测试 --"
getent hosts www.google.com 2>/dev/null || echo "解析 www.google.com 失败"
getent hosts github.com 2>/dev/null || echo "解析 github.com 失败"

say "VPS 自己的出网"
if have curl; then
  curl -sS -m 8 -o /dev/null -w 'gstatic 204: %{http_code}  %{time_total}s\n' \
    https://www.gstatic.com/generate_204 2>&1 || echo "直连出网失败"
else
  echo "没有 curl"
fi

say "经过本机代理出网"
if [ -n "$PROXY" ] && have curl; then
  curl -sS -m 10 -x "$PROXY" -o /dev/null \
    -w "proxy $PROXY: %{http_code}  %{time_total}s\n" \
    https://www.gstatic.com/generate_204 2>&1 || echo "走代理失败"
else
  echo "没给 --proxy，跳过。示例: sh $0 --proxy http://127.0.0.1:1080"
fi

say "SSH 加固状态"
if [ -r /etc/ssh/sshd_config ]; then
  grep -Ei '^\s*(Port|PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|AllowUsers)' \
    /etc/ssh/sshd_config 2>/dev/null | sed -n '1,10p'
fi
if have fail2ban-client; then
  fail2ban-client status 2>/dev/null | sed -n '1,6p'
fi

printf '\n检查结束。以上全是只读操作。\n'
