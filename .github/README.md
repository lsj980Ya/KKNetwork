# GitHub Actions 工作流

本目录包含 KKNetwork 项目的 GitHub Actions 工作流配置。

## 工作流说明

### 1. Deploy Documentation (`deploy-docs.yml`)

自动部署文档到 GitHub Pages。

**触发条件：**
- 推送到 `main` 或 `master` 分支
- 手动触发（workflow_dispatch）

**功能：**
- 自动构建并部署 `docs/` 目录到 GitHub Pages
- 使用最新版本的 GitHub Actions（v4）

**配置 GitHub Pages：**
1. 进入仓库 Settings → Pages
2. Source 选择 "GitHub Actions"
3. 推送代码后自动部署

### 2. Swift CI (`swift.yml`)

Swift 代码的持续集成。

**触发条件：**
- 推送到 `main`、`master` 或 `develop` 分支
- 创建 Pull Request

**功能：**
- 编译检查
- 运行测试
- 验证代码质量

## 使用的 Actions 版本

所有 Actions 都已更新到最新版本：

- `actions/checkout@v4`
- `actions/configure-pages@v4`
- `actions/upload-pages-artifact@v3`
- `actions/deploy-pages@v4`

## 注意事项

1. **权限设置**：确保仓库的 Actions 权限已启用
2. **GitHub Pages**：需要在仓库设置中启用 GitHub Pages
3. **分支保护**：建议为 `main` 分支设置保护规则

## 手动触发部署

可以在 GitHub 仓库的 Actions 标签页手动触发文档部署：

1. 进入 Actions 标签
2. 选择 "Deploy Documentation" 工作流
3. 点击 "Run workflow"
4. 选择分支并运行

## 故障排除

### 部署失败

如果部署失败，检查：
1. GitHub Pages 是否已启用
2. 仓库权限设置是否正确
3. `docs/` 目录是否存在且包含有效内容

### 编译失败

如果 Swift CI 失败，检查：
1. Swift 版本是否兼容
2. 依赖是否正确配置
3. 代码是否有语法错误

## 更多信息

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [GitHub Pages 文档](https://docs.github.com/en/pages)
