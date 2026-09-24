---
title: 项目
cascade:
  build:
    publishResources: false
---

自己做的项目，从构思到发布。`weight` 控制顺序，`status` 标状态（构思 / 开发中 / 已发布）。

**封面图**：把条目做成 Page Bundle（`content/projects/<name>/index.md`），同目录放一张 `cover.*`（jpg/png/webp 均可），列表页会自动取它并压成 webp（720w / 1080w 两档 srcset）；也可以在 front matter 里写 `cover: /images/xxx.jpg` 指定任意路径。SVG 原样使用。没有封面图时列表页显示「暂无图片」占位块，不会破版。

上面那行 `build.publishResources: false` 由 `cascade` 作用到所有项目条目：**同目录的封面原图不会被打包发布**，只有压好的 webp 会 —— 否则你手机拍的 4MB 原图会白占部署空间。
