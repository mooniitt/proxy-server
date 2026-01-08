# 🔍 GitHub Actions 触发问题排查指南

## ✅ 已修复的问题

1. **Tag 匹配模式过于严格**
   - 原：`'v*.*.*'` 只匹配 `v1.0.0` 格式
   - 修复后：`'v*'` 匹配所有以 `v` 开头的 tag

## 📋 排查步骤

### 1. 确认工作流文件已推送到 GitHub

```bash
# 检查工作流文件是否存在
ls -la .github/workflows/

# 应该看到：
# - release.yml
# - test.yml (用于测试)

# 提交并推送
git add .github/workflows/
git commit -m "Add GitHub Actions workflows"
git push origin main
```

### 2. 验证工作流文件语法

访问 GitHub 仓库：
1. 进入 https://github.com/mooniitt/proxy-server
2. 点击 "Actions" 标签
3. 如果工作流文件有语法错误，会显示红色警告

### 3. 测试工作流是否加载

**方式一：使用测试工作流**

我已经创建了一个测试工作流 (`test.yml`)，推送到 main 分支后会自动触发：

```bash
git add .github/workflows/test.yml
git commit -m "Add test workflow"
git push origin main
```

然后访问：https://github.com/mooniitt/proxy-server/actions

应该能看到 "Test Workflow" 运行。

**方式二：手动触发**

1. 访问 https://github.com/mooniitt/proxy-server/actions
2. 选择 "Build and Release" 工作流
3. 点击右侧 "Run workflow" 按钮
4. 输入版本号（如 `v1.0.0`）
5. 点击绿色 "Run workflow" 按钮

### 4. 通过 Tag 触发

如果使用 tag 触发，确保：

```bash
# 1. 创建 tag（确保格式正确）
git tag v1.0.0

# 2. 推送 tag（注意：需要单独推送 tag）
git push origin v1.0.0

# 或者推送所有 tag
git push --tags
```

⚠️ **重要**：只推送代码不会触发 tag 触发的工作流，必须单独推送 tag！

### 5. 检查权限设置

确保仓库允许 GitHub Actions：
1. 进入仓库 Settings
2. 点击 "Actions" → "General"
3. 确认 "Allow all actions and reusable workflows" 已启用
4. 确认工作流权限设置为 "Read and write permissions"

### 6. 查看工作流运行历史

访问：https://github.com/mooniitt/proxy-server/actions

如果工作流从未运行过：
- ❌ 工作流文件可能没有推送
- ❌ 工作流文件语法错误
- ❌ 触发条件不满足

如果工作流运行过但失败了：
- 点击失败的运行，查看日志
- 检查具体错误信息

## 🔧 常见问题

### Q: 推送到 main 分支，为什么 Build and Release 没触发？

**A**: `Build and Release` 工作流只监听 **tag 推送**，不监听分支推送。

解决方法：
1. 使用手动触发（workflow_dispatch）
2. 推送一个 tag：`git tag v1.0.0 && git push origin v1.0.0`

### Q: 推送了 tag，但工作流没触发？

**A**: 检查以下几点：
1. tag 是否以 `v` 开头？（工作流只匹配 `v*`）
2. tag 是否真的推送成功？`git ls-remote --tags origin`
3. 工作流文件是否已提交到仓库？

### Q: 手动触发在哪里？

**A**: 
1. 访问 https://github.com/mooniitt/proxy-server/actions
2. 选择左侧 "Build and Release" 工作流
3. 点击右侧 "Run workflow" 下拉菜单
4. 选择分支，输入版本号，点击 "Run workflow"

### Q: 如何测试工作流是否正常工作？

**A**: 
1. 推送代码到 main 分支（会触发 test.yml）
2. 或手动触发 Build and Release 工作流
3. 查看 Actions 页面是否有运行记录

## ✅ 验证清单

- [ ] `.github/workflows/release.yml` 文件存在
- [ ] 工作流文件已提交并推送到 GitHub
- [ ] 访问 Actions 页面能看到 "Build and Release" 工作流
- [ ] 没有红色警告（语法错误）
- [ ] 仓库 Settings → Actions 已启用
- [ ] 工作流权限设置为 "Read and write permissions"

## 🚀 快速测试步骤

```bash
# 1. 提交工作流文件
git add .github/workflows/
git commit -m "Fix GitHub Actions workflow"
git push origin main

# 2. 手动触发（推荐）
# 访问 https://github.com/mooniitt/proxy-server/actions
# 点击 "Run workflow" 进行测试

# 3. 或推送测试 tag
git tag v1.0.0-test
git push origin v1.0.0-test
```

## 📞 如果还是不行

1. 检查 GitHub Actions 运行日志：https://github.com/mooniitt/proxy-server/actions
2. 查看是否有错误信息
3. 确认仓库设置中 Actions 已启用
