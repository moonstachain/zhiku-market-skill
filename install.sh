#!/usr/bin/env bash
# 随身智库 · AI 组件市场 Skill 一行安装
#   curl -fsSL https://h5.odysseyinst.com/zhiku-skill/install.sh | bash
set -euo pipefail

BASE="https://h5.odysseyinst.com/zhiku-skill"
DEST="${HOME}/.claude/skills/zhiku-market"

mkdir -p "${DEST}"
curl -fsSL "${BASE}/SKILL.md" -o "${DEST}/SKILL.md"

echo "✅ 已安装到 ${DEST}/SKILL.md"
echo ""
echo "下一步："
echo "  · Claude Code: 重启会话后生效，直接说「有没有写公众号的 skill」试试"
echo "  · Codex / Cursor / Gemini CLI / OpenCode 等: 把 ${DEST}/SKILL.md 复制到该平台的 skills 目录"
echo "  · 可选 CLI:  curl -fsSL ${BASE}/zhiku -o /usr/local/bin/zhiku && chmod +x /usr/local/bin/zhiku"
