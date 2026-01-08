#!/bin/bash

# 构建脚本 - 生成多平台可执行文件
# 用户下载对应平台的二进制文件后，无需安装 Go、Node、Rust 等任何依赖即可运行

APP_NAME="proxy-server"
VERSION=${1:-"v1.0.0"}
BUILD_DIR="build"

echo "==== 开始构建 Proxy Server $VERSION ===="
echo ""

# 创建构建目录
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

# 需要打包的静态资源
STATIC_FILES=(
    "index.html"
    "vue.global.js"
    "config.json"
    "vendor"
)

echo "📦 准备静态资源..."

# 构建函数
build_for_platform() {
    local os=$1
    local arch=$2
    local ext=$3
    
    local output_name="${APP_NAME}-${os}-${arch}${ext}"
    local output_dir="${BUILD_DIR}/${APP_NAME}-${os}-${arch}"
    
    echo "🔨 正在构建: $os/$arch"
    
    # 编译
    GOOS=$os GOARCH=$arch go build -ldflags="-s -w" -o "${output_dir}/${APP_NAME}${ext}" main.go
    
    if [ $? -eq 0 ]; then
        # 复制静态资源
        for file in "${STATIC_FILES[@]}"; do
            if [ -e "$file" ]; then
                cp -r "$file" "${output_dir}/"
            fi
        done
        
        # 创建启动说明
        cat > "${output_dir}/README.txt" << EOF
Proxy Mock Server ${VERSION}
============================

快速启动：
1. 双击运行 ${APP_NAME}${ext}（或在终端执行：./${APP_NAME}${ext}）
2. 浏览器会自动打开 http://localhost:9292
3. 将您的设备代理设置为：机器IP:9292

无需安装任何依赖！

详细文档：https://github.com/mooniitt/proxy-server
EOF
        
        # 打包成压缩文件
        cd $BUILD_DIR
        if [[ "$os" == "windows" ]]; then
            zip -rq "${output_name}.zip" "${APP_NAME}-${os}-${arch}"
            echo "   ✅ ${output_name}.zip"
        else
            tar -czf "${output_name}.tar.gz" "${APP_NAME}-${os}-${arch}"
            echo "   ✅ ${output_name}.tar.gz"
        fi
        cd ..
    else
        echo "   ❌ 构建失败"
    fi
}

# 构建各平台版本
echo ""
echo "🚀 开始多平台构建..."
echo ""

# macOS
build_for_platform "darwin" "amd64" ""
build_for_platform "darwin" "arm64" ""

# Linux
build_for_platform "linux" "amd64" ""
build_for_platform "linux" "arm64" ""

# Windows
build_for_platform "windows" "amd64" ".exe"
build_for_platform "windows" "arm64" ".exe"

echo ""
echo "===================================="
echo "✨ 构建完成！"
echo "===================================="
echo ""
echo "📁 输出目录: $BUILD_DIR/"
echo ""
ls -lh $BUILD_DIR/*.{tar.gz,zip} 2>/dev/null | awk '{print "   " $9 " (" $5 ")"}'
echo ""
echo "📝 使用说明："
echo "   1. 将对应平台的压缩包发送给用户"
echo "   2. 用户解压后直接运行即可，无需安装任何依赖"
echo "   3. 支持平台：macOS (Intel/M1/M2), Linux (x64/ARM), Windows (x64/ARM)"
echo ""
