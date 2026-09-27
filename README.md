# kunzhi

[![Generator is Hugo](https://img.shields.io/badge/Generator%20is-Hugo-ff4088?&logo=hugo)](https://github.com/gohugoio/hugo)
[![Source on Forgejo](https://img.shields.io/badge/Source%20on-Forgejo-181717?&logo=forgejo)](https://git.tianheg.co/tianheg/kunzhi)
[![Built with Cloudflare Workers](https://img.shields.io/badge/Built%20with-Cloudflare_Workers-orange?&logo=cloudflare)](https://workers.cloudflare.com/)

个人品牌站 - [kunzhi.me](https://kunzhi.me/)

> 或生而知之，或学而知之，或困而知之。

站名的意思是：生来就懂的人上等，学了才懂的人次之，**困住了才去弄懂的人**——记录的就是这一类。

## 目录

- [站点理念](#站点理念)
- [项目架构](#项目架构)
- [技术栈](#技术栈)
- [环境要求](#环境要求)
- [内容规范](#内容规范)
- [模板体系](#模板体系)
- [设计约定](#设计约定)
- [常用命令](#常用命令)
- [部署](#部署)
- [给协作者的约定](#给协作者的约定)
- [已知陷阱](#已知陷阱)

## 站点理念

与 [tianheg.co](https://tianheg.co/)（博客）分工明确，两个站**不互镜像、不同步、不双写**：

| | tianheg.co | kunzhi.me |
|---|---|---|
| 定位 | 写作 / TIL / 知识库 | 职业发展记录 + 项目发布 |
| 内容 | 长文、笔记、生活 | 折腾过程、项目条目 |
| 语气 | 个人博客 | 工作笔记 / 作品集 |

**不做**：搜索、评论、统计、多语言、暗色切换按钮、订阅入口（RSS 只留 `rel=alternate`）。
**不做重定向**：URL 改名后旧链接直接 404，不补 alias。

## 项目架构

```
kunzhi/
├── assets/css/main.css      # 全站唯一样式表（方案三「手记」风格）
├── content/
│   ├── _index.md            # 首页
│   ├── about.md             # 关于
│   ├── articles/            # 技术文章（职业发展、技能学习、方向思考）
│   ├── projects/            # 项目条目（Page Bundle + 封面图）
│   └── search.md            # 站内搜索页（type: search）
├── layouts/
│   ├── baseof.html          # 基础框架（含 skip-link 与 <main id="main">）
│   ├── home.html            # 首页：年份分组时间轴
│   ├── section.html         # 列表页：目录式（点线 + 编号）
│   ├── single.html          # 详情页：单栏 + 右侧页边注
│   ├── 404.html
│   ├── _markup/             # 渲染钩子（render-link.html：外链自动新标签页）
│   ├── _partials/           # head / header / footer / entry
│   ├── projects/list.html   # 项目页专用：双栏带图
│   └── search/single.html   # 搜索页：Pagefind Component UI
├── scripts/build.sh         # CF Workers Builds 构建脚本（自装 Hugo + Pagefind，均含 sha256 校验）
├── static/                  # 直出 public/（favicon、og.png、apple-touch-icon、_headers）
├── docs/superpowers/        # 设计档与实施计划
├── hugo.yaml
└── wrangler.jsonc           # CF Workers 静态资源配置
```

## 技术栈

- **Hugo 0.166.0**，**标准版**（非 Extended）。标准版实测可输出 webp/avif；Extended 主要多 LibSass，而 LibSass 已在 0.153 废弃、官方推 Dart Sass（任何版本可用），所以不需要。
- **纯 CSS**，只有 `assets/css/main.css` 一个文件，走 Hugo 内置管道（`resources.Get | minify | fingerprint` + SRI）。
- **搜索**：Pagefind 1.5.2 **extended 版** —— 构建后对 `public/` 建静态索引，产物在 `public/pagefind/`，无运行时服务。用 extended 是因为标准版只按空白切词，**中文不分词**（同一份内容索引词数实测 596 → 825）。
- **零 npm / 零 webpack / 零 Node 依赖**。构建只调 `hugo` 与 `pagefind` 两个自装二进制（Pagefind 的 npm 包只是下载器，这里直接用官方 release 二进制）。
- **脚本只在 `/search/`**：Pagefind Component UI 需要一点 JS 和 WebAssembly；其余页面零脚本，暗色模式仍用 `light-dark()` 跟随系统。
- **零 webfont**：全部系统字体栈。
- 部署为 **Cloudflare Workers Static Assets**（不是 Pages），构建由 Workers Builds 触发。

## 环境要求

- Hugo 0.166+（CI 由 `scripts/build.sh` 自装，版本固定并做 sha256 校验）
- 不需要 Node、npm、pnpm

## 内容规范

### articles/ — 技术文章

普通 Markdown 文件，按日期倒序（`weight` 不参与排序）。

```yaml
---
title: 文章标题
date: 2026-09-24T00:00:00+08:00
description: 可选，用于 SEO 与分享卡
---
```

### projects/ — 项目条目

**一律做成 Page Bundle 并自带封面图**（每个新项目条目都必须有 `cover.svg`），封面放同目录：

```
content/projects/my-project/
├── index.md
└── cover.jpg      # 或 cover.png / cover.webp / cover.svg
```

```yaml
---
title: 项目名
status: 构思 | 开发中 | 已发布
date: 2026-09-24T00:00:00+08:00
summary: 一句话摘要，显示在列表卡片上
---
```

封面图规则（由 `layouts/projects/list.html` 处理）：

- bundle 内的 `cover.*` 自动经 Hugo 图片管线压成 **webp**，产出 **720w / 1080w 两档 srcset**，并输出 `width`/`height`
- **SVG 原样使用**（矢量不需要压缩）
- 用 `cover: /images/xxx.jpg` 可指定任意路径（此时不经过管线，原图直出）
- **封面一律用 `cover.svg`**（矢量、不占体积、原样直出不走图片管线）。约定：`viewBox 0 0 800 600`，内联 `<style>` 里定义「手记」色板的 `:root` 变量 ＋ `@media (prefers-color-scheme: dark)` 覆盖，与站点同源；线稿 + 红笔批注（楷体）；无圆角、无阴影、无渐变。参照已有条目的 `cover.svg`
- **没有封面图**时显示「暂无图片」斜纹占位块，不会破版 —— 这是缺图兜底，不是常态：新条目一律配图
- `content/projects/_index.md` 里的 `cascade: build.publishResources: false` 确保**封面原图不被打包发布**——只有压好的 webp 进部署包

### search.md — 搜索页

根目录的 `content/search.md` 用 `type: search` 指向 `layouts/search/single.html`，页面上只放 Pagefind Component UI 的三个 web component（`pagefind-input` / `pagefind-summary` / `pagefind-results`），不需要任何初始化脚本——它们靠共享实例自动连接。

**索引范围由 `data-pagefind-body` 决定**：这个属性只挂在 `layouts/single.html` 的 `<article>` 上，所以索引里只有详情页（文章 / 项目 / 关于）；列表页、首页、搜索页不进索引。

**索引不是内容，是构建产物**：`hugo server` 不产 `public/pagefind/`，本地预览搜索页会取不到 `/pagefind/*`。本地要搜就先跑一次构建 + 建索引（见「常用命令」）。

### 列表排序

- `articles/` 按日期倒序
- `projects/` 按 `weight` 升序，没写 `weight` 的按默认排序
- 首页时间轴按年份倒序分组；**没有 `date` 的条目归到 `—` 组且不显示日期行**

## 模板体系

| 文件 | 作用 |
|---|---|
| `baseof.html` | 所有页面的外壳：skip-link + `.wrap` + `<main id="main">` + footer |
| `home.html` | 首页：按年份分组的时间轴 |
| `section.html` | 列表页：目录式排版（编号 + 点线引导 + 右对齐元信息） |
| `single.html` | 详情页：38rem 单栏正文 + `blockquote` 浮右侧做红字页边注 |
| `projects/list.html` | 覆盖 `section.html`，只作用于 `/projects/`：双栏带图网格 |
| `_markup/render-link.html` | Markdown 链接渲染钩子：**外链自动 `target="_blank" rel="noopener noreferrer"`** |
| `_partials/entry.html` | 单个条目的渲染（首页与列表页共用） |

`aria-current` 由 `IsMenuCurrent or HasMenuCurrent` 判断，**文章/项目详情页也会高亮对应菜单项**。

## 设计约定

**「手记」风格**——纸面笔记的质感，不是网页卡片。

色板（全部 `light-dark()` 双模式）：

| 变量 | 亮色 | 暗色 | 用途 |
|---|---|---|---|
| `--paper` | `#f4f1e7` | `#17150f` | 纸底 |
| `--ink` | `#26241e` | `#e9e4d6` | 正文 |
| `--pen` / `--pen-bg` | `#1d1b17` | `#ece7d9` | 钢笔黑：标题、站名、反白块 |
| `--red` | `#a8342a` | `#d9705f` | 红笔：批注、强调、边注 |
| `--mute` | `#6f6b5c` | `#9a9384` | 元信息小字 |
| `--graphite` | `#4a4741` | `#a29c8e` | 摘要正文 |

全站配色只有**纸黄 / 墨黑 / 红笔**三色系。改色时注意：**所有文本对比度必须 ≥4.5:1**（`--mute` 亮色值曾是 `#857f6d`，只有 3.54:1，已修正为 `#6f6b5c` = 4.72:1）。

字体分工（三套系统字体栈）：

- **楷体**（`--hand`）= 手写：站名、页边注
- **宋体系衬线**（`--serif`）= 正文
- **等宽**（`--mono`）= 数据、编号、日期、状态

**硬性规矩**：无卡片、无阴影、无圆角、无渐变。分区一律用发丝线（1px `--rule`）。样式只写在 `main.css` 里，**不写内联 style**（CSP 的 `style-src 'self'` 会拦）。

## 常用命令

本地预览（局域网 / 手机也能访问，`hugo serve` 与 `hugo server` 完全等价）：

```bash
hugo server \
  --bind 0.0.0.0 \
  --baseURL http://192.168.8.10:1313/ \
  --appendPort=false \
  --disableFastRender
```

四个参数都**不可省**：

- `--bind 0.0.0.0` —— 默认只绑 `127.0.0.1`，不放开局域网访问不了
- `--baseURL ...` —— 配置里 baseURL 是 `https://kunzhi.me/`，不覆盖则页面上的 CSS/RSS/canonical 全指向线上域名
- `--appendPort=false` —— 默认 `true`，Hugo 会往 baseURL 尾部再追加端口，变成 `...:1313:1313`
- `--disableFastRender` —— Fast Render 只重渲染改动那一页，首页/列表页有时不跟着更新

常用可选项：`-D`（含 draft）、`-F`（含未来日期）、`--navigateToChanged`（改完自动跳转）、`--noHTTPCache`（禁浏览器缓存）、`-M`（纯内存渲染，不写磁盘）。

构建（与 CI 一致）：

```bash
# CI 用的完整脚本：自装 Hugo + Pagefind，构建完顺手建搜索索引
./scripts/build.sh

# 手动两步（本地反复改内容时更快）
hugo --gc --minify
pagefind_extended --site public
```

## 部署

```
本地 commit → push Forgejo (origin) → push mirror 自动同步 → GitHub tianheg/kunzhi
                                                                    ↓
                                                    Cloudflare Workers Builds
                                                    （跑 scripts/build.sh）
                                                                    ↓
                                                          kunzhi.me
```

- **origin**：`git@git.tianheg.co:tianheg/kunzhi.git`
- Forgejo 的 **push mirror** 配了 `sync_on_commit`，push 后自动同步到 GitHub，这一步不用手动做
- CF Workers Builds 监听 GitHub 仓库，`wrangler.jsonc` 里 `assets.directory = ./public`
- **本地 `wrangler deploy` 不可用**（没有 Workers Scripts 写权限的凭据），不要试图用它发布
- 分支 `main`，**永不 force-push**

## 给协作者的约定

这一节是给 AI 协作者（和未来的自己）的硬约束：

1. **不要引入 npm / Tailwind / 任何需要 Node 的构建步骤。** 样式只有 `assets/css/main.css` 一个文件，走 Hugo 内置管道；Pagefind 也走官方 release 二进制（`scripts/build.sh` 自装 `pagefind_extended` + sha256 校验），不要改成 `npm install pagefind`。
2. **脚本只允许出现在 `/search/`。** 那一页需要 Pagefind Component UI；其他任何页面都不要加 `<script>`，暗色模式继续靠 `light-dark()`。
3. **不要引入 webfont。** 只用系统字体栈，改字体请改 `--sans` / `--serif` / `--hand` / `--mono` 变量。
4. **不要改部署链路。** 隐私相关：不要往仓库里写 `FORGEJO_TOKEN` / `GH_TOKEN`；任何 token 用占位符代替。
5. **图片一律走 Hugo 图片管线**，不要把大图直接塞进 `static/` 原图直出。
6. **改样式后要核对比度**，正文和元信息小字都要 ≥4.5:1。
7. **不写内联 style / 内联 script**，CSP 是 `style-src 'self'` + `script-src 'self' 'unsafe-inline'`（后者只为放行 Cloudflare bot 检测注入的内联脚本，不是给人用的）。
8. **改 URL 结构时同步改** `hugo.yaml` 的 menus、`layouts/section.html` 里的排序判断（现在是 `eq .Section "articles"`）。
9. **内容与代码分开**：不要在这次提交里混入无关文章。

## 已知陷阱

- **CSP 必须放行两样东西，否则搜索会静默失效**（2026-09-27 实测）：① `script-src` 里的 `'wasm-unsafe-eval'` —— Pagefind 用 WebAssembly，缺了会报 `CompileError: WebAssembly.instantiate() ... violates ... Content Security Policy`；② `img-src 'self' data:` —— 组件把图标写成 data: URI 的 SVG，缺了会在控制台出现 `img-src :: data` 违规。两条都只在**真实入口 + `_headers` 生效**的条件下才暴露，`hugo server` 不读 `_headers`，用它永远测不出来。
- **改 Pagefind 组件内部要当心样式优先级**：Component UI 是 light DOM（`.pf-input` / `.pf-result` / `.pf-input-clear` … 都能选中），但它自带的样式表也设字号，同级选择器「谁后加载谁赢」。改清除按钮文案时就踩过：不加 `!important` 会渲染成英文 + 中文并排的「Clear清空」。这类选择器补丁依赖 Pagefind 内部类名，升级版本后要复查。
- **搜索索引是构建产物**：`public/pagefind/` 由 `pagefind_extended --site public` 生成（CI 在 `scripts/build.sh` 里跑），本地预览搜索页前要先手动建一次。**别把命令换成标准版 `pagefind`** —— 它不会给中文分词，索引词数会从 825 掉到 596（构建日志里会出现 `Indexing Chinese in non-extended mode` 警告）。核对新鲜度看 `public/pagefind/pagefind-entry.json` 的 `page_count`（当前 = 3 个详情页）。
- **改索引范围只动 `data-pagefind-body`**：它现在挂在 `layouts/single.html` 的 `<article>` 上；`layouts/search/single.html` 上是 `data-pagefind-ignore`。加/减后必看 `page_count` 有没有跟着变。
- **外链判定在 `layouts/_markup/render-link.html`**：绝对 URL 且 scheme 为 `http`/`https` 且主机名不是本站（含 `www.`）才加 `target="_blank"`。`mailto:` / `tel:` / 锚点 / 相对路径都不处理。自定义链接渲染钩子会**整体接管** Markdown 链接渲染，改它时记得保留 `.Title` 与 `.Text`，否则会丢标题与链接文字。它只作用于 `.Content`（正文），**不作用于模板里手写的 `<a>`**——模板里的外链要自己加属性。
- **`hugo server` 默认写磁盘并从磁盘 serve**，`public/` 里的旧构建残留在内容改名后仍会被服务（旧 URL 返回 200 而不是 404）。改名后请删掉 `public/` 再重启。
- **`_build` 这个 front matter 键在 Hugo 0.145 已被移除**（不是废弃），写了会让构建直接 ERROR。现在是 `build`。
- **`.hugo_build.lock`** 是 Hugo 的构建互斥锁，0 字节，可以随时删（下次构建自动重建），已在 `.gitignore` 里。
- **Hugo release tar.gz 里含 LICENSE 与 README.md**，解压时务必指定目录或只抽取 `hugo` 这一项，否则会覆盖仓库自己的 README（`scripts/build.sh` 已按此处理）。
- **不要给带 `aria-current` 的 partial 用 `partialCached`**，不带 key 会跨页共享输出导致高亮串页。
- **`imaging.quality` 在 0.163 起废弃**，要按格式分别设 `imaging.{jpeg,webp,avif}.quality`；`resampleFilter` 默认是 `box` 不是 Lanczos。
- **`keepWhitespace` 不是 0.166 的合法 minify 键**，写了会被静默忽略。

## 相关文档

- `docs/superpowers/specs/` —— 站点设计档
- `docs/superpowers/plans/` —— 实施计划
