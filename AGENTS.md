# AGENTS.md — Knowledge base for AI coding agents

This file is the canonical context for any AI coding agent (Claude Code, Cursor, Codex, Zed AI, Gemini, etc.) working in this repository. `CLAUDE.md` is a symlink to this file — edit `AGENTS.md` only.

## What this repo is

A coordinating monorepo for marketplace **plugins / extensions** that install the **Latitude MCP server** into the major AI coding agents and IDEs.

- Latitude is an open-source AI agent monitoring platform. Full observability into what's failing in production: discover underlying issues, get alerts when something breaks, verify your fix worked.
- The MCP server lives at `https://api.latitude.so/v1/mcp` — a remote, OAuth-authenticated (OAuth 2.1 + DCR), streamable HTTP MCP server.
- Tools exposed by the MCP are **dynamically generated** from the Latitude API, so the catalog stays in sync automatically.
- MCP user docs: <https://docs.latitude.so/getting-started/mcp>
- API reference: <https://api.latitude.so/docs>

### How this repo is structured at the git level

- This monorepo holds shared assets (`assets/`), agent-facing docs (`docs/`, `AGENTS.md`), and a working tree for all platforms.
- Each `<platform>/` directory is intended to live in **its own public Git repository** (e.g. `latitude-cursor`, `latitude-claude`, `latitude-codex`, `latitude-zed`, `latitude-antigravity`) so marketplace submissions can point at a single-purpose repo.
- The per-platform repos are wired back into this monorepo as **git submodules** so all five can be edited together from one working copy.
- Therefore: every `<platform>/` folder must remain **self-contained** — its own `LICENSE`, `.gitignore`, `README.md`, and `assets/` — with zero references that escape upward (no `../LICENSE`, no `../assets/icon-light.png`).

## Hard constraints (read first)

1. **Only one plugin per platform**, named "Latitude". No additional plugins.
2. **Ship only the MCP server registration.** Do not add skills, rules, agents, commands, hooks, LSPs, monitors, settings, or any other plugin component. The goal is a clean one-click MCP installer — nothing else.
3. **Don't bundle or vendor the MCP server.** Latitude is a remote HTTPS service. Each plugin only registers the URL with the host.
4. **Don't hardcode any credentials.** Auth is OAuth 2.1 with **Dynamic Client Registration (DCR)** — the client registers itself with the MCP server on first connect. The plugin only ever ships the URL. No client ID, no client secret, no API key.
5. **URL-only configs wherever the host supports remote HTTP MCP.** Cursor, Claude Code, Codex, and Antigravity all do — use their native HTTP transport, not the `mcp-remote` bridge. Zed's extension API only supports spawn-based context servers, so the Zed extension is the one exception and must use `mcp-remote`.
6. **Each `<platform>/` folder must stay self-contained.** Each one will eventually live in its own public repo, wired back into this monorepo as a submodule. So: no upward references from inside `<platform>/` — no `../LICENSE`, no `../assets/...`, no `../docs/...`. Every per-platform repo carries its own `LICENSE`, `.gitignore`, `README.md`, and `assets/`. Agent-facing docs (`AGENTS.md`, `docs/`) live only in the monorepo and **do not** belong inside any `<platform>/`.
7. The `CLAUDE.md` at the monorepo root is a **symlink** to `AGENTS.md`. Edit `AGENTS.md` only — do not delete the symlink or create a separate `CLAUDE.md`. Do not create `CLAUDE.md` or `AGENTS.md` inside any `<platform>/` folder.

## Repo layout

```
mcps/                              # ← this monorepo (the coordinating repo)
├── cursor/                        # → submodule: latitude-cursor
│   ├── .cursor-plugin/plugin.json
│   ├── mcp.json                   # Latitude MCP server config
│   ├── assets/                    # Logos (own copy)
│   ├── .gitignore
│   ├── LICENSE
│   └── README.md
├── claude/                        # → submodule: latitude-claude
│   ├── .claude-plugin/plugin.json
│   ├── .mcp.json                  # Latitude MCP server config (note leading dot)
│   ├── assets/
│   ├── .gitignore
│   ├── LICENSE
│   └── README.md
├── codex/                         # → submodule: latitude-codex
│   ├── .codex-plugin/plugin.json
│   ├── .mcp.json                  # Latitude MCP server config
│   ├── assets/
│   ├── .gitignore
│   ├── LICENSE
│   └── README.md
├── zed/                           # → submodule: latitude-zed
│   ├── extension.toml
│   ├── Cargo.toml
│   ├── src/lib.rs
│   ├── assets/
│   ├── .gitignore
│   ├── LICENSE
│   └── README.md
├── antigravity/                   # → submodule: latitude-antigravity
│   ├── plugin.json
│   ├── mcp_config.json
│   ├── assets/
│   ├── .gitignore
│   ├── LICENSE
│   └── README.md
├── assets/                        # Canonical light/dark icons (source of truth)
│   ├── icon-light.png
│   └── icon-dark.png
├── docs/                          # Plugin-system references + plan
│   ├── plan.md
│   ├── cursor.md
│   ├── claude.md
│   ├── codex.md
│   ├── zed.md
│   └── antigravity.md
├── .gitignore
├── LICENSE
├── README.md
├── AGENTS.md                      # ← this file
└── CLAUDE.md → AGENTS.md          # symlink (monorepo-only)
```

