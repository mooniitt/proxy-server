# 🔒 证书信任问题排查指南

## 问题：证书已安装但仍显示"您的连接不是私密连接"警告

### 📋 快速检查清单

- [ ] 证书已安装到**系统钥匙串**（不是登录钥匙串）
- [ ] 证书信任级别设置为**"始终信任"**
- [ ] **完全退出并重启浏览器**（不只是关闭标签页）
- [ ] 清除浏览器缓存和 Cookie
- [ ] 确认没有多个版本的证书冲突
- [ ] 确认安装的是最新的证书（如果重新生成过）

---

## 🔍 详细排查步骤

### 步骤 1：验证证书是否正确安装（macOS）

#### 1.1 检查证书是否存在

打开"钥匙串访问"应用，搜索 `Proxy Mock Root CA`：

```bash
# 在终端中检查
security find-certificate -a -c "Proxy Mock Root CA" -Z
```

应该能看到证书的 SHA-256 指纹。

#### 1.2 确认证书位置

**重要**：证书必须安装在**"系统"钥匙串**，而不是"登录"钥匙串！

1. 打开"钥匙串访问"
2. 在左侧选择**"系统"**（不是"登录"）
3. 在"类别"中选择"证书"
4. 搜索 `Proxy Mock Root CA`
5. 如果找不到，说明证书安装位置错误

#### 1.3 检查信任设置

1. 双击 `Proxy Mock Root CA` 证书
2. 展开"信任"部分
3. 确认"使用此证书时"设置为**"始终信任"**
4. 如果不是，修改后需要输入管理员密码

---

### 步骤 2：修复证书安装（macOS）

如果证书安装位置或信任设置不正确：

#### 方法 A：重新安装到系统钥匙串

1. **删除旧证书**（如果存在）：
   - 在钥匙串访问中找到 `Proxy Mock Root CA`
   - 右键 → 删除
   - 输入密码确认

2. **下载新证书**：
   ```bash
   curl -O http://localhost:9292/ca.crt
   ```

3. **安装到系统钥匙串**：
   ```bash
   sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ca.crt
   ```
   
   或者手动安装：
   - 双击 `ca.crt` 文件
   - 在钥匙串访问中选择**"系统"**（不是"登录"）
   - 点击"添加"
   - 双击证书，展开"信任"，设置为"始终信任"

#### 方法 B：使用钥匙串访问手动修复

1. 打开"钥匙串访问"
2. 如果证书在"登录"钥匙串中：
   - 找到证书，拖拽到"系统"钥匙串
   - 输入管理员密码
3. 双击证书，设置信任为"始终信任"

---

### 步骤 3：清除浏览器缓存

#### Chrome/Edge

1. 按 `Cmd+Shift+Delete` (macOS) 或 `Ctrl+Shift+Delete` (Windows)
2. 选择"全部时间"
3. 勾选：
   - ✅ Cookie 和其他网站数据
   - ✅ 缓存的图片和文件
4. 点击"清除数据"

#### Safari

1. Safari → 偏好设置 → 隐私
2. 点击"管理网站数据"
3. 点击"全部移除"
4. 或者针对特定网站清除：
   - 搜索 `ai.huadongxunshan.com`
   - 选择并删除

---

### 步骤 4：完全重启浏览器

**重要**：必须完全退出浏览器，不只是关闭窗口！

#### macOS

```bash
# 完全退出 Chrome
killall "Google Chrome"

# 完全退出 Safari
killall Safari

# 完全退出 Edge
killall "Microsoft Edge"
```

或者：
1. 右键点击 Dock 中的浏览器图标
2. 选择"退出"（不是关闭窗口）

#### Windows

1. 按 `Ctrl+Shift+Esc` 打开任务管理器
2. 找到浏览器进程
3. 右键 → 结束任务
4. 重新启动浏览器

---

### 步骤 5：验证证书是否生效

#### 方法 1：使用命令行验证

```bash
# macOS: 检查证书信任状态
security verify-cert -c ca.crt

# 应该显示: certificate verification successful
```

