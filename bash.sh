#!/bin/bash
set -e

echo "🚀 开始执行 Debian 一键安装脚本..."

# 检查 root
if [ "$(id -u)" != "0" ]; then
    echo "❌ 请使用 root 用户运行此脚本"
    exit 1
fi

# 检查 Debian
if ! grep -qi debian /etc/os-release; then
    echo "❌ 这个脚本只适用于 Debian"
    exit 1
fi

####################################
# 第一部分：基础环境准备
####################################

echo "📦 更新软件包并安装依赖..."
apt update -y
apt install -y curl wget cron ca-certificates

####################################
# 第二部分：安装 nyanpass 节点
####################################

echo "🚀 开始安装 nyanpass 节点..."
echo -e "nyanpass\ny\ny" | bash <(curl -fLSs https://dl.nyafw.com/download/nyanpass-install.sh) rel_nodeclient "-t 44d7821d-e8c1-4918-8c43-b41fdda0d650 -u https://materelay.com"
echo -e "1\ny\ny" | bash <(curl -fLSs https://dl.nyafw.com/download/nyanpass-install.sh) rel_nodeclient "-t e2cffc11-ba17-4de5-8d17-7b5719d43680 -u https://ny.qwqa.link"
echo -e "2\ny\ny" | bash <(curl -fLSs https://dl.nyafw.com/download/nyanpass-install.sh) rel_nodeclient "-t 90a1ff7e-b2a2-41d7-88ac-8e4d253086c9 -u https://ny.qwqa.link"
echo "✅ nyanpass 节点安装命令已执行"


####################################
# 第三部分：安装 RelayX 节点
####################################

echo "🚀 开始安装 RelayX 节点..."
curl -sSL https://dl.relayx.cc/install.sh | sh -s -- -s https://www.kalocci.com -t 74236f14-9600-40b7-b2c6-b7d99cf86de7 -n 3e69e771-8f21-4d9d-a7be-020040c01b3f
echo "✅ RelayX 节点安装完成"

####################################
# 第四部分：覆盖 /etc/sysctl.conf
####################################


####################################
# 第五部分：配置 Cloudflare DDNS
####################################

echo "🌐 开始配置 Cloudflare DDNS..."

# ================================
# Cloudflare DDNS 配置信息
# 请修改成你自己的信息
# ================================

CFKEY_INPUT="b9e521142064346bc8d0ee9ca3f7f7724760e"
CFUSER_INPUT="w18xh@outlook.com"
CFZONE_INPUT="kalocci.com"
CFRECORD_INPUT="aws-1-sg.kalocci.com"

DDNS_SCRIPT="/root/cf-v4-ddns.sh"
DDNS_URL="https://raw.githubusercontent.com/yulewang/cloudflare-api-v4-ddns/master/cf-v4-ddns.sh"

echo "📥 正在下载 Cloudflare DDNS 脚本..."
wget -N --no-check-certificate "$DDNS_URL" -O "$DDNS_SCRIPT"

if [ ! -f "$DDNS_SCRIPT" ]; then
    echo "❌ DDNS 脚本下载失败：$DDNS_SCRIPT 不存在"
    exit 1
fi

if [ ! -s "$DDNS_SCRIPT" ]; then
    echo "❌ DDNS 脚本下载失败：文件为空"
    exit 1
fi

echo "✅ DDNS 脚本已下载到：$DDNS_SCRIPT"

echo "🔐 正在设置执行权限..."
chmod +x "$DDNS_SCRIPT"

echo "📝 正在写入 Cloudflare DDNS 配置..."

sed -i "s/^CFKEY=.*/CFKEY=${CFKEY_INPUT}/" "$DDNS_SCRIPT"
sed -i "s/^CFUSER=.*/CFUSER=${CFUSER_INPUT}/" "$DDNS_SCRIPT"
sed -i "s/^CFZONE_NAME=.*/CFZONE_NAME=${CFZONE_INPUT}/" "$DDNS_SCRIPT"
sed -i "s/^CFRECORD_NAME=.*/CFRECORD_NAME=${CFRECORD_INPUT}/" "$DDNS_SCRIPT"

echo "🔎 检查 DDNS 配置是否写入成功..."
grep -E "CFUSER=|CFZONE_NAME=|CFRECORD_NAME=" "$DDNS_SCRIPT"

echo "🧪 正在测试运行 Cloudflare DDNS..."
bash "$DDNS_SCRIPT" || {
    echo "❌ Cloudflare DDNS 测试失败，请检查："
    echo "   1. Cloudflare Global API Key 是否正确"
    echo "   2. Cloudflare 邮箱是否正确"
    echo "   3. 主域名是否已接入 Cloudflare"
    echo "   4. DDNS A 记录是否已提前创建"
    echo "   5. A 记录是否为灰色云朵 DNS only"
    exit 1
}

echo "⏰ 正在添加 Cloudflare DDNS 每分钟定时任务..."

CRON_JOB="*/1 * * * * /root/cf-v4-ddns.sh >/dev/null 2>&1"

crontab -l 2>/dev/null | grep -v "/root/cf-v4-ddns.sh" > /tmp/current_cron || true
echo "$CRON_JOB" >> /tmp/current_cron
crontab /tmp/current_cron
rm -f /tmp/current_cron

echo "🔄 正在启用并重启 cron 服务..."
systemctl enable cron
systemctl restart cron

echo "✅ Cloudflare DDNS 已配置完成，每分钟自动更新 IP"






echo "⚙️ 正在覆盖 /etc/sysctl.conf ..."

cat > /etc/sysctl.conf << 'EOF'
fs.file-max = 6815744
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_ecn=0
net.ipv4.tcp_frto=0
net.ipv4.tcp_mtu_probing=0
net.ipv4.tcp_rfc1337=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_fack=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_adv_win_scale=1
net.ipv4.tcp_moderate_rcvbuf=1
net.core.rmem_max=96300000
net.core.wmem_max=96300000
net.ipv4.tcp_rmem=4096 131072 96300000
net.ipv4.tcp_wmem=4096 131072 96300000
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192
net.ipv4.ip_forward=1
net.ipv4.conf.all.route_localnet=1
net.ipv4.conf.all.forwarding=1
net.ipv4.conf.default.forwarding=1
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

echo "🔄 正在应用 sysctl 参数..."
sysctl -p
sysctl --system