Icons are duplicated into each `<platform>/assets/` directory because each plugin must be self-contained — marketplaces clone or zip each plugin in isolation, and once the platform folder is its own repo there's no parent `assets/` to reach into. The canonical copies live at `/assets/`; the duplicates in each platform folder are kept in sync with those.

## Latitude descriptor (use this verbatim in plugin metadata)

- name: `Latitude`
- title: `Latitude`
- description: `Open-source AI agent monitoring platform. Full observability into what's failing in production. Discover underlying issues, get alerts when something breaks and verify your fix worked.`
- websiteUrl: `https://latitude.so`
- icons:
  - light: `https://framerusercontent.com/images/fPQsqC1Gx3CiQElnbBSmbQVYcA.png`
  - dark: `https://framerusercontent.com/images/l5c1DNVxQ3iAvTDihvg9pFw2l2k.png`
- instructions: `All Latitude MCP methods have descriptions and input/output schemas. For any doubt visit the Latitude documentation: https://docs.latitude.so/llms.txt`

Local copies of the light/dark icons sit at the repo root and inside each plugin's `assets/` directory. Plugins should reference the local copy (relative path) rather than the framerusercontent URL, because most marketplaces require committed assets.

## Per-platform implementation notes

Deeper references for each host's plugin system live under `docs/`: [`docs/cursor.md`](./docs/cursor.md), [`docs/claude.md`](./docs/claude.md), [`docs/codex.md`](./docs/codex.md), [`docs/zed.md`](./docs/zed.md), [`docs/antigravity.md`](./docs/antigravity.md). The implementation + submission roadmap is in [`docs/plan.md`](./docs/plan.md).


### Cursor (`cursor/`)
- **Layout**: single-plugin (plugin at folder root, no `.cursor-plugin/marketplace.json`).
- **MCP transport**: native remote URL — Cursor supports `{ "url": "..." }` directly in `mcp.json`. No bridge needed.
- **Logo field**: `logo` in `plugin.json`, relative path resolves against the plugin root.
- **Local test**: `ln -s "$(pwd)/cursor" ~/.cursor/plugins/local/latitude`, then restart Cursor and check **Cursor Settings → Features → Model Context Protocol**.
- **Submit**: <https://cursor.com/marketplace/publish> with the public repo URL. Manual review.

### Claude Code (`claude/`)
- **Layout**: plugin at folder root, manifest at `.claude-plugin/plugin.json`.
- **MCP transport**: native HTTP — `{ "type": "http", "url": "https://api.latitude.so/v1/mcp" }` in `.mcp.json`. Claude Code's MCP layer supports remote streamable HTTP servers with OAuth + DCR, so no `mcp-remote` bridge is needed and there's no Node.js prerequisite.
  - Caveat: Latitude's manual-install docs still recommend `mcp-remote` for the Claude **Desktop** chat app (a separate product from Claude Code) because that app doesn't speak remote OAuth MCP yet. That doesn't affect this plugin — Claude Code plugins target Claude Code, not Claude Desktop.
- **Don't** put `skills/`, `agents/`, `commands/`, `hooks/`, `monitors/`, `bin/`, `settings.json`, `.lsp.json` inside the plugin. None are needed.
- **Local test**: `claude --plugin-dir ./claude`, then `/mcp`, select `latitude`, authenticate.
- **Submit**: <https://claude.ai/settings/plugins/submit> or <https://platform.claude.com/plugins/submit>. CI runs `claude plugin validate` — run it locally first.

### Codex (`codex/`)
- **Layout**: plugin at folder root, manifest at `.codex-plugin/plugin.json`.
- **MCP transport**: native HTTP. The Codex CLI manual install uses `transport = "http"` + `url = "..."` in TOML; the same key names work in JSON `.mcp.json`. Use `mcp_servers` (snake_case) as the top-level key.
- **Local test**: copy or symlink into `~/.codex/plugins/latitude/`, add an entry to `~/.agents/plugins/marketplace.json` pointing at the folder, restart Codex, then enable the plugin. The `$plugin-creator` skill inside Codex can scaffold a local marketplace entry for you.
- **Submit**: self-serve publishing is "coming soon" per Codex docs. Track <https://developers.openai.com/codex/plugins/build>. For now, the plugin is publish-ready locally; submission has to wait.

