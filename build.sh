#!/bin/bash

# ==========================================
# Proxy Mock Server 全平台构建脚本
# ==========================================

APP_NAME="proxy-server"
VERSION=${1:-"v1.0.0"}
BUILD_DIR="build_out"

echo "🚀 开始构建 Proxy Mock Server $VERSION ..."

# 确保在脚本所在目录执行
cd "$(dirname "$0")"

# 1. 清理旧产物
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 2. 构建前端 UI
echo "📦 正在构建前端 (ui)..."
cd ui
if [ ! -d "node_modules" ]; then
    npm install || exit 1
fi
npm run build || exit 1
cd ..

# 同步 dist 到根目录用于 Go 服务嵌入或读取


echo "✅ 前端构建完成。"

# 3. 定义需要打包的文件
ASSETS=("dist" "config.json" "README.md")

# 4. 构建函数
build_for_platform() {
    local os=$1
    local arch=$2
    local ext=$3
    
    local platform_name="${APP_NAME}-${os}-${arch}"
    local output_dir="${BUILD_DIR}/${platform_name}"
    
    echo "🔨 编译: $os/$arch ..."
    mkdir -p "$output_dir"
    
    # 编译 Go 后端
    GOOS=$os GOARCH=$arch go build -ldflags="-s -w" -o "${output_dir}/${APP_NAME}${ext}" main.go
    
    if [ $? -eq 0 ]; then
        # 复制资源
        for asset in "${ASSETS[@]}"; do
            if [ -e "$asset" ]; then
                cp -r "$asset" "$output_dir/"
            fi
        done
        
        # 压缩
        cd "$BUILD_DIR"
        if [ "$os" == "windows" ]; then
            zip -rq "${platform_name}.zip" "$platform_name"
        else
            tar -czf "${platform_name}.tar.gz" "$platform_name"
        fi
        rm -rf "$platform_name"
        cd ..
        echo "   ✅ 完成: ${platform_name}"
    else
        echo "   ❌ 失败: $os/$arch"
    fi
}

# 5. 执行多平台构建
echo "📂 开始多平台打包..."

# macOS
build_for_platform "darwin" "amd64" ""
build_for_platform "darwin" "arm64" ""

# Linux
build_for_platform "linux" "amd64" ""
build_for_platform "linux" "arm64" ""

# Windows
build_for_platform "windows" "amd64" ".exe"

echo ""
echo "===================================="
echo "✨ 构建成功！产物位于: $BUILD_DIR/"
echo "===================================="
ls -lh "$BUILD_DIR/"
