# kunzhi.me 个人站设计（spec）

- 日期：2026-09-24
- 状态：待用户审阅
- 域名：kunzhi.me（2026-09-23 由 Cloudflare Registrar 注册，zone `5541b09a401bb3ad12b9ba6f5d6a6b88`，status: active，NS nora/nero.ns.cloudflare.com）
- 本地路径：`~/projects/kunzhi`
- origin：`git@git.tianheg.co:tianheg/kunzhi.git`（已存在，空）
- 镜像：`https://github.com/tianheg/kunzhi`（已存在，空）

## 1. 目标

kunzhi 意为「困而知之」——经过困难而获得真知。站点承担两件事：

1. **个人职业发展折腾记录**：技能学习、求职历程、BMS/嵌入式方向的技术摸索、阶段复盘
2. **产品开发发布**：后续自研产品的发布入口与进展公告

站点是这两件事的公开门面，不是 tianheg.co 的翻版。

## 2. 成功标准（可验证）

1. `hugo --gc --minify` 本地零报错，产出 `public/`
2. `hugo server` 下四类页面可达：首页、`/writing/` 列表与单页、`/products/` 列表与单页、`/about/`
3. 仓库内**无 `package.json`、无 `node_modules`**（零 npm 依赖）
4. 推送 Forgejo 后 GitHub 镜像同步：`api.github.com/repos/tianheg/kunzhi` 的 `pushed_at` 更新
5. 第二期上线后：`curl -s https://kunzhi.me/ | grep <首页文案关键词>` 内容命中（不只查状态码）

## 3. 非目标（明确不做）

- 不与 tianheg.co 同步内容、不镜像、不双写；两站 RSS 各自独立
- 不做站内搜索、评论、访问统计、知识图谱
- 不做多语言（中文为主）
- 不做暗色切换按钮（`prefers-color-scheme` 自动跟随）
- 不引 Tailwind、JS 框架、任何第三方 CDN
- 不做侧栏 TOC、链接悬浮预览等 blog 的交互层（内容量撑不起来）

## 4. 目录结构

```
~/projects/kunzhi/
├── hugo.yaml
├── AGENTS.md                 # 项目上下文（结构、命令、部署）
├── content/
│   ├── _index.md             # 首页
│   ├── about.md
│   ├── writing/              # 折腾记录
│   │   └── _index.md
│   └── products/             # 产品
│       └── _index.md
├── layouts/
│   ├── baseof.html
│   ├── home.html
│   ├── single.html
│   ├── section.html
│   ├── 404.html
│   └── _partials/{head,header,footer}.html
├── assets/css/main.css       # 唯一样式文件，走 Hugo 管道
├── static/
│   ├── _headers              # 安全头
│   └── favicon.svg
├── scripts/build.sh          # CF 构建时自装 Hugo
├── wrangler.jsonc
└── docs/superpowers/specs/   # 本文件
```

`docs/` 与 `scripts/` 不在 Hugo 构建范围内，不会进入 `public/`。

## 5. 内容模型

| 板块 | 路径 | 内容 |
|---|---|---|
| 折腾记录 | `/writing/` | 职业发展、技能学习、求职、方向思考的长文。front matter：`title` / `date` / `summary`（单行摘要，列表页用）|
| 产品 | `/products/` | 每个产品一个 `.md`，front matter 含 `status`（`构思` / `开发中` / `已发布`），列表页按状态排序 |
| 关于 | `/about/` | 一页，独立单页模板 |
| 首页 | `/` | 站点名 + 一句话定位 + 最近 5 篇 writing + products 全量入口 |

一期只建骨架，首页/关于/产品的正文放**显式占位文案**（`<!-- 待填 -->` 风格的真文案，不是 Lorem），由用户替换。

不加 taxonomy（tags 先不做，YAGNI）。RSS 用 Hugo 内置 `/index.xml`。

## 6. 视觉规范（自研极简）

参照 gwern.net 的信息优先密度与 blackglory 的克制，不引模板。

