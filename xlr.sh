#!/bin/bash

# 定义变量
CFSPEED_EXEC="./CloudflareSpeedtest"
OS_TYPE=$(uname)
ARCH_TYPE=$(uname -m)
CLOUDFLARE_IP_URL="https://www.cloudflare.com/ips-v4/"
CLOUDFLARE_IP_FILE="ip.txt"
CONFIG_FILE="config.conf"
RESULT_FILE="result.csv"

# 检查命令是否存在，不存在则自动安装
check_command() {
    local CMD="$1"
    local PKG="$2"
    
    if ! command -v "$CMD" &> /dev/null; then
        echo "命令 $CMD 不存在，正在安装..."
        if [[ "$OS_TYPE" == "Linux" ]]; then
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                if [[ "$ID" == "openwrt" ]]; then
                    opkg update && opkg install "$PKG"
                else
                    if command -v apt &> /dev/null; then
                        apt update && apt install -y "$PKG"
                    elif command -v yum &> /dev/null; then
                        yum install -y "$PKG"
                    fi
                fi
            fi
        elif [[ "$OS_TYPE" == "Darwin" ]]; then
            brew install "$PKG"
        elif [[ "$OS_TYPE" =~ MINGW|MSYS|CYGWIN ]]; then
            echo "Windows 系统未实现自动安装功能，请手动安装 $PKG。"
            exit 1
        else
            echo "不支持的操作系统: $OS_TYPE"
            exit 1
        fi
    fi
}

# 检查必要命令
check_command curl curl
check_command jq jq
check_command awk gawk
check_command crontab cron

# 下载 CloudflareSpeedTest 函数
download_speedtest() {
    echo "CloudflareSpeedTest 不存在，开始下载..."
    
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        if [[ "$ARCH_TYPE" == "arm64" ]]; then
            DOWNLOAD_URL="https://github.xlr-wx.cn/https://github.com/ml74113/CloudflareST/releases/download/v2.2.5/CloudflareSpeedtest_darwin_arm64"
        else
            DOWNLOAD_URL="https://github.xlr-wx.cn/https://github.com/ml74113/CloudflareST/releases/download/v2.2.5/CloudflareSpeedtest_darwin_amd64"
        fi
    elif [[ "$OS_TYPE" == "Linux" ]]; then
        if [[ "$ARCH_TYPE" == "aarch64" ]]; then
            DOWNLOAD_URL="https://github.xlr-wx.cn/https://github.com/ml74113/CloudflareST/releases/download/v2.2.5/CloudflareSpeedtest_linux_arm64"
        else
            DOWNLOAD_URL="https://github.xlr-wx.cn/https://github.com/ml74113/CloudflareST/releases/download/v2.2.5/CloudflareSpeedtest_linux_amd64"
        fi
    elif [[ "$OS_TYPE" =~ MINGW|MSYS|CYGWIN ]]; then
        if [[ "$ARCH_TYPE" == "arm64" ]]; then
            DOWNLOAD_URL="https://github.xlr-wx.cn/https://github.com/ml74113/CloudflareST/releases/download/v2.2.5/CloudflareSpeedtest_win_arm64.exe"
        else
            DOWNLOAD_URL="https://github.xlr-wx.cn/https://github.com/ml74113/CloudflareST/releases/download/v2.2.5/CloudflareSpeedtest_win_amd64.exe"
        fi
    else
        echo "不支持的操作系统或架构: $OS_TYPE $ARCH_TYPE"
        exit 1
    fi

    # 尝试下载，失败时重试最多3次
    for i in {1..3}; do
        curl -Lo "$CFSPEED_EXEC" "$DOWNLOAD_URL" && break
        echo "下载失败，第 $i 次重试..."
        if [[ $i -eq 3 ]]; then
            echo "下载失败，已重试 3 次，请检查网络连接或下载源。"
            exit 1
        fi
        sleep 3
    done

    chmod +x "$CFSPEED_EXEC"
    echo "CloudflareSpeedTest 下载成功!"
}


# 主逻辑：检查并下载工具
if [[ ! -f "$CFSPEED_EXEC" ]]; then
    download_speedtest
else
    echo "CloudflareSpeedTest 已存在，跳过下载。"
fi


# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 无颜色

# 显示欢迎信息
echo -e "${GREEN}=============================================="
echo -e "${YELLOW} 欢迎使用 小龙人全自动优选工具${NC}"
echo -e "${YELLOW} 优选IP会直接绑定到子域名${NC}"
echo -e "${RED} 切勿使用被脚本做违反法律的事！一切后果都由本人承担！${NC}"
echo -e "${GREEN}=============================================="

