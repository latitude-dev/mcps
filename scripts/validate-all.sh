#!/usr/bin/env bash
# Run every platform's validation in turn.
# Exits non-zero on the first failure; prints a per-platform summary at the end.
#
# Validators used:
#   cursor       — JSON parse + cursor-agent --plugin-dir smoke-load (if cursor-agent is on PATH)
#   claude       — `claude plugin validate`  (must be installed)
#   codex        — openai/codex's `validate_plugin.py` (downloaded on first run, cached)
#   zed          — `cargo build --target wasm32-wasip2 --release` + ID/name rules from
#                  zed-industries/extensions/src/lib/validation.js
#   antigravity  — JSON parse only (no upstream validator exists yet)

set -o pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLATFORMS=(cursor claude codex zed antigravity)

# Parallel arrays — names and pass/fail codes (macOS bash 3 has no `declare -A`)
RESULT_NAMES=()
RESULT_CODES=()
overall=0

record() {
  RESULT_NAMES+=("$1")
  RESULT_CODES+=("$2")
  if [ "$2" -ne 0 ]; then
    overall=1
  fi
}

red()    { printf "\033[31m%s\033[0m\n" "$*"; }
green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
bold()   { printf "\033[1m%s\033[0m\n" "$*"; }

heading() {
  echo
  bold "== $1 =="
}

# Generic JSON parse check
check_json() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "  ✘ missing: $file"
    return 1
  fi
  python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$file" >/dev/null 2>&1 || {
    echo "  ✘ invalid JSON: $file"
    return 1
  }
  echo "  ✔ valid JSON: $file"
}

validate_cursor() {
  heading "cursor"
  local root="$REPO_ROOT/cursor"
  local ok=0
  check_json "$root/.cursor-plugin/plugin.json" || ok=1
  check_json "$root/mcp.json" || ok=1

  if command -v cursor-agent >/dev/null 2>&1; then
    # Smoke-load via --plugin-dir. cursor-agent has no `validate` subcommand;
    # the closest thing is asking the agent to start with the plugin loaded.
    if cursor-agent --plugin-dir "$root" --trust -p "ok" --mode ask --output-format json >/dev/null 2>&1; then
      echo "  ✔ cursor-agent --plugin-dir loaded the plugin cleanly"
    else
      echo "  ⚠ cursor-agent --plugin-dir reported a non-zero exit (run manually to inspect)"
      ok=1
    fi
  else
    yellow "  ⚠ skipping cursor-agent smoke-load (cursor-agent not on PATH)"
  fi
  return $ok
}

validate_claude() {
  heading "claude"
  local root="$REPO_ROOT/claude"
  if ! command -v claude >/dev/null 2>&1; then
    yellow "  ⚠ skipping: \`claude\` not on PATH"
    return 0
  fi
  if claude plugin validate "$root"; then
    return 0
  else
    return 1
  fi
}

validate_codex() {
  heading "codex"
  local root="$REPO_ROOT/codex"
  local validator="$REPO_ROOT/.cache/codex-validate_plugin.py"
  local venv="$REPO_ROOT/.cache/codex-venv"

  if [ ! -f "$validator" ]; then
    mkdir -p "$(dirname "$validator")"
    if command -v gh >/dev/null 2>&1; then
      gh api repos/openai/codex/contents/codex-rs/skills/src/assets/samples/plugin-creator/scripts/validate_plugin.py \
        --jq '.content' | base64 -d > "$validator"
    else
      curl -fsSL \
        "https://raw.githubusercontent.com/openai/codex/main/codex-rs/skills/src/assets/samples/plugin-creator/scripts/validate_plugin.py" \
        -o "$validator"
    fi
  fi

  if [ ! -d "$venv" ]; then
    python3 -m venv "$venv" >/dev/null
    "$venv/bin/pip" install --quiet pyyaml >/dev/null 2>&1 || {
      red "  ✘ failed to install pyyaml in $venv"
      return 1
    }
  fi

  if "$venv/bin/python" "$validator" "$root"; then
    return 0
  else
    return 1
  fi
}

