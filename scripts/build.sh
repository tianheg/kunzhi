#!/usr/bin/env bash
# CF Workers Builds 构建脚本：自装 Hugo（版本固定，含 sha256 校验）后构建站点。
# 不在 CF 环境运行时也安全（只影响 PATH 内的 hugo）。
set -euo pipefail

HUGO_VERSION=0.166.0
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

hugo --gc --minify
