# 🚀 KKNetwork 部署指南

## ✅ 配置验证

运行验证脚本检查配置：

```bash
cd KKNetwork
bash verify-setup.sh
```

如果看到 "✨ 验证完成！"，说明所有配置都正确。

## 📋 部署清单

### ✅ 已完成的配置

- ✅ 文档目录结构正确 (`docs/`)
- ✅ GitHub Actions 工作流已配置
- ✅ 所有 Actions 已更新到 v4
- ✅ 文档路径配置正确 (`path: 'docs'`)
- ✅ 添加了 environment 配置
- ✅ 添加了并发控制
- ✅ 核心代码文件完整

### 📝 需要手动完成的步骤

#### 1. 启用 GitHub Pages

⚠️ **这是必须的第一步！**

1. 打开 GitHub 仓库
2. 进入 **Settings** → **Pages**
3. **Source** 选择 "**GitHub Actions**"
4. 点击 **Save**

#### 2. 配置权限（如果需要）

如果遇到权限错误：

1. Settings → Actions → General
2. Workflow permissions: 选择 "**Read and write permissions**"
3. 勾选 "Allow GitHub Actions to create and approve pull requests"
4. 保存

#### 3. 推送代码

```bash
git add .
git commit -m "Setup GitHub Pages with documentation"
git push origin main
```

#### 4. 查看部署

1. 进入 **Actions** 标签
2. 查看 "Deploy Documentation" 工作流
3. 等待部署完成（1-2 分钟）

#### 5. 访问文档

部署成功后访问：

```
https://yourusername.github.io/repositoryname/
```

## 🔧 工作流配置

### deploy-docs.yml

```yaml
# 文档路径: docs/
# 触发条件: 推送到 main/master 分支
# Actions 版本: v4 (最新)
# Environment: github-pages
```

**关键配置：**

```yaml
- name: Upload artifact
  uses: actions/upload-pages-artifact@v3
  with:
    path: 'docs'  # ← 正确的路径
```

## 🐛 故障排除

### 错误：Cannot open: No such file or directory

**原因：** 路径配置错误

**解决方案：** ✅ 已修复
- 工作流中的路径已更新为 `docs`
- 不再使用 `KKNetwork/docs`

### 错误：Get Pages site failed

**原因：** GitHub Pages 未启用

**解决方案：**
1. Settings → Pages → Source: GitHub Actions
2. 等待 5-10 分钟
3. 手动触发工作流

### 错误：Permission denied

**原因：** 工作流权限不足

**解决方案：**
- Settings → Actions → General
- Workflow permissions: Read and write permissions

## 📊 目录结构

```
KKNetwork/                          # Git 仓库根目录
├── .git/
├── .github/
│   ├── workflows/
│   │   ├── deploy-docs.yml        # ✅ 文档部署
│   │   └── swift.yml              # Swift CI
│   └── README.md
├── docs/                           # ✅ 文档目录
│   ├── _config.yml
│   ├── index.md
│   ├── core-classes.md
│   ├── request-types.md
│   ├── advanced-features.md
│   ├── best-practices.md
│   ├── api-reference.md
│   └── SETUP_GITHUB_PAGES.md
├── Core/                           # 核心代码
├── Cache/                          # 缓存模块
├── Request/                        # 请求类型
├── README.md
├── QUICK_START.md
├── DEPLOYMENT_GUIDE.md            # 本文件
└── verify-setup.sh                # 验证脚本
```

## 🎯 验证部署成功

部署成功的标志：

1. ✅ Actions 显示绿色勾号
2. ✅ Settings → Pages 显示 "Your site is live at ..."
3. ✅ 可以访问文档网站
4. ✅ 文档内容正确显示

## 📚 相关文档

- [快速开始](QUICK_START.md)
- [GitHub Pages 配置详解](docs/SETUP_GITHUB_PAGES.md)
- [工作流说明](.github/README.md)

## 🎉 完成！

如果验证脚本显示 "✅ 基础配置完整"，你只需要：

1. 在 GitHub 启用 Pages
2. 推送代码
3. 等待部署
4. 访问文档

就这么简单！
