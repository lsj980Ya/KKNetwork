---
layout: default
title: GitHub Pages 配置指南
---

# GitHub Pages 配置指南

本指南将帮助你配置 GitHub Pages 来托管 KKNetwork 文档。

## 前提条件

- GitHub 仓库（public 或 private with GitHub Pro/Team/Enterprise）
- 仓库的管理员权限

## 配置步骤

### 1. 启用 GitHub Pages

1. 打开你的 GitHub 仓库
2. 点击 **Settings**（设置）标签
3. 在左侧菜单中找到 **Pages**
4. 在 **Source** 部分：
   - 选择 **GitHub Actions**（不是 Deploy from a branch）
5. 点击 **Save**（保存）

![GitHub Pages Settings](https://docs.github.com/assets/cb-47267/images/help/pages/publishing-source-drop-down.png)

### 2. 推送代码

将代码推送到 `main` 或 `master` 分支：

```bash
git add .
git commit -m "Setup GitHub Pages"
git push origin main
```

### 3. 查看部署状态

1. 进入仓库的 **Actions** 标签
2. 查看 "Deploy Documentation" 工作流
3. 等待部署完成（通常需要 1-2 分钟）

### 4. 访问文档

部署成功后，你的文档将在以下地址可用：

```
https://lsj980ya.github.io/repositoryname/
```

例如：
- 用户名：`johndoe`
- 仓库名：`KKNetwork`
- 文档地址：`https://johndoe.github.io/KKNetwork/`

## 常见问题

### ❌ 错误：Get Pages site failed

**原因：** GitHub Pages 未启用或配置不正确

**解决方案：**
1. 确保在 Settings → Pages 中选择了 "GitHub Actions"
2. 确保仓库是 public（或有 GitHub Pro 账户）
3. 等待 5-10 分钟让 GitHub 初始化服务
4. 手动触发工作流：
   - Actions → Deploy Documentation → Run workflow

### ❌ 错误：404 Not Found

**原因：** 文档路径配置错误

**解决方案：**
1. 检查 `docs/` 目录是否存在
2. 检查 `docs/index.md` 文件是否存在
3. 确保工作流中的 `path` 配置正确：
   ```yaml
   path: 'KKNetwork/docs'
   ```

### ❌ 错误：Permission denied

**原因：** 工作流权限不足

**解决方案：**
1. 进入 Settings → Actions → General
2. 在 "Workflow permissions" 部分
3. 选择 "Read and write permissions"
4. 勾选 "Allow GitHub Actions to create and approve pull requests"
5. 保存设置

### ⚠️ 警告：使用旧版本的 Actions

**解决方案：** 已在工作流中更新到最新版本（v4）

## 自定义配置

### 自定义域名

1. 在 `docs/` 目录创建 `CNAME` 文件
2. 添加你的域名：
   ```
   docs.example.com
   ```
3. 在域名提供商处配置 DNS：
   ```
   CNAME  docs  lsj980ya.github.io
   ```

### 自定义主题

编辑 `docs/_config.yml`：

```yaml
theme: jekyll-theme-cayman  # 可选其他主题
title: KKNetwork
description: 你的描述
```

可用主题：
- `jekyll-theme-cayman`
- `jekyll-theme-minimal`
- `jekyll-theme-slate`
- `jekyll-theme-architect`
- `jekyll-theme-time-machine`

## 手动触发部署

如果需要手动触发部署：

1. 进入 **Actions** 标签
2. 选择 "Deploy Documentation" 工作流
3. 点击 **Run workflow** 按钮
4. 选择分支（通常是 main）
5. 点击绿色的 **Run workflow** 按钮

## 验证部署

部署成功后，你应该能看到：

1. ✅ Actions 中的工作流显示绿色勾号
2. ✅ Settings → Pages 显示 "Your site is live at ..."
3. ✅ 可以访问文档网站

## 更新文档

每次推送到 main/master 分支时，文档会自动更新：

```bash
# 修改文档
vim docs/index.md

# 提交并推送
git add docs/
git commit -m "Update documentation"
git push origin main

# 等待自动部署（1-2 分钟）
```

## 监控部署

查看部署日志：

1. Actions → Deploy Documentation
2. 点击最新的工作流运行
3. 查看每个步骤的日志
4. 如果失败，查看错误信息

## 需要帮助？

- [GitHub Pages 官方文档](https://docs.github.com/en/pages)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Jekyll 主题文档](https://jekyllrb.com/docs/themes/)

## 总结

✅ 启用 GitHub Pages（Settings → Pages → GitHub Actions）  
✅ 推送代码到 main/master 分支  
✅ 等待自动部署  
✅ 访问你的文档网站  

就这么简单！🎉
