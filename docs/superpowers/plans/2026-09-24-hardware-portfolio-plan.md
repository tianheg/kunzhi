# 硬件技术作品集设计计划

- 日期：2026-09-24
- 基线：Hugo **0.166.0**（本机 `/root/.local/bin/hugo`，实测 `hugo.IsExtended == false`）
- 官方文档基线：`~/projects/hugoDocs`（最后提交 2026-09-09，与 0.166 同期）
- 目标站点：**kunzhi.me**（假设是把它现有的 `products/` 区升级为真正的硬件项目作品集；若要独立成站，第 4 节之后照搬，只换域名/仓库/Worker 名）

---

## 0. 前置结论：参考指南勘误

以下每一条都经**本机实测**或**官方文档源码**核实，不是记忆。

### 硬错误（照抄会踩坑）

**1. 「务必安装 Hugo Extended，标准版不含 `resources.Get` / `.Resize` / `.Fill`」—— 错**

实测（标准版 0.166.0，一张 520×520 JPEG）：

```
Resize "480x"        → /images/test_hu_f6c1bd6e76a5ca6e.jpg   image/jpeg
Resize "480x webp"   → /images/test_hu_5e5001c406d2ab3e.webp image/webp
Resize "480x avif"   → /images/test_hu_fb7f86043fa64a77.avif image/avif
Fill "200x200 Center"→ /images/test_hu_176b4db7a77d467b.jpg  200x200
hugo.IsExtended      → false
构建汇总              → Processed images │ 4
```

官方 `installation/editions` 文档：standard / deploy / extended / extended-deploy **四个版本的核心功能完全相同**，唯一差别是 extended 多了 **LibSass** 支持，外加 deploy 版能直传云存储。原文：`Use the standard edition unless you need additional features.`

且 LibSass 自 **0.153.0 起已废弃**，官方推荐 Dart Sass（任何版本都可用）。

→ **装标准版**。这也和你 blog 2026-04-07「改用标准版，不再依赖 extended」一致。

**2. `[build] writeStats = true` —— 文档键名不对**

官方 `configuration/build.md` 定义的是 `[build.buildStats] enable = true`。

实测：`writeStats = true` 在 0.166 仍被接受，并映射成 `buildStats.enable = true`（兼容别名，没报错）。新项目按文档写；别指望这个别名长期存在。

**3. `[minify.tdewolff.html] keepWhitespace = false` —— 这个键不存在**

实测 `hugo config --format json`，0.166 的 `minify.tdewolff.html` 只有：

```
keepDefaultAttrVals, keepDocumentTags, keepEndTags, keepSpecialComments, templateDelims
```

`keepWhitespace` 写了**被静默忽略**（不报错、不生效）。另外 `html.keepConditionalComments` 已废弃 → 用 `keepSpecialComments`。

**4. 第 9 节数学公式：CDN 拉 KaTeX CSS + 客户端 JS —— 整套过时**

0.166 **内置** KaTeX（`hugo env` 里可见 `github.com/KaTeX/KaTeX = 0.18.4`）。正确做法是构建时渲染：

实测 `{{ transform.ToMath "a^2 + b^2 = c^2" }}` →

```html
<span class=katex><math xmlns="http://www.w3.org/1998/Math/MathML"><semantics>…</semantics></math></span>
```

官方 `functions/transform/ToMath.md` 原话：*"Instead of client-side JavaScript rendering of mathematical markup using MathJax or KaTeX, create a passthrough render hook which calls the `transform.ToMath` function."*

→ **零 JS、零 CDN、零 CSS**，浏览器原生 MathML 渲染。与我们收紧的 CSP 完全相容。

### 过时 / 表述不严谨

**5. `[imaging] quality = 85`** — 自 **0.163.0 废弃**，实测构建直接打 WARN：

```
WARN deprecated: project config key imaging.quality was deprecated in Hugo v0.163.0 …
Set the quality per format instead with imaging.jpeg.quality, imaging.webp.quality and/or imaging.avif.quality.
```

`hint` 同批废弃 → 按格式设。（0.166 仍会把它映射到三个格式，但别依赖。）

**6. `resampleFilter` 的默认值** — 指南没写默认，但官方文档明确 **默认是 `box`**（不是 Lanczos）。照片类内容显式设 `lanczos` 是对的。

