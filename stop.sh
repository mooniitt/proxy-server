#!/bin/bash

APP_NAME="proxy-server"
LOG_FILE="server.log"

echo "==== [$(date '+%Y-%m-%d %H:%M:%S')] 正在停止代理服务 ===="

# 查找 PID
PID=$(pgrep -f "./$APP_NAME")

if [ -z "$PID" ]; then
    echo "⚠️  未发现正在运行的服务 ($APP_NAME)"
    exit 0
fi

echo "🔍 发现服务运行中，PID: $PID"
echo "正在尝试停止服务..."

# 尝试优雅关闭
kill $PID

# 等待进程结束
for i in {1..5}; do
    if ! kill -0 $PID 2>/dev/null; then
        echo "✅ 服务已成功停止"
        exit 0
    fi
    sleep 1
done

# 如果还在运行，尝试强制关闭
if kill -0 $PID 2>/dev/null; then
    echo "⚠️  服务未响应，正在强制关闭 (kill -9)..."
    kill -9 $PID
    sleep 1
    
    if ! kill -0 $PID 2>/dev/null; then
        echo "✅ 服务已强制停止"
    else
        echo "❌ 无法停止服务，请手动检查系统进程 (PID: $PID)"
        exit 1
    fi
else
    echo "✅ 服务已成功停止"
fi