validate_zed() {
  heading "zed"
  local root="$REPO_ROOT/zed"
  local ok=0

  if ! command -v cargo >/dev/null 2>&1; then
    yellow "  ⚠ skipping cargo build (cargo not on PATH)"
  else
    if cargo build --manifest-path "$root/Cargo.toml" --target wasm32-wasip2 --release >/tmp/cargo-build.log 2>&1; then
      echo "  ✔ cargo build --target wasm32-wasip2 succeeded"
    else
      echo "  ✘ cargo build failed (see /tmp/cargo-build.log):"
      tail -10 /tmp/cargo-build.log | sed 's/^/    /'
      ok=1
    fi
  fi

  # extension.toml rules from zed-industries/extensions/src/lib/validation.js:
  #   id   must match ^[a-z0-9-]+$, not start with "zed-", not end with "-zed", not include "extension"
  #   name must not start with "Zed ", not end with " Zed", not include "extension" (case-insensitive)
  #   schema_version must be 1
  python3 - "$root/extension.toml" <<'PY' || ok=1
import re, sys
path = sys.argv[1]
toml_lines = open(path).read().splitlines()
def get(key):
    for line in toml_lines:
        if line.strip().startswith(key + " "):
            return line.split("=", 1)[1].strip().strip('"')
    return None
ext_id   = get("id")
name     = get("name")
schemav  = get("schema_version")
errors = []
if not ext_id or not re.fullmatch(r"[a-z0-9-]+", ext_id):
    errors.append(f"extension id must match ^[a-z0-9-]+$ (got {ext_id!r})")
if ext_id and ext_id.startswith("zed-"):
    errors.append("extension id must not start with 'zed-'")
if ext_id and ext_id.endswith("-zed"):
    errors.append("extension id must not end with '-zed'")
if ext_id and "extension" in ext_id:
    errors.append("extension id must not include 'extension'")
if not name:
    errors.append("extension.toml is missing `name`")
elif name.startswith("Zed "):
    errors.append("extension name must not start with 'Zed '")
elif name.endswith(" Zed"):
    errors.append("extension name must not end with ' Zed'")
elif "extension" in name.lower():
    errors.append("extension name must not include 'extension'")
if schemav and schemav != "1":
    errors.append(f"schema_version must be 1 (got {schemav!r})")
if errors:
    print("  ✘ extension.toml rule violations:")
    for e in errors:
        print(f"    - {e}")
    sys.exit(1)
print("  ✔ extension.toml id/name/schema_version pass zed-industries/extensions rules")
PY

  # LICENSE must exist at the extension root with an accepted license string.
  if [ -f "$root/LICENSE" ] || [ -f "$root/LICENCE" ]; then
    echo "  ✔ LICENSE file present at extension root"
  else
    echo "  ✘ LICENSE/LICENCE file missing at extension root"
    ok=1
  fi

  return $ok
}

validate_antigravity() {
  heading "antigravity"
  local root="$REPO_ROOT/antigravity"
  local ok=0
  # Antigravity has no published CLI validator. We at minimum require valid
  # JSON for plugin.json + mcp_config.json, and we sanity-check the
  # mcp_config.json shape against what Antigravity docs describe.
  check_json "$root/plugin.json" || ok=1
  check_json "$root/mcp_config.json" || ok=1

  python3 - "$root/mcp_config.json" <<'PY' || ok=1
import json, sys
data = json.load(open(sys.argv[1]))
servers = data.get("mcpServers")
if not isinstance(servers, dict) or not servers:
    print("  ✘ mcp_config.json: top-level 'mcpServers' object missing or empty")
    sys.exit(1)
for name, entry in servers.items():
    if not isinstance(entry, dict):
        print(f"  ✘ mcp_config.json: server '{name}' is not an object")
        sys.exit(1)
    if "command" not in entry and "serverUrl" not in entry:
        print(f"  ✘ mcp_config.json: server '{name}' needs either `command` or `serverUrl`")
        sys.exit(1)
print("  ✔ mcp_config.json shape looks right (mcpServers + serverUrl/command)")
PY
  return $ok
}

for p in "${PLATFORMS[@]}"; do
  case "$p" in
    cursor)      validate_cursor; record "$p" $? ;;
    claude)      validate_claude; record "$p" $? ;;
    codex)       validate_codex; record "$p" $? ;;
    zed)         validate_zed; record "$p" $? ;;
    antigravity) validate_antigravity; record "$p" $? ;;
  esac
done

echo
bold "== Summary =="
i=0
while [ $i -lt ${#RESULT_NAMES[@]} ]; do
  if [ "${RESULT_CODES[$i]}" -eq 0 ]; then
    green "  ✔ ${RESULT_NAMES[$i]}"
  else
    red   "  ✘ ${RESULT_NAMES[$i]}"
  fi
  i=$((i + 1))
done

exit $overall
