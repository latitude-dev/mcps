# Implementation Plan

Per-platform plan to ship a single **Latitude** plugin into each major coding-agent / IDE marketplace.

The MCP server itself is already deployed at `https://api.latitude.so/v1/mcp` with OAuth — this repo is purely about packaging that endpoint as a one-click install across hosts.

## Goals

- One Latitude plugin per host, scoped strictly to MCP server registration.
- Self-contained, publishable artifact per `<host>/` subfolder (so each can be mirrored to its own public repo when a marketplace requires it).
- Identical metadata (name, description, icons, website) across hosts so users see consistent branding everywhere.
- No skills, rules, agents, commands, hooks, monitors, LSPs, settings, or other components.
- **URL-only configs** wherever the host supports remote HTTP MCP. The Latitude MCP server uses OAuth 2.1 with **Dynamic Client Registration**, so the URL is literally the only thing every plugin needs to ship. No client IDs, no API keys, no bridges — except for Zed, where the extension API forces a spawn-based command (see §4).

## Cross-cutting work (do once)

| Item | Status |
| --- | --- |
| Pick a canonical name (`Latitude`) and identifier (`latitude` everywhere, including the Zed extension id) | ✅ |
| Commit light/dark icons at repo root and inside each `<host>/assets/` | ✅ |
| Root `README.md`, `AGENTS.md`, `.gitignore`, `LICENSE` (MIT, inherited) | ✅ |
| MCP descriptor (description, website, instructions, icons) reused across all plugins | ✅ documented in `AGENTS.md` |

## Per-platform plans

### 1. Cursor — `cursor/`

