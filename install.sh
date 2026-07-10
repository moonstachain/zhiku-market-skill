#!/usr/bin/env bash
set -euo pipefail

BASE="${ZHIKU_SKILL_BASE:-https://os-zk.84000.art/zhiku-skill}"
TARGET="${ZHIKU_INSTALL_TARGET:-both}"
BIN_DIR="${ZHIKU_BIN_DIR:-${HOME}/.local/bin}"

case "${TARGET}" in codex|claude|both) ;; *) printf 'Invalid ZHIKU_INSTALL_TARGET: %s\n' "${TARGET}" >&2; exit 2 ;; esac

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
for file in SKILL.md zhiku governance-source.json SHA256SUMS; do
  curl -fsSL "${BASE}/${file}" -o "${TMP}/${file}"
done

verify_one(){
  file="$1"
  expected="$(awk -v f="${file}" '$2==f {print $1}' "${TMP}/SHA256SUMS")"
  [ "${#expected}" -eq 64 ] || { printf 'Missing governed checksum for %s\n' "${file}" >&2; exit 3; }
  if command -v shasum >/dev/null 2>&1; then actual="$(shasum -a 256 "${TMP}/${file}" | awk '{print $1}')"
  elif command -v sha256sum >/dev/null 2>&1; then actual="$(sha256sum "${TMP}/${file}" | awk '{print $1}')"
  else printf 'Need shasum or sha256sum for governed install\n' >&2; exit 3; fi
  [ "${actual}" = "${expected}" ] || { printf 'Checksum mismatch for %s\n' "${file}" >&2; exit 3; }
}
verify_one SKILL.md
verify_one zhiku
grep -q '"schema": "zhiku_distribution_source_v1"' "${TMP}/governance-source.json"
grep -Eq '"canonical_source_hash": "[0-9a-f]{64}"' "${TMP}/governance-source.json"

install_to(){
  dest="$1"
  mkdir -p "${dest}/scripts"
  cp "${TMP}/SKILL.md" "${dest}/SKILL.md"
  cp "${TMP}/zhiku" "${dest}/scripts/zhiku"
  cp "${TMP}/governance-source.json" "${dest}/governance-source.json"
  cp "${TMP}/SHA256SUMS" "${dest}/SHA256SUMS"
  chmod +x "${dest}/scripts/zhiku"
  printf 'Installed zhiku-market at %s\n' "${dest}"
}

case "${TARGET}" in
  codex) install_to "${ZHIKU_SKILL_DEST:-${HOME}/.codex/skills/zhiku-market}"; CLI_SOURCE="${ZHIKU_SKILL_DEST:-${HOME}/.codex/skills/zhiku-market}/scripts/zhiku" ;;
  claude) install_to "${ZHIKU_SKILL_DEST:-${HOME}/.claude/skills/zhiku-market}"; CLI_SOURCE="${ZHIKU_SKILL_DEST:-${HOME}/.claude/skills/zhiku-market}/scripts/zhiku" ;;
  both)
    install_to "${HOME}/.codex/skills/zhiku-market"
    install_to "${HOME}/.claude/skills/zhiku-market"
    CLI_SOURCE="${HOME}/.codex/skills/zhiku-market/scripts/zhiku"
    ;;
esac

mkdir -p "${BIN_DIR}"
ln -sfn "${CLI_SOURCE}" "${BIN_DIR}/zhiku"
printf 'CLI: %s/zhiku\n' "${BIN_DIR}"
case ":${PATH}:" in *":${BIN_DIR}:"*) ;; *) printf 'Add %s to PATH to run bare zhiku.\n' "${BIN_DIR}" ;; esac