# 配置输入函数
read_configuration() {
    read -p "请输入 Cloudflare 账户邮箱 [当前值: ${AUTH_EMAIL:-未设置}]: " AUTH_EMAIL_INPUT
    AUTH_EMAIL=${AUTH_EMAIL_INPUT:-${AUTH_EMAIL}}
    read -p "请输入 Cloudflare Global API Key [当前值: ${AUTH_KEY:-未设置}]: " AUTH_KEY_INPUT
    AUTH_KEY=${AUTH_KEY_INPUT:-${AUTH_KEY}}
    
    # 输入域名
    read -p "请输入需要更新的域名（例如 yourdomain.com）[当前值: ${DOMAIN:-未设置}]: " DOMAIN_INPUT
    DOMAIN=${DOMAIN_INPUT:-${DOMAIN}}
    
    # 输入五个子域名
    read -p "请输入第一个子域名（例如 sub1）[当前值: ${SUBDOMAIN1:-未设置}]: " SUBDOMAIN1_INPUT
    SUBDOMAIN1=${SUBDOMAIN1_INPUT:-${SUBDOMAIN1}}
    read -p "请输入第二个子域名（例如 sub2）[当前值: ${SUBDOMAIN2:-未设置}]: " SUBDOMAIN2_INPUT
    SUBDOMAIN2=${SUBDOMAIN2_INPUT:-${SUBDOMAIN2}}
    read -p "请输入第三个子域名（例如 sub3）[当前值: ${SUBDOMAIN3:-未设置}]: " SUBDOMAIN3_INPUT
    SUBDOMAIN3=${SUBDOMAIN3_INPUT:-${SUBDOMAIN3}}
    read -p "请输入第四个子域名（例如 sub4）[当前值: ${SUBDOMAIN4:-未设置}]: " SUBDOMAIN4_INPUT
    SUBDOMAIN4=${SUBDOMAIN4_INPUT:-${SUBDOMAIN4}}
    read -p "请输入第五个子域名（例如 sub5）[当前值: ${SUBDOMAIN5:-未设置}]: " SUBDOMAIN5_INPUT
    SUBDOMAIN5=${SUBDOMAIN5_INPUT:-${SUBDOMAIN5}}
    
    # 保存配置
    cat <<EOT > "$CONFIG_FILE"
AUTH_EMAIL="$AUTH_EMAIL"
AUTH_KEY="$AUTH_KEY"
DOMAIN="$DOMAIN"
SUBDOMAIN1="$SUBDOMAIN1"
SUBDOMAIN2="$SUBDOMAIN2"
SUBDOMAIN3="$SUBDOMAIN3"
SUBDOMAIN4="$SUBDOMAIN4"
SUBDOMAIN5="$SUBDOMAIN5"
EOT
}

# 获取 Zone ID
get_zone_id() {
    if [[ -z "$ZONE_ID" ]]; then
        ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}" \
             -H "X-Auth-Email: ${AUTH_EMAIL}" \
             -H "X-Auth-Key: ${AUTH_KEY}" \
             -H "Content-Type: application/json" | jq -r '.result[0].id')
        
        if [[ -z "$ZONE_ID" || "$ZONE_ID" == "null" ]]; then
            echo "无法获取 Zone ID，请检查域名和认证信息。"
            exit 1
        fi

        # 将 Zone ID 添加到配置文件
        echo "ZONE_ID=\"$ZONE_ID\"" >> "$CONFIG_FILE"
    fi
}

# 下载 Cloudflare IP 列表
echo "下载 Cloudflare IP 列表..."
curl -o "$CLOUDFLARE_IP_FILE" "$CLOUDFLARE_IP_URL"
if [[ $? -ne 0 ]]; then
    echo "下载 Cloudflare IP 列表失败。"
    exit 1
fi
echo "Cloudflare IP 列表已保存到 $CLOUDFLARE_IP_FILE"

# 检查配置文件并加载
if [[ "$1" == "r" ]]; then
    echo "重新填写配置..."
    read_configuration
elif [[ -f "$CONFIG_FILE" ]]; then
    echo "检测到配置文件，自动加载配置。"
    source "$CONFIG_FILE"
else
    echo "配置文件不存在，将引导输入配置。"
    read_configuration
fi

# 获取并保存 Zone ID
get_zone_id

# 确保 result.csv 文件存在
if [[ ! -f "$RESULT_FILE" ]]; then
    echo "result.csv 文件不存在，创建文件..."
    touch "$RESULT_FILE"
fi

# 运行 CloudflareSpeedTest 并使用新参数
echo "运行 CloudflareSpeedTest..."
"$CFSPEED_EXEC" -n 200 -t 4 -dn 10 -tp 443 -p 10 -sl 10 -o "$RESULT_FILE" -url "https://cs.xlr-wx.cn/100m"
if [[ $? -ne 0 ]]; then
    echo "CloudflareSpeedTest 执行失败，请检查执行权限或文件是否正确。"
    exit 1
