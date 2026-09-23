#!/usr/bin/env bash
# CF Workers Builds 构建脚本：自装 Hugo（版本固定，含 sha256 校验）后构建站点。
# 不在 CF 环境运行时也安全（只影响 PATH 内的 hugo）。
set -euo pipefail

HUGO_VERSION=0.166.0

export TZ=Asia/Shanghai

echo "Installing Hugo v${HUGO_VERSION}..."
curl --fail -LJO "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_linux-amd64.tar.gz"
curl --fail -LJO "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_checksums.txt"
grep "hugo_${HUGO_VERSION}_linux-amd64.tar.gz" "hugo_${HUGO_VERSION}_checksums.txt" | sha256sum -c -
tar -xf "hugo_${HUGO_VERSION}_linux-amd64.tar.gz"

mkdir -p /opt/buildhome
cp hugo /opt/buildhome
export PATH=/opt/buildhome:$PATH

rm -f LICENSE README.md "hugo_${HUGO_VERSION}_linux-amd64.tar.gz" "hugo_${HUGO_VERSION}_checksums.txt"

echo "Hugo: $(hugo version)"

hugo --gc --minify
