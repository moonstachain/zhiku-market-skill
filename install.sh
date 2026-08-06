#!/usr/bin/env bash
set -euo pipefail

BASE="${ZHIKU_SKILL_BASE:-https://os-zk.84000.art/zhiku-skill}"
TARGET="${ZHIKU_INSTALL_TARGET:-both}"
BIN_DIR="${ZHIKU_BIN_DIR:-${HOME}/.local/bin}"

case "${TARGET}" in codex|claude|both) ;; *) printf 'Invalid ZHIKU_INSTALL_TARGET: %s\n' "${TARGET}" >&2; exit 2 ;; esac

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
PROFILE_FILES="index.json skills.json agents.json commands.json mcps.json settings.json hooks.json"
for file in SKILL.md zhiku governance-source.json SHA256SUMS; do
  curl -fsSL "${BASE}/${file}" -o "${TMP}/${file}"
done
mkdir -p "${TMP}/profiles"
for file in ${PROFILE_FILES}; do
  curl -fsSL "${BASE}/profiles/${file}" -o "${TMP}/profiles/${file}"
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
for file in ${PROFILE_FILES}; do
  verify_one "profiles/${file}"
done
grep -q '"schema": "zhiku_distribution_source_v1"' "${TMP}/governance-source.json"
grep -Eq '"canonical_source_hash": "[0-9a-f]{64}"' "${TMP}/governance-source.json"
command -v python3 >/dev/null 2>&1 || { printf 'Need python3 for governed profile verification\n' >&2; exit 3; }
python3 - "${TMP}/profiles" "${TMP}/governance-source.json" <<'PY'
import hashlib
import json
import pathlib
import sys

profiles = pathlib.Path(sys.argv[1])
governance = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
index = json.loads((profiles / "index.json").read_text(encoding="utf-8"))
types = ("skills", "agents", "commands", "mcps", "settings", "hooks")
hash_fields = {"profile_bundle_hash", "profile_index_hash", "profile_shards_hash"}
allowed_index_fields = {
    "schema", "built_at", "profile_hash_format", *hash_fields, "source",
    "type_files", "input_hashes", "catalog_count", "profiled_count",
    "excluded_count", "exclusions", "local_overlay", "self_assess", "privacy",
}
exclusion_fields = {"type", "canonical_id", "path", "reason"}
exclusion_reasons = {
    "insufficient_public_metadata", "policy_excluded",
    "unsupported_profile_contract",
}

