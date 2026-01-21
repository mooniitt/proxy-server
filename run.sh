#!/bin/bash

# ==========================================
# Proxy Mock Server 统一启动脚本
# ==========================================

APP_NAME="proxy-server"
LOG_FILE="server.log"
PORT="9292"
URL="http://localhost:$PORT"

# 确保在脚本所在目录执行
cd "$(dirname "$0")"

# 帮助信息
usage() {
    echo "用法: $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  (默认)        构建 UI (如果不存在) 并启动服务"
    echo "  stop          停止正在运行的服务"
    echo "  restart       重启服务"
    echo ""
    echo "选项:"
    echo "  --build-ui    强制重新构建前端 UI"
    echo "  --tauri       启动服务并运行 Tauri 客户端"
    echo "  -h, --help    显示帮助信息"
    echo ""
    exit 0
}

# 检查必要工具
check_requirements() {
    local missing=0
    if ! command -v go >/dev/null 2>&1; then echo "❌ 错误: 未安装 Go"; missing=1; fi
    if ! command -v npm >/dev/null 2>&1; then echo "❌ 错误: 未安装 Node.js/npm"; missing=1; fi
    
    if [ $missing -eq 1 ]; then
        echo "请安装必要工具后再试。"
        exit 1
    fi
}

# 停止服务
stop_service() {
    local pid=$(pgrep -f "./$APP_NAME")
    if [ -z "$pid" ]; then
        echo "ℹ️  未检测到正在运行的服务。"
    else
        echo "🛑 正在停止服务 (PID: $pid)..."
        kill $pid
        sleep 1
        if pgrep -f "./$APP_NAME" >/dev/null; then
            echo "⚠️  进程未退出，强制杀掉..."
            kill -9 $pid
        fi
        echo "✅ 服务已停止。"
    fi
}

# 检查端口占用
check_port() {
    if command -v lsof >/dev/null 2>&1; then
        if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null; then
            local p_info=$(lsof -i :$PORT | grep LISTEN)
            echo "❌ 错误: 端口 $PORT 已被占用！"
            echo "$p_info"
            echo "请运行 '$0 stop' 或手动释放端口。"
            exit 1
        fi
    fi
}

# 构建前端
build_frontend() {
    echo "📦 正在构建前端 (ui)..."
    cd ui
    if [ ! -d "node_modules" ]; then
        echo "📥 正在安装依赖 (npm install)..."
        npm install || exit 1
    fi
    npm run build || exit 1
    cd ..
    
    echo "✅ 前端构建完成。"
}

# 解析参数
BUILD_UI=false
USE_TAURI=false
COMMAND="run"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        --build-ui) BUILD_UI=true; shift ;;
        --tauri) USE_TAURI=true; shift ;;
        stop) COMMAND="stop"; shift ;;
        restart) COMMAND="restart"; shift ;;
        *) shift ;;
    esac
done

# 执行命令
case $COMMAND in
    stop)
        stop_service
        exit 0
        ;;
    restart)
        stop_service
        # 重启时不强制 rebuild UI，除非显式指定
        ;;
esac

# 正常启动流程
echo "==== [$(date '+%Y-%m-%d %H:%M:%S')] 准备启动代理服务 ===="

# 1. 环境检查
check_requirements
check_port

# 2. UI 处理
if [ ! -d "dist" ] || [ "$BUILD_UI" = true ]; then
    build_frontend
fi

# 3. 编译 Go 服务
if [ ! -f "./$APP_NAME" ]; then
    echo "🔨 编译 Go 服务..."
    go build -o $APP_NAME main.go || exit 1
    echo "✅ 编译成功。"
fi

# 4. 启动服务
echo "🚀 启动服务并重定向日志到 $LOG_FILE..."
nohup ./$APP_NAME > $LOG_FILE 2>&1 &
sleep 2

# 确认启动结果
PID=$(pgrep -f "./$APP_NAME")
if [ -z "$PID" ]; then
    echo "❌ 启动失败，请检查 $LOG_FILE"
    exit 1
fi
echo "✓ 进程运行中 (PID: $PID)"

# 5. 等待服务就绪
echo "⏳ 等待服务响应..."
for i in {1..20}; do
    if curl -s -o /dev/null -w "%{http_code}" $URL | grep -q "200"; then
        echo "✅ 服务已就绪！"
        break
    fi
    sleep 0.5
done

# 6. 启动客户端
if [ "$USE_TAURI" = true ]; then
    echo "🖥️  正在启动 Tauri 客户端..."
    npm --prefix ui run tauri dev -- --config ../tauri/tauri.conf.json >/dev/null 2>&1 &
else
    echo "🌐 正在打开浏览器: $URL"
    if [[ "$OSTYPE" == "darwin"* ]]; then open $URL
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then xdg-open $URL 2>/dev/null || sensible-browser $URL
    elif [[ "$OSTYPE" == "msys" ]]; then start $URL
    fi
fi

echo "================================"
echo "🎉 所有组件已启动"
echo "👉 后端 API: $URL"
echo "📝 日志文件: tail -f $LOG_FILE"
echo "================================"

