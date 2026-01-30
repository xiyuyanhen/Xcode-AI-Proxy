#!/bin/bash

# Xcode AI Proxy 重启脚本
# 先停止再启动，方便管理服务
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
LOG_FILE="$SCRIPT_DIR/log/operation.log"

# 操作日志：只保留当天的记录
keep_only_today_log() {
    [ ! -f "$LOG_FILE" ] && return
    local today
    today=$(date '+%Y-%m-%d')
    awk -v today="$today" '
        /^=== [0-9]{4}-[0-9]{2}-[0-9]{2} / { keep = ($2 == today) }
        keep { print }
    ' "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
}

mkdir -p "$SCRIPT_DIR/log"
keep_only_today_log
printf '=== %s [restart] ===\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Xcode AI Proxy 重启脚本${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# 先停止
bash "$SCRIPT_DIR/stop.sh"
echo ""

# 再启动
echo -e "${YELLOW}[2/2] 启动服务...${NC}"
bash "$SCRIPT_DIR/start.sh"