**7. 「`layouts/_default/` 目录被移除」** — 官方 `templates/new-templatesystem-overview.md` 的迁移表确实写着 `The _default folder is removed`，要求把文件上移到 `layouts/` 根。但 0.166 **仍兼容解析** `_default`——你 blog 的 `layouts/_default/single.md.md` 正在线上工作。准确表述：新规范不再有它，老写法不报错。**新项目别用。**

**8. 13.2 节 `partialCached` 用在 header / footer / TOC —— 危险建议**

`partialCached` 不带额外 key 时**跨页共享同一份渲染结果**。header 若含当前页判断（`aria-current`、菜单高亮），所有页面会显示同一个高亮——串页 bug；TOC 更是彻底 per-page 的东西，**绝不能**缓存。

正确写法是把差异维度放进 key：`{{ partialCached "header.html" . .Kind }}`。你 kunzhi 的 `header.html` 正好用了 `$.IsMenuCurrent`，属于会踩坑的那类。

**9. Cloudflare Pages + `HUGO_VERSION` 环境变量** — 与我们的实际链路不符。kunzhi 走 Workers Builds + `scripts/build.sh` 自装并校验 Hugo，不依赖构建镜像的版本变量；Pages 也是 CF 正在收敛的旧路线。

**10. 第 10 节暗色模式（`data-theme` + localStorage + 内联阻塞脚本）** — 可行，但和你现有约定冲突：blog 与 kunzhi 都用 `light-dark()` 纯 CSS 跟随系统，零 JS。只有做「手动切换按钮」时才需要它，属于可选功能。

**11. `[security] enableInlineShortcodes = false`** — 这就是默认值，写出来无害但冗余。

**12. `unsafe = true`** — 硬件文里要嵌原始 HTML 时**需要**，但等于关掉 Goldmark 的 HTML 消毒。因为内容全部是自己写的，风险可控；但不要把它用在接受外部投稿的场景。

### 指南里正确、可照用的部分

- `hugo new site --format toml` ✅（实测有效）
- `[pagination] pagerSize`、`disableKinds = ['taxonomy','term']`、`[imaging.exif] disableDate/disableLatLong`、`[markup.tableOfContents] startLevel/endLevel/ordered`、`[minify] minifyOutput`、`resampleFilter` ✅ 全部有效
- Chroma 样式 `github-dark` **存在**（`hugo gen chromastyles --style=github-dark` 成功）
- Leaf Bundle / Branch Bundle 的组织方式、`_markup/render-image.html`、`resources.Concat | minify | fingerprint` ✅ 正确
- 「`hugo server` 不写 `public/`，Pagefind 必须在生产构建后测」✅ 正确

---

## 1. 定位

硬件作品集不是「又一个博客」。它要回答三个问题，而且**靠图回答**：

1. 这块板子/这个设备是什么，长什么样（实物图、PCB、原理图、框图）
2. 关键参数是什么（规格表，可扫读）
3. 能不能拿到东西（仓库、原理图 PDF、BOM、固件）

因此与 kunzhi 现有取向有两点冲突需要显式处理：

| 现状 | 硬件作品集需要 | 处理 |
|---|---|---|
| 零 JS、零 npm | Pagefind 搜索需要 npm | 暂不装 Pagefind；内容量 < 50 页时它不划算 |
| 无第三方 CDN | 数学公式 / 图表 | 公式用内置 KaTeX→MathML；图表用**离线生成的 SVG** 入库，不引 Mermaid CDN |

## 2. 内容模型：Page Bundles

每个硬件项目一个 **Leaf Bundle**（`index.md` + 同目录资源）：

```
content/projects/can-analyzer/
├── index.md            # 正文 + front matter 规格
├── cover.jpg           # 封面（列表页 + OG）
├── pcb-front.jpg       # 资源，正文里用 ![](pcb-front.jpg) 引用
├── schematic.svg       # 原理图（矢量，最好）
├── block-diagram.svg
└── bom.csv             # 下载文件（也可放 static/downloads/）
```

关键点：**放 bundle 里的资源才能被 Hugo 管线处理**（resize/webp/srcset）。放 `static/` 的只能原样复制。

front matter（沿用你现有的 `status` 字段，扩展）：

