---
title: 智能手表厂商的开放 API 现状
date: 2026-09-27T00:00:00+08:00
summary: 运动手表里真正对个人开放、能自助拉自己数据的只有少数几家；Garmin、Suunto、华为、小米的门槛都在企业资质上。这是 2026-09 的实况盘点。
---

结论先摆出来：**运动手表厂商的开放 API 基本是 B 端生意**，个人能自助拿到自己数据的只有少数几家（Polar、WHOOP、Oura、Withings）。剩下两条路——逆向私有接口，或者手动导出文件。

## 一、个人自助可用（免费、正式 OAuth / Token）

- **Polar AccessLink**（v3 / v4）—— 最干净的一条。任何 Polar Flow 用户自己去 `admin.polaraccesslink.com` 建 client 就能拿到 OAuth2 的 id / secret，不要求公司身份。覆盖训练会话、日常活动、夜间恢复、连续心率、PPI（pulse-to-pulse 间期）、睡眠、体温。芬兰公司（Polar Electro Oy，1977 年成立于 Kempele），数据在 EU 受 GDPR 管。
- **WHOOP API v2** —— 免费（前提是有 WHOOP 设备 + 订阅）。在 Developer Dashboard 自助建 app，OAuth2 + webhook，出 recovery / sleep / strain / workout。数据模型里的「physiological cycle」和自然日不是一回事，接入前要读清楚。
- **Oura API v2** —— 戒指不是表，但 API 最省事：在 `cloud.ouraring.com` 生成 **Personal Access Token** 直接读自己的数据；OAuth app 默认 10 用户上限。自用这一条就够。
- **Withings Public API** —— 免费、无需合同、官方明确欢迎独立开发者。设备线偏体重、血压、睡眠垫，不是运动表。
- **Apple HealthKit / Google Health Connect** —— 端侧、免费、无审批。HealthKit 只在 App 内读写，**苹果没有云端 API**；Health Connect 是 Android 上的本地聚合层。意义是做手机侧 App 读数据，不是远程拉数。

## 二、必须企业资质或审批（个人基本过不了）

| 品牌 | 门槛 |
|---|---|
| **Garmin** | Connect Developer Program 的 FAQ 写死 only for business use：免费但要申请、1–4 周集成。个人拿数据的正规路只有账号里的全量数据导出 |
| **Suunto** | Cloud API 只给公司/组织，明确不提供个人使用，要签 API 协议 |
| **COROS** | OAuth2 接口只对平台方 onboarding，个人需要让某个平台替你申请 |
| **华为** | Health Kit 要求企业实缴注册资本 ≥50 万（基础数据）/ 500 万（高阶）；个人开发者只开放基础数据，且应用必须上架华为应用市场 |
| **小米** | 运动健康数据服务文档明写只对小米生态链企业及合作伙伴开放。个人只能走 `account.xiaomi.com` → 隐私 → 管理您的数据 → MI Fitness 下载导出 |
| **Fitbit** | 老 Fitbit Web API 在 2026-09 关停，迁到 Google Health API；新 scope **全部是 Restricted**，要过隐私安全审查 |
| **Samsung** | Health Data SDK 只读数据可用 developer mode 自测，公开发行必须走 partner 审批；写数据要另拿 access code |

## 三、没有正式 API，只能逆向或导出

- **Amazfit / Zepp** —— 官方开放平台已 Deprecated，且只认早已退役的小米账号。实际能用的路线是逆向私有接口：`appid` + `apptoken` 打 `api-mifit*.zepp.com`，逐秒心率走文件索引，睡眠藏在 `band_data` 的 base64 blob 里。违反 ToS，且有风控风险。
- **Apple Watch** —— 无云 API，健康 App 导出 ZIP/XML。

## 四、一个例外：Suunto 开了面向用户的 MCP

Suunto 的 Cloud API 不给个人，但它另外提供了 **Suunto MCP**（只读，OAuth 授权，`https://mcp.suunto.cn/open/mcp`），官方手册里直接列了 ChatGPT、Claude、Codex、WorkBuddy、Hermes、OpenClaw 的接法。这大概是「消费级手表 + 个人开发者」目前最接近开放 API 的入口：

```yaml
mcp_servers:
  suunto:
    url: https://mcp.suunto.cn/open/mcp
    auth: oauth
    sampling:
      enabled: false
```

授权后 AI 助手能读运动、睡眠、恢复和路线数据，改不了账号与记录。

## 五、如果有天要换表

按「个人能不能合法拿到数据」排序：

1. **Suunto** —— 唯一能直接喂给 AI 助手的，代价是只读、且数据面比 Garmin 窄。
2. **Polar** —— 自助建 client、免费、含 PPI 与连续心率，工程师自用最舒服。
3. **Garmin** —— 数据最全，但个人拿不到 API，不算开放。

**结论**：想要「数据入口自己说了算」，在现有厂商体系里买不到，只能自己做（见项目区的[自制智能手表](/projects/diy-smartwatch/)）；或者接受逆向私有接口的代价。
