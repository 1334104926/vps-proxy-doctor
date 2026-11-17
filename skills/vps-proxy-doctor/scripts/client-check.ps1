# client-check.ps1 — 在 Windows 上查为什么连不上自建代理。只读。
#
# 用法:
#   .\client-check.ps1 -Server 203.0.113.10 -Port 443
#   .\client-check.ps1 -Server 203.0.113.10 -Port 443 -Proxy http://127.0.0.1:7890

param(
  [Parameter(Mandatory = $true)][string]$Server,
  [int]$Port = 443,
  [string]$Proxy = ""
)

$ErrorActionPreference = "Continue"

function Say($t) { Write-Host "`n== $t ==" }

Say "本机"
"$($env:COMPUTERNAME)  $(Get-Date -Format o)"
"PowerShell $($PSVersionTable.PSVersion)"

Say "时间偏差"
$w32 = Get-Service w32time -ErrorAction SilentlyContinue
if ($w32) { "w32time: $($w32.Status)" } else { "没有 w32time 服务" }

Say "DNS 服务器"
Get-DnsClientServerAddress -AddressFamily IPv4 |
  Where-Object { $_.ServerAddresses } |
  ForEach-Object { "$($_.InterfaceAlias): $($_.ServerAddresses -join ', ')" }

Say "解析测试"
foreach ($d in @("www.google.com", "github.com")) {
  try {
    $r = Resolve-DnsName -Name $d -Type A -ErrorAction Stop |
      Where-Object { $_.IPAddress } | Select-Object -First 1
    "$d -> $($r.IPAddress)"
  } catch {
    "$d 解析失败"
  }
}

Say "TCP $Server`:$Port"
$t = Test-NetConnection -ComputerName $Server -Port $Port -WarningAction SilentlyContinue
if ($t.TcpTestSucceeded) { "通" } else { "不通（端口被封、服务没起、或防火墙拦了）" }
"延迟: $($t.PingReplyDetails.RoundtripTime) ms"

Say "直连出网（预期失败或很慢）"
try {
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $r = Invoke-WebRequest -Uri "https://www.gstatic.com/generate_204" -TimeoutSec 8 -UseBasicParsing
  $sw.Stop()
  "直连 gstatic: $($r.StatusCode)  $([math]::Round($sw.Elapsed.TotalSeconds,2))s"
} catch {
  "直连失败，正常"
}

if ($Proxy -ne "") {
  Say "走代理出网"
  try {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $r = Invoke-WebRequest -Uri "https://www.gstatic.com/generate_204" -Proxy $Proxy -TimeoutSec 15 -UseBasicParsing
    $sw.Stop()
    "代理 $Proxy`: $($r.StatusCode)  $([math]::Round($sw.Elapsed.TotalSeconds,2))s"
  } catch {
    "走代理失败: $($_.Exception.Message)"
  }

  Say "Windows 系统代理设置"
  $p = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
  "ProxyEnable: $($p.ProxyEnable)"
  "ProxyServer: $($p.ProxyServer)"
  "注意：系统代理只影响走 WinINET 的程序，浏览器和很多应用要各自设。"
}

Say "判断"
@"
TCP 通 + 直连不通  -> 端口没封，问题在协议或客户端配置
TCP 不通           -> 先查 VPS 防火墙、云厂商安全组、端口是否被墙
TCP 通 + 代理也通  -> 服务端正常，问题在分流规则或 DNS
"@ | Write-Host
