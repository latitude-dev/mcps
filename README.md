# Latitude — Plugins & Extensions

Marketplace plugins / extensions for the [Latitude](https://latitude.so) MCP server across the major coding agents and IDEs.

Each plugin is a one-click installer for the Latitude MCP server — a remote, OAuth-authenticated, streamable HTTP Model Context Protocol server living at `https://api.latitude.so/v1/mcp`. Once installed and authorized, the host agent can read and manage your Latitude workspace (projects, members, keys, traces, annotations, scores, searches, issues, datasets, and more).

About Latitude: open-source AI agent monitoring platform. Full observability into what's failing in production. Discover underlying issues, get alerts when something breaks, and verify your fix worked.

- Website: <https://latitude.so>
- Docs: <https://docs.latitude.so>
- MCP docs: <https://docs.latitude.so/getting-started/mcp>

## Layout

```
mcps/
├── cursor/        # Cursor plugin (Cursor Marketplace)
├── claude/        # Claude Code plugin (Claude plugins directory)
├── codex/         # Codex plugin (Codex plugin directory)
├── zed/           # Zed extension (Zed extensions marketplace)
├── antigravity/   # Google Antigravity plugin (Customizations / Build with Google)
├── assets/        # Canonical light/dark icons (each plugin keeps its own copy)
├── docs/          # Per-platform plugin-system references + implementation plan
├── AGENTS.md      # Knowledge base for AI coding agents (CLAUDE.md → AGENTS.md)
└── README.md
```

Each `<platform>/` subfolder is a **self-contained, publishable repository** for its target marketplace. The plan is to publish each platform as its own public repo (e.g. `latitude-cursor`, `latitude-claude`, …) and link them back into this monorepo via **git submodules**, so all five plugins can be edited from one working copy.

Each `<platform>/` ships its own `LICENSE`, `.gitignore`, `README.md`, and `assets/` — once detached, the folder needs zero changes to be a working repo for marketplace submission.

Icons are duplicated into each plugin's `assets/` because marketplaces clone/zip plugins individually and assets need to be resolvable inside each plugin's tree.

### Working with submodules

After each platform repo is created and added back as a submodule, the typical loop is:

```bash
# Initial clone
git clone --recurse-submodules <this-repo>
# Or, if already cloned without submodules:
git submodule update --init --recursive

# Pull latest for all platforms
git submodule update --remote --merge

# When making changes in <platform>/, push the submodule first,
# then commit the new SHA in the monorepo:
cd cursor && git add . && git commit -m "..." && git push && cd ..
git add cursor && git commit -m "bump cursor submodule" && git push
```

If submodule UX becomes a friction point, an alternative is keeping this as a regular monorepo and using a GitHub Action like [`s0/git-publish-subdir-action`](https://github.com/s0/git-publish-subdir-action) to mirror each `<platform>/` to its own public repo on push.

## What gets shipped

Every plugin ships **only** the Latitude MCP server registration. No skills, rules, agents, commands, hooks, or other components. The goal is a friction-free one-click install of the MCP server.

After install, the user is taken through the host's standard MCP authorization flow (OAuth) and chooses the Latitude organization the agent should access.

## Per-platform quick reference

| Platform | Manifest | MCP config | Submission |
| --- | --- | --- | --- |
| Cursor | `cursor/.cursor-plugin/plugin.json` | `cursor/mcp.json` | <https://cursor.com/marketplace/publish> |
| Claude Code | `claude/.claude-plugin/plugin.json` | `claude/.mcp.json` | <https://claude.ai/settings/plugins/submit> |
| Codex | `codex/.codex-plugin/plugin.json` | `codex/.mcp.json` | Self-serve publishing coming soon |
| Zed | `zed/extension.toml` + Rust crate | `context_server_command` in `src/lib.rs` | PR to [`zed-industries/extensions`](https://github.com/zed-industries/extensions) |
| Antigravity | `antigravity/plugin.json` | `antigravity/mcp_config.json` | Manual install (no public submission flow yet) |

## Validating

A single command validates all five plugins:

```bash
./scripts/validate-all.sh
```

Under the hood it runs `claude plugin validate`, Codex's `validate_plugin.py`, `cargo build` for the Zed extension, and a `cursor-agent --plugin-dir` smoke-load for Cursor. See [`AGENTS.md`](./AGENTS.md#validating-plugins) for the per-platform details.

## Docs

- [`docs/plan.md`](./docs/plan.md) — implementation & submission plan
- [`docs/cursor.md`](./docs/cursor.md) — Cursor plugin system reference
- [`docs/claude.md`](./docs/claude.md) — Claude Code plugin system reference
- [`docs/codex.md`](./docs/codex.md) — Codex plugin system reference
- [`docs/zed.md`](./docs/zed.md) — Zed extension system reference
- [`docs/antigravity.md`](./docs/antigravity.md) — Antigravity plugin system reference
- [`AGENTS.md`](./AGENTS.md) — agent-facing knowledge base

## License

[MIT](./LICENSE)
