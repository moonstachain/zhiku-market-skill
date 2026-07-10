---
name: zhiku-market
description: 随身智库-MAX 的公开接入适配器。Use when the user asks for an existing Skill, Agent, Command, MCP, Setting or Hook, wants component recommendations, or mentions 随身智库、组件市场、技能统帅、治理体检。Always read the live index and deep metadata before recommending; never invent components or expose private component bodies.
---

# 随身智库-MAX · 公开接入适配器

随身智库把 2,000+ 个 Skills、Agents、Commands、MCPs、Settings 与 Hooks 汇成可检索目录。公开适配器只读取匿名元数据与 deep 摘要，不包含私有组件正文。

## Canonical surfaces

- Market: `https://os-zk.84000.art/zhiku-market.html`
- API: `https://os-zk.84000.art/zhiku-api`
- MCP: `https://os-zk.84000.art/zhiku-mcp/mcp`
- Agent access: `https://os-zk.84000.art/zhiku-skill/`

## Routing protocol

1. 先读 `/index.json`，确认 build、总量和六类计数。
2. 按任务从 `/catalog.json` 或单类型文件检索。
3. 推荐前读取 `/deep/<type>.json`；私有组件没有公开 deep 正文。
4. 优先已经安装且可调用的本地能力。
5. 每个候选说明匹配理由、安装状态、前置条件、风险和下一步。
6. 没有可信候选就停止，不杜撰组件。

## CLI

```bash
curl -fsSL https://os-zk.84000.art/zhiku-skill/zhiku -o /usr/local/bin/zhiku
chmod +x /usr/local/bin/zhiku
zhiku --deep -n 5 "我要写一篇公众号长文"
zhiku --max "治理 skill MCP GitHub"
```

Operate 使用 `operation_recipe_v1`：H5 只生成 recipe，本地 `zhiku operate` 执行；`apply` 默认阻断，`publish_or_pay` 永久保持人工门。

## Privacy and trust

- `mine=1` 只表示私有渠道，不代表安全验证通过。
- provenance、usage、functional/security validation 是独立信号。
- 不输出密钥、私有正文、客户文本或本机私有路径。
- 客户端密码门只是 UI 门；真正私密数据必须服务端鉴权。

本文件由私有正本 `moonstachain/yuanli-os-starter/staging/L1/zhiku-market` 确定性生成，不在发行仓手工维护。
