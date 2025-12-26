#!/bin/bash

APP_NAME="proxy-server"
LOG_FILE="server.log"

# Function to display usage
usage() {
    echo "Usage: pg <command>"
    echo ""
    echo "Commands:"
    echo "  run    Builds and runs the proxy server"
    exit 1
}

# Parse command
if [ "$#" -eq 0 ]; then
    usage
fi

COMMAND="$1"
shift # Remove the command from the arguments list

case "$COMMAND" in
    run)
        echo "==== [$(date '+%Y-%m-%d %H:%M:%S')] 开始运行服务 ===="

        # 1. 查找并停止旧进程
        PID=$(pgrep -f "./$APP_NAME")
        if [ -n "$PID" ]; then
            echo "停止现有进程 (PID: $PID)..."
            kill $PID
            sleep 1
            # 强制检查是否停止
            if pgrep -f "./$APP_NAME" > /dev/null; then
                echo "进程未响应，正在强制结束..."
                kill -9 $PID
            fi
        else
            echo "未发现运行中的 $APP_NAME 进程。"
        fi

        # 2. 重新编译打包
        echo "正在重新打包..."
        go build -o $APP_NAME main.go
        if [ $? -ne 0 ]; then
            echo "❌ 编译失败，请检查代码错误！"
            exit 1
        fi
        echo "✅ 编译成功。"

        # 3. 启动服务
        echo "正在启动服务并在后台运行..."
        nohup ./$APP_NAME > $LOG_FILE 2>&1 &
        sleep 1

        # 4. 确认状态
        NEW_PID=$(pgrep -f "./$APP_NAME")
        if [ -n "$NEW_PID" ]; then
            echo "🚀 服务已启动！"
            echo "新进程 PID: $NEW_PID"
            echo "日志正在输出到: $LOG_FILE"
            echo "--------------------------------"
            tail -n 5 $LOG_FILE
        else
            echo "❌ 启动失败，请查看 $LOG_FILE。"
            exit 1
        fi
        ;;
    *)
        echo "未知命令: $COMMAND"
        usage
        ;;
esac