#!/usr/bin/env bash
# CF Workers Builds 构建脚本：自装 Hugo（版本固定，含 sha256 校验）后构建站点。
# 不在 CF 环境运行时也安全（只影响 PATH 内的 hugo）。
set -euo pipefail

HUGO_VERSION=0.167.0
PAGEFIND_VERSION=1.5.2
BIN_DIR=/opt/buildhome

export TZ=Asia/Shanghai

echo "Installing Hugo v${HUGO_VERSION}..."
curl --fail -LJO "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_linux-amd64.tar.gz"
curl --fail -LJO "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_checksums.txt"
grep "hugo_${HUGO_VERSION}_linux-amd64.tar.gz" "hugo_${HUGO_VERSION}_checksums.txt" | sha256sum -c -

# 只把 hugo 二进制抽到独立目录。
# 注意：Release 的 tar.gz 里除了 hugo 还含 LICENSE 与 README.md，
# 若解压到项目根会覆盖仓库自己的 README.md / LICENSE（本地跑会真丢文件）。
# 另外，BIN_DIR 可能被历史遗留的文件占用（曾把二进制误复制成 buildhome），
# 那时 mkdir 会失败，所以先清掉再建目录。
if [ -e "$BIN_DIR" ] && [ ! -d "$BIN_DIR" ]; then
  rm -f "$BIN_DIR"
fi
mkdir -p "$BIN_DIR"
tar -xf "hugo_${HUGO_VERSION}_linux-amd64.tar.gz" -C "$BIN_DIR" hugo
export PATH="$BIN_DIR:$PATH"

rm -f "hugo_${HUGO_VERSION}_linux-amd64.tar.gz" "hugo_${HUGO_VERSION}_checksums.txt"

echo "Hugo: $(hugo version)"

# Pagefind：构建后生成站内搜索索引（纯静态产物，无运行时服务）。
# 用 extended 版（52MB）：标准版对**中文不分词**（它只按空白切词），索引词数实测 596 vs extended 825；
# 官方警告原文：Indexing Chinese in non-extended mode ... will not segment words that are not whitespace separated。
# 同样固定版本 + sha256 校验；已在 PATH 里且版本一致时跳过下载（本地反复构建省事）。
# 注意 Pagefind 的 npm 包只是个下载器 —— 这里直接用官方 release 二进制，站点保持零 npm。
if command -v pagefind_extended >/dev/null 2>&1 && [ "$(pagefind_extended --version 2>/dev/null | awk '{print $2}')" = "$PAGEFIND_VERSION" ]; then
  echo "Pagefind (extended) v${PAGEFIND_VERSION} already installed, skipping download."
else
  echo "Installing Pagefind extended v${PAGEFIND_VERSION}..."
  PF_ASSET="pagefind_extended-v${PAGEFIND_VERSION}-x86_64-unknown-linux-musl.tar.gz"
  PF_BASE="https://github.com/Pagefind/pagefind/releases/download/v${PAGEFIND_VERSION}"
  curl --fail -LJO "${PF_BASE}/${PF_ASSET}"
  curl --fail -LJO "${PF_BASE}/${PF_ASSET}.sha256"
  sha256sum -c "${PF_ASSET}.sha256"
  tar -xzf "$PF_ASSET" -C "$BIN_DIR" pagefind_extended
  rm -f "$PF_ASSET" "${PF_ASSET}.sha256"
fi

echo "Pagefind: $(pagefind_extended --version)"

hugo --gc --minify
pagefind_extended --site public