### Zed (`zed/`)
- **Layout**: a Git repository containing `extension.toml` + a Rust crate compiled to Wasm. Submitted as a **Git submodule** under `extensions/latitude/` in <https://github.com/zed-industries/extensions>.
- **MCP transport**: Zed's **extension API only supports spawn-based context servers** (`zed_extension_api::Command`). Zed's settings file accepts a `url`-only context server, but the extension API does **not** — there's no way to register a remote URL from extension code. So this is the one plugin in the monorepo that has to bridge via `mcp-remote`.
  - Implementation: `context_server_command` returns `npx -y mcp-remote https://api.latitude.so/v1/mcp`.
  - Document the Node.js prerequisite in `zed/README.md`.
  - DCR still works through the bridge — `mcp-remote` does the OAuth/DCR dance with the remote MCP and exposes a stdio transport locally.
- **License**: extension repo must contain one of the accepted licenses (MIT works). The license file goes at the extension root.
- **Naming**: extension `id` must not contain "zed" or "extension". Use `latitude` — the "popular tooling" exception in the Zed docs covers brand-name IDs.
- **Local test**: open Extensions panel → "Install Dev Extension" → pick `zed/`. Use `zed --foreground` to see `dbg!`/`println!` output.
- **Submit**: PR to <https://github.com/zed-industries/extensions> adding the extension as a submodule pointing at this repo's eventual `zed/` mirror, plus an entry in `extensions.toml`. The submodule must use HTTPS, be public, and point at a branch (not a detached commit).

### Antigravity (`antigravity/`)
- **Layout**: plugin folder containing `plugin.json` (marker file) + `mcp_config.json` at the root. **No** `.<platform>-plugin/` subdir — Antigravity discovers plugins by the presence of the `plugin.json` marker file directly at the plugin root.
- **Manifest**: minimal — `{ "name": "latitude" }`. The `name` field is optional and defaults to the directory name; we set it explicitly.
- **MCP config field name**: `serverUrl`, **not** `url`. Antigravity's schema is its own — don't copy Cursor/Claude/Codex shapes.
- **MCP transport**: native streamable HTTP — `{ "mcpServers": { "latitude": { "serverUrl": "https://api.latitude.so/v1/mcp" } } }`. Antigravity handles OAuth + DCR automatically; no client ID/secret, no bridge.
- **Don't** put `skills/`, `rules/`, or `hooks.json` in the plugin. None are needed.
- **Local test**: copy `antigravity/` into one of:
  - `~/.gemini/config/plugins/latitude/` (editor, global)
  - `~/.gemini/antigravity-cli/plugins/latitude/` (CLI, global)
  - `<workspace>/.agents/plugins/latitude/` (workspace)

  Then restart Antigravity → **Customizations** tab → **Authenticate** next to `latitude`.
- **Submit**: no public third-party submission flow yet. The bundled marketplace ("Build with Google") is curated by Google. For now the distribution path is users copying the folder into one of the install locations above. Track <https://antigravity.google/docs/plugins> for changes.

## Common pitfalls

- **Folder structure inside `.claude-plugin/`**: only `plugin.json` belongs there. `skills/`, `agents/`, `hooks/`, etc. live at the plugin **root** — never inside `.claude-plugin/`. Same pattern in `.cursor-plugin/` and `.codex-plugin/`. Antigravity is different — its `plugin.json` sits directly at the plugin root, no hidden subdir.
- **MCP config field naming is not portable across hosts**:
  - Cursor / Antigravity raw config — `url` (Cursor) vs `serverUrl` (Antigravity).
  - Claude Code — `type: "http"` + `url`.
  - Codex — `transport: "http"` + `url`, with `mcp_servers` (snake_case) at the top level.
  - Zed extensions — Rust `Command` only; no URL field via the extension API.
  Don't copy one host's MCP config into another's file.
- **Cursor single-plugin layout**: no `marketplace.json` for a single plugin. The plugin folder is the repo root for Cursor's purposes (in this monorepo, that's the `cursor/` subdir).
- **Zed extension shipping a server binary**: not allowed. Always spawn from the user environment.
- **Zed extension IDs**: must avoid `zed` and `extension` substrings; descriptive suffixes (`-theme`, `-snippets`) are recommended except for "popular tooling" brands, where the bare brand id is acceptable. We use `latitude`.
- **Icon paths**: must be relative to the plugin folder and committed to the repo. Don't reference the framerusercontent URLs from manifests — marketplaces won't accept that.
- **Symlinks for assets**: avoid them. Marketplaces clone/zip plugins and symlinks travel poorly. Copy icons into each plugin's `assets/`.