- **版式**：单栏，measure `34em`，正文 `17px` / 行高 `1.75`（中文 25–35 字/行）
- **元信息**：`13px`，等宽字体 + `tabular-nums`，次要灰（对比度 ≥ 4.5:1）
- **链接**：常驻淡下划线（`currentColor` 45% alpha，`underline-offset: .2em`），hover 转实色 —— 与 blog 2026-09-20 定的规则一致，避免触屏只有颜色可辨的问题
- **暗色**：`light-dark()` + `color-mix()`，跟随系统，无切换按钮
- **克制项**：无卡片、无阴影、无圆角、无动效；分隔线 `1px` 极淡；无 hero 大图
- **字体**：只走系统中文字体栈，不下载 webfont
- **强调色**：单一低饱和色，仅用于链接与交互态；标识类元素用中性灰

## 7. 技术决策

| 决策 | 理由 |
|---|---|
| 纯 CSS + Hugo 内置管道（`resources.Get \| minify \| fingerprint`） | 零 npm 依赖；静态站不需要 Tailwind 的工程化能力 |
| Workers **纯 assets**（`wrangler.jsonc` 无 `main`） | 站点无动态逻辑，比 blog 少一层 Worker 脚本；资产请求直出不经过 Worker |
| `scripts/build.sh` 在构建时下载并校验 Hugo | CF 构建镜像的 Hugo 版本不可控，blog 已验证该做法（含 sha256 校验）；固定 `0.166.0` 与本地一致 |
| 零 JS | 唯一 JS 候选（返回顶部）在短页面上无价值 |
| Forgejo push mirror 而非本地 `wrangler deploy` | 本地无 Workers Scripts 写权限的凭据；blog 同链路已被验证 |

## 8. 部署链路

```
本地 commit → Forgejo (origin, push) → Forgejo push mirror (sync_on_commit)
  → GitHub tianheg/kunzhi → Cloudflare Workers Builds（构建并部署）
  → kunzhi.me / www.kunzhi.me
```

`wrangler.jsonc`：

```jsonc
{
  "name": "kunzhi",
  "compatibility_date": "2026-09-24",
  "build": { "command": "./scripts/build.sh" },
  "assets": {
    "directory": "./public",
    "not_found_handling": "404-page"
  }
}
```

**CF 侧由用户手工完成**：新建 Worker `kunzhi`、连接 GitHub 仓库 `tianheg/kunzhi`、绑定 custom domain `kunzhi.me` 与 `www.kunzhi.me`。zone 已在 CF 账号内，custom domain 会自行创建 DNS 记录，**不需要手工加 A 记录**，因此本期不需要 `cf-dns`。

## 9. 风险与遗留

1. **`cf-dns` 的 `--zone` bug**：`load_credentials()` 返回 cert.pem 里的 `zoneID` 作为 hint，`zone_id()` 见 hint 即直接返回，导致 `--zone kunzhi.me` 被忽略、实际操作 tianheg.co。本期修掉——即使第二期不依赖它，留着就是误操作风险（对错误 zone 增删记录）。
2. **push mirror 的凭据**：配置 mirror 需要 `FORGEJO_TOKEN`（write:repository）与 `GH_TOKEN`（repo scope）。用完即弃，不进仓库、不进对话。
3. **Hugo 版本漂移**：本地 0.166.0，`build.sh` 固定同版本；升级时两边一起动。
4. **Workers Builds 传播延迟**：push 后 2–8 分钟内不 curl 判成败，避免被假 404 误导。

## 10. 分期

**第一期（无外部依赖，本地可完成）**
1. 修 `cf-dns` 的 `--zone` bug
2. 建 `~/projects/kunzhi`：Hugo 配置、自研主题、四个板块骨架、占位文案
3. 本地 `hugo server` 与 `hugo --gc --minify` 验证
4. `git init` + 首次 commit + 推送 Forgejo + 配置 push mirror

**第二期（用户在 CF Dashboard 操作）**
1. 建 Worker、连 GitHub、绑域名
2. 内容级验收（curl 命中关键词）

## 11. 站点文案（已确认）

- **站名**：困而知之
- **hero**：或生而知之，或学而知之，或困而知之（《中庸》第二十章）
- **导航**：写作 / 产品 / 关于 —— 不做 `/now`，不做订阅入口（RSS 只作为 `rel=alternate` link 存在，页面上不引导）
