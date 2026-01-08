# Proxy Mock Server ⚡

一个轻量级、高性能的 Go 编写的 MITM (中间人) 代理服务器，专为 API 开发和调试设计。

## 核心功能

- **HTTP/HTTPS 代理**：支持全协议代理。
- **MITM 解密**：自动生成证书，实时查看 HTTPS 流量。
- **API Mocking**：通过正则、精确匹配或前缀匹配拦截并篡改 API 返回。
- **现代化 UI**：内置 Vue 3 后台，支持实时流量监控、规则管理、证书重置等。
- **自动保存**：所有规则改动即时生效，无需重启。
- **零依赖部署**：单一可执行文件，无需 Node.js、npm 或其他运行时。

## 技术架构

- **后端**：Go 语言（单一可执行文件）
- **前端**：Vue 3 (CDN) + Ace Editor
- **部署**：开箱即用，无需安装任何依赖
- **配置**：JSON 文件存储，实时热重载

## 环境要求

### 💡 零依赖运行（推荐给用户）

用户可以直接下载预编译的二进制文件运行：

1. 从 [Releases](https://github.com/mooniitt/proxy-server/releases) 下载对应平台的压缩包
2. 解压后双击运行或执行 `./proxy-server`
3. 浏览器自动打开管理界面

支持平台：
- ✅ macOS (Intel / Apple Silicon)
- ✅ Linux (x64 / ARM64)
- ✅ Windows (x64 / ARM64)

### 开发环境

如果你需要修改代码或从源码构建：
- [Go 1.16+](https://golang.google.cn/doc/install)

前端使用 CDN 版本的 Vue 3，无需 Node.js 环境。

---

## 快速开始

### 1. 运行服务

#### 方式一：一键启动（推荐）✨
在项目根目录运行，自动启动服务并打开浏览器：
```bash
./run.sh
```

或使用 bin 命令：
```bash
./bin/proxy-server
```

**特性**：
- ✅ 自动检查服务状态，避免重复启动
- ✅ 自动编译（如需要）
- ✅ 后台运行，日志输出到 `server.log`
- ✅ 自动打开浏览器访问管理后台
- ✅ 跨平台支持（macOS/Linux/Windows）

#### 方式二：开发模式
适合频繁修改代码时使用：
```bash
./pg.sh run
```

#### 方式三：重启服务
修改代码后需要重启：
```bash
./restart.sh
```

服务默认运行在 `:9292` 端口。

### 2. 管理后台
服务启动后会自动打开浏览器，或手动访问 [http://localhost:9292](http://localhost:9292)。

### 3. 设置代理
将您的设备（手机或浏览器）代理设置为：
- **IP**: 您的机器 IP（在管理后台顶部可以看到）
- **端口**: `9292`

### 4. 全局命令（可选）
如果希望在任何目录都能使用 `proxy-server` 命令，可以将 bin 目录添加到 PATH：

```bash
# 添加到 ~/.zshrc 或 ~/.bash_profile
echo 'export PATH="$PATH:/Users/mit-xl/code/proxy-server/bin"' >> ~/.zshrc
source ~/.zshrc
```

之后就可以在任何位置运行：
```bash
proxy-server
```

---

## 构建与分发

### 一键构建所有平台（推荐）

使用自动化构建脚本，一次性生成所有平台的可分发包：

```bash
./build.sh v1.0.0
```

这会在 `build/` 目录生成以下压缩包：
- `proxy-server-darwin-amd64.tar.gz` (macOS Intel)
- `proxy-server-darwin-arm64.tar.gz` (macOS Apple Silicon)
- `proxy-server-linux-amd64.tar.gz` (Linux x64)
- `proxy-server-linux-arm64.tar.gz` (Linux ARM64)
- `proxy-server-windows-amd64.zip` (Windows x64)
- `proxy-server-windows-arm64.zip` (Windows ARM64)

每个压缩包包含：
- ✅ 可执行文件（无需任何依赖）
- ✅ 所有静态资源（HTML、JS、CSS）
- ✅ 使用说明

**用户只需解压后直接运行，零依赖！**

### 创建 GitHub Releases

#### 方式一：自动化发布（推荐）✨

使用 GitHub Actions 自动构建和发布：

```bash
# 1. 创建并推送 tag
git tag v1.0.0
git push origin main
git push origin v1.0.0
```

GitHub Actions 会自动构建所有平台并创建 Release。

#### 方式二：手动构建

```bash
# 1. 本地构建所有平台
./build.sh v1.0.0

# 2. 在 GitHub 上创建 Release
# 访问 https://github.com/mooniitt/proxy-server/releases/new
# 上传 build/ 目录下的所有压缩包
```

📖 **详细说明**：查看 [RELEASE.md](./RELEASE.md) 了解完整的发布流程。

### 手动编译单个平台

#### 编译为当前操作系统
```bash
go build -o proxy-server main.go
```

#### 跨平台编译
```bash
# Windows
GOOS=windows GOARCH=amd64 go build -o proxy-server.exe main.go

# macOS (Intel)
GOOS=darwin GOARCH=amd64 go build -o proxy-server-macos main.go

# macOS (Apple Silicon)
GOOS=darwin GOARCH=arm64 go build -o proxy-server-macos-arm64 main.go

# Linux
GOOS=linux GOARCH=amd64 go build -o proxy-server-linux main.go
```

### 通过 Homebrew 安装 (macOS/Linux)

1.  **准备 Formula**:
    *   将项目根目录下的 `proxy-server.rb` 文件放置到您自己的 Homebrew Tap 仓库中 (例如 `your-github-user/homebrew-tap`)。
    *   编辑 `proxy-server.rb`，将 `homepage`, `url` 和 `sha256` 替换为您的项目信息和发布存档的实际值。`sha256` 可以通过 `curl -L <url_to_archive> | shasum -a 256` 命令获取。
2.  **添加 Tap 并安装**:
    ```bash
    brew tap your-github-user/tap # 替换为您的 tap 名称
    brew install proxy-server
    ```
3.  **启动服务**:
    ```bash
    proxy-server # 直接运行二进制文件
    ```

> `pg.sh` 脚本适用于 Unix-like 系统 (macOS/Linux)，主要用于开发过程中便捷地停止、重建并重启服务。

---

## HTTPS 证书安装指南

### ⚠️ 重要提示：为什么会出现"您的连接不是私密连接"警告？

**这是正常现象！** 代理服务器使用 MITM（中间人）技术来解密 HTTPS 流量，以便进行 Mock 和流量监控。浏览器会显示安全警告，因为：

1. 代理服务器会为每个 HTTPS 网站生成一个证书
2. 浏览器默认不信任这些证书
3. **解决方法**：安装并信任代理服务器的 CA 根证书

安装证书后，浏览器就会信任代理生成的所有证书，警告就会消失。

---

### 📥 如何安装证书

#### 方式一：通过管理后台下载（推荐）

1. 访问代理管理后台：http://localhost:9292
2. 点击顶部 **📥 下载 CA 证书** 按钮
3. 按照下面的步骤安装证书

#### 方式二：直接访问证书 URL

在浏览器中访问：`http://localhost:9292/ca.crt`（或 `http://<你的IP>:9292/ca.crt`）

---

### 💻 桌面端安装步骤

#### macOS (Safari/Chrome)

1. **下载证书**：访问 http://localhost:9292/ca.crt
2. **打开钥匙串访问**：
   - 双击下载的 `ca.crt` 文件
   - 或手动打开"钥匙串访问"应用
3. **导入证书**：
   - 在钥匙串访问中找到 `Proxy Mock Root CA`
   - 双击打开证书详情
   - 展开"信任"选项
   - 将"使用此证书时"设置为"始终信任"
4. **输入密码**：需要输入 macOS 管理员密码确认

#### Windows (Chrome/Edge)

1. **下载证书**：访问 http://localhost:9292/ca.crt
2. **安装证书**：
   - 双击 `ca.crt` 文件
   - 选择"安装证书"
   - 选择"当前用户"或"本地计算机"
   - 点击"下一步"
3. **选择存储位置**：
   - 选择"将所有证书都放入下列存储"
   - 点击"浏览"
   - 选择"受信任的根证书颁发机构"
   - 点击"确定" → "下一步" → "完成"
4. **确认安装**：会弹出安全警告，点击"是"确认

#### Linux (Chrome/Firefox)

**Chrome/Chromium:**
```bash
# 下载证书
wget http://localhost:9292/ca.crt

# 安装到系统证书存储
sudo cp ca.crt /usr/local/share/ca-certificates/proxy-mock-ca.crt
sudo update-ca-certificates
```

**Firefox:**
1. 打开 Firefox 设置 → 隐私与安全
2. 滚动到底部，点击"查看证书"
3. 选择"证书颁发机构"标签
4. 点击"导入"
5. 选择下载的 `ca.crt` 文件
6. 勾选"信任此 CA 以标识网站"
7. 点击"确定"

---

### 📱 移动端安装步骤

#### iOS

1. **下载证书**：
   - 在 Safari 中访问 `http://<代理IP>:9292/ca.crt`
   - 点击下载链接
   - 系统会提示"已下载描述文件"
2. **安装证书**：
   - 打开"设置" → "已下载描述文件"
   - 点击"Proxy Mock Root CA"
   - 点击"安装"
   - 输入设备密码确认
3. **⚠️ 关键步骤 - 启用信任**：
   - 打开"设置" → "通用" → "关于本机"
   - 滚动到底部，点击"证书信任设置"
   - 找到 `Proxy Mock Root CA`
   - **勾选开关启用信任**
   - 点击"继续"确认

#### Android

1. **下载证书**：
   - 在浏览器中访问 `http://<代理IP>:9292/ca.crt`
   - 下载证书文件
2. **安装证书**：
   - 打开"设置" → "安全" → "更多安全设置"
   - 点击"加密和凭据" → "从存储盘安装"
   - 选择下载的 `ca.crt` 文件
   - 输入证书名称（如：Proxy Mock CA）
   - 点击"确定"安装

---

### ✅ 验证证书是否安装成功

安装证书后：

1. **重启浏览器**（重要！）
2. 访问任意 HTTPS 网站（如 https://www.google.com）
3. **应该不再显示安全警告**
4. 地址栏应该显示正常的锁图标 🔒

如果仍然显示警告：
- 确认证书已正确安装到"受信任的根证书颁发机构"
- 确认已重启浏览器
- 尝试清除浏览器缓存和 Cookie
- 检查代理服务器的 CA 证书是否已重新生成（如果重新生成，需要重新安装）

---

### 🔄 重新生成 CA 证书

如果需要重新生成 CA 证书（例如：证书泄露或需要重置）：

1. 访问管理后台：http://localhost:9292
2. 点击 **🔄 重生成 CA** 按钮
3. **重要**：所有已安装旧证书的设备需要重新下载并安装新证书
4. 旧证书将失效，需要重新安装

---

## Mock 规则说明

1. **匹配方式**:
   - **正则匹配 (Regex)**: 使用强大的正则表达式匹配完整 URL。
   - **精确匹配 (Exact)**: URL 必须完全一致。
   - **前缀匹配 (Prefix)**: 匹配以特定字符开头的 URL。
2. **响应配置**:
   - 可自定义 HTTP 状态码（如 200, 404, 500）。
   - 支持自定义响应头（Headers）和响应体（JSON/Text）。

---

## 故障排除

### ⚠️ 出现"您的连接不是私密连接"警告？

**这是正常现象！** 代理服务器使用 MITM 技术解密 HTTPS 流量，浏览器会显示安全警告。

**解决方法**：
1. 访问 http://localhost:9292 下载 CA 证书
2. 安装并信任证书（详见上面的"HTTPS 证书安装指南"）
3. 重启浏览器
4. 警告应该消失

**如果安装证书后仍然显示警告**：
- 确认证书已安装到"受信任的根证书颁发机构"
- 确认已重启浏览器
- 检查是否安装了多个版本的证书（删除旧的）
- 尝试清除浏览器缓存

### 接口"消失"了？
- 确保证书已正确安装并开启**完全信任**。
- 确认没被 `sign` 签名算法拦截（代理会自动透传 Content-Length 和 Host）。
- 检查后台的"流量监控"标签，确认请求是否已到达代理。

### 控制台报错证书错误？
- 点击后台顶部的 **🔄 重生成 CA**，重新下载并安装新证书。
- 如果重新生成了证书，所有设备都需要重新安装新证书。