def canonical_hash(value):
    payload = json.dumps(
        value, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()

if set(index) != allowed_index_fields:
    raise SystemExit("profile_index_fields_mismatch")
if index.get("profile_hash_format") != "indexed-v2":
    raise SystemExit("profile_index_binding_required")
source = index.get("source") or {}
source_counts = source.get("counts") or {}
coverage_values = (
    index.get("catalog_count"), index.get("profiled_count"),
    index.get("excluded_count"),
)
exclusions = index.get("exclusions")
if (
    any(type(value) is not int or value < 0 for value in coverage_values)
    or not isinstance(exclusions, list)
    or index.get("catalog_count") != source.get("total")
    or index.get("profiled_count", -1) + index.get("excluded_count", -1)
    != index.get("catalog_count")
    or index.get("excluded_count") != len(exclusions)
    or not isinstance(source_counts, dict)
    or set(source_counts) != set(types)
):
    raise SystemExit("profile_coverage_counts_invalid")
excluded_identities = set()
excluded_type_counts = {typ: 0 for typ in types}
for position, row in enumerate(exclusions):
    if not isinstance(row, dict) or set(row) != exclusion_fields:
        raise SystemExit(f"profile_exclusion_fields_mismatch:{position}")
    typ = row.get("type")
    canonical_id = row.get("canonical_id")
    path = row.get("path")
    if (
        typ not in types
        or not isinstance(canonical_id, str) or not canonical_id.startswith("zk:")
        or not isinstance(path, str) or not path or path.startswith(("/", "~"))
        or ".." in pathlib.PurePosixPath(path).parts
        or row.get("reason") not in exclusion_reasons
    ):
        raise SystemExit(f"profile_exclusion_contract_invalid:{position}")
    identity = (typ, canonical_id, path)
    if identity in excluded_identities:
        raise SystemExit(f"profile_exclusion_identity_duplicate:{position}")
    excluded_identities.add(identity)
    excluded_type_counts[typ] += 1
if exclusions != sorted(
    exclusions,
    key=lambda row: (
        types.index(row["type"]), row["path"], row["canonical_id"], row["reason"],
    ),
):
    raise SystemExit("profile_exclusions_not_sorted")
if index.get("local_overlay") != {
    "enabled": False,
    "installed_name_count": 0,
    "ambiguous_identity_names": 0,
    "telemetry_components": 0,
    "telemetry_status": "unmeasured",
}:
    raise SystemExit("profile_local_overlay_evidence_present")
input_hashes = index.get("input_hashes") or {}
empty_hash = canonical_hash({})
if (
    input_hashes.get("local_telemetry_analysis") is not None
    or any(
        input_hashes.get(field) != empty_hash
        for field in (
            "metabolism", "self_assess_audit", "self_assess_decision_board",
            "identity_conflicts", "lifecycle_v2",
        )
    )
):
    raise SystemExit("profile_local_input_evidence_present")

rows = []
profiled_identities = set()
profiled_type_counts = {}
for typ in types:
    path = profiles / f"{typ}.json"
    shard = json.loads(path.read_text(encoding="utf-8"))
    items = shard.get("items")
    if not isinstance(items, list):
        raise SystemExit(f"profile_items_invalid:{typ}")
    if (shard.get("_meta") or {}).get("count") != len(items):
        raise SystemExit(f"profile_type_meta_mismatch:{typ}")
    profiled_type_counts[typ] = len(items)
    for position, item in enumerate(items):
        if not isinstance(item, dict):
            raise SystemExit(f"profile_row_invalid:{typ}:{position}")
        identity = (typ, item.get("canonical_id"), item.get("path"))
        if identity in profiled_identities or identity in excluded_identities:
            raise SystemExit(f"profile_coverage_identity_invalid:{typ}:{position}")
        profiled_identities.add(identity)
    rows.extend((path.name.encode("utf-8"), b"\0", path.read_bytes(), b"\0"))
covered_type_counts = {
    typ: profiled_type_counts[typ] + excluded_type_counts[typ]
    for typ in types
}
if (
    source_counts != covered_type_counts
    or index.get("profiled_count") != sum(profiled_type_counts.values())
    or index.get("excluded_count") != sum(excluded_type_counts.values())
):
    raise SystemExit("profile_coverage_shard_counts_mismatch")
shards_hash = hashlib.sha256(b"".join(rows)).hexdigest()
index_hash = canonical_hash({key: value for key, value in index.items() if key not in hash_fields})
bundle_hash = canonical_hash({
    "profile_hash_format": "indexed-v2",
    "profile_index_hash": index_hash,
    "profile_shards_hash": shards_hash,
})
if index.get("profile_shards_hash") != shards_hash:
    raise SystemExit("profile_shards_hash_mismatch")
if index.get("profile_index_hash") != index_hash:
    raise SystemExit("profile_index_hash_mismatch")
if index.get("profile_bundle_hash") != bundle_hash:
    raise SystemExit("profile_bundle_hash_mismatch")
if governance.get("profile_bundle_hash") != bundle_hash:
    raise SystemExit("governance_profile_bundle_hash_mismatch")
for name in ("index.json", *(f"{typ}.json" for typ in types)):
    actual = hashlib.sha256((profiles / name).read_bytes()).hexdigest()
    if (governance.get("files") or {}).get(f"profiles/{name}") != actual:
        raise SystemExit(f"governance_profile_file_hash_mismatch:{name}")
PY

install_to(){
  dest="$1"
  parent="$(dirname "${dest}")"
  base="$(basename "${dest}")"
  mkdir -p "${parent}"
  staged="$(mktemp -d "${parent}/.${base}.new.XXXXXX")"
  if ! {
    mkdir -p "${staged}/scripts" "${staged}/profiles"
    cp "${TMP}/SKILL.md" "${staged}/SKILL.md"
    cp "${TMP}/zhiku" "${staged}/scripts/zhiku"
    cp "${TMP}/governance-source.json" "${staged}/governance-source.json"
    cp "${TMP}/SHA256SUMS" "${staged}/SHA256SUMS"
    for file in ${PROFILE_FILES}; do
      cp "${TMP}/profiles/${file}" "${staged}/profiles/${file}"
    done
    chmod +x "${staged}/scripts/zhiku"
  }; then
    rm -rf "${staged}"
    return 1
  fi
  previous="${parent}/.${base}.old.$$"
  [ ! -e "${previous}" ] && [ ! -L "${previous}" ] || { rm -rf "${staged}"; printf 'Atomic install backup already exists: %s\n' "${previous}" >&2; return 1; }
  if [ -e "${dest}" ] || [ -L "${dest}" ]; then
    mv "${dest}" "${previous}"
  else
    previous=""
  fi
  if ! mv "${staged}" "${dest}"; then
    rm -rf "${staged}"
    [ -z "${previous}" ] || mv "${previous}" "${dest}"
    return 1
  fi
  [ -z "${previous}" ] || rm -rf "${previous}"
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
