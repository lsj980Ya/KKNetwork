#!/bin/bash

# KKNetwork 配置验证脚本

echo "🔍 验证 KKNetwork 配置..."
echo ""

# 检查 Git 仓库
echo "📦 检查 Git 仓库..."
if [ -d ".git" ]; then
    echo "  ✅ Git 仓库已初始化"
    REPO_ROOT=$(git rev-parse --show-toplevel)
    echo "  📁 仓库根目录: $REPO_ROOT"
else
    echo "  ❌ 未找到 Git 仓库"
    exit 1
fi

echo ""

# 检查文档目录
echo "📚 检查文档目录..."
if [ -d "docs" ]; then
    echo "  ✅ docs/ 目录存在"
    DOC_COUNT=$(find docs -name "*.md" | wc -l)
    echo "  📄 文档文件数: $DOC_COUNT"
else
    echo "  ❌ docs/ 目录不存在"
    exit 1
fi

echo ""

# 检查关键文件
echo "📋 检查关键文件..."
FILES=(
    "docs/index.md"
    "docs/_config.yml"
    "docs/core-classes.md"
    "docs/request-types.md"
    "docs/advanced-features.md"
    "docs/best-practices.md"
    "docs/api-reference.md"
    ".github/workflows/deploy-docs.yml"
    "README.md"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file 不存在"
    fi
done

echo ""

# 检查工作流配置
echo "⚙️  检查 GitHub Actions 配置..."
if [ -f ".github/workflows/deploy-docs.yml" ]; then
    echo "  ✅ deploy-docs.yml 存在"
    
    # 检查路径配置
    if grep -q "path: 'docs'" .github/workflows/deploy-docs.yml; then
        echo "  ✅ 文档路径配置正确 (path: 'docs')"
    else
        echo "  ⚠️  文档路径可能配置错误"
        echo "     当前配置:"
        grep "path:" .github/workflows/deploy-docs.yml | head -1
    fi
    
    # 检查 Actions 版本
    if grep -q "actions/checkout@v4" .github/workflows/deploy-docs.yml; then
        echo "  ✅ 使用最新版本的 Actions (v4)"
    else
        echo "  ⚠️  Actions 版本可能过旧"
    fi
else
    echo "  ❌ deploy-docs.yml 不存在"
fi

echo ""

# 检查核心代码
echo "💻 检查核心代码..."
CORE_FILES=(
    "Core/KKBaseRequest.swift"
    "Core/KKNetworkConfig.swift"
    "Core/KKNetworkLogger.swift"
    "Cache/KKNetworkCache.swift"
    "KKNetwork.swift"
    "Package.swift"
)

for file in "${CORE_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ⚠️  $file 不存在"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 验证总结:"
echo ""

if [ -d ".git" ] && [ -d "docs" ] && [ -f ".github/workflows/deploy-docs.yml" ]; then
    echo "  ✅ 基础配置完整"
    echo ""
    echo "🚀 下一步操作:"
    echo ""
    echo "  1. 在 GitHub 仓库启用 Pages:"
    echo "     Settings → Pages → Source: GitHub Actions"
    echo ""
    echo "  2. 推送代码:"
    echo "     git add ."
    echo "     git commit -m 'Setup GitHub Pages'"
    echo "     git push origin main"
    echo ""
    echo "  3. 查看部署状态:"
    echo "     Actions → Deploy Documentation"
    echo ""
    echo "  4. 访问文档:"
    echo "     https://yourusername.github.io/repositoryname/"
    echo ""
else
    echo "  ❌ 配置不完整，请检查上述错误"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✨ 验证完成！"
