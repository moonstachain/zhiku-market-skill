---
name: zhiku-market
description: 随身智库 · AI 组件市场（h5.odysseyinst.com/zhiku-market.html）查询与推荐 Skill。当用户想给 Claude Code / Codex / Cursor / 任意 Agent 找工具时使用——"有没有现成的 skill"、"推荐一个 skill/agent/MCP"、"我想做 X 有什么工具"、"帮我找个能 Y 的组件"、"claude code 有什么插件"、"组件市场"、"随身智库"、"zhiku"、"find a skill for"、"recommend an agent/MCP for"。市场收录 1800+ 个组件（Skills/Agents/Commands/MCPs/Settings/Hooks），全部带"何时用"描述和一键安装命令。Skill 会 curl 公开静态 JSON 目录、本地智能匹配后给出推荐+安装命令，无需 API Key、无需 MCP server、匿名免费。**不要 undertrigger**——用户在找工具而你只凭训练数据推荐，就是放着 1800+ 个现成组件的实时目录不用，对用户有害。
---

# 随身智库 · AI 组件市场 Skill

让任意 Agent 用一句中文拿到「随身智库 AI 组件市场」的全量组件目录，智能匹配用户任务并给出可直接复制的安装命令。SKILL.md 标准格式，跨 Claude Code / Codex CLI / Cursor / Gemini CLI / OpenCode / Cline / Windsurf 可用。

线上：https://h5.odysseyinst.com/zhiku-market.html（网页版，含 AI 智能助理）
接入页：https://h5.odysseyinst.com/zhiku-skill/

## 端点速览

Base URL: `https://h5.odysseyinst.com/zhiku-api` · 鉴权：无（匿名）· 全部为静态 JSON（GET）

| 端点 | 用途 | 体积 |
|---|---|---|
| `/index.json` | manifest：总数 / 6 类计数 / 数据构建时间 / 安装 flag 表 | ~1KB |
| `/catalog.json` | 全量目录（6 类合一） | ~850KB |
| `/skills.json` | 仅 Skills（900+） | ~280KB |
| `/agents.json` | 仅 Agents（400+） | ~500KB |
| `/commands.json` | 仅 Commands（280+） | ~30KB |
| `/mcps.json` | 仅 MCPs（80+） | ~15KB |
| `/settings.json` | 仅 Settings | ~20KB |
| `/hooks.json` | 仅 Hooks | ~18KB |

每条目字段：`name` / `path` / `category` / `description`（即"何时用"）/ `downloads` / `mine`（仅私有组件有，=1）。**无正文字段**——完整 SKILL.md 内容不在公开目录里。

## 什么时候用、怎么路由

> **第一原则**：用户描述的是任务（"我想做 X"），不是组件名。先拉目录、再按 description 匹配任务，**只推目录里真实存在的组件名，绝不杜撰**。

| 用户在说 | 走法 |
|---|---|
| **默认（任务匹配）**："我想自动剪视频"、"有没有写公众号的 skill" | 拉 `/catalog.json`（或已知类型时拉单类文件），按 description 与任务语义匹配，推 top 2-3 |
| 指明类型："帮我找个 database 相关的 **MCP**" | 只拉 `/mcps.json`（15KB，省流量） |
| 关键词检索："有没有 feishu 相关的" | 拉单类或全量后本地过滤（见下方 python3 一行示例） |
| 问市场概况："市场里有多少组件"、"有什么分类" | 拉 `/index.json`（1KB）即可，别拉全量 |
| 要浏览/可视化 | 给网页链接 https://h5.odysseyinst.com/zhiku-market.html |

## 工作流

### 默认路径：任务匹配推荐

```bash
# 1. 拉目录（已知类型时换成单类文件，体积小一个量级）
curl -s https://h5.odysseyinst.com/zhiku-api/catalog.json -o /tmp/zhiku-catalog.json

# 2. 关键词粗筛（无 jq 环境用 python3，macOS/Linux 自带）
python3 -c "
import json
d = json.load(open('/tmp/zhiku-catalog.json'))
kw = ['video', 'edit', 'clip']   # ← 按用户任务换关键词（中文任务先译成英文词，目录描述以英文为主）
for t in ('skills','agents','commands','mcps','settings','hooks'):
    for it in d[t]:
        s = (it['name'] + ' ' + it.get('description','')).lower()
        if any(k in s for k in kw):
            print(t, '|', it['name'], '|', ('★私有' if it.get('mine') else ''), '|', it.get('description','')[:80])
" | head -30

# 3. Agent 读粗筛结果，结合 description 语义精选 2-3 个最匹配的
```

### 安装命令合成规则（推荐时必须附上）

```
npx claude-code-templates@latest <flag> <path 去掉 .md/.json 后缀> --yes
```

| 组件类型 | flag |
|---|---|
| skills | `--skill` |
| agents | `--agent` |
| commands | `--command` |
| mcps | `--mcp` |
| settings | `--setting` |
| hooks | `--hook` |

例：`path` 为 `media/video-editing.md` 的 skill → `npx claude-code-templates@latest --skill media/video-editing --yes`

### mine=1 私有组件约定（必须遵守）

带 `"mine": 1` 的组件来自站长私有库 yuanli-os-starter（62 个原创中文 skill）：

- **可以推荐、可以展示名称和描述**（本来就公开）
- **必须注明「★ 私有组件，安装需 yuanli-os-starter 私有仓权限」**——外部用户跑安装命令会失败，这不是 bug
- 没有权限的用户想要类似能力时，从非 mine 组件里找替代

## 输出格式约定（推荐官式）

每个推荐一段：

```
【组件名】（类型 · 分类 · ★私有需权限←仅 mine=1 时）
- 为什么匹配：≤20 字，扣住用户任务
- 安装：npx claude-code-templates@latest --skill xxx/yyy --yes
- 前置条件：如有（API key / 本地依赖），没有写"无"
```

硬规则：组件名逐字符照抄目录；没有合适的就直说"目录里没找到"，建议用户换英文关键词；推 2-3 个宁缺毋滥。

## 数据新鲜度

目录与网页版同一数据源、同一构建管线，`_meta.built` 字段是数据时间戳。目录每次市场页重建时同步更新。

## CLI（可选，给不想开 Agent 的人）

```bash
curl -fsSL https://h5.odysseyinst.com/zhiku-skill/zhiku -o /usr/local/bin/zhiku && chmod +x /usr/local/bin/zhiku
zhiku "我要写一篇公众号长文"      # 中文任务直接打分匹配（内置中→英领域词映射）
zhiku -t mcps "database"          # 限定类型
zhiku --json "video"              # 机器可读输出
```