fi
echo "CloudflareSpeedTest 任务完成！"

# 从测速结果文件中筛选出速度最快的五个IP
BEST_IPS=$(awk -F, 'NR > 1 { if($6 >= 10) { print $1 } }' "$RESULT_FILE" | head -n 5)

# 检查是否获取到了五个 IP
if [[ $(echo "$BEST_IPS" | wc -l) -lt 5 ]]; then
    echo "无法获取足够的合适 IP 地址。"
    exit 1
fi

# 获取 DNS 记录 ID
get_record_id() {
    local subdomain="$1"
    local full_subdomain="${subdomain}.${DOMAIN}"
    
    echo "正在获取 DNS 记录 ID: ${full_subdomain}"

    RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A&name=${full_subdomain}" \
         -H "X-Auth-Email: ${AUTH_EMAIL}" \
         -H "X-Auth-Key: ${AUTH_KEY}" \
         -H "Content-Type: application/json" | jq -r '.result[0].id')

    echo "返回的 DNS 记录 ID: $RECORD_ID"
    
    if [[ -z "$RECORD_ID" || "$RECORD_ID" == "null" ]]; then
        echo "[INFO] DNS 记录未找到，准备创建新的 A 记录：${full_subdomain}"
        RECORD_ID="new"
    fi
    return 0
}

# 更新或创建 DNS 记录
update_dns_record() {
    local subdomain="$1"
    local ip="$2"

    # 获取 DNS 记录 ID
    get_record_id "$subdomain"

    if [[ "$RECORD_ID" == "new" ]]; then
        # 如果记录不存在，则创建新的 A 记录
        echo "[INFO] 正在创建新的 A 记录：${subdomain}.${DOMAIN} -> ${ip%%:*}"

        CREATE_RESULT=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
             -H "X-Auth-Email: ${AUTH_EMAIL}" \
             -H "X-Auth-Key: ${AUTH_KEY}" \
             -H "Content-Type: application/json" \
             --data '{
               "type": "A",
               "name": "'"${subdomain}.${DOMAIN}"'",
               "content": "'"${ip%%:*}"'",
               "ttl": 120,
               "proxied": false
             }' | jq -r '.success')

        if [[ "$CREATE_RESULT" == "true" ]]; then
            echo "[INFO] 新的 DNS 记录创建成功：${subdomain}.${DOMAIN} -> ${ip%%:*}"
        else
            echo "[ERROR] 创建新的 DNS 记录失败，请检查日志。"
            return 1
        fi
    else
        # 如果记录存在，则更新 A 记录
        echo "[INFO] 正在更新 DNS 记录：${subdomain}.${DOMAIN} -> ${ip%%:*}"

        UPDATE_RESULT=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
             -H "X-Auth-Email: ${AUTH_EMAIL}" \
             -H "X-Auth-Key: ${AUTH_KEY}" \
             -H "Content-Type: application/json" \
             --data '{
               "type": "A",
               "name": "'"${subdomain}.${DOMAIN}"'",
               "content": "'"${ip%%:*}"'",
               "ttl": 120,
               "proxied": false
             }' | jq -r '.success')

        if [[ "$UPDATE_RESULT" == "true" ]]; then
            echo "[INFO] DNS 记录更新成功：${subdomain}.${DOMAIN} -> ${ip%%:*}"
        else
            echo "[ERROR] DNS 记录更新失败，请检查日志。"
            return 1
        fi
    fi
    return 0
}

# 更新 DNS 记录
INDEX=0
for BEST_IP in $BEST_IPS; do
    case $INDEX in
        0) update_dns_record "$SUBDOMAIN1" "$BEST_IP" ;;
        1) update_dns_record "$SUBDOMAIN2" "$BEST_IP" ;;
        2) update_dns_record "$SUBDOMAIN3" "$BEST_IP" ;;
        3) update_dns_record "$SUBDOMAIN4" "$BEST_IP" ;;
        4) update_dns_record "$SUBDOMAIN5" "$BEST_IP" ;;
    esac
    ((INDEX++))
done

# 显示结束信息
echo "=============================================="
echo -e "\033[1;32mDNS 更新完成\033[0m"  # 使用绿色文本
echo "感谢使用 小龙人全自动优选测速脚本"
echo "所有优选 IP 已解析到域名，2 分钟后生效。"
echo "请耐心等待并检查 DNS 配置是否正常。"
echo -e "\033[1;34m==============================================\033[0m"  # 使用蓝色框架
