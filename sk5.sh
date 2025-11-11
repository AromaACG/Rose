#!/bin/bash
# 固定端口：23321
# 账号：acg
# 密码：cAz6by#2

set -e

# ========== 1. 安装 Xray ==========
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)"

# ========== 2. 写入配置文件 ==========
cat >/usr/local/etc/xray/config.json <<EOF
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": 23321,
      "protocol": "socks",
      "settings": {
        "auth": "password",
        "accounts": [
          {
            "user": "acg",
            "pass": "cAz6by#2"
          }
        ],
        "udp": true
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      },
      "tag": "socks-in"
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "block"
      }
    ]
  }
}
EOF

# ========== 3. 防扫描优化 ==========
# 启用防火墙，只开放必要端口
ufw --force reset
ufw allow 22/tcp   # SSH
ufw allow 23321/tcp
ufw allow 23321/udp
ufw default deny incoming
ufw default allow outgoing
ufw --force enable

# ========== 4. 调整系统参数 ==========
# 降低可被端口扫描的几率
sysctl -w net.ipv4.tcp_syncookies=1
sysctl -w net.ipv4.icmp_echo_ignore_all=1
sysctl -w net.ipv4.conf.all.rp_filter=1

# 永久保存
cat >/etc/sysctl.d/99-xray.conf <<EOF
net.ipv4.tcp_syncookies=1
net.ipv4.icmp_echo_ignore_all=1
net.ipv4.conf.all.rp_filter=1
EOF

# ========== 5. 启动并设置自启 ==========
systemctl daemon-reload
systemctl enable xray
systemctl restart xray

echo ""
echo "Xray 已成功配置！"
echo "----------------------------"
echo "协议：SOCKS5"
echo "端口：23321"
echo "账号：acg"
echo "密码：cAz6by#2"
echo "----------------------------"
echo "已启用防火墙保护，仅开放 22 与 23321 端口"