## Versioning

- Start each plugin at `0.1.0`. Bump per plugin independently as each marketplace ships updates.
- Latitude API version doesn't need to match — the MCP server URL is stable, so plugins don't need to be re-released when the API ticks.
- For Claude Code, omitting `version` in `plugin.json` falls back to commit SHA = every commit ships as a new version. Setting an explicit `version` is preferred for controlled releases.

## Validating plugins

`scripts/validate-all.sh` at the monorepo root runs every platform's validator in turn and prints a pass/fail summary. Run it from anywhere; it works out the repo root from its own location.

```bash
./scripts/validate-all.sh
```

What each platform's validator does, and how to run it standalone:

| Platform | Validator | Run standalone |
| --- | --- | --- |
| Cursor | JSON parse + `cursor-agent --plugin-dir <dir>` smoke-load. Cursor ships **no** `validate` subcommand. | `cursor-agent --plugin-dir cursor --trust -p ok --mode ask` |
| Claude Code | `claude plugin validate` — ships with the `claude` CLI. Strict; rejects unknown manifest keys. | `claude plugin validate claude` |
| Codex | Python script `validate_plugin.py` from `openai/codex` (vendored on first run into `.cache/`). Enforces required `interface.*` fields, hex `brandColor`, `mcpServers` keying, etc. | `python3 .cache/codex-validate_plugin.py codex` |
| Zed | `cargo build --target wasm32-wasip2 --release` (compile = validation) + ID/name rules ported from `zed-industries/extensions/src/lib/validation.js` + LICENSE-present check. | `cargo build --manifest-path zed/Cargo.toml --target wasm32-wasip2 --release` |
| Antigravity | JSON parse + structural check that `mcp_config.json` has a `mcpServers` map with `serverUrl` or `command` per server. Antigravity has **no** published CLI validator. | (run `validate-all.sh`) |

### Gotchas

- **Claude `displayName` rejection**: `claude plugin validate` in v2.1.141 reports `Unrecognized key: "displayName"` even though the docs say it was added in v2.1.143. Until 2.1.143 ships, leave `displayName` out of `claude/.claude-plugin/plugin.json`.
- **Codex first-run cost**: the first invocation downloads `validate_plugin.py` and provisions a `pyyaml` venv under `.cache/`. Subsequent runs are instant. The `.cache/` directory is gitignored.
- **Zed build target**: `wasm32-wasip2` is the current Zed extension target. Older docs reference `wasm32-wasip1` which also works; `rustup target add wasm32-wasip2` may be needed.
- **Cursor local installs don't follow symlinks**: Cursor's plugin docs suggest `ln -s … ~/.cursor/plugins/local/<name>`, but stable Cursor (≥ 3.4.20 tested) silently skips symlinks. Use `cp -R` and re-copy when iterating.
- **Cursor local installs don't render `logo` / `description`**: Cursor resolves the manifest's relative `logo` path to a `raw.githubusercontent.com` URL using the marketplace's repo+SHA record, which doesn't exist for local installs. Description and icon both surface only after marketplace publishing. Don't chase this during local testing — it's expected.

## Working with submodules

Once each `<platform>/` is its own public repo wired back in as a submodule, normal `git` operations inside a platform folder act on the submodule's repo, not the monorepo. Workflow:

```bash
# Initial bring-up
git clone --recurse-submodules <monorepo>
# Or, if cloned already:
git submodule update --init --recursive

# Pick up latest from every platform repo
git submodule update --remote --merge

# Edits inside <platform>/:
cd cursor
git checkout main          # avoid detached HEAD
# … make changes …
git add . && git commit -m "..." && git push
cd ..
git add cursor && git commit -m "bump cursor submodule" && git push
```

Common pitfalls when working as an AI agent:
- After editing files in a `<platform>/` folder, run `git status` *both* from the platform folder (which sees the submodule's working tree) and from the monorepo root (which sees the gitlink change). Both need their own commit.
- A submodule sitting on a detached HEAD will accept commits but won't push them anywhere useful — always check the branch first.
- Don't commit a monorepo gitlink that points at an unpushed submodule commit. Push the submodule first.

## When making changes

- **Logos / branding**: update `assets/icon-light.png` / `assets/icon-dark.png` at the monorepo root (source of truth), then re-copy into each `<platform>/assets/`. Don't change one without the others.
- **MCP URL or auth model**: this is set by the Latitude backend. If it ever changes, every plugin's MCP config has to be updated in lockstep.
- **Adding a new host platform**: create a sibling folder. Add a `docs/<platform>.md` reference and update `docs/plan.md` and `README.md`. Mirror the constraint set above (single plugin, MCP-only).
