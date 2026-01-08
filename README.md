# Proxy Mock Server ⚡

一个轻量级、高性能的 Go 编写的 MITM (中间人) 代理服务器，专为 API 开发和调试设计。

## 核心功能

- **HTTP/HTTPS 代理**：支持全协议代理。
- **MITM 解密**：自动生成证书，实时查看 HTTPS 流量。
- **API Mocking**：通过正则、精确匹配或前缀匹配拦截并篡改 API 返回。
- **现代化 UI**：内置 Vue 3 后台，支持实时流量监控、规则管理、证书重置等。
- **自动保存**：所有规则改动即时生效，无需重启。

## 环境要求

- [Go 1.16+](https://golang.google.cn/doc/install)

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

## 构建 (Build)

您可以编译为当前系统或跨平台的可执行文件。

### 编译为当前操作系统
```bash
go build -o proxy-server main.go
```
然后运行：`./proxy-server` (macOS/Linux) 或 `proxy-server.exe` (Windows)。

### 跨平台编译
例如，为 Windows 编译：
```bash
GOOS=windows GOARCH=amd64 go build -o proxy-server.exe main.go
```
为 macOS 编译：
```bash
GOOS=darwin GOARCH=amd64 go build -o proxy-server-macos main.go
```
为 Linux 编译：
```bash
GOOS=linux GOARCH=amd64 go build -o proxy-server-linux main.go
```
更多 `GOOS` 和 `GOARCH` 组合请参考 Go 官方文档。

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

若要解密 HTTPS 流量，必须安装并信任根证书：

### 移动端 (iOS/Android)
1. 在设备浏览器访问 `http://<IP>:9292/ca.crt` 下载证书。
2. **iOS**:
   - 设置 -> 已下载描述文件 -> 安装。
   - **关键步骤**: 设置 -> 通用 -> 关于本机 -> 证书信任设置 -> 勾选 `Proxy Mock Root CA`。
3. **Android**:
   - 设置 -> 安全 -> 更多安全设置 -> 加密和凭据 -> 从存储盘安装 -> 选择 `ca.crt`。

### 桌面端 (Chrome/macOS)
1. 点击后台顶部的 **📥 下载 CA 证书**。
2. 打开 Chrome 设置 -> 隐私和安全 -> 安全 -> 管理证书 -> 导入。
3. 选择“始终信任”。

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

### 接口“消失”了？
- 确保证书已正确安装并开启**完全信任**。
- 确认没被 `sign` 签名算法拦截（代理会自动透传 Content-Length 和 Host）。
- 检查后台的“流量监控”标签，确认请求是否已到达代理。

### 控制台报错证书错误？
- 点击后台顶部的 **🔄 重生成 CA**，重新下载并安装新证书。