#### 方法 2：在浏览器中检查

1. 访问任意 HTTPS 网站（如 https://www.google.com）
2. 点击地址栏的锁图标
3. 查看证书信息
4. 应该能看到证书链中包含 `Proxy Mock Root CA`

#### 方法 3：检查特定网站

访问 `ai.huadongxunshan.com`：
- 如果仍然显示警告，继续下一步
- 如果正常，说明问题已解决

---

### 步骤 6：检查是否有多个证书冲突

可能安装了多个版本的证书：

1. 打开钥匙串访问
2. 搜索 `Proxy Mock`
3. 查看是否有多个证书
4. 如果有多个：
   - 删除所有旧证书
   - 重新下载并安装最新证书

---

### 步骤 7：重新生成证书（最后手段）

如果以上方法都不行，可能需要重新生成证书：

1. **访问管理后台**：http://localhost:9292
2. **点击"🔄 重生成 CA"**
3. **删除所有旧证书**：
   ```bash
   # macOS: 删除所有 Proxy Mock 证书
   security delete-certificate -c "Proxy Mock Root CA" /Library/Keychains/System.keychain
   ```
4. **下载新证书**：http://localhost:9292/ca.crt
5. **重新安装**（按照步骤 2）
6. **完全重启浏览器**

---

## 🐛 常见问题

### Q: 证书在"登录"钥匙串中，不在"系统"钥匙串

**A**: 这是最常见的问题！macOS 需要证书在"系统"钥匙串中才能被所有应用信任。

**解决**：
1. 在钥匙串访问中，将证书从"登录"拖拽到"系统"
2. 或使用命令行安装到系统钥匙串

### Q: 信任设置是"使用系统默认值"，不是"始终信任"

**A**: 需要手动设置为"始终信任"。

**解决**：
1. 双击证书
2. 展开"信任"
3. 将"使用此证书时"改为"始终信任"
4. 输入密码确认

### Q: 某些网站正常，某些网站仍然警告

**A**: 可能是浏览器缓存了特定网站的证书状态。

**解决**：
1. 清除该网站的 Cookie 和缓存
2. 使用隐私模式访问测试
3. 完全重启浏览器

### Q: 重启浏览器后仍然警告

**A**: 可能没有完全退出浏览器，或证书安装位置不对。

**解决**：
1. 使用 `killall` 命令强制退出浏览器
2. 确认证书在"系统"钥匙串中
3. 确认信任设置为"始终信任"

---

## ✅ 验证修复是否成功

修复后，应该：

1. ✅ 访问任意 HTTPS 网站不显示警告
2. ✅ 地址栏显示正常的锁图标 🔒
3. ✅ 点击锁图标能看到证书链包含 `Proxy Mock Root CA`
4. ✅ 访问 `ai.huadongxunshan.com` 不显示警告

---

## 📞 如果仍然无法解决

1. **检查代理服务器日志**：
   ```bash
   tail -f server.log
   ```
   查看是否有证书相关的错误

2. **检查浏览器控制台**：
   - 按 F12 打开开发者工具
   - 查看 Console 标签中的错误信息
   - 查看 Security 标签中的证书信息

3. **尝试其他浏览器**：
   - 如果 Chrome 不行，试试 Safari 或 Firefox
   - 确认是否是浏览器特定问题

4. **检查系统时间**：
   - 确保证书未过期
   - 确认系统时间正确

---

## 🔧 快速修复命令（macOS）

```bash
# 1. 删除旧证书
sudo security delete-certificate -c "Proxy Mock Root CA" /Library/Keychains/System.keychain 2>/dev/null

# 2. 下载新证书
curl -O http://localhost:9292/ca.crt

# 3. 安装到系统钥匙串并设置为信任
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ca.crt

# 4. 验证安装
security verify-cert -c ca.crt

# 5. 完全退出浏览器
killall "Google Chrome" 2>/dev/null
killall Safari 2>/dev/null
killall "Microsoft Edge" 2>/dev/null

# 6. 清理下载的证书文件
rm ca.crt
```

然后重新启动浏览器测试。
