# zhiku-market — 随身智库 · AI 组件市场 Skill

让任意 Agent（Claude Code / Codex CLI / Cursor / Gemini CLI / OpenCode / Cline …）用一句中文查询「随身智库 AI 组件市场」的 1800+ 个组件（Skills / Agents / Commands / MCPs / Settings / Hooks），描述任务即可拿到推荐 + 一键安装命令。匿名免费、无需 token、零后端（纯静态 JSON）。

- 网页版（含 AI 智能助理）: https://h5.odysseyinst.com/zhiku-market.html
- 接入页: https://h5.odysseyinst.com/zhiku-skill/

## 三种接入方式

### ① Skill（任意 Agent）

在你的 Agent 里直接发：

```
帮我安装这个 skill: https://h5.odysseyinst.com/zhiku-skill/SKILL.md
```

或终端一行装（Claude Code）：

```bash
curl -fsSL https://h5.odysseyinst.com/zhiku-skill/install.sh | bash
```

触发示例："有没有写公众号长文的 skill" / "我想自动剪视频，推荐个工具" / "帮我找个 database 相关的 MCP"

### ② CLI（python3 零依赖）

```bash
curl -fsSL https://h5.odysseyinst.com/zhiku-skill/zhiku -o /usr/local/bin/zhiku && chmod +x /usr/local/bin/zhiku
zhiku "我要写一篇公众号长文"
zhiku -t mcps "database"
zhiku --json "video"
```

### ③ REST 风格 API（静态 JSON · 匿名 GET）

Base: `https://h5.odysseyinst.com/zhiku-api`

| 端点 | 用途 |
|---|---|
| `/index.json` | manifest（总数/分类计数/数据时间/安装 flag 表，~1KB） |
| `/catalog.json` | 全量目录（~1MB） |
| `/skills.json` `/agents.json` `/commands.json` `/mcps.json` `/settings.json` `/hooks.json` | 按类拆分 |

## 数据范围

公开目录只含组件名称 / 分类 / 描述（"何时用"）/ 安装命令，**不含 SKILL.md 正文**。带 `mine=1`（★）的 62 个为站长私有组件：可见可推荐，安装需私有仓权限；其余 1700+ 来自 [aitmpl.com](https://www.aitmpl.com) 上游，人人可装。

## License

MIT
