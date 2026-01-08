#!/bin/bash

APP_NAME="proxy-server"
LOG_FILE="server.log"
PORT="9292"
URL="http://localhost:$PORT"

echo "==== [$(date '+%Y-%m-%d %H:%M:%S')] 启动代理服务 ===="

# 0. 构建前端逻辑
BUILD_UI=false
if [ ! -d "dist" ]; then
    echo "⚠️  未检测到 dist 目录，准备构建前端..."
    BUILD_UI=true
fi

for arg in "$@"; do
    if [ "$arg" == "--build-ui" ]; then
        echo "🔄 用户请求强制重新构建 UI..."
        BUILD_UI=true
    fi
done

if [ "$BUILD_UI" = true ]; then
    if command -v npm >/dev/null 2>&1; then
        echo "📦 进入 dashboard 目录..."
        cd dashboard
        
        if [ ! -d "node_modules" ]; then
             echo "📦 node_modules 不存在，正在安装依赖 (npm install)..."
             npm install
             if [ $? -ne 0 ]; then
                 echo "❌ npm install 失败！"
                 exit 1
             fi
        fi

        echo "📦 正在构建前端 (npm run build)..."
        npm run build
        if [ $? -ne 0 ]; then
             echo "❌ 前端构建失败！"
             exit 1
        fi
        
        cd ..
        echo "✅ 前端构建成功"
    else
        echo "❌ 未找到 npm 命令！无法构建前端。请先安装 Node.js 或手动将构建好的 dist 目录放入根目录。"
        exit 1
    fi
fi

# 1. 检查是否已有进程在运行
PID=$(pgrep -f "./$APP_NAME")
if [ -n "$PID" ]; then
    echo "✓ 服务已在运行 (PID: $PID)"
else
    # 2. 检查二进制文件是否存在，不存在则编译
    if [ ! -f "./$APP_NAME" ]; then
        echo "正在编译..."
        go build -o $APP_NAME main.go
        if [ $? -ne 0 ]; then
            echo "❌ 编译失败，请检查代码错误！"
            exit 1
        fi
        echo "✅ 编译成功"
    fi

    # 3. 启动服务
    echo "正在启动服务..."
    nohup ./$APP_NAME > $LOG_FILE 2>&1 &
    sleep 2

    # 4. 确认服务已启动
    NEW_PID=$(pgrep -f "./$APP_NAME")
    if [ -n "$NEW_PID" ]; then
        echo "🚀 服务已启动！(PID: $NEW_PID)"
    else
        echo "❌ 启动失败，请查看 $LOG_FILE"
        exit 1
    fi
fi

# 5. 等待服务就绪
echo "等待服务就绪..."
for i in {1..10}; do
    if curl -s -o /dev/null -w "%{http_code}" $URL | grep -q "200"; then
        echo "✓ 服务已就绪"
        break
    fi
    sleep 0.5
done

# 6. 打开浏览器
echo "正在打开浏览器: $URL"
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    open $URL
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    xdg-open $URL 2>/dev/null || sensible-browser $URL 2>/dev/null || x-www-browser $URL 2>/dev/null
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    # Windows
    start $URL
else
    echo "⚠️  无法自动打开浏览器，请手动访问: $URL"
fi

echo "================================"
echo "🎉 完成！代理服务运行在: $URL"
echo "日志文件: $LOG_FILE"
echo "================================"
