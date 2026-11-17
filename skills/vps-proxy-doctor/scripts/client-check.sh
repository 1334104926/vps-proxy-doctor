#!/usr/bin/env bash
# client-check.sh — 在客户端（Linux / macOS）上查为什么连不上自建代理。
#
# 用法:
#   ./client-check.sh <VPS地址> [端口] [代理地址]
#   ./client-check.sh 203.0.113.10 443 http://127.0.0.1:7890
#
# 全部是只读探测，不改本机设置。

set -u

HOST="${1:-}"
PORT="${2:-443}"
PROXY="${3:-}"

if [ -z "$HOST" ]; then
  sed -n '2,8p' "$0"
  exit 2
fi

say() { printf '\n== %s ==\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

say "本机"
uname -srm 2>/dev/null
date -Is 2>/dev/null

say "DNS 配置"
if have scutil; then
  scutil --dns 2>/dev/null | grep -m3 'nameserver' || true
else
  grep -m3 '^nameserver' /etc/resolv.conf 2>/dev/null || echo "读不到 resolv.conf"
fi

say "解析测试"
for d in www.google.com github.com; do
  if have dig; then
    printf '%-18s ' "$d"
    dig +short +time=3 +tries=1 "$d" 2>/dev/null | head -1
  else
    getent hosts "$d" 2>/dev/null | head -1 || echo "$d 解析失败"
  fi
done

say "TCP $HOST:$PORT"
if timeout 5 bash -c "exec 3<>/dev/tcp/$HOST/$PORT" 2>/dev/null; then
  echo "通"
else
  echo "不通（端口被封、服务没起、或防火墙拦了）"
fi

if [ "$PORT" = "443" ] && have openssl; then
  say "TLS 握手"
  echo | timeout 8 openssl s_client -connect "$HOST:$PORT" -servername "$HOST" 2>/dev/null \
    | grep -E 'subject=|issuer=|Verify return code' | head -3 \
    || echo "握手失败"
fi

say "直连出网（预期失败或很慢）"
if have curl; then
  curl -sS -m 8 -o /dev/null -w '直连 gstatic: %{http_code}  %{time_total}s\n' \
    https://www.gstatic.com/generate_204 2>&1 || echo "直连失败，正常"
fi

if [ -n "$PROXY" ]; then
  say "走代理出网"
  curl -sS -m 12 -x "$PROXY" -o /dev/null \
    -w "proxy $PROXY: %{http_code}  %{time_total}s\n" \
    https://www.gstatic.com/generate_204 2>&1 || echo "走代理失败"
fi

say "判断"
cat <<'EOF'
TCP 通 + 直连不通  → 端口没封，问题在协议或客户端配置
TCP 不通           → 先查 VPS 防火墙、云厂商安全组、端口是否被墙
TCP 通 + 代理也通  → 服务端正常，问题在分流规则或 DNS
EOF