```yaml
---
title: 便携式双通道 CAN 分析仪
date: 2026-06-15
summary: 基于 STM32H743 的双通道 CAN FD 分析仪，USB-C 供电，铝合金外壳。
status: 已完成            # 构思 | 开发中 | 已完成 | 已归档
role: 硬件设计 + 固件开发
weight: 10
cover: cover.jpg          # 相对 bundle，不是 URL
repo: https://github.com/tianheg/xxx
pdf: /downloads/xxx-schematic.pdf
specs:
  主控: STM32H743VIT6 @ 480MHz
  接口: USB-C 2.0, 2× DB9
  电源: USB-C 5V，板载 3.3V LDO
  尺寸: 78 × 52 mm, 4 层板
  工具: KiCad 9, PlatformIO, FreeRTOS
---
```

## 3. 目录结构（增量）

在 kunzhi 现有结构上增加：

```
content/projects/          # 新：硬件项目（现 products/ 保留或改名，见第 12 节）
layouts/
├── projects/
│   ├── list.html          # 项目网格（卡片含封面缩略图）
│   └── single.html        # 项目详情（封面大图 + 规格表 + 正文 + 下载区）
└── _partials/
    ├── image.html         # 响应式图片（srcset + 显式宽高防 CLS）
    ├── spec-table.html    # 规格表
    └── project-card.html  # 列表卡片
layouts/_markup/
├── render-image.html      # 把 ![](x.jpg) 自动转响应式图
└── render-passthrough.html# 数学公式 → transform.ToMath
layouts/_shortcodes/
├── spec-table.html        # 行内规格表
├── callout.html           # 提示框（注意/危险/笔记）
├── download.html          # 下载卡片
└── gallery.html           # 多图（bundle 资源）
assets/css/                # main.css 增加 components 段，或拆 components.css
```

## 4. 图片管线（重点）

`layouts/_partials/image.html` 接收 bundle 资源，生成多尺寸 + 现代格式：

```go-html-template
{{/* resources: Hugo Resource；alt；sizes；loading */}}
{{ $r := .resource }}
{{ $sizes := .sizes | default "(max-width: 768px) 100vw, 720px" }}
{{ $sm := $r.Resize "480x webp" }}
{{ $md := $r.Resize "800x webp" }}
{{ $lg := $r.Resize "1200x webp" }}
<img src="{{ $md.RelPermalink }}"
     srcset="{{ $sm.RelPermalink }} 480w, {{ $md.RelPermalink }} 800w, {{ $lg.RelPermalink }} 1200w"
     sizes="{{ $sizes }}"
     width="{{ $r.Width }}" height="{{ $r.Height }}"
     alt="{{ .alt }}" loading="{{ .loading | default "lazy" }}" decoding="async">
```

要点：

- **`width`/`height` 必填**（防 CLS）——用**原图**的宽高，不是缩放后的
- `xml`/`svg` 不要走 resize 管线（Hugo 不处理 SVG 位图缩放），SVG 直接 `{{ $r.RelPermalink }}`
- 封面图（首屏可见）用 `loading="eager"`，其余 lazy

## 5. 配置（修正版 · YAML，可直接用）

```yaml
baseURL: https://kunzhi.me/
locale: zh-cn
title: 困而知之

disableKinds: [taxonomy, term]

pagination:
  pagerSize: 20

imaging:
  resampleFilter: lanczos        # 默认是 box，照片用 lanczos
  jpeg:
    quality: 85
  webp:
    quality: 82
  avif:
    quality: 65                  # avif 质量可更低，视觉等价
  exif:
    disableDate: true
    disableLatLong: true
    # 拍照设备的 EXIF 不进产物（隐私 + 体积）

markup:
  goldmark:
    renderer:
      unsafe: true               # 硬件文里嵌原始 HTML 需要
    extensions:
      passthrough:
        enable: true             # 数学公式透传，配合 render-passthrough.html
  highlight:
    style: github                # 与现有极简 chroma 配色保持一致
    noClasses: false             # class 模式，暗色可用自己的 token
  tableOfContents:
    startLevel: 2
    endLevel: 3

build:
  buildStats:
    enable: true                 # 文档键；不是 writeStats
```

> 注意：`imaging.quality`（顶层）**不要写**，0.163 起废弃。

## 6. 数学与图表

**公式**（构建时渲染，零 JS）：

