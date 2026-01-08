# 📦 如何创建 Releases 压缩包

## 方式一：手动创建（本地构建）

### 1. 使用构建脚本

运行构建脚本，会自动生成所有平台的压缩包：

```bash
./build.sh v1.0.0
```

这会在 `build/` 目录下生成以下文件：
- `proxy-server-darwin-amd64.tar.gz` (macOS Intel)
- `proxy-server-darwin-arm64.tar.gz` (macOS Apple Silicon)  
- `proxy-server-linux-amd64.tar.gz` (Linux x64)
- `proxy-server-linux-arm64.tar.gz` (Linux ARM64)
- `proxy-server-windows-amd64.zip` (Windows x64)
- `proxy-server-windows-arm64.zip` (Windows ARM64)

### 2. 创建 GitHub Release

1. 访问 https://github.com/mooniitt/proxy-server/releases/new

2. 选择或创建标签（如 `v1.0.0`）

3. 填写 Release 标题和说明：
   ```
   ## Proxy Mock Server v1.0.0
   
   ### 📦 下载
   请根据您的操作系统下载对应的压缩包：
   
   - **macOS (Intel)**: `proxy-server-darwin-amd64.tar.gz`
   - **macOS (Apple Silicon)**: `proxy-server-darwin-arm64.tar.gz`
   - **Linux (x64)**: `proxy-server-linux-amd64.tar.gz`
   - **Linux (ARM64)**: `proxy-server-linux-arm64.tar.gz`
   - **Windows (x64)**: `proxy-server-windows-amd64.zip`
   - **Windows (ARM64)**: `proxy-server-windows-arm64.zip`
   
   ### 🚀 快速开始
   1. 解压下载的压缩包
   2. 双击运行 `proxy-server`（Windows 为 `proxy-server.exe`）
   3. 浏览器会自动打开 http://localhost:9292
   ```

4. 将 `build/` 目录下的所有压缩包拖拽到 "Attach binaries" 区域

5. 点击 "Publish release"

---

## 方式二：自动化创建（推荐）✨

使用 GitHub Actions 自动构建和发布，**无需本地操作**！

### 步骤 1：推送 Tag 触发发布

```bash
# 1. 提交代码
git add .
git commit -m "Release v1.0.0"

# 2. 创建并推送 tag
git tag v1.0.0
git push origin main
git push origin v1.0.0
```

GitHub Actions 会自动：
- ✅ 构建所有平台的可执行文件
- ✅ 打包静态资源
- ✅ 创建 GitHub Release
- ✅ 上传所有平台的压缩包

### 步骤 2：手动触发（可选）

如果你想在不创建 tag 的情况下测试构建：

1. 访问 https://github.com/mooniitt/proxy-server/actions
2. 选择 "Build and Release" 工作流
3. 点击 "Run workflow"
4. 输入版本号（如 `v1.0.0`）
5. 点击 "Run workflow"

---

## 验证构建结果

构建完成后，检查每个压缩包是否包含：

```
proxy-server-{os}-{arch}/
├── proxy-server[.exe]    # 可执行文件
├── index.html            # 前端页面
├── vue.global.js         # 前端框架库
├── vendor/               # Ace Editor 等静态资源
│   └── ace/
│       ├── ace.js
│       └── ...
├── config.json           # 配置文件（可选）
└── README.txt            # 使用说明
```

---

## 注意事项

1. **版本号格式**：建议使用语义化版本号（如 `v1.0.0`, `v1.1.0`, `v2.0.0`）

2. **静态资源**：确保 `index.html`, `vue.global.js`, `vendor/` 目录都在项目根目录

3. **配置文件**：`config.json` 是可选的，如果不存在会使用默认配置

4. **测试**：在发布前，建议在对应平台上测试一下可执行文件是否正常工作

---

## 常见问题

**Q: 构建失败怎么办？**  
A: 检查 Go 版本是否 >= 1.16，确保所有静态资源文件存在。

**Q: 如何在本地测试构建结果？**  
A: 解压对应平台的压缩包，运行可执行文件，访问 http://localhost:9292 验证。

**Q: 可以只构建特定平台吗？**  
A: 可以修改 `build.sh` 脚本，注释掉不需要的平台构建函数。
