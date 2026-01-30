#!/bin/bash

# Xcode AI Proxy 停止脚本
# 确保脚本在错误时停止
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}======================================${NC}"
echo -e "${YELLOW}  Xcode AI Proxy 停止脚本${NC}"
echo -e "${YELLOW}======================================${NC}"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
PID_FILE="$SCRIPT_DIR/.xcode-ai-proxy.pid"
LOG_FILE="$SCRIPT_DIR/log/operation.log"

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
printf '=== %s [stop] ===\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# 优先从 .env 读取端口，否则默认 8899
PORT=8899
if [ -f ".env" ]; then
    if grep -q "^PORT=" .env 2>/dev/null; then
        PORT=$(grep "^PORT=" .env | cut -d'=' -f2 | tr -d ' ')
    fi
fi

# 仅保留「工作目录为本项目」的 PID，避免误杀其它服务
filter_pids_by_cwd() {
    local pids="$1"
    local to_kill=""
    for pid in $pids; do
        [ -z "$pid" ] && continue
        # 取该进程的当前工作目录（macOS/Linux 通用）
        cwd=$(ps -p "$pid" -o cwd= 2>/dev/null | tr -d ' \n')
        [ -z "$cwd" ] && continue
        # 规范化路径后比较，只杀本项目目录下启动的进程
        cwd_real=$(cd "$cwd" 2>/dev/null && pwd)
        [ "$cwd_real" = "$SCRIPT_DIR" ] && to_kill="$to_kill $pid"
    done
    echo "$to_kill" | tr -s ' ' '\n' | grep -v '^$' || true
}

# 优先使用 PID 文件（由 start.sh 写入，最精确）
PIDS=""
if [ -f "$PID_FILE" ]; then
    READ_PID=$(cat "$PID_FILE" 2>/dev/null | tr -d ' \n')
    if [ -n "$READ_PID" ] && kill -0 "$READ_PID" 2>/dev/null; then
        # 确认是该进程在本项目目录下启动，避免误用陈旧的 PID 文件
        cwd=$(ps -p "$READ_PID" -o cwd= 2>/dev/null | tr -d ' \n')
        if [ -n "$cwd" ]; then
            cwd_real=$(cd "$cwd" 2>/dev/null && pwd)
            [ "$cwd_real" = "$SCRIPT_DIR" ] && PIDS="$READ_PID"
        fi
    fi
fi

# 若无有效 PID 文件，再按进程名/端口 + cwd 过滤
if [ -z "$PIDS" ]; then
    CANDIDATES=$(pgrep -f "python.*server\.py" 2>/dev/null || true)
    if [ -z "$CANDIDATES" ] && command -v lsof &> /dev/null; then
        CANDIDATES=$(lsof -ti ":$PORT" 2>/dev/null || true)
    fi
    PIDS=$(filter_pids_by_cwd "$CANDIDATES")
fi

if [ -n "$PIDS" ]; then
    echo -e "${YELLOW}正在停止 Xcode AI Proxy 服务 (PID: ${PIDS})...${NC}"
    echo "$PIDS" | xargs kill 2>/dev/null || true
    sleep 2
    # 若仍在运行则强制结束（再次按 cwd 过滤，避免误杀）
    REMAINING=$(filter_pids_by_cwd "$(pgrep -f "python.*server\.py" 2>/dev/null || true)")
    if [ -z "$REMAINING" ]; then
        REMAINING=$(filter_pids_by_cwd "$(lsof -ti ":$PORT" 2>/dev/null || true)")
    fi
    if [ -n "$REMAINING" ]; then
        echo -e "${YELLOW}进程未响应，强制结束...${NC}"
        echo "$REMAINING" | xargs kill -9 2>/dev/null || true
    fi
fi

# 若未通过 PID/cwd 找到进程，但端口仍被占用（如 uvicorn 子进程、历史残留），则按端口清理，避免 restart 时 address already in use
PORT_PIDS=""
if command -v lsof &> /dev/null; then
    PORT_PIDS=$(lsof -ti ":$PORT" 2>/dev/null || true)
fi
if [ -n "$PORT_PIDS" ]; then
    echo -e "${YELLOW}端口 ${PORT} 被占用 (PID: ${PORT_PIDS})，已结束占用进程${NC}"
    [ -z "$PIDS" ] && echo -e "${YELLOW}（可能非本脚本启动，已清理以便 restart 可用）${NC}"
    echo "$PORT_PIDS" | xargs kill -9 2>/dev/null || true
fi

rm -f "$PID_FILE"

if [ -n "$PIDS" ] || [ -n "$PORT_PIDS" ]; then
    echo -e "${GREEN}✓ Xcode AI Proxy 服务已停止${NC}"
else
    echo -e "${YELLOW}未发现运行中的 Xcode AI Proxy 服务 (端口: ${PORT})${NC}"
fi
