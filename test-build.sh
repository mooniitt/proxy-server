#!/bin/bash

# 测试构建脚本的逻辑（不实际编译，只测试流程）

echo "🧪 测试构建脚本逻辑..."
echo ""

# 检查必要的文件是否存在
echo "📋 检查必要文件..."
FILES=("main.go" "index.html" "vue.global.js" "vendor" "build.sh")
for file in "${FILES[@]}"; do
    if [ -e "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file (缺失)"
    fi
done

echo ""
echo "📝 检查构建脚本语法..."
if bash -n build.sh; then
    echo "   ✅ build.sh 语法正确"
else
    echo "   ❌ build.sh 语法错误"
    exit 1
fi

echo ""
echo "🔍 验证静态资源..."
STATIC_FILES=("index.html" "vue.global.js" "vendor")
for file in "${STATIC_FILES[@]}"; do
    if [ -e "$file" ]; then
        echo "   ✅ $file 存在"
        if [ -d "$file" ]; then
            echo "      类型: 目录"
            file_count=$(find "$file" -type f 2>/dev/null | wc -l | tr -d ' ')
            echo "      包含文件数: $file_count"
        else
            size=$(ls -lh "$file" | awk '{print $5}')
            echo "      大小: $size"
        fi
    else
        echo "   ⚠️  $file 不存在（构建时会跳过）"
    fi
done

echo ""
echo "📦 验证构建函数参数..."
echo "   测试构建函数调用格式..."
# 模拟构建函数调用
for os in darwin linux windows; do
    for arch in amd64 arm64; do
        ext=""
        if [ "$os" == "windows" ]; then
            ext=".exe"
        fi
        echo "   - $os/$arch: proxy-server${ext}"
    done
done

echo ""
echo "✅ 所有检查完成！"
echo ""
echo "💡 提示："
echo "   - 实际构建请运行: ./build.sh v1.0.0"
echo "   - 由于沙盒限制，本地测试可能无法完整编译"
echo "   - 建议在 GitHub Actions 中测试完整构建流程"
