# Codex — Plugin system reference

Source of truth: <https://developers.openai.com/codex/plugins/build>.

A Codex plugin bundles **skills, MCP servers, app integrations, and lifecycle hooks** for distribution through Codex marketplaces. Plugins are scoped via JSON marketplace catalogs that Codex can install and track.

## Marketplaces

Codex reads marketplaces from any of these locations (and any combination):

- The curated official marketplace (powers the public Plugin Directory).
- Repo marketplace: `$REPO_ROOT/.agents/plugins/marketplace.json`
- Legacy-compatible: `$REPO_ROOT/.claude-plugin/marketplace.json`
- Personal marketplace: `~/.agents/plugins/marketplace.json`

A marketplace is just a JSON catalog of plugins. Codex installs each plugin into `~/.codex/plugins/cache/$MARKETPLACE_NAME/$PLUGIN_NAME/$VERSION/`. Each plugin's on/off state is stored in `~/.codex/config.toml`.

## Plugin directory structure

```
my-plugin/
├── .codex-plugin/
│   └── plugin.json     # Required: manifest (only file inside .codex-plugin)
├── skills/             # Optional: <name>/SKILL.md folders
├── hooks/hooks.json    # Optional: lifecycle hooks (off by default; gated by features.plugin_hooks)
├── .mcp.json           # Optional: MCP server configs
├── .app.json           # Optional: app or connector mappings
└── assets/             # Optional: icons, logos, screenshots
```

Only `plugin.json` belongs in `.codex-plugin/`. Everything else at plugin root.

For Latitude we ship **only** `plugin.json`, `.mcp.json`, `assets/`, and `README.md`.

## Manifest (`.codex-plugin/plugin.json`)

Top-level fields define package metadata and point to bundled components. The `interface` block controls how install surfaces present the plugin.

```json
{
  "name": "my-plugin",
  "version": "0.1.0",
  "description": "...",
  "author": { "name": "...", "email": "...", "url": "..." },
  "homepage": "...",
  "repository": "...",
  "license": "MIT",
  "keywords": ["..."],
  "skills": "./skills/",
  "mcpServers": "./.mcp.json",
  "apps": "./.app.json",
  "hooks": "./hooks/hooks.json",
  "interface": {
    "displayName": "My Plugin",
    "shortDescription": "...",
    "longDescription": "...",
    "developerName": "...",
    "category": "Productivity",
    "capabilities": ["Read", "Write"],
    "websiteURL": "https://...",
    "privacyPolicyURL": "https://...",
    "termsOfServiceURL": "https://...",
    "defaultPrompt": ["..."],
    "brandColor": "#10A37F",
    "composerIcon": "./assets/icon.png",
    "logo": "./assets/logo.png",
    "screenshots": ["./assets/screenshot-1.png"]
  }
}
```

Path rules:
- All paths are relative to the plugin root and must start with `./`.
- Visual assets live under `./assets/` by convention.

## MCP server config (`.mcp.json`)

Direct server map (or wrap with a top-level `mcp_servers` key — both accepted):

```json
{
  "mcp_servers": {
    "<name>": {
      "transport": "http",
      "url": "https://api.example.com/mcp"
    },
    "<stdio-example>": {
      "command": "docs-mcp",
      "args": ["--stdio"]
    }
  }
}
```

Codex supports remote HTTP MCP natively (Codex CLI manual install uses `transport = "http"` in TOML). For Latitude the URL is enough — DCR handles OAuth client registration on first connect.

After install, users can tune approval policy from `~/.codex/config.toml`:

```toml
[plugins."my-plugin".mcp_servers.docs]
enabled = true
default_tools_approval_mode = "prompt"
enabled_tools = ["search"]

[plugins."my-plugin".mcp_servers.docs.tools.search]
approval_mode = "approve"
```

## Marketplace catalog

A marketplace catalog can hold one plugin (during testing) or many. Entries point at plugin source paths; Codex resolves them relative to the marketplace root.

```json
{
  "name": "local-example-plugins",
  "interface": { "displayName": "Local Example Plugins" },
  "plugins": [
    {
      "name": "my-plugin",
      "source": { "source": "local", "path": "./plugins/my-plugin" },
      "policy": { "installation": "AVAILABLE", "authentication": "ON_INSTALL" },
      "category": "Productivity"
    }
  ]
}
```

`source.source` values:
- `"local"` — local path. Can also be a plain string (`"source": "./plugins/my-plugin"`).
- `"url"` — Git-backed plugin at repo root.
- `"git-subdir"` — Git-backed plugin in a subdirectory. Supports `url`, `path`, `ref`, `sha`.

`policy.installation`: `AVAILABLE`, `INSTALLED_BY_DEFAULT`, `NOT_AVAILABLE`.
`policy.authentication`: usually `ON_INSTALL` or first-use.

## CLI

```bash
# Add a marketplace
codex plugin marketplace add owner/repo
codex plugin marketplace add owner/repo --ref main
codex plugin marketplace add https://github.com/example/plugins.git --sparse .agents/plugins
codex plugin marketplace add ./local-marketplace-root

# Refresh / remove
codex plugin marketplace upgrade
codex plugin marketplace upgrade <name>
codex plugin marketplace remove <name>
```

## Local development

The built-in `$plugin-creator` skill inside Codex scaffolds both a plugin manifest and a marketplace entry. Manually:

1. Copy the plugin into `~/.codex/plugins/<name>` (personal) or `$REPO_ROOT/plugins/<name>` (repo).
2. Add an entry under `plugins[]` in `~/.agents/plugins/marketplace.json` (personal) or `$REPO_ROOT/.agents/plugins/marketplace.json` (repo) pointing at that directory.
3. Restart Codex; the plugin appears in the directory.

When you change the plugin, update the directory the marketplace entry points at and restart Codex.

## Lifecycle hooks

Plugin hooks are **off by default**; gated by `[features].plugin_hooks = true` in `~/.codex/config.toml`. When enabled, the default file is `hooks/hooks.json`. Hook commands receive `PLUGIN_ROOT` and `PLUGIN_DATA` env vars (plus `CLAUDE_PLUGIN_ROOT`/`CLAUDE_PLUGIN_DATA` for compatibility). Same event schema as regular Codex hooks.

## Submission

Self-serve plugin publishing and management are **coming soon** per the Codex docs. For now, the artifact is publish-ready locally but submission is gated. Track <https://developers.openai.com/codex/plugins/build>.
