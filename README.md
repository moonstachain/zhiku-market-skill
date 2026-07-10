# zhiku-market · 随身智库-MAX

公开接入包由私有唯一正本自动生成，提供 Skill、零依赖 CLI、静态 JSON API 与 Remote MCP 接入。

- Market: https://os-zk.84000.art/zhiku-market.html
- API: https://os-zk.84000.art/zhiku-api
- MCP: https://os-zk.84000.art/zhiku-mcp/mcp
- Agent access: https://os-zk.84000.art/zhiku-skill/

```bash
curl -fsSL https://os-zk.84000.art/zhiku-skill/install.sh | bash
zhiku --deep "飞书 多维表"
```

公开目录只暴露名称、分类、描述、安装信息和启发式 deep 摘要；不暴露私有组件正文、密钥或客户数据。

## Source governance

本仓是派生发行面，不是手工正本。每次发布必须携带 `governance-source.json`，并通过统一 governance manifest 对账。

License: MIT
