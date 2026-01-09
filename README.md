# Proxy Mock Server ⚡

一个轻量级、高性能的 Go 编写的 MITM (中间人) 代理服务器，配备现代化 Vue 3 管理后台，专为 API 开发和调试设计。

![alt text](https://youke3.picui.cn/s1/2026/01/09/6960a04482baf.png)

## 核心功能

- **🚀 炫酷开场**：内置品牌感十足的字母入场动画。
- **HTTP/HTTPS 代理**：支持全协议代理，稳定可靠。
- **MITM 解密**：自动生成 CA 证书，实时查看并拦截 HTTPS 流量。
- **API Mocking**：支持正则、精确、前缀匹配，可篡改状态码、Header 及 Body。
- **工程化 UI**：基于 Vue 3 + Vite + Ace Editor 的高性能管理后台。
- **自动保存**：规则改动即时生效，支持配置导入导出。

---

## 🛠 技术架构

- **后端**: Go (Golang) - 处理高性能代理逻辑及 API 接口。
- **前端**: Vue 3 + Vite + Tailwind/Custom CSS - 响应式管理后台。
- **编辑器**: Ace Editor - 提供丝滑的代码编辑体验。
- **构建**: 支持一键打包，将前端资源静态嵌入或由 Go 服务托管。

---

## ⏱ 快速开始

### 1. 环境准备

- **Go**: 1.18+ (运行/编译后端)
- **Node.js**: 16+ (构建前端 UI)

### 2. 一键启动

项目提供了一个强大的 `proxy` 调度脚本，建议使用：

```bash
# 赋予执行权限
chmod +x proxy run.sh stop.sh

# 启动服务 (首次运行会自动安装依赖并构建 UI)
./proxy run

# 重启服务
./proxy restart

# 停止服务
./proxy stop

# 强制重新构建 UI 并启动
./proxy build

# 查看实时日志
./proxy log
```

服务默认运行在 `http://localhost:9292`。

---

## 👨‍💻 开发指南

### 前端开发 (Vue 3)

如果您想修改管理后台界面：

```bash
cd dashboard
npm install
npm run dev
```

访问 `http://localhost:5173`。开发服务器已配置代理，会自动将 `/api` 请求转发至 `:9292` 的 Go 后端。

### 后端开发 (Go)

```bash
# 直接运行后端
go run main.go
```

### 生产打包

修改完前端代码后，需要打包供 Go 服务托管：

```bash
./proxy build
```

这会生成 `dist/` 目录，Go 服务会自动从中读取静态资源。

---

## 📥 HTTPS 证书安装指南

> **重要**：要拦截 HTTPS 流量，必须安装并信任生成的根证书。

1. 访问管理后台 `http://localhost:9292`。
2. 点击顶部 **📥 下载 CA 证书**。
3. **安装与信任**：
   - **macOS**: 双击证书 -> 钥匙串访问 -> 找到 `Proxy Mock Root CA` -> 右键简介 -> **始终信任**。
   - **iOS**: 设置 -> 已下载描述文件 -> 安装；然后到 **关于本机 -> 证书信任设置 -> 开启开关**。
   - **Android**: 设置 -> 安全 -> 加密和凭据 -> 从存储盘安装。
   - **Windows**: 安装至“受信任的根证书颁发机构”。

---

## 故障排除

- **UI 无法显示**: 确保运行了 `./proxy build` 生成了 `dist` 目录。
- **HTTPS 拦截失败**: 请检查证书是否已在系统中开启“始终信任”/“完全信任”。
- **端口冲突**: 确保 `9292` 端口未被占用。

---

## License

MIT

## 欢迎通过一下方式直接提需求改进

![alt text](https://youke3.picui.cn/s1/2026/01/09/69609f9213e8c.jpg)
