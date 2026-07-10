#!/usr/bin/env bash
set -euo pipefail

BASE="${ZHIKU_SKILL_BASE:-https://os-zk.84000.art/zhiku-skill}"
DEST="${ZHIKU_SKILL_DEST:-${HOME}/.claude/skills/zhiku-market}"

mkdir -p "${DEST}/scripts"
curl -fsSL "${BASE}/SKILL.md" -o "${DEST}/SKILL.md"
curl -fsSL "${BASE}/zhiku" -o "${DEST}/scripts/zhiku"
chmod +x "${DEST}/scripts/zhiku"

printf 'Installed zhiku-market adapter at %s\n' "${DEST}"
printf 'CLI: %s\n' "${DEST}/scripts/zhiku"
