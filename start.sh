#!/bin/bash

# Xcode AI Proxy 启动脚本
# 确保脚本在错误时停止
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 脚本所在目录（与 .pid、log 路径一致）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
LOG_FILE="$SCRIPT_DIR/log/operation.log"
PID_FILE="$SCRIPT_DIR/.xcode-ai-proxy.pid"

# 操作日志：只保留当天的记录（按 === YYYY-MM-DD ... === 会话块过滤）
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
printf '=== %s [start] ===\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Xcode AI Proxy 启动脚本${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# 检查 Python 版本
echo -e "${YELLOW}[1/5] 检查 Python 版本...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}错误: 未找到 Python3，请先安装 Python 3.12+${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | awk '{print $2}')
echo -e "${GREEN}✓ Python 版本: ${PYTHON_VERSION}${NC}"
echo ""

# 检查 uv 是否安装
echo -e "${YELLOW}[2/5] 检查 uv 包管理工具...${NC}"
if ! command -v uv &> /dev/null; then
    echo -e "${RED}错误: 未找到 uv，请先安装 uv${NC}"
    echo "安装命令: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi
echo -e "${GREEN}✓ uv 已安装${NC}"
echo ""

# 检查 .env 文件
echo -e "${YELLOW}[3/5] 检查配置文件...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${RED}错误: 未找到 .env 文件${NC}"
    if [ -f ".env.example" ]; then
        echo -e "${YELLOW}提示: 请复制 .env.example 为 .env 并填入你的 API 密钥${NC}"
        echo "命令: cp .env.example .env"
    fi
    exit 1
fi
echo -e "${GREEN}✓ .env 配置文件存在${NC}"
echo ""

# 创建虚拟环境（如果不存在）
echo -e "${YELLOW}[4/5] 配置 Python 虚拟环境...${NC}"
if [ ! -d ".venv" ]; then
    echo "创建虚拟环境..."
    uv venv
    echo -e "${GREEN}✓ 虚拟环境创建成功${NC}"
else
    echo -e "${GREEN}✓ 虚拟环境已存在${NC}"
fi

# 激活虚拟环境并安装依赖
echo "安装依赖..."
source .venv/bin/activate
uv sync
echo -e "${GREEN}✓ 依赖安装完成${NC}"
echo ""

# 启动服务
echo -e "${YELLOW}[5/5] 启动 Xcode AI Proxy 服务...${NC}"
echo -e "${GREEN}服务地址: http://localhost:8899${NC}"
echo -e "${GREEN}按 Ctrl+C 停止服务${NC}"
echo ""
echo -e "${GREEN}======================================${NC}"
echo ""

# 后台启动并记录 PID，便于 stop.sh 精确结束
python3 server.py &
PID=$!
echo $PID > "$PID_FILE"
trap 'rm -f "$PID_FILE"' EXIT

# 前台等待，Ctrl+C 可停止服务
wait $PID