**Distribution path**: [Cursor Marketplace](https://cursor.com/marketplace). Manually reviewed. Plugin is consumed as a Git repo.

**Layout**: single-plugin layout per Cursor docs ("move plugin folder contents to the repository root, keep one `.cursor-plugin/plugin.json`, and remove `.cursor-plugin/marketplace.json`"). In this monorepo, `cursor/` plays the role of the plugin root.

**Files**:
- `cursor/.cursor-plugin/plugin.json` — manifest: `name=latitude`, `displayName=Latitude`, `description`, `version`, `author`, `homepage`, `repository`, `license`, `keywords`, `logo: assets/icon-light.png`.
- `cursor/mcp.json` — `{ "mcpServers": { "latitude": { "url": "https://api.latitude.so/v1/mcp" } } }`. Cursor supports remote URL MCP servers directly.
- `cursor/assets/icon-light.png` / `icon-dark.png` — committed icons.
- `cursor/README.md` — install / manual / submission notes.

**Local test**:
```bash
ln -s "$(pwd)/cursor" ~/.cursor/plugins/local/latitude
# Restart Cursor (or run "Developer: Reload Window").
# Verify Latitude appears under Settings → Features → Model Context Protocol.
```

**Submit**: <https://cursor.com/marketplace/publish>. Either point Cursor at this monorepo (it understands subdirectory-as-plugin), or create a sibling public repo containing only `cursor/`'s contents at its root.

**Risks / open questions**:
- The Cursor marketplace submission form may require the plugin at the repo root, not a subdir. If so, mirror `cursor/` into `latitude-cursor-plugin` (a thin public repo) at submission time.

---

### 2. Claude Code — `claude/`

**Distribution path**: [Claude plugins directory](https://claude.com/plugins) (community marketplace). Reviewed by Anthropic. Submitted via <https://claude.ai/settings/plugins/submit>.

**Layout**: per Claude Code plugin docs — manifest in `.claude-plugin/plugin.json`, `.mcp.json` at the plugin root, no other component directories.

**Files**:
- `claude/.claude-plugin/plugin.json` — `name=latitude`, `description`, `version`, `author`, `homepage`, `repository`, `license`, `keywords`.
- `claude/.mcp.json` — native HTTP transport, URL only:
  ```json
  {
    "mcpServers": {
      "latitude": {
        "type": "http",
        "url": "https://api.latitude.so/v1/mcp"
      }
    }
  }
  ```
  Claude Code supports remote streamable HTTP MCP with OAuth + DCR, so the URL alone is enough. The `mcp-remote` bridge that Latitude docs recommend for the Claude **Desktop** chat app is unrelated — Claude Code plugins target the Claude Code agent, not Claude Desktop.
- `claude/assets/icon-light.png` / `icon-dark.png`.
- `claude/README.md` — install / manual / submission notes.

**Local test**:
```bash
claude --plugin-dir ./claude
# Inside Claude Code: /mcp → select latitude → Authenticate.
```

Pre-submission: run `claude plugin validate` against `claude/`.

**Submit**: <https://claude.ai/settings/plugins/submit>. Approved plugins land in [`anthropics/claude-plugins-community`](https://github.com/anthropics/claude-plugins-community) and sync nightly.

**Risks / open questions**:
- Whether Anthropic accepts plugins that only register an MCP server (and ship nothing else). Worth checking before submission — the docs imply yes (MCP servers are a first-class plugin component).

---

### 3. Codex — `codex/`

**Distribution path**: [Codex plugins directory](https://developers.openai.com/codex/plugins). Self-serve publishing is "coming soon" per OpenAI docs — for now, the artifact is publish-ready locally, but submission is gated.

**Layout**: per Codex plugin docs — manifest in `.codex-plugin/plugin.json`, `.mcp.json` at plugin root.

**Files**:
- `codex/.codex-plugin/plugin.json` — `name=latitude`, `version`, `description`, `author`, `homepage`, `repository`, `license`, `keywords`, `mcpServers: ./.mcp.json`, and an `interface` block with `displayName`, `shortDescription`, `longDescription`, `developerName`, `category`, `websiteURL`, `logo`, `composerIcon`.
- `codex/.mcp.json`:
  ```json
  {
    "mcp_servers": {
      "latitude": {
        "transport": "http",
        "url": "https://api.latitude.so/v1/mcp"
      }
    }
  }
  ```
  Codex natively supports remote HTTP MCP (CLI manual install uses `transport = "http"`), so no `mcp-remote` bridge is needed.
- `codex/assets/icon-light.png` / `icon-dark.png` / `logo.png` (logo can reuse the light icon).
- `codex/README.md`.

**Local test**:
1. Copy / symlink `codex/` into `~/.codex/plugins/latitude/`.
2. Add an entry pointing at that directory in `~/.agents/plugins/marketplace.json` (or use the in-Codex `$plugin-creator` skill to scaffold one).
3. Restart Codex; the plugin appears in the directory.

**Submit**: pending — Codex public publishing flow is not GA yet. Track <https://developers.openai.com/codex/plugins/build>.

**Risks / open questions**:
- JSON-form `transport: "http"` is inferred from the TOML manual-install docs. If Codex's `.mcp.json` parser doesn't accept it, fall back to spawning `mcp-remote` via `command`/`args`.
- Codex's `interface` schema has many fields; we'll fill out the required ones and leave optional polish (screenshots, brand color, default prompts) for a follow-up.

---

### 4. Zed — `zed/`

**Distribution path**: [Zed extensions marketplace](https://zed.dev/extensions). Submitted as a Git submodule PR to [`zed-industries/extensions`](https://github.com/zed-industries/extensions).

**Layout**: a Zed extension is a Git repo with `extension.toml` + a Rust crate compiled to Wasm.

**Files**:
- `zed/extension.toml` — `id=latitude` (the bare brand id is OK under the Zed docs' "popular tooling" exception; must avoid the substrings "zed" and "extension"), `name=Latitude`, `version`, `schema_version=1`, `authors`, `description`, `repository`, `[context_servers.latitude]`.
- `zed/Cargo.toml` — `crate-type = ["cdylib"]`, depends on `zed_extension_api`.
- `zed/src/lib.rs` — implements `zed::Extension` and `context_server_command`, returning `npx -y mcp-remote https://api.latitude.so/v1/mcp`. The Zed extension API only supports spawn-based MCP servers, so a Node bridge is unavoidable for a remote OAuth MCP even though DCR removes any other client-side setup.
- `zed/LICENSE` — required at the extension root (one of the accepted licenses). MIT.
- `zed/README.md` — install + Node.js prerequisite.
- `zed/assets/icon-light.png` / `icon-dark.png`.

**Local test**:
1. Zed → Extensions panel → "Install Dev Extension" → pick `zed/`.
2. Open the Agent panel and verify Latitude appears under context servers; click Authenticate.
3. For verbose logs: `zed --foreground`.

**Submit**:
1. Mirror `zed/` to its own public repo (e.g. `latitude-dev/zed-latitude`) with an accepted license at the root and a publicly visible branch.
2. Fork `zed-industries/extensions` and add the extension as a submodule under `extensions/latitude/`.
3. Add an entry to `extensions.toml`.
4. Run `pnpm sort-extensions`.
5. Open the PR.

**Risks / open questions**:
- Zed's `zed_extension_api` version compatibility: pick the latest stable release on crates.io that supports `context_server_command` (≥ `0.1.0` works; bump as Zed advances).
- If Node.js isn't installed, the spawn will fail. Documented in `zed/README.md`. A future alternative would be a small Rust HTTP-to-stdio bridge compiled to a binary the extension downloads — defer until requested.

---

### 5. Antigravity — `antigravity/`

**Distribution path**: Google Antigravity uses bundled plugins ("Build with Google") for first-party / curated entries and a drop-in directory discovery mechanism for everything else. There's no public self-serve submission flow documented yet.

**Layout**: per the [Antigravity plugin docs](https://antigravity.google/docs/plugins) — `plugin.json` marker at the plugin root, `mcp_config.json` next to it, optional `skills/` / `rules/` / `hooks.json`.

**Files**:
- `antigravity/plugin.json` — marker file. We set `{ "name": "latitude" }` even though `name` is optional (defaults to directory name) — explicit is friendlier when grepping.
- `antigravity/mcp_config.json`:
  ```json
  {
    "mcpServers": {
      "latitude": {
        "serverUrl": "https://api.latitude.so/v1/mcp"
      }
    }
  }
  ```
  Antigravity supports remote streamable HTTP MCP, and **automatically handles OAuth for DCR-enabled servers** — so the URL alone is enough. Field name is `serverUrl` (not `url`); don't copy from another host's MCP config.
- `antigravity/assets/icon-light.png` / `icon-dark.png`.
- `antigravity/README.md`.

**Local test**: copy `antigravity/` into one of the discovery directories:
- `~/.gemini/config/plugins/latitude/` (Antigravity editor, global)
- `~/.gemini/antigravity-cli/plugins/latitude/` (Antigravity CLI, global)
- `<workspace>/.agents/plugins/latitude/` (workspace)

Restart Antigravity → **Customizations** tab → **Authenticate** next to `latitude`.

**Submit**: no public submission flow today. Distribution today = users manually copying the plugin folder, or reaching out to Google for "Build with Google" inclusion. Track <https://antigravity.google/docs/plugins>.

**Risks / open questions**:
- Whether `serverUrl` accepts plain DCR with no extra hints, or if we'll eventually need to also include `oauth: { clientId, clientSecret }` for fallback. The Antigravity docs explicitly say DCR works URL-only, so this is just a watch-item.
- The Latitude `docs.latitude.so/getting-started/mcp` page references `~/.antigravity/mcp.json` as the manual MCP path; the actual Antigravity docs put it at `~/.gemini/antigravity/mcp_config.json`. The Latitude doc may need an upstream fix.

## Open decisions (not blockers)

- Whether each `<host>/` ever needs to live in its own dedicated public repo for marketplace ingestion (Cursor / Zed especially). The monorepo is the source of truth; we can mirror per host on demand.
- Whether to add a CI step (GitHub Actions) that validates each plugin on PR — `cursor` doesn't have a CLI validator anymore, `claude plugin validate` exists, Zed extensions get validated by the central PR pipeline. Worth adding once the plugins stabilize.

## Sequencing

1. Land monorepo skeleton (root files, per-host folders with skeletons). **← current step**
2. Local-test each plugin once against its host.
3. Lock metadata (icons, descriptions, keywords) for consistency.
4. Submit / publish in this order, lowest friction first:
   1. Cursor (manual review, no GA dependency).
   2. Claude Code (review pipeline, CI runs `claude plugin validate`).
   3. Zed (submodule PR, license + naming gates apply).
   4. Antigravity (no formal submission yet — publish as a drop-in folder on GitHub, optionally reach out to Google for "Build with Google" inclusion).
   5. Codex (waits for self-serve publishing GA).