```go-html-template
{{/* layouts/_markup/render-passthrough.html */}}
{{ if eq .Type "block" }}
  <div class="math-block">{{ transform.ToMath .Inner (dict "output" "mathml") }}</div>
{{ else }}
  {{ transform.ToMath .Inner (dict "output" "mathml") }}
{{ end }}
```

Markdown 里直接写 `$f_c = \frac{1}{2\pi RC}$` 或 `$$ … $$`。

**图表**：不用 Mermaid CDN。二选一——
- 用 D2 / Graphviz **离线生成 SVG** 存进 bundle（与你 d2-diagram skill 一致）
- 或直接用导出图

理由：Mermaid 客户端渲染 = 一个 JS 依赖 + 首屏抖动 + 与我们 CSP 的 `script-src` 打架。

## 7. 与既有约束的冲突处理

| 约束 | 本计划 |
|---|---|
| 零 npm | 保持。不装 Pagefind、不装 Tailwind；图片与 CSS 全走 Hugo 内置管线 |
| 零第三方 CDN | 保持。公式走内置 KaTeX→MathML；图表走离线 SVG |
| 零 JS | 仅 **lightbox 可选**。若要做点击放大，用原生 `<dialog>` + 十几行 JS，或干脆不做（图片大图页本身就是详情） |
| 零 webfont | 保持 |
| `light-dark()` 跟随系统 | 保持，不引 `data-theme` 切换 |
| CSP `script-src` 收紧 | 新增交互（如 lightbox）时同步更新 `static/_headers` |

## 8. 部署与限额

链路不变：本地 → Forgejo → push mirror → GitHub → CF Workers Builds。

**CF Workers 静态资产硬限额**（官方 limits 页）：

- 免费版 **20,000 个文件 / Worker 版本**（Paid 100,000）
- 单文件 **25 MiB**
- `_headers` 最多 100 条规则，单行 ≤ 2,000 字符

图片是主要体积来源：每个硬件项目 1 张封面 + 3–8 张图，每张生成 3 个 webp 变体 → 单项目约 20–30 个文件。**几百张图的项目仍是安全的**，但要有意识：原图入库前压到长边 ≤2000px。

## 9. 分阶段实施

**阶段 A：管线就位（无新内容，先让图能跑通）**
1. 更新 `hugo.yaml`（第 5 节）+ 清掉 `imaging.quality`
2. 加 `_partials/image.html`、`_markup/render-image.html`
3. 拿一张真图放进 `content/products/sample/`（改用 bundle 结构）验证：webp 变体生成、srcset、宽高属性在位
4. 构建 + 本地 `hugo server` 目视

**阶段 B：项目区模板**
1. `layouts/projects/{list,single}.html` + `project-card.html` + `spec-table.html`
2. 迁移现有 `content/products/` → `content/projects/`（或保留 products 名，见待确认）
3. 首页项目区改为封面网格

**阶段 C：技术文增强**
1. `render-passthrough.html` + 公式冒烟（一篇带 `$…$` 的文章）
2. 短代码：`spec-table` / `callout` / `download` / `gallery`
3. 图片灯箱（可选，需同时改 CSP）

**阶段 D：真实内容**
1. 选 2–3 个真实项目填进去（ESP32 / 电池守护 / homelab 之类）
2. 每项目：封面 + 规格 + 正文 + 下载

## 10. 明确不做

- 不装 Pagefind（内容量不足，且破零 npm）
- 不引 Mermaid / KaTeX CDN / MathJax
- 不做 `data-theme` 手动切换（跟随系统足够）
- 不引 Tailwind
- 不用 `partialCached` 缓存含当前页状态的 partial
- 不用 Extended（标准版够）

## 11. 待确认

1. **项目区放哪**：把现有 `products/` 改名成 `projects/`（URL 变化、语义更准），还是保留 `products/` 只是内容升级？
2. **是否有 `articles/` 技术文区**：指南设了 `projects` + `articles` 双区。kunzhi 已有 `writing/`（折腾记录）——是把技术文并进 `writing/`，还是另开 `articles/`？
3. **直角/圆角与视觉**：硬件站通常需要图周围更中性的容器。现有 kunzhi 是「无卡片、无阴影、无圆角」，项目网格是否破例？
4. **是否需要 lightbox**（点击放大图）——它意味着引入站点第一段 JS 并放宽 CSP。
5. 部署方式沿用现有 Worker `kunzhi`（同域 `/projects/`），还是独立子域/独立 Worker？
